# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
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
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_alendronate_raloxifene",
                          oracleTempSchema,
                          outputFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)

  .createCohorts(connection = conn,
                 cdmDatabaseSchema = cdmDatabaseSchema,
                 cohortDatabaseSchema = workDatabaseSchema,
                 cohortTable = studyCohortTable,
                 oracleTempSchema = oracleTempSchema,
                 outputFolder = outputFolder)

  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "AlendronateVsRaloxifene")
  negativeControls <- read.csv(pathToCsv)
  writeLines("- Creating negative control outcome cohorts")
  sql <- SqlRender::loadRenderTranslateSql("NegativeControls.sql",
                                           "AlendronateVsRaloxifene",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           outcome_ids = negativeControls$conceptId)
  DatabaseConnector::executeSql(conn, sql)

  # Check number of subjects per cohort:
  writeLines("Counting cohorts")
  countCohorts(connectionDetails = connectionDetails,
               cdmDatabaseSchema = cdmDatabaseSchema,
               workDatabaseSchema = workDatabaseSchema,
               studyCohortTable = studyCohortTable,
               oracleTempSchema = oracleTempSchema,
               outputFolder = outputFolder)
}


addCohortNames <- function(data, IdColumnName = "cohortDefinitionId", nameColumnName = "cohortName") {
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "AlendronateVsRaloxifene")
  cohortsToCreate <- read.csv(pathToCsv)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "AlendronateVsRaloxifene")
  negativeControls <- read.csv(pathToCsv)

  idToName <- data.frame(cohortId = c(cohortsToCreate$cohortId, negativeControls$conceptId),
                         cohortName = c(as.character(cohortsToCreate$name), as.character(negativeControls$name)))
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
