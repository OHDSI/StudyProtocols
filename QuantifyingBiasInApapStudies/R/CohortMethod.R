# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of QuantifyingBiasInApapStudies
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


#' Run CohortMethod package
#'
#' @details
#' Run the CohortMethod package, which implements the comparative cohort design.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
runCohortMethod <- function(connectionDetails,
                            cdmDatabaseSchema,
                            cohortDatabaseSchema,
                            cohortTable,
                            oracleTempSchema,
                            outputFolder,
                            maxCores) {
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  if (!file.exists(cmOutputFolder)) {
    dir.create(cmOutputFolder)
  }
  cmAnalysisListFile <- system.file("settings",
                                    "cmAnalysisList.json",
                                    package = "QuantifyingBiasInApapStudies")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
  tcosList <- createTcos(outputFolder = outputFolder)
  outcomesOfInterest <- getOutcomesOfInterest()
  results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         exposureDatabaseSchema = cohortDatabaseSchema,
                                         exposureTable = cohortTable,
                                         outcomeDatabaseSchema = cohortDatabaseSchema,
                                         outcomeTable = cohortTable,
                                         outputFolder = cmOutputFolder,
                                         oracleTempSchema = oracleTempSchema,
                                         cmAnalysisList = cmAnalysisList,
                                         targetComparatorOutcomesList = tcosList,
                                         getDbCohortMethodDataThreads = min(3, maxCores),
                                         createStudyPopThreads = min(3, maxCores),
                                         createPsThreads = max(1, round(maxCores/10)),
                                         psCvThreads = min(10, maxCores),
                                         trimMatchStratifyThreads = min(10, maxCores),
                                         fitOutcomeModelThreads = max(1, round(maxCores/2)),
                                         outcomeCvThreads = min(2, maxCores),
                                         refitPsForEveryOutcome = FALSE)
  
  ParallelLogger::logInfo("Summarizing results")
  analysisSummary <- CohortMethod::summarizeAnalyses(referenceTable = results, 
                                                     outputFolder = cmOutputFolder)
  analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
  analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
  analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
  analysisSummary <- addAnalysisDescription(analysisSummary, "analysisId", "analysisDescription")
  write.csv(analysisSummary, file.path(outputFolder, "cmAnalysisSummary.csv"), row.names = FALSE)
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
createCmAnalysesDetails <- function(workFolder) {
  defaultControl <- Cyclops::createControl(cvType = "auto",
                                           startingVariance = 0.01,
                                           noiseLevel = "quiet",
                                           tolerance  = 1e-06,
                                           maxIterations = 2500,
                                           cvRepetitions = 10,
                                           seed = 123)
  
  # Exclude acetaminophen and all other ingredients included in drugs containing acetaminophen:
  toExclude <- c(1134439, 1135766, 1153013, 1189596, 1201620, 906780, 1125315, 1130585, 1103518, 19092290, 1129625, 1119510, 724394, 1153664, 1124957, 964407, 1112807, 1103314, 44361362, 19004724, 19037833, 1139993, 1154332)
  
  defaultCovariateSettings <- FeatureExtraction::createDefaultCovariateSettings(excludedCovariateConceptIds = toExclude,
                                                                         addDescendantsToExclude = TRUE)
  customCovariateSettings <- createCustomCovariatesSettings(useSmoking = TRUE,
                                                            useRheumatoidArthritis = TRUE,
                                                            useNonRa = TRUE,
                                                            useFatigue = TRUE,
                                                            useMigraine = TRUE)
  
  covariateSettings <- list(defaultCovariateSettings, customCovariateSettings)
  
  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = FALSE,
                                                                   restrictToCommonPeriod = FALSE,
                                                                   maxCohortSize = 0, 
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)
  
  noDelayTar <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                                   firstExposureOnly = FALSE,
                                                                                   washoutPeriod = 0,
                                                                                   removeDuplicateSubjects = FALSE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 0,
                                                                                   startAnchor = "cohort start",
                                                                                   riskWindowEnd = 0,
                                                                                   endAnchor = "cohort end",
                                                                                   censorAtNewRiskWindow = FALSE)
  
  delayTar <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                           firstExposureOnly = FALSE,
                                                           washoutPeriod = 0,
                                                           removeDuplicateSubjects = FALSE,
                                                           minDaysAtRisk = 1,
                                                           riskWindowStart = 2*365,
                                                           startAnchor = "cohort start",
                                                           riskWindowEnd = 0,
                                                           endAnchor = "cohort end",
                                                           censorAtNewRiskWindow = FALSE)
  
  createPsArgs <- CohortMethod::createCreatePsArgs(control = defaultControl, 
                                                   errorOnHighCorrelation = FALSE,
                                                   stopOnError = FALSE) 
  
  # Covariates to include in outcome model:
  includeCovariateIds <- c(8532001,
                           1997,
                           1901,
                           1995,
                           1994,
                           1993,
                           1992)
  # Female
  # Smoking
  # Charlson Index
  # History of rheumatoid arthritis
  # History of non-rheumatoid arthritis or chronic neck/back/joint pain.
  # History of fatigue or lack of energy
  # History of migraines or frequent headaches  

  fitOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = TRUE,
                                                                 modelType = "cox",
                                                                 stratified = FALSE,
                                                                 prior = Cyclops::createPrior("none"), 
                                                                 includeCovariateIds = includeCovariateIds)
  
  a9 <- CohortMethod::createCmAnalysis(analysisId = 9,
                                       description = "No delay",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = noDelayTar,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  a10 <- CohortMethod::createCmAnalysis(analysisId = 10,
                                       description = "Delay",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = delayTar,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs)
  
  cmAnalysisList <- list(a9, a10)
  
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

computeCovariateBalance <- function(row, cmOutputFolder, balanceFolder) {
  outputFileName <- file.path(balanceFolder,
                              sprintf("bal_t%s_c%s_o%s_a%s.rds", row$targetId, row$comparatorId, row$outcomeId, row$analysisId))
  if (!file.exists(outputFileName)) {
    ParallelLogger::logTrace("Creating covariate balance file ", outputFileName)
    cohortMethodDataFolder <- file.path(cmOutputFolder, row$cohortMethodDataFolder)
    cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)
    strataFile <- file.path(cmOutputFolder, row$strataFile)
    strata <- readRDS(strataFile)
    balance <- CohortMethod::computeCovariateBalance(population = strata, cohortMethodData = cohortMethodData)
    saveRDS(balance, outputFileName)
  }
}

