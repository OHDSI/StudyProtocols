# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
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

#' Generate diagnostics
#'
#' @details
#' This function generates analyses diagnostics. Requires the study to be executed first.
#'
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#'
#' @export
generateDiagnostics <- function(outputFolder) {
  packageName <- "AlendronateVsRaloxifene"
  modelType <- "cox" # For MDRR computation
  psStrategy <- "stratification" # For covariate balance labels
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  diagnosticsFolder <- file.path(outputFolder, "diagnostics")
  if (!file.exists(diagnosticsFolder))
    dir.create(diagnosticsFolder)
  
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = packageName)
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  reference <- unique(reference)
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmAnalysisList.json", package = packageName))
  for (i in 1:length(cmAnalysisList)) {
    analysisSummary$description[analysisSummary$analysisId == cmAnalysisList[[i]]$analysisId] <-  cmAnalysisList[[i]]$description
  }
  allControlsFile <- file.path(outputFolder, "AllControls.csv")
  allControls <- read.csv(allControlsFile)
  tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  mdrrs <- data.frame()
  for (i in 1:nrow(tcsOfInterest)) {
    targetId <- tcsOfInterest$targetId[i]
    comparatorId <- tcsOfInterest$comparatorId[i]
    targetLabel <- tcosOfInterest$targetName[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId][1]
    comparatorLabel <- tcosOfInterest$comparatorName[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId][1]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    for (analysisId in unique(reference$analysisId)) {
      controlSubset <- allControls[allControls$targetId == targetId & allControls$comparatorId == comparatorId, ]
      controlSubset <- merge(controlSubset[, c("targetId", "comparatorId", "outcomeId", "oldOutcomeId", "targetEffectSize")], analysisSummary[analysisSummary$analysisId == analysisId, ])
      
      # Outcome controls
      label <- "OutcomeControls"
      
      negControlSubset <- controlSubset[controlSubset$targetEffectSize == 1, ]
      
      validNcs <- sum(!is.na(negControlSubset$seLogRr))
      if (validNcs >= 5) {
        null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
        
        fileName <-  file.path(diagnosticsFolder, paste0("nullDistribution_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".png"))
        EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = negControlSubset$logRr,
                                                    seLogRrNegatives = negControlSubset$seLogRr,
                                                    null = null,
                                                    showCis = TRUE,
                                                    fileName = fileName)
      } else {
        null <- NULL
      }
      if (sum(!is.na(controlSubset$seLogRr)) >= 5) {
        fileName <-  file.path(diagnosticsFolder, paste0("trueAndObs_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".png"))
        EmpiricalCalibration::plotTrueAndObserved(logRr = controlSubset$logRr, 
                                                  seLogRr = controlSubset$seLogRr, 
                                                  trueLogRr = log(controlSubset$targetEffectSize),
                                                  fileName = fileName)
      }
      validPcs <- sum(!is.na(controlSubset$seLogRr[controlSubset$targetEffectSize != 1]))
      if (validPcs >= 10) {
        model <- EmpiricalCalibration::fitSystematicErrorModel(controlSubset$logRr, controlSubset$seLogRr, log(controlSubset$targetEffectSize), estimateCovarianceMatrix = FALSE)
        class(model) <- "vector"
        fileName <-  file.path(diagnosticsFolder, paste0("systematicErrorModel_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".csv"))
        write.csv(t(model), fileName, row.names = FALSE)
        
        fileName <-  file.path(diagnosticsFolder, paste0("ciCoverage_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".png"))
        evaluation <- EmpiricalCalibration::evaluateCiCalibration(logRr = controlSubset$logRr, 
                                                                  seLogRr = controlSubset$seLogRr, 
                                                                  trueLogRr = log(controlSubset$targetEffectSize),
                                                                  crossValidationGroup = controlSubset$oldOutcomeId)
        EmpiricalCalibration::plotCiCoverage(evaluation = evaluation,
                                             fileName = fileName)
      } 
      
      
      for (outcomeId in outcomeIds) {
        # Compute MDRR
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        if (strataFile == "") {
          strataFile <- reference$studyPopFile[reference$analysisId == analysisId &
                                                 reference$targetId == targetId &
                                                 reference$comparatorId == comparatorId &
                                                 reference$outcomeId == outcomeId]
        }
        population <- readRDS(strataFile)
        mdrr <- CohortMethod::computeMdrr(population, alpha = 0.05, power = 0.8, twoSided = TRUE, modelType = modelType)
        mdrr$analysisId <- analysisId
        mdrr$targetId <- targetId
        mdrr$comparatorId <- comparatorId
        mdrr$outcomeId <- outcomeId
        mdrrs <- rbind(mdrrs, mdrr)
        fileName <-  file.path(diagnosticsFolder, paste0("attritionDiagram_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId, ".png"))
        CohortMethod::drawAttritionDiagram(population, treatmentLabel = targetLabel, comparatorLabel = comparatorLabel, fileName = fileName)
        
        fileName <-  file.path(diagnosticsFolder, paste0("attritionTable_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId, ".csv"))
        attritionTable <- CohortMethod::getAttritionTable(population)
        write.csv(attritionTable, fileName, row.names = FALSE)
        
        if (!is.null(null)) {
          fileName <-  file.path(diagnosticsFolder, paste0("type1Error_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId,"_", label, ".png"))
          EmpiricalCalibration::plotExpectedType1Error(seLogRrPositives = mdrr$se,
                                                       null = null,
                                                       showCis = TRUE,
                                                       title = label,
                                                       fileName = fileName)
        }
      }
      exampleRef <- reference[reference$analysisId == analysisId &
                                reference$targetId == targetId &
                                reference$comparatorId == comparatorId &
                                reference$outcomeId == outcomeIds[1], ]
      ps <- readRDS(exampleRef$sharedPsFile)
      if (nrow(ps) != 0) {
        if (exampleRef$sharedPsFile == "") {
          psAfterMatching <- readRDS(exampleRef$studyPopFile)
        } else {
          psAfterMatching <- readRDS(exampleRef$strataFile)
          
          fileName <-  file.path(diagnosticsFolder, paste0("psBeforeStratification_a",analysisId,"_t",targetId,"_c",comparatorId,".png"))
          psPlot <- CohortMethod::plotPs(data = ps,
                                         treatmentLabel = targetLabel,
                                         comparatorLabel = comparatorLabel,
                                         fileName = fileName)
          
          
          fileName <-  file.path(diagnosticsFolder, paste0("psAfterStratification_a",analysisId,"_t",targetId,"_c",comparatorId,".png"))
          psPlot <- CohortMethod::plotPs(data = psAfterMatching,
                                         unfilteredData = ps,
                                         treatmentLabel = targetLabel,
                                         comparatorLabel = comparatorLabel,
                                         fileName = fileName)
          
          prepapredPsPlot <- EvidenceSynthesis::preparePsPlot(data = psAfterMatching,
                                                              unfilteredData = ps)
          fileName <-  file.path(diagnosticsFolder, paste0("preparedPsPlot_a",analysisId,"_t",targetId,"_c",comparatorId,".csv"))
          write.csv(prepapredPsPlot, fileName, row.names = FALSE)
          
          cmData <- CohortMethod::loadCohortMethodData(exampleRef$cohortMethodDataFolder)
          
          balance <- CohortMethod::computeCovariateBalance(psAfterMatching, cmData)
          fileName = file.path(diagnosticsFolder, paste("balance_a",analysisId,"_t",targetId,"_c",comparatorId,".csv",sep=""))
          write.csv(balance, fileName, row.names = FALSE)
          
          fileName = file.path(diagnosticsFolder, paste("balanceScatter_a",analysisId,"_t",targetId,"_c",comparatorId,".png",sep=""))
          balanceScatterPlot <- CohortMethod::plotCovariateBalanceScatterPlot(balance = balance,
                                                                              beforeLabel = paste("Before", psStrategy),
                                                                              afterLabel =  paste("After", psStrategy),
                                                                              fileName = fileName)
          
          fileName = file.path(diagnosticsFolder, paste("balanceTop_a",analysisId,"_t",targetId,"_c",comparatorId,".png",sep=""))
          balanceTopPlot <- CohortMethod::plotCovariateBalanceOfTopVariables(balance = balance,
                                                                             beforeLabel = paste("Before", psStrategy),
                                                                             afterLabel =  paste("After", psStrategy),
                                                                             fileName = fileName)
        }
        fileName = file.path(diagnosticsFolder, paste("table1_a",analysisId,"_t",targetId,"_c",comparatorId,".csv",sep=""))
        table1 <- CohortMethod::createCmTable1(balance = balance,  
                                               beforeTargetPopSize = sum(cmData$cohorts$treatment == 1),
                                               afterTargetPopSize = sum(psAfterMatching$treatment == 1),
                                               beforeComparatorPopSize = sum(cmData$cohorts$treatment == 0),
                                               afterComparatorPopSize = sum(psAfterMatching$treatment == 0),
                                               targetLabel = targetLabel,
                                               comparatorLabel = comparatorLabel,
                                               beforeLabel = paste("Before", psStrategy), 
                                               afterLabel =  paste("After", psStrategy))
        write.csv(table1, fileName, row.names = FALSE)
        
        fileName = file.path(diagnosticsFolder, paste("followupDist_a",analysisId,"_t",targetId,"_c",comparatorId, ".png",sep=""))
        CohortMethod::plotFollowUpDistribution(psAfterMatching, 
                                               targetLabel = targetLabel,
                                               comparatorLabel = comparatorLabel,
                                               fileName = fileName)
      }
    }
  }
  mdrrs <- addCohortNames(mdrrs, "targetId", "targetName")
  mdrrs <- addCohortNames(mdrrs, "comparatorId", "comparatorName")
  mdrrs <- addCohortNames(mdrrs, "outcomeId", "outcomeName")
  fileName <-  file.path(diagnosticsFolder, "mdrrs.csv")
  write.csv(mdrrs, fileName, row.names = FALSE)
  
}
