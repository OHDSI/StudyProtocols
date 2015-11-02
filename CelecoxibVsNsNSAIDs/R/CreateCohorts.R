# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of CelecoxibVsNsNSAIDs
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
#' @param workDatabaseSchema   Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param studyCohortTable     The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param cdmVersion           Version of the CDM. Can be "4" or "5"
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_celecoxib_nsnsaids",
                          oracleTempSchema,
                          cdmVersion = 5,
                          outputFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)

  # Create study cohort table structure:
  sql <- "IF OBJECT_ID('@work_database_schema.@study_cohort_table', 'U') IS NOT NULL\n  DROP TABLE @work_database_schema.@study_cohort_table;\n    CREATE TABLE @work_database_schema.@study_cohort_table (cohort_definition_id INT, subject_id BIGINT, cohort_start_date DATE, cohort_end_date DATE);"
  sql <- SqlRender::renderSql(sql,
                              work_database_schema = workDatabaseSchema,
                              study_cohort_table = studyCohortTable)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

  writeLines("- Creating treatment cohort")
  sql <- SqlRender::loadRenderTranslateSql("Treatment.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 1)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating comparator cohort")
  sql <- SqlRender::loadRenderTranslateSql("Comparator.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 2)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating myocardial infarction cohort")
  sql <- SqlRender::loadRenderTranslateSql("MyocardialInfarction.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 10)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating myocardial infarction and ischemic death cohort")
  sql <- SqlRender::loadRenderTranslateSql("MiAndIschemicDeath.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 11)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating gastrointestinal hemorrhage cohort")
  sql <- SqlRender::loadRenderTranslateSql("GiHemorrhage.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 12)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating angioedema cohort")
  sql <- SqlRender::loadRenderTranslateSql("Angioedema.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 13)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating acute renal failure cohort")
  sql <- SqlRender::loadRenderTranslateSql("AcuteRenalFailure.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 14)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating drug induced liver injury cohort")
  sql <- SqlRender::loadRenderTranslateSql("DrugInducedLiverInjury.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 15)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating heart failure cohort")
  sql <- SqlRender::loadRenderTranslateSql("HeartFailure.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 16)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating negative control outcome cohort")
  sql <- SqlRender::loadRenderTranslateSql("NegativeControls.sql",
                                           "CelecoxibVsNsNSAIDs",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable)
  DatabaseConnector::executeSql(conn, sql)

  # Check number of subjects per cohort:
  sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @work_database_schema.@study_cohort_table GROUP BY cohort_definition_id"
  sql <- SqlRender::renderSql(sql,
                              work_database_schema = workDatabaseSchema,
                              study_cohort_table = studyCohortTable)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  counts <- DatabaseConnector::querySql(conn, sql)
  names(counts) <- SqlRender::snakeCaseToCamelCase(names(counts))
  counts <- addOutcomeNames(counts, "cohortDefinitionId")
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"))
  print(counts)

  RJDBC::dbDisconnect(conn)
}

#' Add names to a data frame with outcome IDs
#'
#' @param data                  The data frame to add the outcome names to
#' @param outcomeIdColumnName   The name of the column in the data frame that holds the outcome IDs.
#'
#' @export
addOutcomeNames <- function(data, outcomeIdColumnName = "outcomeId") {
  idToName <- data.frame(outcomeId = c(1, 2, 10, 11, 12, 13, 14, 15, 16),
                         cohortName = c("Treatment",
                                                                                         "Comparator",
                                                                                         "Myocardial infarction",
                                                                                         "Myocardial infarction and ischemic death",
                                                                                         "Gastrointestinal hemorrhage",
                                                                                         "Angioedema",
                                                                                         "Acute renal failure",
                                                                                         "Drug induced liver injury",
                                                                                         "Heart failure"))
  names(idToName)[1] <- outcomeIdColumnName
  data <- merge(data, idToName, all.x = TRUE)
  return(data)
}
