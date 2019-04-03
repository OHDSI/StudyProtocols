#' @export
generateDiagnostics <- function(outputFolder,
                                databaseName) {

  packageName <- "sglt2iDka"
  modelType <- "cox" # For MDRR computation
  psStrategy <- "matching" # For covariate balance labels

  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  diagnosticsFolder <- file.path(outputFolder, "diagnostics")
  if (!file.exists(diagnosticsFolder))
    dir.create(diagnosticsFolder)

  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  tcosOfInterest <- unique(tcosAnalyses[, c("targetCohortId", "targetDrugName", "targetCohortName", "comparatorCohortId", "comparatorDrugName", "comparatorCohortName",
                                            "outcomeCohortId", "outcomeCohortName")])
  names(tcosOfInterest) <- c("targetId", "targetDrugName", "targetName", "comparatorId", "comparatorDrugName", "comparatorName",
                             "outcomeId", "outcomeName")

  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  analysisSummary <- addCohortNames(analysisSummary, dose = FALSE, "targetId", "targetName")
  analysisSummary <- addCohortNames(analysisSummary, dose = FALSE, "comparatorId", "comparatorName")
  analysisSummary <- addCohortNames(analysisSummary, dose = FALSE, "outcomeId", "outcomeName")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmAnalysisList.json", package = packageName))
  analyses <- data.frame(analysisId = unique(reference$analysisId),
                         analysisDescription = "",
                         stringsAsFactors = FALSE)
  for (i in 1:length(cmAnalysisList)) {
    analyses$analysisDescription[analyses$analysisId == cmAnalysisList[[i]]$analysisId] <- cmAnalysisList[[i]]$description
  }
  analysisSummary <- merge(analysisSummary, analyses)

  negativeControlOutcomeCohorts <- read.csv(system.file("settings", "negativeControlOutcomeCohorts.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  negativeControlOutcomeCohortIds <- negativeControlOutcomeCohorts$COHORT_DEFINITION_ID
  outcomeIds <- unique(tcosOfInterest$outcomeId)
  outcomeNames <- unique(tcosOfInterest$outcomeName)

  mdrrs <- data.frame()
  mdrrsFileName <- file.path(diagnosticsFolder, "mdrr.csv")
  hetergeneityOfEffect <- data.frame()
  hetergeneityOfEffectFileName <- file.path(diagnosticsFolder, "effectHeterogeneity.csv")
  models <- data.frame()
  modelsFileName <- file.path(diagnosticsFolder, "propensityModels.csv")

  tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  for (i in 1:nrow(tcsOfInterest)) {
    # i=1

    targetId <- tcsOfInterest$targetId[i]
    comparatorId <- tcsOfInterest$comparatorId[i]
    idx <- which(tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId)[1]
    targetLabel <- tcosOfInterest$targetName[idx]
    comparatorLabel <- tcosOfInterest$comparatorName[idx]

    for (analysisId in unique(reference$analysisId)) {
      # analysisId=1

      analysisDescription <- analyses$analysisDescription[analyses$analysisId == analysisId]
      negControlSubset <- analysisSummary[analysisSummary$targetId == targetId &
                                            analysisSummary$comparatorId == comparatorId &
                                            analysisSummary$outcomeId %in% negativeControlOutcomeCohortIds &
                                            analysisSummary$analysisId == analysisId, ]
      label <- "OutcomeControls"
      validNcs <- sum(!is.na(negControlSubset$seLogRr))

      # calibration plots
      if (validNcs < 5) {
        null <- NULL
      } else {
        fileName <-  file.path(diagnosticsFolder, paste0("nullDistribution_a", analysisId,
                                                         "_t", targetId,
                                                         "_c", comparatorId,
                                                         "_", label,
                                                         ".png"))
        if (!file.exists(fileName)) {
          null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
          plot <- EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = negControlSubset$logRr,
                                                              seLogRrNegatives = negControlSubset$seLogRr,
                                                              null = null,
                                                              showCis = TRUE)
          title <- paste(targetLabel, comparatorLabel, sep = " vs.\n")
          plot <- plot + ggplot2::ggtitle(title)
          plot <- plot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 10, hjust = 0.5))
          ggplot2::ggsave(fileName, plot, width = 6, height = 5, dpi = 400)
        }
      }

      refDataQuintilEffects <- data.frame()
      for (outcomeId in outcomeIds) {
        # outcomeId=200

        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        population <- readRDS(strataFile)

        # compute MDRR
        if (!file.exists(mdrrsFileName)) {
          mdrr <- CohortMethod::computeMdrr(population, alpha = 0.05, power = 0.8, twoSided = TRUE, modelType = modelType)
          mdrr$targetId <- targetId
          mdrr$targetName <- targetLabel
          mdrr$comparatorId <- comparatorId
          mdrr$comparatorName <- comparatorLabel
          mdrr$outcomeId <- outcomeId
          mdrr$outcomeName <- outcomeName
          mdrr$analysisId <- mdrr$analysisId
          mdrr$analysisDescription <- analysisDescription
          mdrrs <- rbind(mdrrs, mdrr)
        }

        # heterogeneity of effect across PS quintiles
        if (!file.exists(hetergeneityOfEffectFileName)) {
          refData <- data.frame(analysisId = 0,
                                analysisDescription = "",
                                outcomeId = 0,
                                outcomeName = "",
                                targetId = 0,
                                targetName = "",
                                comparatorId = 0,
                                comparatorName = "",
                                database = "")
          refData$analysisId <- analysisId
          refData$analysisDescription <- analysisDescription
          refData$outcomeId <- outcomeId
          refData$outcomeName <- outcomeName
          refData$targetId <- targetId
          refData$targetName <- targetLabel
          refData$comparatorId <- comparatorId
          refData$comparatorName <- comparatorLabel
          refData$database <- databaseName

          stratifiedPopulation <- CohortMethod::stratifyByPs(population = population, numberOfStrata = 5, baseSelection = "all")
          quintileEffects <- data.frame()
          for (quintile in 1:5) {
            outcomeModel <- CohortMethod::fitOutcomeModel(population = stratifiedPopulation[stratifiedPopulation$stratumId == quintile, ],
                                                          modelType = "cox",
                                                          stratified = FALSE,
                                                          useCovariates = FALSE,
                                                          control = Cyclops::createControl(noiseLevel = "quiet"))
            quintileEffect <- sglt2iDka::summarizeOneAnalysis(outcomeModel)
            quintileEffect$quintile <- quintile
            quintileEffects <- rbind(quintileEffects, quintileEffect)
          }
          refDataQuintilEffects <- merge(refData, quintileEffects)
          hetergeneityOfEffect <- rbind(hetergeneityOfEffect, refDataQuintilEffects)
        }

        # KM plots
        fileName <-  file.path(diagnosticsFolder, paste0("km_a", analysisId,
                                                         "_t", targetId,
                                                         "_c", comparatorId,
                                                         "_o", outcomeId,
                                                         ".png"))
        if (!file.exists(fileName)) {
          plot <- sglt2iDka::plotKaplanMeier(population = population,
                                          targetLabel = targetLabel,
                                          comparatorLabel = comparatorLabel,
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

      # preference score plots
      fileName <- file.path(diagnosticsFolder, paste0("psBefore", psStrategy,
                                                       "_a",analysisId,
                                                       "_t",targetId,
                                                       "_c",comparatorId,
                                                       ".png"))
      if (!file.exists(fileName)) {
        plot <- CohortMethod::plotPs(data = ps,
                                     treatmentLabel = targetLabel,
                                     comparatorLabel = comparatorLabel)
        plot <- plot + ggplot2::theme(legend.title = ggplot2::element_blank(), legend.position = "top", legend.direction = "vertical")
        ggplot2::ggsave(fileName, plot, width = 3.5, height = 4, dpi = 400)
      }

      # follow-up distribution plots
      fileName <- file.path(diagnosticsFolder, paste0("followupDist_a", analysisId,
                                                     "_t", targetId,
                                                     "_c", comparatorId,
                                                     ".png"))
      if (!file.exists(fileName)) {
        plot <- CohortMethod::plotFollowUpDistribution(psAfterMatching,
                                                       targetLabel = targetLabel,
                                                       comparatorLabel = comparatorLabel,
                                                       title = NULL)
        plot <- plot + ggplot2::theme(legend.title = ggplot2::element_blank(), legend.position = "top", legend.direction = "vertical")
        ggplot2::ggsave(fileName, plot, width = 4, height = 3.5, dpi = 400)
      }

      # propensity score models
      if (!file.exists(modelsFileName)) {
        model <- CohortMethod::getPsModel(ps, cmData)
        model$targetId <- targetId
        model$targetName <- targetLabel
        model$comparatorId <- comparatorId
        model$comparatorName <- comparatorLabel
        model$analysisId <- mdrr$analysisId
        model$analysisDescription <- analysisDescription
        models <- rbind(models, model)
      }

      # index date visualization
      fileName <- file.path(diagnosticsFolder, paste0("index_date_a", analysisId,
                                                      "_t", targetId,
                                                      "_c", comparatorId,
                                                      ".png"))
      if (!file.exists(fileName)) {
        cohorts <- cmData$cohorts
        cohorts$group <- targetLabel
        cohorts$group[cohorts$treatment == 0] <- comparatorLabel
        plot <- ggplot2::ggplot(cohorts, ggplot2::aes(x = cohortStartDate, color = group, fill = group, group = group)) +
          ggplot2::geom_density(alpha = 0.5) +
          ggplot2::xlab("Cohort start date") +
          ggplot2::ylab("Density") +
          ggplot2::theme(legend.title = ggplot2::element_blank(),
                         legend.position = "top",
                         legend.direction = "vertical")
        ggplot2::ggsave(filename = fileName, plot = plot, width = 5, height = 3.5, dpi = 400)
      }

      # covariate balance scatter plot
      fileName <- file.path(diagnosticsFolder, paste0("balanceScatter_a", analysisId,
                                                        "_t", targetId,
                                                        "_c", comparatorId,
                                                        ".png"))
      if (!file.exists(fileName)) {
        balance <- CohortMethod::computeCovariateBalance(psAfterMatching, cmData)
        balanceScatterPlot <- CohortMethod::plotCovariateBalanceScatterPlot(balance = balance,
                                                                            beforeLabel = paste("Before", psStrategy),
                                                                            afterLabel =  paste("After", psStrategy))
        title <- paste(targetLabel, comparatorLabel, sep = " vs.\n")
        balanceScatterPlot <- balanceScatterPlot + ggplot2::ggtitle(title)
        balanceScatterPlot <- balanceScatterPlot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 8, hjust = 0.5))
        ggplot2::ggsave(fileName, balanceScatterPlot, width = 4, height = 4.5, dpi = 400)
      }

      # top covariate balance plot
      fileName <- file.path(diagnosticsFolder, paste0("balanceTop_a", analysisId,
                                                      "_t", targetId,
                                                      "_c", comparatorId,
                                                      ".png"))
      if (!file.exists(fileName)) {
        balanceTopPlot <- CohortMethod::plotCovariateBalanceOfTopVariables(balance = balance,
                                                                           beforeLabel = paste("Before", psStrategy),
                                                                           afterLabel =  paste("After", psStrategy))
        title <- paste(targetLabel, comparatorLabel, sep = " vs.\n")
        balanceTopPlot <- balanceTopPlot + ggplot2::ggtitle(title)
        balanceTopPlot <- balanceTopPlot + ggplot2::theme(plot.title = ggplot2::element_text(colour = "#000000", size = 9, hjust = 0.5))
        ggplot2::ggsave(fileName, balanceTopPlot, width = 10, height = 6.5, dpi = 400)
      }
    }
  }
  if (!file.exists(mdrrsFileName))
    write.csv(mdrrs, mdrrsFileName, row.names = FALSE)

  if (!file.exists(hetergeneityOfEffectFileName))
    write.csv(hetergeneityOfEffect, hetergeneityOfEffectFileName, row.names = FALSE)

  if (!file.exists(modelsFileName))
    write.csv(models, modelsFileName, row.names = FALSE)
}
