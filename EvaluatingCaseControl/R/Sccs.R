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

runSccs <- function(connectionDetails,
                    cdmDatabaseSchema,
                    oracleTempSchema,
                    cohortDatabaseSchema,
                    cohortTable,
                    outputFolder,
                    maxCores) {
  # Chou replication --------------------------------------------------------
  sccsApFolder <- file.path(outputFolder, "sccsAp")
  if (!file.exists(sccsApFolder))
    dir.create(sccsApFolder)

  analysisListFile <- system.file("settings", "sccsAnalysisListAp.json", package = "EvaluatingCaseControl")
  analysisList <- SelfControlledCaseSeries::loadSccsAnalysisList(analysisListFile)
  eoList <- createEos(outputFolder = outputFolder,
                      exposureId = 4,
                      outcomeId = 2)
  sccsResult <- SelfControlledCaseSeries::runSccsAnalyses(connectionDetails = connectionDetails,
                                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                                          oracleTempSchema = oracleTempSchema,
                                                          exposureDatabaseSchema = cohortDatabaseSchema,
                                                          exposureTable = cohortTable,
                                                          outcomeDatabaseSchema = cohortDatabaseSchema,
                                                          outcomeTable = cohortTable,
                                                          sccsAnalysisList = analysisList,
                                                          exposureOutcomeList = eoList,
                                                          outputFolder = sccsApFolder,
                                                          getDbSccsDataThreads = 3,
                                                          createSccsEraDataThreads = min(3, maxCores),
                                                          fitSccsModelThreads = min(5, maxCores),
                                                          cvThreads = min(10, maxCores),
                                                          compressSccsEraDataFiles = TRUE)
  sccsSummary <- SelfControlledCaseSeries::summarizeSccsAnalyses(sccsResult, sccsApFolder)
  sccsSummaryFile <- file.path(outputFolder, "sccsSummaryAp.rds")
  saveRDS(sccsSummary, sccsSummaryFile)

  sccsSummary <- readRDS(file.path(outputFolder, "sccsSummaryAp.rds"))
  ncs <- sccsSummary[sccsSummary$exposureId != 4, ]
  pcs <- sccsSummary[sccsSummary$exposureId == 4, ]
  EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = ncs$`logRr(Exposure of interest)`,
                                              seLogRrNegatives = ncs$`seLogRr(Exposure of interest)`,
                                              logRrPositives = pcs$`logRr(Exposure of interest)`,
                                              seLogRrPositives = pcs$`seLogRr(Exposure of interest)`,
                                              showCis = TRUE)

  # Crockett replication --------------------------------------------------------
  sccsIbdFolder <- file.path(outputFolder, "sccsIbd")
  if (!file.exists(sccsIbdFolder))
    dir.create(sccsIbdFolder)

  analysisListFile <- system.file("settings", "sccsAnalysisListIbd.json", package = "EvaluatingCaseControl")
  analysisList <- SelfControlledCaseSeries::loadSccsAnalysisList(analysisListFile)
  eoList <- createEos(outputFolder = outputFolder,
                      exposureId = 5,
                      outcomeId = 3)
  sccsResult <- SelfControlledCaseSeries::runSccsAnalyses(connectionDetails = connectionDetails,
                                              cdmDatabaseSchema = cdmDatabaseSchema,
                                              oracleTempSchema = oracleTempSchema,
                                              exposureDatabaseSchema = cohortDatabaseSchema,
                                              exposureTable = cohortTable,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              outcomeTable = cohortTable,
                                              sccsAnalysisList = analysisList,
                                              exposureOutcomeList = eoList,
                                              outputFolder = sccsIbdFolder,
                                              getDbSccsDataThreads = 3,
                                              createSccsEraDataThreads = min(3, maxCores),
                                              fitSccsModelThreads = min(5, maxCores),
                                              cvThreads = min(10, maxCores),
                                              compressSccsEraDataFiles = TRUE)
  sccsSummary <- SelfControlledCaseSeries::summarizeSccsAnalyses(sccsResult, sccsIbdFolder)
  sccsSummaryFile <- file.path(outputFolder, "sccsSummaryIbd.rds")
  saveRDS(sccsSummary, sccsSummaryFile)

  sccsSummary <- readRDS(file.path(outputFolder, "sccsSummaryIbd.rds"))
  ncs <- sccsSummary[sccsSummary$exposureId != 5, ]
  pcs <- sccsSummary[sccsSummary$exposureId == 5, ]
  EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = ncs$`logRr(Exposure of interest)`,
                                              seLogRrNegatives = ncs$`seLogRr(Exposure of interest)`,
                                              logRrPositives = pcs$`logRr(Exposure of interest)`,
                                              seLogRrPositives = pcs$`seLogRr(Exposure of interest)`,
                                              showCis = TRUE)
}

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param workFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createSccsAnalysesDetails <- function(workFolder) {

  # Chou replication --------------------------------------------------------
  getDbSccsDataArgsAp <- SelfControlledCaseSeries::createGetDbSccsDataArgs(useCustomCovariates = FALSE,
                                                                           deleteCovariatesSmallCount = 100,
                                                                           studyStartDate = "",
                                                                           studyEndDate = "",
                                                                           exposureIds = c(),
                                                                           maxCasesPerOutcome = 250000)

  covarExposureOfIntAp <- SelfControlledCaseSeries::createCovariateSettings(label = "Exposure of interest",
                                                                            includeCovariateIds = "exposureId",
                                                                            start = 1,
                                                                            end = 30,
                                                                            addExposedDaysToEnd = TRUE)

  covarPreExposureAp = SelfControlledCaseSeries::createCovariateSettings(label = "Pre-exposure",
                                                                         includeCovariateIds = "exposureId",
                                                                         start = -30,
                                                                         end = -1)

  ageSettingsAp <- SelfControlledCaseSeries::createAgeSettings(includeAge = TRUE, ageKnots = 5, computeConfidenceIntervals = FALSE)

  seasonalitySettingsAp <- SelfControlledCaseSeries::createSeasonalitySettings(includeSeasonality = TRUE, seasonKnots = 5, computeConfidenceIntervals = FALSE)

  createSccsEraDataArgsAp <- SelfControlledCaseSeries::createCreateSccsEraDataArgs(naivePeriod = 365,
                                                                                   firstOutcomeOnly = FALSE,
                                                                                   covariateSettings = list(covarExposureOfIntAp,
                                                                                                            covarPreExposureAp),
                                                                                   ageSettings = ageSettingsAp,
                                                                                   seasonalitySettings = seasonalitySettingsAp,
                                                                                   minCasesForAgeSeason = 10000)

  fitSccsModelArgsAp <- SelfControlledCaseSeries::createFitSccsModelArgs()

  sccsAnalysisAp <- SelfControlledCaseSeries::createSccsAnalysis(analysisId = 1,
                                                                 description = "Using pre-exposure window, age, and season",
                                                                 getDbSccsDataArgs = getDbSccsDataArgsAp,
                                                                 createSccsEraDataArgs = createSccsEraDataArgsAp,
                                                                 fitSccsModelArgs = fitSccsModelArgsAp)

  sccsAnalysisListAp <- list(sccsAnalysisAp)
  SelfControlledCaseSeries::saveSccsAnalysisList(sccsAnalysisListAp, file.path(workFolder, "sccsAnalysisListAp.json"))

  # Crockett replication ----------------------------------------------------
  getDbSccsDataArgsIbd <- SelfControlledCaseSeries::createGetDbSccsDataArgs(useCustomCovariates = FALSE,
                                                                            deleteCovariatesSmallCount = 100,
                                                                            studyStartDate = "",
                                                                            studyEndDate = "",
                                                                            exposureIds = c(),
                                                                            maxCasesPerOutcome = 250000)

  covarExposureOfIntIbd <- SelfControlledCaseSeries::createCovariateSettings(label = "Exposure of interest",
                                                                             includeCovariateIds = "exposureId",
                                                                             start = 1,
                                                                             end = 365,
                                                                             addExposedDaysToEnd = TRUE)

  covarPreExposureIbd = SelfControlledCaseSeries::createCovariateSettings(label = "Pre-exposure",
                                                                          includeCovariateIds = "exposureId",
                                                                          start = -30,
                                                                          end = -1)

  ageSettingsIbd <- SelfControlledCaseSeries::createAgeSettings(includeAge = TRUE, ageKnots = 5, computeConfidenceIntervals = FALSE)

  seasonalitySettingsIbd <- SelfControlledCaseSeries::createSeasonalitySettings(includeSeasonality = TRUE, seasonKnots = 5, computeConfidenceIntervals = FALSE)

  createSccsEraDataArgsIbd <- SelfControlledCaseSeries::createCreateSccsEraDataArgs(naivePeriod = 365,
                                                                                    firstOutcomeOnly = FALSE,
                                                                                    covariateSettings = list(covarExposureOfIntIbd,
                                                                                                             covarPreExposureIbd),
                                                                                    ageSettings = ageSettingsIbd,
                                                                                    seasonalitySettings = seasonalitySettingsIbd,
                                                                                    minCasesForAgeSeason = 10000)

  fitSccsModelArgsIbd <- SelfControlledCaseSeries::createFitSccsModelArgs()

  sccsAnalysisIbd <- SelfControlledCaseSeries::createSccsAnalysis(analysisId = 1,
                                                                  description = "Using pre-exposure window, age, and season",
                                                                  getDbSccsDataArgs = getDbSccsDataArgsIbd,
                                                                  createSccsEraDataArgs = createSccsEraDataArgsIbd,
                                                                  fitSccsModelArgs = fitSccsModelArgsIbd)

  sccsAnalysisListIbd <- list(sccsAnalysisIbd)
  SelfControlledCaseSeries::saveSccsAnalysisList(sccsAnalysisListIbd, file.path(workFolder, "sccsAnalysisListIbd.json"))
}

createEos <- function(outputFolder, exposureId, outcomeId) {
  allControlsFile = file.path(outputFolder, "AllControlsAp.csv")
  if (file.exists(allControlsFile)) {
    allControls <- read.csv(allControlsFile)
  } else {
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
    allControls <- read.csv(pathToCsv)
    allControls <- allControls[allControls$outcomeId == outcomeId, ]
  }
  eonList <- list(SelfControlledCaseSeries::createExposureOutcome(exposureId = exposureId,
                                                                  outcomeId = outcomeId))
  for (i in 1:nrow(allControls)) {
    eon <- SelfControlledCaseSeries::createExposureOutcome(exposureId = allControls$targetId[i],
                                                           outcomeId = allControls$outcomeId[i])

    eonList[[length(eonList) + 1]] <- eon
  }
  return(eonList)
}
