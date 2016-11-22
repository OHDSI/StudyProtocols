# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of CiCalibration
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
#' Execute OHDSI Celecoxib versus non-selective NSAIDs study
#'
#' @details
#' This function executes the OHDSI Celecoxib versus non-selective NSAIDs study.
#'
#' @return
#' TODO
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
#' @param workFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
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
#'         workDatabaseSchema = "results",
#'         oracleTempSchema = NULL,
#'         workFolder = "c:/temp/study_results",
#'         cdmVersion = "5")
#'
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    workDatabaseSchema = cdmDatabaseSchema,
                    studyCohortTable = "ohdsi_ci_calibration",
                    oracleTempSchema = NULL,
                    cdmVersion = 5,
                    study,
                    workFolder,
                    createCohorts = TRUE,
                    runAnalyses = TRUE,
                    empiricalCalibration = TRUE,
                    packageResultsForSharing = TRUE) {

  if (cdmVersion == 4) {
    stop("CDM version 4 not supported")
  }

  if (!file.exists(workFolder))
    dir.create(workFolder)

  if (createCohorts) {
    writeLines("Creating exposure and outcome cohorts")
    createCohorts(connectionDetails,
                  cdmDatabaseSchema,
                  workDatabaseSchema,
                  studyCohortTable,
                  oracleTempSchema,
                  cdmVersion,
                  workFolder)
  }

  if (runAnalyses) {
    writeLines("Running analyses")
    cmAnalysisListFile <- system.file("settings",
                                      "cmAnalysisList.txt",
                                      package = "CelecoxibVsNsNSAIDs")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
    drugComparatorOutcomesListFile <- system.file("settings",
                                                  "drugComparatorOutcomesList.txt",
                                                  package = "CelecoxibVsNsNSAIDs")
    drugComparatorOutcomesList <- CohortMethod::loadDrugComparatorOutcomesList(drugComparatorOutcomesListFile)
    CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                exposureDatabaseSchema = workDatabaseSchema,
                                exposureTable = studyCohortTable,
                                outcomeDatabaseSchema = workDatabaseSchema,
                                outcomeTable = studyCohortTable,
                                workFolder = workFolder,
                                cmAnalysisList = cmAnalysisList,
                                cdmVersion = cdmVersion,
                                drugComparatorOutcomesList = drugComparatorOutcomesList,
                                getDbCohortMethodDataThreads = 1,
                                createPsThreads = 1,
                                psCvThreads = 10,
                                computeCovarBalThreads = 2,
                                trimMatchStratifyThreads = 10,
                                fitOutcomeModelThreads = 3,
                                outcomeCvThreads = 10)
    # TODO: exposure multi-threading parameters
  }

  if (empiricalCalibration) {
    writeLines("Performing empirical calibration")
    doEmpiricalCalibration(workFolder = workFolder)
  }

  if (packageResultsForSharing) {
    writeLines("Packaging results")
    packageResults(workFolder = workFolder)
  }
}
