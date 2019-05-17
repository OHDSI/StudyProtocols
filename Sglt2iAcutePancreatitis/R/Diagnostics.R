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

abbreviateLabel <- function(label) {
  # label <- "new users of any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA with established cardiovascular disease and at least 1 prior non-metformin AHA exposure in 365 days prior to first exposure of any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA "
  label <- gsub("new users of ", "", label)
  label <- gsub(" with established cardiovascular disease", " with CV", label)
  label <- gsub(" at least 1 prior non-metformin AHA exposure in 365 days prior to.*", " prior AHA", label)
  label <- gsub(" no prior non-metformin AHA exposure in 365 days prior to.*", " no prior AHA", label)
  label <- gsub("any DPP-4 inhibitor, GLP-1 agonist, or other select AHA", "traditional AHAs", label)
  label <- gsub("any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA", "traditional AHAs + insulin", label)
  label <- gsub(" exposure to", "", label)
  return(label)
}

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
  packageName <- "AHAsAcutePancreatitis"
  modelType <- "cox" # For MDRR computation
  psStrategy <- "matching" # For covariate balance labels
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  
  diagnosticsFolder <- file.path(outputFolder, "diagnostics")
  if (!file.exists(diagnosticsFolder))
    dir.create(diagnosticsFolder)
  
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = packageName)
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
  analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
  analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmAnalysisList.json", package = packageName))
  analyses <- data.frame(analysisId = unique(reference$analysisId),
                         analysisDescription = "",
                         stringsAsFactors = FALSE)
  for (i in 1:length(cmAnalysisList)) {
    analyses$analysisDescription[analyses$analysisId == cmAnalysisList[[i]]$analysisId] <- cmAnalysisList[[i]]$description
  }
  analysisSummary <- merge(analysisSummary, analyses)
  negativeControls <- read.csv(system.file("settings", "NegativeControls.csv", package = packageName))
  tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  mdrrs <- data.frame()
  models <- data.frame()
  for (i in 1:nrow(tcsOfInterest)) {
    targetId <- tcsOfInterest$targetId[i]
    comparatorId <- tcsOfInterest$comparatorId[i]
    idx <- which(tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId)[1]
    targetLabel <- tcosOfInterest$targetName[idx]
    comparatorLabel <- tcosOfInterest$comparatorName[idx]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[idx])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeNames <- as.character(tcosOfInterest$outcomeNames[idx])
    outcomeNames <- strsplit(outcomeNames, split = ";")[[1]]
    for (analysisId in unique(reference$analysisId)) {
      analysisDescription <- analyses$analysisDescription[analyses$analysisId == analysisId]
      negControlSubset <- analysisSummary[analysisSummary$targetId == targetId &
                                            analysisSummary$comparatorId == comparatorId &
                                            analysisSummary$outcomeId %in% negativeControls$outcomeId &
                                            analysisSummary$analysisId == analysisId, ]
      
      # Outcome controls
      label <- "OutcomeControls"
      
      validNcs <- sum(!is.na(negControlSubset$seLogRr))
      if (validNcs >= 5) {
        null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
        
        fileName <-  file.path(diagnosticsFolder, paste0("nullDistribution_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".png"))
        plot <- EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = negControlSubset$logRr,
                                                    seLogRrNegatives = negControlSubset$seLogRr,
                                                    null = null,
                                                    showCis = TRUE)
        title <- paste(abbreviateLabel(targetLabel), abbreviateLabel(comparatorLabel), sep = " vs.\n")
        plot <- plot + ggplot2::ggtitle(title)
        plot <- plot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 10, hjust = 0.5))
        ggplot2::ggsave(fileName, plot, width = 6, height = 5, dpi = 400)
      } else {
        null <- NULL
      }
      # fileName <-  file.path(diagnosticsFolder, paste0("trueAndObs_a", analysisId, "_t", targetId, "_c", comparatorId, "_", label, ".png"))
      # EmpiricalCalibration::plotTrueAndObserved(logRr = controlSubset$logRr, 
      #                                           seLogRr = controlSubset$seLogRr, 
      #                                           trueLogRr = log(controlSubset$targetEffectSize),
      #                                           fileName = fileName)

      for (outcomeId in outcomeIds) {
        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        # Compute MDRR
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        population <- readRDS(strataFile)
        mdrr <- CohortMethod::computeMdrr(population, alpha = 0.05, power = 0.8, twoSided = TRUE, modelType = modelType)
        mdrr$targetId <- targetId
        mdrr$targetName <- targetLabel
        mdrr$comparatorId <- comparatorLabel
        mdrr$comparatorName <- comparatorLabel
        mdrr$outcomeId <- outcomeId
        mdrr$outcomeName <- outcomeName
        mdrr$analysisId <- mdrr$analysisId
        mdrr$analysisDescription <- analysisDescription
        mdrrs <- rbind(mdrrs, mdrr)
        # fileName <-  file.path(diagnosticsFolder, paste0("attrition_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId, ".png"))
        # CohortMethod::drawAttritionDiagram(population, treatmentLabel = targetLabel, comparatorLabel = comparatorLabel, fileName = fileName)
        if (!is.null(null)) {
          fileName <-  file.path(diagnosticsFolder, paste0("type1Error_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId,"_", label, ".png"))
          title <- paste0(abbreviateLabel(targetLabel), " vs.\n", abbreviateLabel(comparatorLabel), " for\n", outcomeName)
          plot <- EmpiricalCalibration::plotExpectedType1Error(seLogRrPositives = mdrr$se,
                                                       null = null,
                                                       showCis = TRUE,
                                                       title = title,
                                                       fileName = fileName)
        }
      }
      exampleRef <- reference[reference$analysisId == analysisId &
                                reference$targetId == targetId &
                                reference$comparatorId == comparatorId &
                                reference$outcomeId == outcomeIds[1], ]
      
      ps <- readRDS(exampleRef$sharedPsFile)
      psAfterMatching <- readRDS(exampleRef$strataFile)

      cmData <- CohortMethod::loadCohortMethodData(exampleRef$cohortMethodDataFolder)
      
      fileName <-  file.path(diagnosticsFolder, paste0("psBefore",psStrategy,"_a",analysisId,"_t",targetId,"_c",comparatorId,".png"))
      psPlot <- CohortMethod::plotPs(data = ps,
                                     treatmentLabel = abbreviateLabel(targetLabel),
                                     comparatorLabel = abbreviateLabel(comparatorLabel))
      psPlot <- psPlot + ggplot2::theme(legend.title = ggplot2::element_blank(), legend.position = "top", legend.direction = "vertical")
      ggplot2::ggsave(fileName, psPlot, width = 3.5, height = 4, dpi = 400)
      
      fileName = file.path(diagnosticsFolder, paste("followupDist_a",analysisId,"_t",targetId,"_c",comparatorId, ".png",sep=""))
      
      
      
      plot <- CohortMethod::plotFollowUpDistribution(psAfterMatching,
                                                     targetLabel = abbreviateLabel(targetLabel),
                                                     comparatorLabel = abbreviateLabel(comparatorLabel),
                                                     title = NULL)
      plot <- plot + ggplot2::theme(legend.title = ggplot2::element_blank(), legend.position = "top", legend.direction = "vertical")
      ggplot2::ggsave(fileName, plot, width = 4, height = 3.5, dpi = 400)
      
      model <- CohortMethod::getPsModel(ps, cmData)
      model$targetId <- targetId
      model$targetName <- targetLabel
      model$comparatorId <- comparatorLabel
      model$comparatorName <- comparatorLabel
      model$analysisId <- mdrr$analysisId
      model$analysisDescription <- analysisDescription
      models <- rbind(models, model)
      
      fileName = file.path(diagnosticsFolder, paste("time_a",analysisId,"_t",targetId,"_c",comparatorId, ".png",sep=""))
      cohorts <- cmData$cohorts
      cohorts$group <- abbreviateLabel(targetLabel)
      cohorts$group[cohorts$treatment == 0] <- abbreviateLabel(comparatorLabel)
      plot <- ggplot2::ggplot(cohorts, ggplot2::aes(x = cohortStartDate, color = group, fill = group, group = group)) +
        ggplot2::geom_density(alpha = 0.5) +
        ggplot2::xlab("Cohort start date") +
        ggplot2::ylab("Density") +
        ggplot2::theme(legend.title = ggplot2::element_blank(), 
                       legend.position = "top", 
                       legend.direction = "vertical")
      ggplot2::ggsave(filename = fileName, plot = plot, width = 5, height = 3.5, dpi = 400)
            
      balance <- CohortMethod::computeCovariateBalance(psAfterMatching, cmData)

      fileName = file.path(diagnosticsFolder, paste("balanceScatter_a",analysisId,"_t",targetId,"_c",comparatorId,".png",sep=""))
      balanceScatterPlot <- CohortMethod::plotCovariateBalanceScatterPlot(balance = balance,
                                                                          beforeLabel = paste("Before", psStrategy),
                                                                          afterLabel =  paste("After", psStrategy))
      title <- paste(abbreviateLabel(targetLabel), abbreviateLabel(comparatorLabel), sep = " vs.\n")
      balanceScatterPlot <- balanceScatterPlot + ggplot2::ggtitle(title)
      balanceScatterPlot <- balanceScatterPlot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 8, hjust = 0.5))
      ggplot2::ggsave(fileName, balanceScatterPlot, width = 4, height = 4.5, dpi = 400)

      fileName = file.path(diagnosticsFolder, paste("balanceTop_a",analysisId,"_t",targetId,"_c",comparatorId,".png",sep=""))
      balanceTopPlot <- CohortMethod::plotCovariateBalanceOfTopVariables(balance = balance,
                                                                         beforeLabel = paste("Before", psStrategy),
                                                                         afterLabel =  paste("After", psStrategy))
      title <- paste(abbreviateLabel(targetLabel), abbreviateLabel(comparatorLabel), sep = " vs.\n")
      balanceTopPlot <- balanceTopPlot + ggplot2::ggtitle(title)
      balanceTopPlot <- balanceTopPlot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 9, hjust = 0.5))
      ggplot2::ggsave(fileName, balanceTopPlot, width = 10, height = 6.5, dpi = 400)
    }
  }
  fileName <-  file.path(diagnosticsFolder, paste0("mdrr.csv"))
  write.csv(mdrrs, fileName, row.names = FALSE)
  fileName <-  file.path(diagnosticsFolder, paste0("propensityModels.csv"))
  write.csv(models, fileName, row.names = FALSE)
}
