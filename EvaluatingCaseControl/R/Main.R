# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of EvaluatingCaseControl
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

#' @title
#' Execute OHDSI Evaluating the Case-Control Design Study
#'
#' @description
#' This function executes the OHDSI Evaluating the Case-Control Design Study.
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
#' @param createCohorts        Instantiate the necessary cohorts in the cohortTable?
#' @param synthesizePositiveControls  Synthesize positive controls based on the negative controls?
#' @param runAnalyses          Execute the case-control analaysis?
#' @param createFiguresAndTables Create the figures and tables for the paper?
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cohortDatabaseSchema = "results",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results")
#'
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema,
                    cohortTable,
                    oracleTempSchema,
                    outputFolder,
                    createCohorts = TRUE,
                    synthesizePositiveControls = TRUE,
                    runAnalyses = TRUE,
                    createFiguresAndTables  = TRUE,
                    maxCores = 4) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder)

  OhdsiRTools::addDefaultFileLogger(file.path(outputFolder, "log.txt"))

  if (createCohorts) {
    OhdsiRTools::logInfo("Creating exposure and outcome cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  oracleTempSchema = oracleTempSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  outputFolder = outputFolder)
  }
  if (synthesizePositiveControls) {
    OhdsiRTools::logInfo("Synthesizing positive controls")
    synthesizePositiveControls(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               cohortTable = cohortTable,
                               oracleTempSchema = oracleTempSchema,
                               outputFolder = outputFolder,
                               maxCores = maxCores)
    OhdsiRTools::logInfo("")
  }

  if (runAnalyses) {
    OhdsiRTools::logInfo("Running analyses")
    runCaseControlDesigns(connectionDetails = connectionDetails,
                          cdmDatabaseSchema = cdmDatabaseSchema,
                          oracleTempSchema = oracleTempSchema,
                          cohortDatabaseSchema = cohortDatabaseSchema,
                          cohortTable = cohortTable,
                          outputFolder = outputFolder,
                          maxCores = maxCores)
  }
  if (createFiguresAndTables) {
    OhdsiRTools::logInfo("Creating figures and tables")
    createFiguresAndTables(connectionDetails = connectionDetails,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           oracleTempSchema = oracleTempSchema,
                           outputFolder = outputFolder)
  }
}
