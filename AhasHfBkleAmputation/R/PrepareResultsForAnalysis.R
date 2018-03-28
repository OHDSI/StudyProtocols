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

#' Prepare results for analysis
#'
#' @details
#' This function generates analyses results, and prepares data for the Shiny app. Requires the study to be executed first.
#'
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param databaseName         A unique name for the database.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
prepareResultsForAnalysis <- function(outputFolder, databaseName, maxCores) {
  packageName <- "AhasHfBkleAmputation"
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  
  resultsFolder <- file.path(outputFolder, "results")
  if (!file.exists(resultsFolder))
    dir.create(resultsFolder)
  shinyDataFolder <- file.path(resultsFolder, "shinyData")
  if (!file.exists(shinyDataFolder))
    dir.create(shinyDataFolder)
  balanceDataFolder <- file.path(resultsFolder, "balance")
  if (!file.exists(balanceDataFolder))
    dir.create(balanceDataFolder)
  
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = packageName)
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "Analyses.csv", package = packageName)
  analyses <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = packageName)
  negativeControls <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  reference$cohortMethodDataFolder <- gsub("^[a-z]:/", "r:/",  reference$cohortMethodDataFolder)
  reference$studyPopFile <- gsub("^[a-z]:/", "r:/",  reference$studyPopFile)
  reference$sharedPsFile <- gsub("^[a-z]:/", "r:/",  reference$sharedPsFile)
  reference$psFile <- gsub("^[a-z]:/", "r:/",  reference$psFile)
  reference$strataFile <- gsub("^[a-z]:/", "r:/",  reference$strataFile)
  reference$outcomeModelFile <- gsub("^[a-z]:/", "r:/",  reference$outcomeModelFile)

  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  # saveRDS(analysisSummary, "analysisSummary.rds")
  # analysisSummary <- readRDS("analysisSummary.rds")
  analysisSummary <- merge(analysisSummary, analyses)
  subset <- tcosOfInterest
  subset$excludedCovariateConceptIds <- NULL
  subset$outcomeIds <- NULL
  subset$outcomeNames <- NULL
  analysisSummary <- merge(analysisSummary, subset)
  analysisSummary <- merge(analysisSummary, negativeControls[, c("outcomeId", "outcomeName")], all.x = TRUE)
  analysisSummary$type <- "Outcome of interest"
  analysisSummary$type[analysisSummary$outcomeId %in% negativeControls$outcomeId] <- "Negative control"
  analysisSummary$database <- databaseName
  
  # Present analyses without censoring at switch as another time-at-risk
  analysisSummary$timeAtRisk[!analysisSummary$censorAtSwitch] <- paste(analysisSummary$timeAtRisk[!analysisSummary$censorAtSwitch], "(no censor at switch)")
  analysisSummary <- analysisSummary[!(analysisSummary$timeAtRisk %in% c("Intent to Treat (no censor at switch)",
                                                                         "Modified ITT (no censor at switch)")), ]
  analysisSummary$censorAtSwitch <- NULL
  # chunk <- analysisSummary[analysisSummary$targetId == 5357 & analysisSummary$comparatorId == 5363, ]
  runTc <- function(chunk, tcosOfInterest, negativeControls, shinyDataFolder, balanceDataFolder, outputFolder, databaseName, reference) {
    ffbase::load.ffdf(file.path(outputFolder, "priorAhaExposures"))
    targetId <- chunk$targetId[1]
    comparatorId <- chunk$comparatorId[1]
    OhdsiRTools::logTrace("Preparing results for target ID ", targetId, ", comparator ID", comparatorId)
    idx <- which(tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId)[1] 
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[idx])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeNames <- as.character(tcosOfInterest$outcomeNames[idx])
    outcomeNames <- strsplit(outcomeNames, split = ";")[[1]]
    for (analysisId in unique(reference$analysisId)) {
      OhdsiRTools::logTrace("Analysis ID ", analysisId)
      negControlSubset <- chunk[chunk$targetId == targetId &
                                  chunk$comparatorId == comparatorId &
                                  chunk$outcomeId %in% negativeControls$outcomeId &
                                  chunk$analysisId == analysisId, ]
      validNcs <- sum(!is.na(negControlSubset$seLogRr))
      if (validNcs >= 5) {
        fileName <-  file.path(shinyDataFolder, paste0("null_a",analysisId,"_t",targetId,"_c",comparatorId,"_",databaseName,".rds"))
        if (file.exists(fileName)) {
          null <- readRDS(fileName)
        } else {
          null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
          saveRDS(null, fileName)
        }
        idx <- chunk$targetId == targetId &
          chunk$comparatorId == comparatorId &
          chunk$analysisId == analysisId
        calibratedP <- EmpiricalCalibration::calibrateP(null = null,
                                                        logRr = chunk$logRr[idx],
                                                        seLogRr = chunk$seLogRr[idx])
        chunk$calP[idx] <- calibratedP$p
        chunk$calP_lb95ci[idx] <- calibratedP$lb95ci
        chunk$calP_ub95ci[idx] <- calibratedP$ub95ci
      } 
      
      for (outcomeId in outcomeIds) {
        OhdsiRTools::logTrace("Outcome ID ", outcomeId)
        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        idx <- chunk$targetId == targetId &
          chunk$comparatorId == comparatorId &
          chunk$outcomeId == outcomeId &
          chunk$analysisId == analysisId
 
        # Compute MDRR
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        population <- readRDS(strataFile)
        mdrr <- CohortMethod::computeMdrr(population, alpha = 0.05, power = 0.8, twoSided = TRUE, modelType = "cox")
        chunk$mdrr[idx] <- mdrr$mdrr
        chunk$outcomeName[idx] <- outcomeName
        
        # Compute time-at-risk distribtion stats
        distTarget <- quantile(population$timeAtRisk[population$treatment == 1], c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1))
        distComparator <- quantile(population$timeAtRisk[population$treatment == 0], c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1))
        chunk$tarTargetMean[idx] <- mean(population$timeAtRisk[population$treatment == 1])
        chunk$tarTargetSd[idx] <- sd(population$timeAtRisk[population$treatment == 1])
        chunk$tarTargetMin[idx] <- distTarget[1]
        chunk$tarTargetP10[idx] <- distTarget[2]
        chunk$tarTargetP25[idx] <- distTarget[3]
        chunk$tarTargetMedian[idx] <- distTarget[4]
        chunk$tarTargetP75[idx] <- distTarget[5]
        chunk$tarTargetP90[idx] <- distTarget[6]
        chunk$tarTargetMax[idx] <- distTarget[7]
        chunk$tarComparatorMean[idx] <- mean(population$timeAtRisk[population$treatment == 0])
        chunk$tarComparatorSd[idx] <- sd(population$timeAtRisk[population$treatment == 0])
        chunk$tarComparatorMin[idx] <- distComparator[1]
        chunk$tarComparatorP10[idx] <- distComparator[2]
        chunk$tarComparatorP25[idx] <- distComparator[3]
        chunk$tarComparatorMedian[idx] <- distComparator[4]
        chunk$tarComparatorP75[idx] <- distComparator[5]
        chunk$tarComparatorP90[idx] <- distComparator[6]
        chunk$tarComparatorMax[idx] <- distComparator[7]
        
        # Compute covariate balance 
        refRow <- reference[reference$analysisId == analysisId &
                              reference$targetId == targetId &
                              reference$comparatorId == comparatorId &
                              reference$outcomeId == outcomeId, ]
        psAfterMatching <- readRDS(refRow$strataFile)
        cmData <- CohortMethod::loadCohortMethodData(refRow$cohortMethodDataFolder)
        fileName <-  file.path(balanceDataFolder, paste0("bal_a",analysisId,"_t",targetId,"_c",comparatorId,"_o",outcomeId,"_",databaseName,".rds"))
        if (!file.exists(fileName)) {
          balance <- CohortMethod::computeCovariateBalance(psAfterMatching, cmData)
          saveRDS(balance, fileName)
        }
        
        # Compute balance for prior AHA exposure covariates
        fileName <-  file.path(shinyDataFolder, paste0("ahaBal_a",analysisId,"_t",targetId,"_c",comparatorId,"_o",outcomeId,"_",databaseName,".rds"))
        if (!file.exists(fileName)) {
          dummyCmData <- cmData
          dummyCmData$covariates <- merge(covariates, 
                                          ff::as.ffdf(cmData$cohorts[, c("rowId", "subjectId", "cohortStartDate")]))
          dummyCmData$covariateRef <- covariateRef
          balance <- CohortMethod::computeCovariateBalance(psAfterMatching, dummyCmData)
          balance$conceptId <- NULL
          balance$beforeMatchingSd <- NULL
          balance$afterMatchingSd <- NULL
          balance$beforeMatchingSumTreated <- NULL
          balance$beforeMatchingSumComparator <- NULL
          balance$afterMatchingSumTreated <- NULL
          balance$afterMatchingSumComparator <- NULL
          if (nrow(balance) > 0)
            balance$analysisId <- as.integer(balance$analysisId)
          saveRDS(balance, fileName)
        }
        
        # Create KM plot
        fileName <-  file.path(shinyDataFolder, paste0("km_a",analysisId,"_t",targetId,"_c",comparatorId,"_o",outcomeId,"_",databaseName,".rds"))
        if (!file.exists(fileName)) {
          plot <- CohortMethod::plotKaplanMeier(psAfterMatching)
          # plot <- CohortMethod::plotKaplanMeier(psAfterMatching, 
          #                                       treatmentLabel = chunk$targetDrug[chunk$targetId == targetId][1],
          #                                       comparatorLabel = chunk$comparatorDrug[chunk$comparatorId == comparatorId][1])
          saveRDS(plot, fileName)
        }
        
        # Add cohort sizes before matching/stratification
        chunk$treatedBefore[idx] <- sum(cmData$cohorts$treatment == 1)
        chunk$comparatorBefore[idx] <- sum(cmData$cohorts$treatment == 0)
      }
      fileName <-  file.path(shinyDataFolder, paste0("ps_a",analysisId,"_t",targetId,"_c",comparatorId,"_",databaseName,".rds"))
      if (!file.exists(fileName)) {
        exampleRef <- reference[reference$analysisId == analysisId &
                                  reference$targetId == targetId &
                                  reference$comparatorId == comparatorId &
                                  reference$outcomeId == outcomeIds[1], ]
        ps <- readRDS(exampleRef$sharedPsFile)
        preparedPsPlot <- EvidenceSynthesis::preparePsPlot(ps)
        saveRDS(preparedPsPlot, fileName)
      }
    }
    OhdsiRTools::logDebug("Finished chunk with ", nrow(chunk), " rows")
    return(chunk)
  }
  # OhdsiRTools::addDefaultFileLogger("s:/temp/log.log")
  cluster <- OhdsiRTools::makeCluster(min(maxCores, 10))
  comparison <- paste(analysisSummary$targetId, analysisSummary$comparatorId)
  chunks <- split(analysisSummary, comparison) 
  analysisSummaries <- OhdsiRTools::clusterApply(cluster = cluster, 
                                                 x = chunks, 
                                                 fun = runTc, 
                                                 tcosOfInterest = tcosOfInterest,
                                                 negativeControls = negativeControls, 
                                                 shinyDataFolder = shinyDataFolder,
                                                 balanceDataFolder = balanceDataFolder,
                                                 outputFolder = outputFolder,
                                                 databaseName = databaseName,
                                                 reference = reference)
  OhdsiRTools::stopCluster(cluster)
  analysisSummary <- do.call(rbind, analysisSummaries)
  
  fileName <-  file.path(resultsFolder, paste0("results_", databaseName,".csv"))
  write.csv(analysisSummary, fileName, row.names = FALSE)
  
  hois <- analysisSummary[analysisSummary$type == "Outcome of interest", ]
  fileName <-  file.path(shinyDataFolder, paste0("resultsHois_", databaseName,".rds"))
  saveRDS(hois, fileName)
  
  ncs <- analysisSummary[analysisSummary$type == "Negative control", c("targetId", "comparatorId", "outcomeId", "analysisId", "database", "logRr", "seLogRr")]
  fileName <-  file.path(shinyDataFolder, paste0("resultsNcs_", databaseName,".rds"))
  saveRDS(ncs, fileName)
  
  OhdsiRTools::logInfo("Minimizing balance files for Shiny app")
  allCovarNames <- data.frame()
  balanceFiles <- list.files(balanceDataFolder, "bal.*.rds")
  pb <- txtProgressBar(style = 3)
  for (i in 1:length(balanceFiles)) {
    fileName <- balanceFiles[i]
    balance <- readRDS(file.path(balanceDataFolder, fileName))
    idx <- !(balance$covariateId %in% allCovarNames$covariateId)
    if (any(idx)) {
      allCovarNames <- rbind(allCovarNames, balance[idx, c("covariateId", "covariateName")])
    }
    balance$covariateName <- NULL
    balance$conceptId <- NULL
    balance$beforeMatchingSd <- NULL
    balance$afterMatchingSd <- NULL
    balance$beforeMatchingSumTreated <- NULL
    balance$beforeMatchingSumComparator <- NULL
    balance$afterMatchingSumTreated <- NULL
    balance$afterMatchingSumComparator <- NULL
    balance$analysisId <- as.integer(balance$analysisId)
    saveRDS(balance, file.path(shinyDataFolder, fileName))
    if (i %% 100 == 0) {
      setTxtProgressBar(pb, i/length(balanceFiles))
    }
  }
  setTxtProgressBar(pb, 1)
  close(pb)
  fileName <-  file.path(shinyDataFolder, paste0("covarNames_", databaseName,".rds"))
  saveRDS(allCovarNames, fileName)
}

# files <- list.files(shinyDataFolder, "ahaBal_a.*.rds", full.names = TRUE)
# targetFiles <- gsub(shinyDataFolder, balanceDataFolder, sourceFiles)
# file.rename(sourceFiles, targetFiles)
# unlink(files)