addAnalysisDescription <- function(data, IdColumnName = "analysisId", nameColumnName = "analysisDescription") {
  cmAnalysisListFile <- system.file("settings",
                                    "cmAnalysisList.json",
                                    package = "QuantifyingBiasInApapStudies")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
  idToName <- lapply(cmAnalysisList, function(x) data.frame(analysisId = x$analysisId, description = as.character(x$description)))
  idToName <- do.call("rbind", idToName)
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data) , (idCol + 1):(ncol(data) - 1))]
  }
  return(data)
}

createTcos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "QuantifyingBiasInApapStudies")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  allControls <- read.csv(pathToCsv)
  
  tcs <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  createTco <- function(i) {
    targetId <- tcs$targetId[i]
    comparatorId <- tcs$comparatorId[i]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeIds <- c(outcomeIds, allControls$outcomeId[allControls$targetId == targetId & allControls$comparatorId == comparatorId])
    excludeConceptIds <- as.character(tcosOfInterest$excludedCovariateConceptIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    if (length(excludeConceptIds) == 1 && is.na(excludeConceptIds)) {
      excludeConceptIds <- c()
    } else if (length(excludeConceptIds) > 0) {
      excludeConceptIds <- as.numeric(strsplit(excludeConceptIds, split = ";")[[1]])
    }
    includeConceptIds <- as.character(tcosOfInterest$includedCovariateConceptIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    if (length(includeConceptIds) == 1 && is.na(includeConceptIds)) {
      includeConceptIds <- c()
    } else if (length(includeConceptIds) > 0) {
      includeConceptIds <- as.numeric(strsplit(excludeConceptIds, split = ";")[[1]])
    }
    tco <- CohortMethod::createTargetComparatorOutcomes(targetId = targetId,
                                                        comparatorId = comparatorId,
                                                        outcomeIds = outcomeIds,
                                                        excludedCovariateConceptIds = excludeConceptIds,
                                                        includedCovariateConceptIds = includeConceptIds)
    return(tco)
  }
  tcosList <- lapply(1:nrow(tcs), createTco)
  return(tcosList)
}

getOutcomesOfInterest <- function() {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "QuantifyingBiasInApapStudies")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE) 
  outcomeIds <- as.character(tcosOfInterest$outcomeIds)
  outcomeIds <- do.call("c", (strsplit(outcomeIds, split = ";")))
  outcomeIds <- unique(as.numeric(outcomeIds))
  return(outcomeIds)
}

getAllControls <- function(outputFolder) {
  allControlsFile <- file.path(outputFolder, "AllControls.csv")
  if (file.exists(allControlsFile)) {
    # Positive controls must have been synthesized. Include both positive and negative controls.
    allControls <- read.csv(allControlsFile)
  } else {
    # Include only negative controls
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
    allControls <- read.csv(pathToCsv)
    allControls$oldOutcomeId <- allControls$outcomeId
    allControls$targetEffectSize <- rep(1, nrow(allControls))
  }
  return(allControls)
}
