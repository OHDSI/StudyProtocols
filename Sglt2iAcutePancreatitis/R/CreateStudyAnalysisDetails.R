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

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param workFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createAnalysesDetails <- function(workFolder) {
  defaultPrior <- Cyclops::createPrior("laplace", 
                                       exclude = c(0),
                                       useCrossValidation = TRUE)
  
  defaultControl <- Cyclops::createControl(cvType = "auto",
                                           startingVariance = 0.01,
                                           noiseLevel = "quiet",
                                           tolerance  = 1e-06,
                                           maxIterations = 2500,
                                           cvRepetitions = 10,
                                           seed = 1234)
  
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                         useDemographicsAgeGroup = TRUE,
                                                                         useDemographicsIndexYear = TRUE,
                                                                         useDemographicsIndexMonth = TRUE,
                                                                         useConditionGroupEraLongTerm = TRUE,
                                                                         useDrugExposureLongTerm = TRUE,
                                                                         useDrugGroupEraLongTerm = TRUE,
                                                                         useProcedureOccurrenceLongTerm = TRUE,
                                                                         useMeasurementLongTerm = TRUE, 
                                                                         useCharlsonIndex = TRUE,
                                                                         useDistinctConditionCountLongTerm = TRUE,
                                                                         useDistinctIngredientCountLongTerm = TRUE,
                                                                         useDistinctProcedureCountLongTerm = TRUE,
                                                                         useDistinctMeasurementCountLongTerm = TRUE,
                                                                         useDistinctObservationCountLongTerm = TRUE,
                                                                         useVisitCountLongTerm = TRUE,
                                                                         useVisitConceptCountLongTerm = TRUE,
                                                                         longTermStartDays = -365,
                                                                         mediumTermStartDays = -180, 
                                                                         shortTermStartDays = -30, 
                                                                         endDays = 0,
                                                                         addDescendantsToExclude = TRUE)		
  
  priorOutcomesCovariateSettings <- createPriorOutcomesCovariateSettings(windowStart = -99999,
                                                                         windowEnd = -1,
                                                                         outcomeIds = c(6479),
                                                                         outcomeNames = c("Acute Pancreatitis"))
  
  covariateSettings <- list(priorOutcomesCovariateSettings, defaultCovariateSettings)
  
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = FALSE,
                                                                   restrictToCommonPeriod = TRUE,
                                                                   maxCohortSize = 0,
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)
  
  timeToFirstEverEventPP <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                                   firstExposureOnly = FALSE,
                                                                                   washoutPeriod = 0,
                                                                                   removeDuplicateSubjects = FALSE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 1,
                                                                                   addExposureDaysToStart = FALSE,
                                                                                   riskWindowEnd = 30,
                                                                                   addExposureDaysToEnd = TRUE,
                                                                                   censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventPP <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                        firstExposureOnly = FALSE,
                                                                                        washoutPeriod = 0,
                                                                                        removeDuplicateSubjects = FALSE,
                                                                                        minDaysAtRisk = 1,
                                                                                        riskWindowStart = 1,
                                                                                        addExposureDaysToStart = FALSE,
                                                                                        riskWindowEnd = 30,
                                                                                        addExposureDaysToEnd = TRUE,
                                                                                        censorAtNewRiskWindow = FALSE)
  
  timeToFirstEverEventPPZero <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                          firstExposureOnly = FALSE,
                                                                          washoutPeriod = 0,
                                                                          removeDuplicateSubjects = FALSE,
                                                                          minDaysAtRisk = 1,
                                                                          riskWindowStart = 1,
                                                                          addExposureDaysToStart = FALSE,
                                                                          riskWindowEnd = 0,
                                                                          addExposureDaysToEnd = TRUE,
                                                                          censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventPPZero <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                               firstExposureOnly = FALSE,
                                                                               washoutPeriod = 0,
                                                                               removeDuplicateSubjects = FALSE,
                                                                               minDaysAtRisk = 1,
                                                                               riskWindowStart = 1,
                                                                               addExposureDaysToStart = FALSE,
                                                                               riskWindowEnd = 0,
                                                                               addExposureDaysToEnd = TRUE,
                                                                               censorAtNewRiskWindow = FALSE)
  
  timeToFirstEverEventPPSixty <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                              firstExposureOnly = FALSE,
                                                                              washoutPeriod = 0,
                                                                              removeDuplicateSubjects = FALSE,
                                                                              minDaysAtRisk = 1,
                                                                              riskWindowStart = 1,
                                                                              addExposureDaysToStart = FALSE,
                                                                              riskWindowEnd = 60,
                                                                              addExposureDaysToEnd = TRUE,
                                                                              censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventPPSixty <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                   firstExposureOnly = FALSE,
                                                                                   washoutPeriod = 0,
                                                                                   removeDuplicateSubjects = FALSE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 1,
                                                                                   addExposureDaysToStart = FALSE,
                                                                                   riskWindowEnd = 60,
                                                                                   addExposureDaysToEnd = TRUE,
                                                                                   censorAtNewRiskWindow = FALSE)
  
  timeToFirstEverEventITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                           firstExposureOnly = FALSE,
                                                                           washoutPeriod = 0,
                                                                           removeDuplicateSubjects = FALSE,
                                                                           minDaysAtRisk = 1,
                                                                           riskWindowStart = 1,
                                                                           addExposureDaysToStart = FALSE,
                                                                           riskWindowEnd = 9999,
                                                                           addExposureDaysToEnd = FALSE,
                                                                           censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                firstExposureOnly = FALSE,
                                                                                washoutPeriod = 0,
                                                                                removeDuplicateSubjects = FALSE,
                                                                                minDaysAtRisk = 1,
                                                                                riskWindowStart = 1,
                                                                                addExposureDaysToStart = FALSE,
                                                                                riskWindowEnd = 9999,
                                                                                addExposureDaysToEnd = FALSE,
                                                                                censorAtNewRiskWindow = FALSE)
  

  createPsArgs1 <- CohortMethod::createCreatePsArgs(control = defaultControl, 
                                                    errorOnHighCorrelation = FALSE,
                                                    stopOnError = FALSE) 
  
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)
  matchOnPsArgsCaliperSensitivity <- CohortMethod::createMatchOnPsArgs(caliper = 0.1, maxRatio=100)
  
  stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 10) 
  
  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = TRUE,
                                                                  prior = defaultPrior, 
                                                                  control = defaultControl)
  
  a1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                       description = "Time to First Ever Event Per Protocol, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a9 <- CohortMethod::createCmAnalysis(analysisId = 9,
                                       description = "Time to First Ever Event Per Protocol, Matching, Zero Day",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventPPZero,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a10 <- CohortMethod::createCmAnalysis(analysisId = 10,
                                       description = "Time to First Ever Event Per Protocol, Matching, Sixty Day",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventPPSixty,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                       description = "Time to First Post Index Event Per Protocol, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a13 <- CohortMethod::createCmAnalysis(analysisId = 13,
                                       description = "Time to First Post Index Event Per Protocol, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgsCaliperSensitivity,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a11 <- CohortMethod::createCmAnalysis(analysisId = 11,
                                       description = "Time to First Post Index Event Per Protocol, Matching, Zero Day",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPPZero,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a12 <- CohortMethod::createCmAnalysis(analysisId = 12,
                                        description = "Time to First Post Index Event Per Protocol, Matching, Sixty Day",
                                        getDbCohortMethodDataArgs = getDbCmDataArgs,
                                        createStudyPopArgs = timeToFirstPostIndexEventPPSixty,
                                        createPs = TRUE,
                                        createPsArgs = createPsArgs1,
                                        matchOnPs = TRUE,
                                        matchOnPsArgs = matchOnPsArgs1,
                                        fitOutcomeModel = TRUE,
                                        fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a3 <- CohortMethod::createCmAnalysis(analysisId = 3,
                                       description = "Time to First Ever Event Intent to Treat, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a4 <- CohortMethod::createCmAnalysis(analysisId = 4,
                                       description = "Time to First Post Index Event Intent to Treat, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)

  a14 <- CohortMethod::createCmAnalysis(analysisId = 14,
                                       description = "Time to First Post Index Event Intent to Treat, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgsCaliperSensitivity,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a5 <- CohortMethod::createCmAnalysis(analysisId = 5,
                                       description = "Time to First Ever Event Per Protocol, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a6 <- CohortMethod::createCmAnalysis(analysisId = 6,
                                       description = "Time to First Post Index Event Per Protocol, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a7 <- CohortMethod::createCmAnalysis(analysisId = 7,
                                       description = "Time to First Ever Event Intent to Treat, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a8 <- CohortMethod::createCmAnalysis(analysisId = 8,
                                       description = "Time to First Post Index Event Intent to Treat, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  cmAnalysisList <- list(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)
  
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

createTcos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AHAsAcutePancreatitis")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "AHAsAcutePancreatitis")
  negativeControls <- read.csv(pathToCsv)
  negativeControlOutcomes <- negativeControls[negativeControls$type == "Outcome", ]
  dcosList <- list()
  tcs <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  for (i in 1:nrow(tcs)) {
    targetId <- tcs$targetId[i]
    comparatorId <- tcs$comparatorId[i]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeIds <- c(outcomeIds, negativeControlOutcomes$outcomeId)
    excludeConceptIds <- tcosOfInterest$excludedCovariateConceptIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId]
    excludeConceptIds <- as.numeric(strsplit(excludeConceptIds, split = ";")[[1]])
    dcos <- CohortMethod::createDrugComparatorOutcomes(targetId = targetId,
                                                       comparatorId = comparatorId,
                                                       outcomeIds = outcomeIds,
                                                       excludedCovariateConceptIds =  excludeConceptIds)
    dcosList[[length(dcosList) + 1]] <- dcos
  }
  return(dcosList)
}
