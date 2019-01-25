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

runCohortMethodDesigns <- function(connectionDetails,
                                   cdmDatabaseSchema,
                                   oracleTempSchema,
                                   cohortDatabaseSchema,
                                   cohortTable,
                                   outputFolder,
                                   maxCores) {
  # Chou replication --------------------------------------------------------
  cmApFolder <- file.path(outputFolder, "cmAp")
  if (!file.exists(cmApFolder))
    dir.create(cmApFolder)

  analysisListFile <- system.file("settings", "cmAnalysisListAp.json", package = "EvaluatingCaseControl")
  analysisList <- CohortMethod::loadCmAnalysisList(analysisListFile)
  tcoList <- createTcos(outputFolder = outputFolder,
                       exposureId = 4,
                       outcomeId = 2)
  cmResult <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = oracleTempSchema,
                                          exposureDatabaseSchema = cohortDatabaseSchema,
                                          exposureTable = cohortTable,
                                          outcomeDatabaseSchema = cohortDatabaseSchema,
                                          outcomeTable = cohortTable,
                                          cmAnalysisList = analysisList,
                                          targetComparatorOutcomesList = tcoList,
                                          outputFolder = cmApFolder,
                                          refitPsForEveryOutcome = FALSE,
                                          getDbCohortMethodDataThreads = min(3, maxCores),
                                          createStudyPopThreads = min(3, maxCores),
                                          createPsThreads = max(3, round(maxCores/10)),
                                          psCvThreads = min(10, maxCores),
                                          trimMatchStratifyThreads = min(10, maxCores),
                                          fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                          outcomeCvThreads = min(4, maxCores))
  cmSummary <- CohortMethod::summarizeAnalyses(cmResult, cmApFolder)
  cmSummaryFile <- file.path(outputFolder, "cmSummaryAp.rds")
  saveRDS(cmSummary, cmSummaryFile)

  ncs <- cmSummary[cmSummary$targetId != 4, ]
  EmpiricalCalibration::plotCalibrationEffect(ncs$logRr, ncs$seLogRr, showCis = TRUE)


  # Crockett replication --------------------------------------------------------
  cmIbdFolder <- file.path(outputFolder, "cmIbd")
  if (!file.exists(cmIbdFolder))
    dir.create(cmIbdFolder)

  analysisListFile <- system.file("settings", "cmAnalysisListIbd.json", package = "EvaluatingCaseControl")
  analysisList <- CohortMethod::loadCmAnalysisList(analysisListFile)
  tcoList <- createTcos(outputFolder = outputFolder,
                        exposureId = 5,
                        outcomeId = 3)
  cmResult <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                          oracleTempSchema = oracleTempSchema,
                                          exposureDatabaseSchema = cohortDatabaseSchema,
                                          exposureTable = cohortTable,
                                          outcomeDatabaseSchema = cohortDatabaseSchema,
                                          outcomeTable = cohortTable,
                                          cmAnalysisList = analysisList,
                                          targetComparatorOutcomesList = tcoList,
                                          outputFolder = cmIbdFolder,
                                          refitPsForEveryOutcome = FALSE,
                                          getDbCohortMethodDataThreads = min(3, maxCores),
                                          createStudyPopThreads = min(3, maxCores),
                                          createPsThreads = max(3, round(maxCores/10)),
                                          psCvThreads = min(10, maxCores),
                                          trimMatchStratifyThreads = min(10, maxCores),
                                          fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                          outcomeCvThreads = min(4, maxCores))
  cmSummary <- CohortMethod::summarizeAnalyses(cmResult, cmIbdFolder)
  cmSummaryFile <- file.path(outputFolder, "cmSummaryIbd.rds")
  saveRDS(cmSummary, cmSummaryFile)

  ncs <- cmSummary[cmSummary$targetId != 5, ]
  EmpiricalCalibration::plotCalibrationEffect(ncs$logRr, ncs$seLogRr, showCis = TRUE)
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
createCohortMethodAnalysesDetails <- function(workFolder) {

  # Chou replication --------------------------------------------------------

  covarSettings <- FeatureExtraction::createDefaultCovariateSettings(addDescendantsToExclude = TRUE)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 365,
                                                                   firstExposureOnly = TRUE,
                                                                   removeDuplicateSubjects = TRUE,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   covariateSettings = covarSettings,
                                                                   maxCohortSize = 250000)

  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 0,
                                                                      addExposureDaysToStart = FALSE,
                                                                      riskWindowEnd = 0,
                                                                      addExposureDaysToEnd = TRUE)

  createPsArgs <- CohortMethod::createCreatePsArgs(control = Cyclops::createControl(cvType = "auto",
                                                                                    startingVariance = 0.01,
                                                                                    noiseLevel = "quiet",
                                                                                    tolerance  = 2e-07,
                                                                                    cvRepetitions = 1),
                                                   stopOnError = FALSE)

  matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)

  fitOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                 modelType = "cox",
                                                                 stratified = TRUE)

  cmAnalysis <- CohortMethod::createCmAnalysis(analysisId = 1,
                                               description = "Matching plus simple outcome model",
                                               getDbCohortMethodDataArgs = getDbCmDataArgs,
                                               createStudyPopArgs = createStudyPopArgs,
                                               createPs = TRUE,
                                               createPsArgs = createPsArgs,
                                               matchOnPs = TRUE,
                                               matchOnPsArgs = matchOnPsArgs,
                                               fitOutcomeModel = TRUE,
                                               fitOutcomeModelArgs = fitOutcomeModelArgs)

  cmAnalysisList <- list(cmAnalysis)
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisListAp.json"))


  # Crockett replication ----------------------------------------------------

  covarSettings <- FeatureExtraction::createDefaultCovariateSettings()

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 365,
                                                                   firstExposureOnly = TRUE,
                                                                   removeDuplicateSubjects = TRUE,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   covariateSettings = covarSettings,
                                                                   maxCohortSize = 250000)

  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 0,
                                                                      addExposureDaysToStart = FALSE,
                                                                      riskWindowEnd = 365,
                                                                      addExposureDaysToEnd = FALSE)

  createPsArgs <- CohortMethod::createCreatePsArgs(control = Cyclops::createControl(cvType = "auto",
                                                                                    startingVariance = 0.01,
                                                                                    noiseLevel = "quiet",
                                                                                    tolerance  = 2e-07,
                                                                                    cvRepetitions = 1),
                                                   stopOnError = FALSE)

  matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)

  fitOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                 modelType = "cox",
                                                                 stratified = TRUE)

  cmAnalysis <- CohortMethod::createCmAnalysis(analysisId = 1,
                                               description = "Matching plus simple outcome model",
                                               getDbCohortMethodDataArgs = getDbCmDataArgs,
                                               createStudyPopArgs = createStudyPopArgs,
                                               createPs = TRUE,
                                               createPsArgs = createPsArgs,
                                               matchOnPs = TRUE,
                                               matchOnPsArgs = matchOnPsArgs,
                                               fitOutcomeModel = TRUE,
                                               fitOutcomeModelArgs = fitOutcomeModelArgs)

  cmAnalysisList <- list(cmAnalysis)
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisListIbd.json"))
}


