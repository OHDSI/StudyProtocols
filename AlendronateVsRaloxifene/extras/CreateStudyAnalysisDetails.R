# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of TofaRep
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

createAnalysesDetails <- function(workFolder) {
  covarSettings <- FeatureExtraction::createDefaultCovariateSettings(addDescendantsToExclude = TRUE)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 365,
                                                                   restrictToCommonPeriod = TRUE,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = TRUE,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covarSettings)

  createStudyPopArgs1 <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                       removeDuplicateSubjects = "keep first",
                                                                       minDaysAtRisk = 0,
                                                                       riskWindowStart = 90,
                                                                       addExposureDaysToStart = FALSE,
                                                                       riskWindowEnd = 9999,
                                                                       addExposureDaysToEnd = FALSE)

  createStudyPopArgs2 <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                       removeDuplicateSubjects = "keep first",
                                                                       minDaysAtRisk = 0,
                                                                       riskWindowStart = 90,
                                                                       addExposureDaysToStart = FALSE,
                                                                       riskWindowEnd = 0,
                                                                       addExposureDaysToEnd = TRUE)


  createPsArgs <- CohortMethod::createCreatePsArgs(control = Cyclops::createControl(cvType = "auto",
                                                                                    startingVariance = 0.01,
                                                                                    noiseLevel = "quiet",
                                                                                    tolerance = 2e-07,
                                                                                    cvRepetitions = 10))

  stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 5)

  fitOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                 modelType = "cox",
                                                                 stratified = TRUE)

  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "Main analysis: ITT",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs1,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs)

  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "Sensitivity analysis: Per-protocol",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs2,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs)



  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2)

  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

