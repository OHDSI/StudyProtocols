# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of QuantifyingBiasInApapStudies
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Create the exposure and outcome cohorts
#'
#' @details
#' This function will create the exposure and outcome cohorts following the definitions included in
#' this package.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                          cohortTable = "cohort",
                          oracleTempSchema,
                          outputFolder) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  
  ParallelLogger::logInfo("Creating ATLAS cohorts")
  .createCohorts(connection = connection,
                 cdmDatabaseSchema = cdmDatabaseSchema,
                 cohortDatabaseSchema = cohortDatabaseSchema,
                 cohortTable = cohortTable,
                 oracleTempSchema = oracleTempSchema,
                 outputFolder = outputFolder)
  
  ParallelLogger::logInfo("Creating negative control outcome cohorts")
  createNegativeControlCohorts(connection = connection,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               cohortTable = cohortTable,
                               oracleTempSchema = oracleTempSchema)
  
  ParallelLogger::logInfo("Creating exposure cohorts")
  createExposureCohorts(connection = connection,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        cohortDatabaseSchema = cohortDatabaseSchema,
                        cohortTable = cohortTable,
                        oracleTempSchema = oracleTempSchema)
  
  # Check number of subjects per cohort:
  ParallelLogger::logInfo("Counting cohorts")
  countCohorts(connection = connection,
               cdmDatabaseSchema = cdmDatabaseSchema,
               cohortDatabaseSchema = cohortDatabaseSchema,
               cohortTable = cohortTable,
               oracleTempSchema = oracleTempSchema,
               outputFolder = outputFolder)
  
}

createNegativeControlCohorts <- function(connection,
                                         cdmDatabaseSchema,
                                         cohortDatabaseSchema,
                                         cohortTable,
                                         oracleTempSchema) {
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  negativeControlOutcomes <- negativeControls[negativeControls$type == "outcome", ]
  sql <- SqlRender::loadRenderTranslateSql("NegativeControlOutcomes.sql",
                                           "QuantifyingBiasInApapStudies",
                                           dbms =  connection@dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = cohortDatabaseSchema,
                                           target_cohort_table = cohortTable,
                                           outcome_ids = negativeControlOutcomes$outcomeId)
  DatabaseConnector::executeSql(connection, sql)
}

createExposureCohorts <- function(connection,
                                  cdmDatabaseSchema,
                                  cohortDatabaseSchema,
                                  cohortTable,
                                  oracleTempSchema) {
  # connection <- DatabaseConnector::connect(connectionDetails)
  washoutDays <- 4*365.25
  periodStartDate <- "2008-01-01"
  periodEndDate <- "2008-12-31"
  minAge <- 50
  maxAge <- 76
  
  # Get initial set of eligible individuals (persons with observation somewhere during period):
  sql <- SqlRender::loadRenderTranslateSql("GetEligibleSubjects.sql",
                                           "QuantifyingBiasInApapStudies",
                                           dbms =  connection@dbms,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           washout_days = washoutDays,
                                           period_start_date = periodStartDate,
                                           period_end_date = periodEndDate,
                                           min_age = minAge,
                                           max_age = maxAge)
  persons <- DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
  # Sample index dates in R to assure reproducibility:
  set.seed(123)
  persons$indexDate <- as.Date(periodStartDate) + sample.int(1 + as.integer(as.Date(periodEndDate) - as.Date(periodStartDate)),
                                                             nrow(persons), 
                                                             replace = TRUE) - 1
  
  # Can only bulk upload into permanent table. Move to temp table later:
  tableName <- paste(cohortDatabaseSchema, paste(sample(letters, 10), collapse = ""), sep = ".")
  DatabaseConnector::insertTable(connection = connection, 
                                 tableName = tableName,
                                 data = persons,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE, 
                                 tempTable = FALSE, 
                                 oracleTempSchema = oracleTempSchema,
                                 useMppBulkLoad = TRUE, 
                                 camelCaseToSnakeCase = TRUE)
  sql <- "
  IF OBJECT_ID('tempdb..#index_date', 'U') IS NOT NULL
	DROP TABLE #index_date;
  SELECT * INTO #index_date FROM @table_name;"
  DatabaseConnector::renderTranslateExecuteSql(connection, sql, table_name = tableName, progressBar = FALSE, reportOverallTime = FALSE)
  
  sql <- "TRUNCATE TABLE @table_name; DROP TABLE @table_name;"
  DatabaseConnector::renderTranslateExecuteSql(connection, sql, table_name = tableName, progressBar = FALSE, reportOverallTime = FALSE)
  
  # Create target and comparator cohorts:
  sql <- SqlRender::loadRenderTranslateSql("CreateExposureCohorts.sql",
                                           "QuantifyingBiasInApapStudies",
                                           dbms =  connection@dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           washout_days = washoutDays,
                                           target_database_schema = cohortDatabaseSchema,
                                           target_cohort_table = cohortTable)
  DatabaseConnector::executeSql(connection, sql)
  
  
}

countCohorts <- function(connection,
                         cdmDatabaseSchema,
                         cohortDatabaseSchema,
                         cohortTable = "cohort",
                         oracleTempSchema,
                         outputFolder) {
  sql <- SqlRender::loadRenderTranslateSql("GetCounts.sql",
                                           "QuantifyingBiasInApapStudies",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable)
  counts <- DatabaseConnector::querySql(connection, sql)
  colnames(counts) <- SqlRender::snakeCaseToCamelCase(colnames(counts))
  counts <- addCohortNames(counts)
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"), row.names = FALSE)
}

addCohortNames <- function(data, IdColumnName = "cohortDefinitionId", nameColumnName = "cohortName") {
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "QuantifyingBiasInApapStudies")
  cohortsToCreate <- read.csv(pathToCsv)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  
  idToName <- data.frame(cohortId = c(cohortsToCreate$cohortId, 
                                      negativeControls$outcomeId),
                         cohortName = c(as.character(cohortsToCreate$fullName), 
                                        as.character(negativeControls$outcomeName)))
  idToName <- idToName[order(idToName$cohortId), ]
  idToName <- idToName[!duplicated(idToName$cohortId), ]
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data) , (idCol+1):(ncol(data)-1))]
  }
  return(data)
}