createTcos <- function(outputFolder, exposureId, outcomeId, nestingCohortId = NULL) {
  allControlsFile = file.path(outputFolder, "AllControlsAp.csv")
  if (file.exists(allControlsFile)) {
    allControls <- read.csv(allControlsFile)
  } else {
    pathToCsv <- system.file("settings", "NegativeControlsForCm.csv", package = "EvaluatingCaseControl")
    allControls <- read.csv(pathToCsv)
    allControls <- allControls[allControls$outcomeId == outcomeId, ]
  }
  # nestedExposures <- read.csv(file.path(outputFolder, "NestedExposures.csv"))
  tcoList <- list()
  for (i in 1:nrow(allControls)) {
    # targetId <- nestedExposures$nestedExposureId[nestedExposures$exposureId == allControls$targetId[i] &
    #                                                nestedExposures$nestingId == allControls$nestingId[i]]
    # comparatorId <- nestedExposures$nestedExposureId[nestedExposures$exposureId == allControls$comparatorId[i] &
    #                                                nestedExposures$nestingId == allControls$nestingId[i]]
    targetId <- allControls$targetId[i]
    comparatorId <- allControls$comparatorId[i]

    tco <- CohortMethod::createTargetComparatorOutcomes(targetId = targetId,
                                                        comparatorId = comparatorId,
                                                        outcomeIds = allControls$outcomeId[i],
                                                        excludedCovariateConceptIds = c(allControls$targetId[i], allControls$comparatorId[i]))
    tcoList[[length(tcoList) + 1]] <- tco
  }
  return(tcoList)
}
