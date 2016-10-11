# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of KeppraAngioedema
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

#' Execute OHDSI Keppra and the Risk of Angioedema study
#'
#' @details
#' This function executes the OHDSI Keppra and the Risk of Angioedema study.
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
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createCohorts        Create the studyCohortTable table with the exposure and outcome cohorts?
#' @param runAnalyses          Perform the cohort method analyses?
#' @param packageResults       Package the results for sharing?
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
#'         workDatabaseSchema = "results",
#'         studyCohortTable = "ohdsi_keppra_angioedema",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results",
#'         maxCores = 4)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    workDatabaseSchema = cdmDatabaseSchema,
                    studyCohortTable = "ohdsi_keppra_angioedema",
                    oracleTempSchema = workDatabaseSchema,
                    cdmVersion = 5,
                    outputFolder,
                    createCohorts = TRUE,
                    runAnalyses = TRUE,
                    packageResults = TRUE,
                    maxCores = 4) {

  if (cdmVersion == 4) {
    stop("CDM version 4 not supported")
  }

  if (!file.exists(outputFolder))
    dir.create(outputFolder)

  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  if (!file.exists(cmOutputFolder))
    dir.create(cmOutputFolder)

  if (createCohorts) {
    writeLines("Creating exposure and outcome cohorts")
    createCohorts(connectionDetails,
                  cdmDatabaseSchema,
                  workDatabaseSchema,
                  studyCohortTable,
                  oracleTempSchema,
                  cdmVersion,
                  outputFolder)
    writeLines("")
  }

  if (runAnalyses) {
    writeLines("Running analyses")
    cmAnalysisListFile <- system.file("settings",
                                      "cmAnalysisList.txt",
                                      package = "KeppraAngioedema")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
    drugComparatorOutcomesListFile <- system.file("settings",
                                                  "drugComparatorOutcomesList.txt",
                                                  package = "KeppraAngioedema")
    drugComparatorOutcomesList <- CohortMethod::loadDrugComparatorOutcomesList(drugComparatorOutcomesListFile)
    CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                exposureDatabaseSchema = workDatabaseSchema,
                                exposureTable = studyCohortTable,
                                outcomeDatabaseSchema = workDatabaseSchema,
                                outcomeTable = studyCohortTable,
                                outputFolder = cmOutputFolder,
                                oracleTempSchema = oracleTempSchema,
                                cmAnalysisList = cmAnalysisList,
                                cdmVersion = cdmVersion,
                                drugComparatorOutcomesList = drugComparatorOutcomesList,
                                getDbCohortMethodDataThreads = 1,
                                createStudyPopThreads = min(3, maxCores),
                                createPsThreads = 1,
                                psCvThreads = min(16, maxCores),
                                computeCovarBalThreads = min(3, maxCores),
                                trimMatchStratifyThreads = min(10, maxCores),
                                fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                outcomeCvThreads = min(4, maxCores),
                                refitPsForEveryOutcome = FALSE)
    writeLines("")
  }
  if (packageResults) {
    writeLines("Packaging results in export folder for sharing")
    packageResults(connectionDetails = connectionDetails,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   outputFolder = outputFolder)
    writeLines("")
  }
  invisible(NULL)
}
