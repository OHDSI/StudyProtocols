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

runCaseControlDesigns <- function(connectionDetails,
                                  cdmDatabaseSchema,
                                  oracleTempSchema,
                                  cohortDatabaseSchema,
                                  cohortTable,
                                  outputFolder,
                                  maxCores) {
  OhdsiRTools::logInfo("Running Chou replication")
  ccApFolder <- file.path(outputFolder, "ccAp")
  if (!file.exists(ccApFolder))
    dir.create(ccApFolder)

  analysisListFile <- system.file("settings", "ccAnalysisListAp.json", package = "EvaluatingCaseControl")
  analysisList <- CaseControl::loadCcAnalysisList(analysisListFile)
  eonList <- createEons(allControlsFile = file.path(outputFolder, "AllControlsAp.csv"),
                        exposureId = 4,
                        outcomeId = 2,
                        nestingCohortId = 1)
  ccResult <- CaseControl::runCcAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         oracleTempSchema = oracleTempSchema,
                                         exposureDatabaseSchema = cohortDatabaseSchema,
                                         exposureTable = cohortTable,
                                         outcomeDatabaseSchema = cohortDatabaseSchema,
                                         outcomeTable = cohortTable,
                                         nestingCohortDatabaseSchema = cohortDatabaseSchema,
                                         nestingCohortTable = cohortTable,
                                         ccAnalysisList = analysisList,
                                         exposureOutcomeNestingCohortList = eonList,
                                         outputFolder = ccApFolder,
                                         getDbCaseDataThreads = 1,
                                         selectControlsThreads = min(3, maxCores),
                                         getDbExposureDataThreads = 1,
                                         createCaseControlDataThreads = min(5, maxCores),
                                         fitCaseControlModelThreads = min(5, maxCores),
                                         cvThreads = min(2,maxCores),
                                         prefetchExposureData = FALSE)
  ccSummary <- CaseControl::summarizeCcAnalyses(ccResult)
  ccSummaryFile <- file.path(outputFolder, "ccSummaryAp.rds")
  saveRDS(ccSummary, ccSummaryFile)

  OhdsiRTools::logInfo("Running Crockett replication")
  ccIbdFolder <- file.path(outputFolder, "ccIbd")
  if (!file.exists(ccIbdFolder))
    dir.create(ccIbdFolder)

  analysisListFile <- system.file("settings", "ccAnalysisListIbd.json", package = "EvaluatingCaseControl")
  analysisList <- CaseControl::loadCcAnalysisList(analysisListFile)
  eonList <- createEons(allControlsFile = file.path(outputFolder, "AllControlsIbd.csv"),
                        exposureId = 5,
                        outcomeId = 3)
  ccResult <- CaseControl::runCcAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         oracleTempSchema = oracleTempSchema,
                                         exposureDatabaseSchema = cohortDatabaseSchema,
                                         exposureTable = cohortTable,
                                         outcomeDatabaseSchema = cohortDatabaseSchema,
                                         outcomeTable = cohortTable,
                                         nestingCohortDatabaseSchema = cohortDatabaseSchema,
                                         nestingCohortTable = cohortTable,
                                         ccAnalysisList = analysisList,
                                         exposureOutcomeNestingCohortList = eonList,
                                         outputFolder = ccIbdFolder,
                                         getDbCaseDataThreads = 1,
                                         selectControlsThreads = min(3, maxCores),
                                         getDbExposureDataThreads = 1,
                                         createCaseControlDataThreads = min(5, maxCores),
                                         fitCaseControlModelThreads = min(5, maxCores),
                                         prefetchExposureData = TRUE)

  # Crockett used option not supported by package: controls have index date 1 year from observation start
  # Achieve this by resetting index date and rerunning analysis.
  OhdsiRTools::logInfo("Resetting conrol index date")
  #ccResult <- readRDS(file.path(ccIbdFolder, "outcomeModelReference.rds"))
  caseData <- CaseControl::loadCaseData(ccResult$caseDataFolder[1])
  caseControlsFiles <- ccResult$caseControlsFile
  for (caseControlsFile in unique(caseControlsFiles)) {
    caseControls <- readRDS(caseControlsFile)
    cases <- caseControls[caseControls$isCase, ]
    controls <- caseControls[!caseControls$isCase, ]
    controlsData <- caseData$nestingCohorts[ffbase::`%in%`(caseData$nestingCohorts$personId, controls$personId), c("personId", "startDate", "endDate")]
    controls <- merge(controls, controlsData, all.x = TRUE)
    controls <- controls[controls$indexDate >= controls$startDate & controls$indexDate <= controls$endDate, ]
    controls$indexDate <- controls$startDate + 365
    controls$startDate <- NULL
    controls$endDate <- NULL
    caseControls <- rbind(cases, controls)
    saveRDS(caseControls, caseControlsFile)
  }
  unlink(unique(ccResult$exposureDataFile), recursive = TRUE)
  unlink(unique(ccResult$caseControlDataFile))
  unlink(unique(ccResult$modelFile))

  ccResult <- CaseControl::runCcAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         oracleTempSchema = oracleTempSchema,
                                         exposureDatabaseSchema = cohortDatabaseSchema,
                                         exposureTable = cohortTable,
                                         outcomeDatabaseSchema = cohortDatabaseSchema,
                                         outcomeTable = cohortTable,
                                         nestingCohortDatabaseSchema = cohortDatabaseSchema,
                                         nestingCohortTable = cohortTable,
                                         ccAnalysisList = analysisList,
                                         exposureOutcomeNestingCohortList = eonList,
                                         outputFolder = ccIbdFolder,
                                         getDbCaseDataThreads = 1,
                                         selectControlsThreads = min(3, maxCores),
                                         getDbExposureDataThreads = 1,
                                         createCaseControlDataThreads = min(5, maxCores),
                                         fitCaseControlModelThreads = min(5, maxCores),
                                         prefetchExposureData = TRUE)
  ccSummary <- CaseControl::summarizeCcAnalyses(ccResult)
  ccSummaryFile <- file.path(outputFolder, "ccSummaryIbd.rds")
  saveRDS(ccSummary, ccSummaryFile)
}

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param outputFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createCaseControlAnalysesDetails <- function(outputFolder) {

  # Chou replication --------------------------------------------------------
  cdAp <- CaseControl::createGetDbCaseDataArgs(useNestingCohort = TRUE,
                                               useObservationEndAsNestingEndDate = TRUE,
                                               getVisits = FALSE)

  ccAp <- CaseControl::createSelectControlsArgs(firstOutcomeOnly = TRUE,
                                                washoutPeriod = 365,
                                                controlsPerCase = 4,
                                                matchOnAge = TRUE,
                                                ageCaliper = 1,
                                                matchOnGender = TRUE,
                                                matchOnProvider = FALSE,
                                                matchOnVisitDate = FALSE,
                                                matchOnTimeInCohort = TRUE,
                                                daysInCohortCaliper = 365,
                                                removedUnmatchedCases = TRUE)

  pathToCsv <- system.file("settings", "Icd9Covariates.csv", package = "EvaluatingCaseControl")
  icd9CovariateDefs <- read.csv(pathToCsv)
  icd9CovariateSettings <- createIcd9CovariateSettings(icd9CovariateDefs)

  pathToCsv <- system.file("settings", "AtcCovariates.csv", package = "EvaluatingCaseControl")
  atcCovariateDefs <- read.csv(pathToCsv)
  atcCovariateSettings <- createAtcCovariateSettings(atcCovariateDefs)

  defaultCovariateSettings = FeatureExtraction::createCovariateSettings(useDcsi = TRUE,
                                                                        endDays = -1)

  edAp <-  CaseControl::createGetDbExposureDataArgs(covariateSettings = list(icd9CovariateSettings,
                                                                             atcCovariateSettings,
                                                                             defaultCovariateSettings))

  ccdAp <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                        riskWindowStart = -30,
                                                        riskWindowEnd = 0)

  mAp <-  CaseControl::createFitCaseControlModelArgs(useCovariates = TRUE,
                                                     prior = Cyclops::createPrior("normal", 10000))

  ccAnalysisAp <- CaseControl::createCcAnalysis(analysisId = 1,
                                                description = "Chou replication for AP",
                                                getDbCaseDataArgs = cdAp,
                                                selectControlsArgs = ccAp,
                                                getDbExposureDataArgs = edAp,
                                                createCaseControlDataArgs = ccdAp,
                                                fitCaseControlModelArgs = mAp)

  ccAnalysisListAp <- list(ccAnalysisAp)
  CaseControl::saveCcAnalysisList(ccAnalysisListAp, file.path(outputFolder, "ccAnalysisListAp.json"))

  # pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
  # negativeControls <- read.csv(pathToCsv)
  # negativeControls <- negativeControls[negativeControls$outcomeName == "Acute pancreatitis", ]
  # eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = 4, outcomeId = 2, nestingCohortId = 1)
  # eonsAp <- list(eon)
  # for (i in 1:nrow(negativeControls)) {
  #   eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = negativeControls$targetId[i],
  #                                                          outcomeId = 2,
  #                                                          nestingCohortId = negativeControls$nestingId[i])
  #   eonsAp[[length(eonsAp) + 1]] <- eon
  # }
  # CaseControl::saveExposureOutcomeNestingCohortList(eonsAp, file.path(outputFolder, "ccExposureOutcomeNestingAp.json"))


  # Crockett replication ----------------------------------------------------

  cdIbd <- CaseControl::createGetDbCaseDataArgs(getVisits = FALSE)

  ccIbd <- CaseControl::createSelectControlsArgs(firstOutcomeOnly = TRUE,
                                                 washoutPeriod = 365,
                                                 controlsPerCase = 3,
                                                 matchOnAge = TRUE,
                                                 ageCaliper = 2,
                                                 matchOnGender = TRUE,
                                                 matchOnProvider = FALSE,
                                                 matchOnVisitDate = FALSE,
                                                 matchOnTimeInCohort = TRUE,
                                                 daysInCohortCaliper = 90,
                                                 removedUnmatchedCases = TRUE)

  edIbd <-  CaseControl::createGetDbExposureDataArgs()

  ccdIbd <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                         riskWindowStart = -365,
                                                         riskWindowEnd = 0)

  mIbd <-  CaseControl::createFitCaseControlModelArgs()

  ccAnalysisIbd <- CaseControl::createCcAnalysis(analysisId = 2,
                                                 description = "Crockett replication for IBD",
                                                 getDbCaseDataArgs = cdIbd,
                                                 selectControlsArgs = ccIbd,
                                                 getDbExposureDataArgs = edIbd,
                                                 createCaseControlDataArgs = ccdIbd,
                                                 fitCaseControlModelArgs = mIbd)

  ccAnalysisListIbd <- list(ccAnalysisIbd)
  CaseControl::saveCcAnalysisList(ccAnalysisListIbd, file.path(outputFolder, "ccAnalysisListIbd.json"))


  # pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
  # negativeControls <- read.csv(pathToCsv)
  # negativeControls <- negativeControls[negativeControls$outcomeName == "Ulcerative colitis", ]
  # eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = 5, outcomeId = 3)
  # eonsIbd <- list(eon)
  # for (i in 1:nrow(negativeControls)) {
  #   eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = negativeControls$targetId[i],
  #                                                          outcomeId = 3)
  #   eonsIbd[[length(eonsIbd) + 1]] <- eon
  # }
  # CaseControl::saveExposureOutcomeNestingCohortList(eonsIbd, file.path(outputFolder, "ccExposureOutcomeNestingIbd.json"))
}

createEons <- function(allControlsFile, exposureId, outcomeId, nestingCohortId = NULL) {
  allControls <- read.csv(allControlsFile)
  eonList <- list(CaseControl::createExposureOutcomeNestingCohort(exposureId = exposureId,
                                                                  outcomeId = outcomeId,
                                                                  nestingCohortId = nestingCohortId))
  for (i in 1:nrow(allControls)) {
    eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = allControls$targetId[i],
                                                           outcomeId = allControls$outcomeId[i],
                                                           nestingCohortId = allControls$nestingId[i])

    eonList[[length(eonList) + 1]] <- eon
  }
  return(eonList)
}
