# Copyright 2018 Observational Health Data Sciences and Informatics
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

#' Execute AHAsAcutePancreatitis Study
#'
#' @details
#' This function executes the AHAsAcutePancreatitis Study.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema   Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createCohorts        Create the cohortTable table with the exposure and outcome cohorts?
#' @param runAnalyses          Perform the cohort method analyses?
#' @param getPriorExposureData Get data on prior exposure to AHAs?
#' @param runDiagnostics       Should study diagnostics be generated?
#' @param prepareResults       Prepare results for analysis?
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
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results",
#'         maxCores = 4)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    databaseName, 
                    createCohorts = TRUE,
                    runAnalyses = TRUE,
                    getPriorExposureData = TRUE,
                    runDiagnostics = TRUE,
                    prepareResults = TRUE,
                    maxCores = maxCores) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  
  # prevent multiple logging of the same output across executions
  OhdsiRTools::clearLoggers()
  OhdsiRTools::addDefaultFileLogger(file.path(outputFolder, "log.txt"))

  if (createCohorts) {
    OhdsiRTools::logInfo("Creating exposure and outcome cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
  }
  
  if (runAnalyses) {
    OhdsiRTools::logInfo("Running analyses")
    cmOutputFolder <- file.path(outputFolder, "cmOutput")
    if (!file.exists(cmOutputFolder))
      dir.create(cmOutputFolder)
    cmAnalysisListFile <- system.file("settings",
                                      "cmAnalysisList.json",
                                      package = "AHAsAcutePancreatitis")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
    cmAnalysisList <- setOutcomeDatabaseSchemaAndTable(cmAnalysisList, cohortDatabaseSchema, cohortTable)
    dcosList <- createTcos(outputFolder = outputFolder)
    results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           exposureDatabaseSchema = cohortDatabaseSchema,
                                           exposureTable = cohortTable,
                                           outcomeDatabaseSchema = cohortDatabaseSchema,
                                           outcomeTable = cohortTable,
                                           outputFolder = cmOutputFolder,
                                           oracleTempSchema = oracleTempSchema,
                                           cmAnalysisList = cmAnalysisList,
                                           drugComparatorOutcomesList = dcosList,
                                           getDbCohortMethodDataThreads = min(3, maxCores),
                                           createStudyPopThreads = min(3, maxCores),
                                           createPsThreads = max(1, round(maxCores/10)),
                                           psCvThreads = min(10, maxCores),
                                           computeCovarBalThreads = min(3, maxCores),
                                           trimMatchStratifyThreads = min(10, maxCores),
                                           fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                           outcomeCvThreads = min(4, maxCores),
                                           refitPsForEveryOutcome = FALSE,
                                           refitPsForEveryStudyPopulation = FALSE,
                                           outcomeIdsOfInterest = c(6479))
  }
  if (getPriorExposureData) {
    OhdsiRTools::logInfo("Getting prior AHA exposure data from server")
    getPriorAhaExposureData(connectionDetails = connectionDetails,
                            cdmDatabaseSchema = cdmDatabaseSchema,
                            cohortDatabaseSchema = cohortDatabaseSchema,
                            cohortTable = cohortTable,
                            oracleTempSchema = oracleTempSchema,
                            outputFolder = outputFolder)
  }
  if (runDiagnostics) {
    OhdsiRTools::logInfo("Running diagnostics")
    generateDiagnostics(outputFolder = outputFolder)
  }
  if (prepareResults) {
    OhdsiRTools::logInfo("Preparing results for analysis")
    prepareResultsForAnalysis(outputFolder = outputFolder,
                              databaseName = databaseName, 
                              maxCores = maxCores)
  }
  invisible(NULL)
}
