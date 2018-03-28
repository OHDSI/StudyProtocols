# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
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
                                                                         outcomeIds = c(5432, 5433),
                                                                         outcomeNames = c("hospitalizations for heart failure (primary inpatient diagnosis)", "Below Knee Lower Extremity Amputation events"))
  
  covariateSettings <- list(priorOutcomesCovariateSettings, defaultCovariateSettings)
  
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = FALSE,
                                                                   restrictToCommonPeriod = TRUE,
                                                                   maxCohortSize = 0, 
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)
  
  timeToFirstEverEventOnTreatment <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                                   firstExposureOnly = FALSE,
                                                                                   washoutPeriod = 0,
                                                                                   removeDuplicateSubjects = FALSE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 1,
                                                                                   addExposureDaysToStart = FALSE,
                                                                                   riskWindowEnd = 0,
                                                                                   addExposureDaysToEnd = TRUE,
                                                                                   censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventOnTreatment <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                        firstExposureOnly = FALSE,
                                                                                        washoutPeriod = 0,
                                                                                        removeDuplicateSubjects = FALSE,
                                                                                        minDaysAtRisk = 1,
                                                                                        riskWindowStart = 1,
                                                                                        addExposureDaysToStart = FALSE,
                                                                                        riskWindowEnd = 0,
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
  
  timeToFirstEverEventLag <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                           firstExposureOnly = FALSE,
                                                                           washoutPeriod = 0,
                                                                           removeDuplicateSubjects = FALSE,
                                                                           minDaysAtRisk = 1,
                                                                           riskWindowStart = 60,
                                                                           addExposureDaysToStart = FALSE,
                                                                           riskWindowEnd = 60,
                                                                           addExposureDaysToEnd = TRUE,
                                                                           censorAtNewRiskWindow = FALSE)
  
  timeToFirstPostIndexEventLag <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                firstExposureOnly = FALSE,
                                                                                washoutPeriod = 0,
                                                                                removeDuplicateSubjects = FALSE,
                                                                                minDaysAtRisk = 1,
                                                                                riskWindowStart = 60,
                                                                                addExposureDaysToStart = FALSE,
                                                                                riskWindowEnd = 60,
                                                                                addExposureDaysToEnd = TRUE,
                                                                                censorAtNewRiskWindow = FALSE)
  
  timeToFirstEverEventModifiedITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                                   firstExposureOnly = FALSE,
                                                                                   washoutPeriod = 0,
                                                                                   removeDuplicateSubjects = FALSE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 1,
                                                                                   addExposureDaysToStart = FALSE,
                                                                                   riskWindowEnd = 9999,
                                                                                   addExposureDaysToEnd = FALSE,
                                                                                   censorAtNewRiskWindow = TRUE)
  
  timeToFirstPostIndexEventModifiedITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                        firstExposureOnly = FALSE,
                                                                                        washoutPeriod = 0,
                                                                                        removeDuplicateSubjects = FALSE,
                                                                                        minDaysAtRisk = 1,
                                                                                        riskWindowStart = 1,
                                                                                        addExposureDaysToStart = FALSE,
                                                                                        riskWindowEnd = 9999,
                                                                                        addExposureDaysToEnd = FALSE,
                                                                                        censorAtNewRiskWindow = TRUE)

  createPsArgs1 <- CohortMethod::createCreatePsArgs(control = defaultControl, 
                                                    errorOnHighCorrelation = FALSE,
                                                    stopOnError = FALSE) 
  
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)
  
  stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 10) 
  
  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = TRUE,
                                                                  prior = defaultPrior, 
                                                                  control = defaultControl)
  
  a1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                       description = "Time to First Ever Event On Treatment, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventOnTreatment,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                       description = "Time to First Post Index Event On Treatment, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventOnTreatment,
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
  
  a5 <- CohortMethod::createCmAnalysis(analysisId = 5,
                                       description = "Time to First Ever Event Lag, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventLag,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a6 <- CohortMethod::createCmAnalysis(analysisId = 6,
                                       description = "Time to First Post Index Event Lag, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventLag,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a7 <- CohortMethod::createCmAnalysis(analysisId = 7,
                                       description = "Time to First Ever Event Modified ITT, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventModifiedITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a8 <- CohortMethod::createCmAnalysis(analysisId = 8,
                                       description = "Time to First Post Index Event Modified ITT, Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventModifiedITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs1,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a9 <- CohortMethod::createCmAnalysis(analysisId = 9,
                                       description = "Time to First Ever Event On Treatment, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventOnTreatment,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a10 <- CohortMethod::createCmAnalysis(analysisId = 10,
                                       description = "Time to First Post Index Event On Treatment, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventOnTreatment,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a11 <- CohortMethod::createCmAnalysis(analysisId = 11,
                                       description = "Time to First Ever Event Intent to Treat, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a12 <- CohortMethod::createCmAnalysis(analysisId = 12,
                                       description = "Time to First Post Index Event Intent to Treat, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a13 <- CohortMethod::createCmAnalysis(analysisId = 13,
                                       description = "Time to First Ever Event Lag, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventLag,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a14 <- CohortMethod::createCmAnalysis(analysisId = 14,
                                       description = "Time to First Post Index Event Lag, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventLag,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a15 <- CohortMethod::createCmAnalysis(analysisId = 15,
                                       description = "Time to First Ever Event Modified ITT, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstEverEventModifiedITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  
  a16 <- CohortMethod::createCmAnalysis(analysisId = 16,
                                       description = "Time to First Post Index Event Modified ITT, Stratification",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventModifiedITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs1,
                                       stratifyByPs = TRUE,
                                       stratifyByPsArgs = stratifyByPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)
  cmAnalysisList <- list(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16)
  #cmAnalysisList <- list(a1)
  
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

createTcos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AhasHfBkleAmputation")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "AhasHfBkleAmputation")
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
