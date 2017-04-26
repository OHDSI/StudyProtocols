# Copyright 2017 Observational Health Data Sciences and Informatics
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

#' Run the Southworth study replication
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
runCohortMethodSouthworth <- function(connectionDetails,
                                      cdmDatabaseSchema,
                                      workDatabaseSchema = cdmDatabaseSchema,
                                      studyCohortTable = "ohdsi_ci_calibration",
                                      oracleTempSchema = NULL,
                                      maxCores = 4) {
    cmFolder <- file.path(workFolder, "cmOutputSouthworth")
    if (!file.exists(cmFolder))
        dir.create(cmFolder)

    writeLines("Running cohort analyses")
    cmAnalysisListFile <- system.file("settings", "cmAnalysisListSouthworth.txt", package = "CiCalibration")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)

    pathToHoi <- system.file("settings", "cmHypothesisOfInterestSouthworth.txt", package = "CiCalibration")
    hypothesesOfInterest <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)

    # Add negative control outcomes:
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
    negativeControls <- read.csv(pathToCsv)
    negativeControls <- negativeControls[negativeControls$study == "Southworth", ]
    hypothesesOfInterest[[1]]$outcomeIds <- c(hypothesesOfInterest[[1]]$outcomeIds, negativeControls$conceptId)

    # Add positive control outcomes:
    summ <- read.csv(file.path(workFolder, "SignalInjectionSummary_Southworth.csv"))
    hypothesesOfInterest[[1]]$outcomeIds <- c(hypothesesOfInterest[[1]]$outcomeIds, summ$newOutcomeId)

    cmResult <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            exposureDatabaseSchema = workDatabaseSchema,
                                            exposureTable = studyCohortTable,
                                            outcomeDatabaseSchema = workDatabaseSchema,
                                            outcomeTable = studyCohortTable,
                                            outputFolder = cmFolder,
                                            cmAnalysisList = cmAnalysisList,
                                            cdmVersion = "5",
                                            drugComparatorOutcomesList = hypothesesOfInterest,
                                            getDbCohortMethodDataThreads = 1,
                                            createStudyPopThreads = min(4, maxCores),
                                            createPsThreads = max(1, round(maxCores/6)),
                                            psCvThreads = min(10, maxCores),
                                            trimMatchStratifyThreads = min(4, maxCores),
                                            fitOutcomeModelThreads = min(4, maxCores),
                                            outcomeCvThreads = min(4, maxCores),
                                            refitPsForEveryOutcome = FALSE)
    # cmResult <- readRDS(file.path(cmFolder, "outcomeModelReference.rds"))
    cmSummary <- CohortMethod::summarizeAnalyses(cmResult)
    write.csv(cmSummary, file.path(workFolder, "cmSummarySouthworth.csv"), row.names = FALSE)

    studyPopFile <- cmResult$studyPopFile[cmResult$outcomeId == hypothesesOfInterest[[1]]$outcomeIds[1]]
    studyPop <- readRDS(studyPopFile)
    mdrr <- CohortMethod::computeMdrr(population = studyPop, modelType = "cox")
    write.csv(mdrr, file.path(workFolder, "cmMdrrSouthworth.csv"), row.names = FALSE)
}

#' Run the Graham study replication
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
runCohortMethodGraham <- function(connectionDetails,
                                  cdmDatabaseSchema,
                                  workDatabaseSchema = cdmDatabaseSchema,
                                  studyCohortTable = "ohdsi_ci_calibration",
                                  oracleTempSchema = NULL,
                                  maxCores = 4) {
    cmFolder <- file.path(workFolder, "cmOutputGraham")
    if (!file.exists(cmFolder))
        dir.create(cmFolder)

    writeLines("Running cohort analyses")
    cmAnalysisListFile <- system.file("settings", "cmAnalysisListGraham.txt", package = "CiCalibration")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)

    pathToHoi <- system.file("settings", "cmHypothesisOfInterestGraham.txt", package = "CiCalibration")
    hypothesesOfInterest <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)

    # Add negative control outcomes:
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
    negativeControls <- read.csv(pathToCsv)
    negativeControls <- negativeControls[negativeControls$study == "Graham", ]
    hypothesesOfInterest[[1]]$outcomeIds <- c(hypothesesOfInterest[[1]]$outcomeIds, negativeControls$conceptId)

    # Add positive control outcomes:
    summ <- read.csv(file.path(workFolder, "SignalInjectionSummary_Graham.csv"))
    hypothesesOfInterest[[1]]$outcomeIds <- c(hypothesesOfInterest[[1]]$outcomeIds, summ$newOutcomeId)

    cmResult <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            exposureDatabaseSchema = workDatabaseSchema,
                                            exposureTable = studyCohortTable,
                                            outcomeDatabaseSchema = workDatabaseSchema,
                                            outcomeTable = studyCohortTable,
                                            outputFolder = cmFolder,
                                            cmAnalysisList = cmAnalysisList,
                                            cdmVersion = "5",
                                            drugComparatorOutcomesList = hypothesesOfInterest,
                                            getDbCohortMethodDataThreads = 1,
                                            createStudyPopThreads = min(4, maxCores),
                                            createPsThreads = max(1, round(maxCores/6)),
                                            psCvThreads = min(10, maxCores),
                                            trimMatchStratifyThreads = min(4, maxCores),
                                            fitOutcomeModelThreads = min(4, maxCores),
                                            outcomeCvThreads = min(4, maxCores),
                                            refitPsForEveryOutcome = FALSE)
    cmSummary <- CohortMethod::summarizeAnalyses(cmResult)
    write.csv(cmSummary, file.path(workFolder, "cmSummaryGraham.csv"), row.names = FALSE)

    # cmResult <- readRDS(file.path(cmFolder, "outcomeModelReference.rds"))
    ps <- readRDS(cmResult$sharedPsFile[1])
    fileName <- file.path(cmFolder, "ps.png")
    CohortMethod::plotPs(ps, fileName = fileName)

    strata <- readRDS(cmResult$strataFile[1])
    cohortMethodData <- CohortMethod::loadCohortMethodData(cmResult$cohortMethodDataFolder[1])
    balance <- CohortMethod::computeCovariateBalance(population = strata,
                                                     cohortMethodData = cohortMethodData)
    fileName <- file.path(cmFolder, "balanceScatterplot.png")
    CohortMethod::plotCovariateBalanceScatterPlot(balance = balance, fileName = fileName)
    fileName <- file.path(cmFolder, "balanceTopVarsplot.png")
    CohortMethod::plotCovariateBalanceOfTopVariables(balance = balance, fileName = fileName)

    studyPopFile <- cmResult$studyPopFile[cmResult$outcomeId == hypothesesOfInterest[[1]]$outcomeIds[1]]
    studyPop <- readRDS(studyPopFile)
    mdrr <- CohortMethod::computeMdrr(population = studyPop, modelType = "cox")
    write.csv(mdrr, file.path(workFolder, "cmMdrrGraham.csv"), row.names = FALSE)
}

