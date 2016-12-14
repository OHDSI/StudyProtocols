# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
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

#' Run the cohort method package
#'
#' @details
#' Runs the cohort method package to produce propensity scores and outcome models.
#'
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
runCohortMethod <- function(workFolder, maxCores = 4) {
    cmFolder <- file.path(workFolder, "cmOutput")
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    createDcos <- function(i, exposureSummary) {
        # originalTargetId <- exposureSummary$tCohortDefinitionId[i]
        # originalComparatorId <- exposureSummary$cCohortDefinitionId[i]
        targetId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        folderName <- file.path(cmFolder, paste0("CmData_l1_t", targetId, "_c", comparatorId))
        cmData <- CohortMethod::loadCohortMethodData(folderName, readOnly = TRUE)
        outcomeIds <-   attr(cmData$outcomes, "metaData")$outcomeIds
        dco <- CohortMethod::createDrugComparatorOutcomes(targetId = targetId,
                                                          comparatorId = comparatorId,
                                                          outcomeIds = outcomeIds)
        return(dco)
    }
    dcos <- lapply(1:nrow(exposureSummary), createDcos, exposureSummary)
    cmAnalysisListFile <- system.file("settings",
                                      "cmAnalysisList.txt",
                                      package = "LargeScalePopEst")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)

    pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
    hois <- read.csv(pathToCsv)

    CohortMethod::runCmAnalyses(connectionDetails = NULL,
                                cdmDatabaseSchema = NULL,
                                exposureDatabaseSchema = NULL,
                                exposureTable = NULL,
                                outcomeDatabaseSchema = NULL,
                                outcomeTable = NULL,
                                outputFolder = cmFolder,
                                oracleTempSchema = NULL,
                                cmAnalysisList = cmAnalysisList,
                                cdmVersion = 5,
                                drugComparatorOutcomesList = dcos,
                                getDbCohortMethodDataThreads = 1,
                                createStudyPopThreads = min(4, maxCores),
                                createPsThreads = max(1, round(maxCores/10)),
                                psCvThreads = min(10, maxCores),
                                trimMatchStratifyThreads = min(4, maxCores),
                                fitOutcomeModelThreads = min(4, maxCores),
                                outcomeCvThreads = min(4, maxCores),
                                refitPsForEveryOutcome = FALSE,
                                outcomeIdsOfInterest = hois$cohortDefinitionId)
    outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
    analysesSum <- CohortMethod::summarizeAnalyses(outcomeModelReference)
    write.csv(analysesSum, file.path(workFolder, "analysisSummary.csv"), row.names = FALSE)
}

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param outputFolder   Name of local folder to place results; make sure to use forward slashes (/)
#'
#' @export
createAnalysesDetails <- function(outputFolder) {
    # dummy args, will never be used because data objects have already been created:
    getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(covariateSettings = FeatureExtraction::createCovariateSettings())

    createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeDuplicateSubjects = FALSE,
                                                                        removeSubjectsWithPriorOutcome = TRUE,
                                                                        riskWindowStart = 0,
                                                                        riskWindowEnd = 0,
                                                                        addExposureDaysToEnd = TRUE,
                                                                        minDaysAtRisk = 1)
    # Fixing seed for reproducability
    # Ignoring high correlation with mental disorder covariates. These appear highly predictive when comparing nortriptyline to
    # psychotherapy, which is probably correct (Many nortriptyline users appear to use the drug for headache-related conditions)
    createPsArgs <- CohortMethod::createCreatePsArgs(control = Cyclops::createControl(noiseLevel = "silent",
                                                                                      cvType = "auto",
                                                                                      tolerance = 2e-07,
                                                                                      cvRepetitions = 1,
                                                                                      startingVariance = 0.01,
                                                                                      seed = 123),
                                                     stopOnError = FALSE)

    # matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)

    stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 10)

    fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(stratified = FALSE,
                                                                    useCovariates = FALSE,
                                                                    modelType = "cox")

    fitOutcomeModelArgs2 <- CohortMethod::createFitOutcomeModelArgs(stratified = TRUE,
                                                                    useCovariates = FALSE,
                                                                    modelType = "cox")


    cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                  description = "Crude: no propensity scores",
                                                  getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                  createStudyPopArgs = createStudyPopArgs,
                                                  fitOutcomeModel = TRUE,
                                                  fitOutcomeModelArgs = fitOutcomeModelArgs1)

    # cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
    #                                               description = "1-on-1 matching plus conditioned outcome model",
    #                                               getDbCohortMethodDataArgs = getDbCmDataArgs,
    #                                               createStudyPopArgs = createStudyPopArgs,
    #                                               createPs = TRUE,
    #                                               createPsArgs = createPsArgs,
    #                                               matchOnPs = TRUE,
    #                                               matchOnPsArgs = matchOnPsArgs,
    #                                               fitOutcomeModel = TRUE,
    #                                               fitOutcomeModelArgs = fitOutcomeModelArgs2)

    cmAnalysis3 <- CohortMethod::createCmAnalysis(analysisId = 3,
                                                  description = "PS stratification plus conditioned outcome model",
                                                  getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                  createStudyPopArgs = createStudyPopArgs,
                                                  createPs = TRUE,
                                                  createPsArgs = createPsArgs,
                                                  stratifyByPs =  TRUE,
                                                  stratifyByPsArgs = stratifyByPsArgs,
                                                  fitOutcomeModel = TRUE,
                                                  fitOutcomeModelArgs = fitOutcomeModelArgs2)

   # cmAnalysisList <- list(cmAnalysis1, cmAnalysis2, cmAnalysis3)
    cmAnalysisList <- list(cmAnalysis1, cmAnalysis3)

    CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(outputFolder, "cmAnalysisList.txt"))
}
