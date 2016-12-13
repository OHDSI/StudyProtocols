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

#' Run the self-controlled case series
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
runSccs <- function(connectionDetails,
                    cdmDatabaseSchema,
                    workDatabaseSchema = cdmDatabaseSchema,
                    studyCohortTable = "ohdsi_ci_calibration",
                    oracleTempSchema = NULL,
                    maxCores = 4) {
  sccsFolder <- file.path(workFolder, "sccsOutput")
  if (!file.exists(sccsFolder))
    dir.create(sccsFolder)

  writeLines("Running self-controlled case series")
  sccsAnalysisListFile <- system.file("settings", "sccsAnalysisList.txt", package = "CiCalibration")
  sccsAnalysisList <- SelfControlledCaseSeries::loadSccsAnalysisList(sccsAnalysisListFile)

  pathToHoi <- system.file("settings", "sccsHypothesisOfInterest.txt", package = "CiCalibration")
  hypothesesOfInterest <- SelfControlledCaseSeries::loadExposureOutcomeList(pathToHoi)

  # Add negative control outcomes:
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
  negativeControls <- read.csv(pathToCsv)
  negativeControls <- negativeControls[negativeControls$study == "Tata", ]
  for (outcomeId in negativeControls$conceptId) {
      hoi <- SelfControlledCaseSeries::createExposureOutcome(exposureId = hypothesesOfInterest[[1]]$exposureId,
                                                             outcomeId = outcomeId)
      hypothesesOfInterest[[length(hypothesesOfInterest) + 1]] <- hoi
  }

  # Add positive control outcomes:
  summ <- read.csv(file.path(workFolder, "SignalInjectionSummary_Tata.csv"))
  for (outcomeId in summ$newOutcomeId) {
      hoi <- SelfControlledCaseSeries::createExposureOutcome(exposureId = hypothesesOfInterest[[1]]$exposureId,
                                                             outcomeId = outcomeId)
      hypothesesOfInterest[[length(hypothesesOfInterest) + 1]] <- hoi
  }

  sccsResult <- SelfControlledCaseSeries::runSccsAnalyses(connectionDetails = connectionDetails,
                                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                                          oracleTempSchema = oracleTempSchema,
                                                          exposureDatabaseSchema = workDatabaseSchema,
                                                          exposureTable = studyCohortTable,
                                                          outcomeDatabaseSchema = workDatabaseSchema,
                                                          outcomeTable = studyCohortTable,
                                                          sccsAnalysisList = sccsAnalysisList,
                                                          exposureOutcomeList = hypothesesOfInterest,
                                                          cdmVersion = 5,
                                                          outputFolder = sccsFolder,
                                                          combineDataFetchAcrossOutcomes = TRUE,
                                                          getDbSccsDataThreads = 1,
                                                          createSccsEraDataThreads = min(3, maxCores),
                                                          fitSccsModelThreads = max(1, round(maxCores/6)),
                                                          cvThreads = min(10, maxCores))
  sccsSummary <- SelfControlledCaseSeries::summarizeSccsAnalyses(sccsResult)
  write.csv(sccsSummary, file.path(workFolder, "sccsSummary.csv"), row.names = FALSE)
}

