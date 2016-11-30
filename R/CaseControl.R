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

#' Run case control
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
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
runCaseControl <- function(connectionDetails,
                           cdmDatabaseSchema,
                           workDatabaseSchema = cdmDatabaseSchema,
                           studyCohortTable = "ohdsi_ci_calibration",
                           oracleTempSchema = NULL,
                           maxCores = 4) {
  ccFolder <- file.path(workFolder, "ccOutput")
  if (!file.exists(ccFolder))
    dir.create(ccFolder)

  writeLines("Running case-control")
  ccAnalysisListFile <- system.file("settings", "ccAnalysisList.txt", package = "CiCalibration")
  ccAnalysisList <- CaseControl::loadCcAnalysisList(ccAnalysisListFile)

  pathToHoi <- system.file("settings", "ccHypothesisOfInterest.txt", package = "CiCalibration")
  hypothesesOfInterest <- CaseControl::loadExposureOutcomeNestingCohortList(pathToHoi)

  # Add negative control outcomes:
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
  negativeControls <- read.csv(pathToCsv)
  negativeControls <- negativeControls[negativeControls$study == "SSRIs", ]
  for (outcomeId in negativeControls$conceptId) {
      hoi <- CaseControl::createExposureOutcomeNestingCohort(exposureId = hypothesesOfInterest[[1]]$exposureId,
                                                             outcomeId = outcomeId)
      hypothesesOfInterest[[length(hypothesesOfInterest) + 1]] <- hoi
  }

  # Add positive control outcomes:
  summ <- read.csv(file.path(workFolder, "SignalInjectionSummary_SSRIs.csv"))
  for (outcomeId in summ$newOutcomeId) {
      hoi <- CaseControl::createExposureOutcomeNestingCohort(exposureId = hypothesesOfInterest[[1]]$exposureId,
                                                             outcomeId = outcomeId)
      hypothesesOfInterest[[length(hypothesesOfInterest) + 1]] <- hoi
  }

  ccResult <- CaseControl::runCcAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         oracleTempSchema = oracleTempSchema,
                                         exposureDatabaseSchema = workDatabaseSchema,
                                         exposureTable = studyCohortTable,
                                         outcomeDatabaseSchema = workDatabaseSchema,
                                         outcomeTable = studyCohortTable,
                                         ccAnalysisList = ccAnalysisList,
                                         exposureOutcomeNestingCohortList = hypothesesOfInterest,
                                         outputFolder = ccFolder,
                                         getDbCaseDataThreads = 1,
                                         selectControlsThreads = min(3, maxCores),
                                         getDbExposureDataThreads = min(3, maxCores),
                                         createCaseControlDataThreads = min(5, maxCores),
                                         fitCaseControlModelThreads = min(5, maxCores),
                                         cvThreads = min(2, maxCores))
  ccSummary <- CaseControl::summarizeCcAnalyses(ccResult)
  write.csv(ccSummary, file.path(workFolder, "ccSummary.csv"), row.names = FALSE)
}
