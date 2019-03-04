#' @export
prepareResultsForAnalysis <- function(outputFolder,
                                      databaseName,
                                      maxCores) {
  packageName <- "sglt2iDka"
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

  # TCOs of interest
  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = packageName), stringsAsFactors = FALSE)
  tcosOfInterest <- unique(tcosAnalyses[, c("targetCohortId", "targetDrugName", "targetCohortName", "comparatorCohortId", "comparatorDrugName", "comparatorCohortName",
                                            "outcomeCohortId", "outcomeCohortName")])
  names(tcosOfInterest) <- c("targetId", "targetDrugName", "targetName", "comparatorId", "comparatorDrugName", "comparatorName",
                             "outcomeId", "outcomeName")
  negativeControls <- read.csv(system.file("settings", "negativeControlOutcomeCohorts.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  names(negativeControls) <- c("outcomeId", "outcomeName")
  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = FALSE, "outcomeId", "outcomeName")
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = FALSE, "comparatorId", "comparatorName")
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = FALSE, "targetId", "targetName")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmAnalysisList.json", package = packageName))
  analyses <- data.frame(analysisId = unique(reference$analysisId),
                         analysisDescription = "",
                         stringsAsFactors = FALSE)
  for (i in 1:length(cmAnalysisList)) {
    analyses$analysisDescription[analyses$analysisId == cmAnalysisList[[i]]$analysisId] <- cmAnalysisList[[i]]$description
  }
  analysisSummary <- merge(analysisSummary, analyses)
  analysisSummary <- analysisSummary[, c(1,20,2:19)]
  analysisSummary$type <- "Outcome of interest"
  analysisSummary$type[analysisSummary$outcomeId %in% negativeControls$outcomeId] <- "Negative control"
  analysisSummary$database <- databaseName

  #for dev
  # comparison <- paste(analysisSummary$targetId, analysisSummary$comparatorId)
  # chunks <- split(analysisSummary, comparison)
  # chunk <- chunks[[17]]
  #for dev

  runTc <- function(chunk,
                    tcosOfInterest,
                    negativeControls,
                    shinyDataFolder,
                    balanceDataFolder,
                    outputFolder,
                    databaseName,
                    reference) {
    ffbase::load.ffdf(file.path(outputFolder, "multiTherapyData"))
    tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
    targetId <- chunk$targetId[1]
    comparatorId <- chunk$comparatorId[1]
    outcomeIds <- unique(tcosOfInterest$outcomeId)
    outcomeNames <- unique(tcosOfInterest$outcomeName)
    OhdsiRTools::logTrace("Preparing results for target ID ", targetId, ", comparator ID", comparatorId)

    for (analysisId in unique(reference$analysisId)) {
    # analysisId=1

      OhdsiRTools::logTrace("Analysis ID ", analysisId)
      negControlSubset <- chunk[chunk$targetId == targetId &
                                  chunk$comparatorId == comparatorId &
                                  chunk$outcomeId %in% negativeControls$outcomeId &
                                  chunk$analysisId == analysisId, ]

      validNcs <- sum(!is.na(negControlSubset$seLogRr))

      if (validNcs >= 5) {
        fileName <-  file.path(shinyDataFolder, paste0("null_a", analysisId,
                                                       "_t", targetId,
                                                       "_c", comparatorId,
                                                       "_", databaseName,
                                                       ".rds"))
        if (file.exists(fileName)) {
          null <- readRDS(fileName)
        } else {
          null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
          saveRDS(null, fileName)
        }

        idx <- chunk$targetId == targetId & chunk$comparatorId == comparatorId & chunk$analysisId == analysisId
        calibratedP <- EmpiricalCalibration::calibrateP(null = null,
                                                        logRr = chunk$logRr[idx],
                                                        seLogRr = chunk$seLogRr[idx])
        chunk$calP[idx] <- calibratedP$p
        chunk$calP_lb95ci[idx] <- calibratedP$lb95ci
        chunk$calP_ub95ci[idx] <- calibratedP$ub95ci
        mcmc <- attr(null, "mcmc")
        chunk$null_mean <- mean(mcmc$chain[,1])
        chunk$null_sd <- 1/sqrt(mean(mcmc$chain[,2]))
      }

      for (outcomeId in outcomeIds) {
      # outcomeId=200

        OhdsiRTools::logTrace("Outcome ID ", outcomeId)
        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        idx <- chunk$analysisId == analysisId &
          chunk$targetId == targetId &
          chunk$comparatorId == comparatorId &
          chunk$outcomeId == outcomeId

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
        distTarget <- quantile(population$timeAtRisk[population$treatment == 1], c(0, 0.5, 1))
        distComparator <- quantile(population$timeAtRisk[population$treatment == 0], c(0, 0.5, 1))
        chunk$tarTargetMean[idx] <- mean(population$timeAtRisk[population$treatment == 1])
        chunk$tarTargetSd[idx] <- sd(population$timeAtRisk[population$treatment == 1])
        chunk$tarTargetMin[idx] <- distTarget[1]
        chunk$tarTargetMedian[idx] <- distTarget[2]
        chunk$tarTargetMax[idx] <- distTarget[3]
        chunk$tarComparatorMean[idx] <- mean(population$timeAtRisk[population$treatment == 0])
        chunk$tarComparatorSd[idx] <- sd(population$timeAtRisk[population$treatment == 0])
        chunk$tarComparatorMin[idx] <- distComparator[1]
        chunk$tarComparatorMedian[idx] <- distComparator[2]
        chunk$tarComparatorMax[idx] <- distComparator[3]

        # Compute covariate balance
        refRow <- reference[reference$analysisId == analysisId &
                              reference$targetId == targetId &
                              reference$comparatorId == comparatorId &
                              reference$outcomeId == outcomeId, ]
        psAfterMatching <- readRDS(refRow$strataFile)
        cmData <- CohortMethod::loadCohortMethodData(refRow$cohortMethodDataFolder)
        fileName <-  file.path(balanceDataFolder, paste0("bal_a", analysisId,
                                                         "_t", targetId,
                                                         "_c", comparatorId,
                                                         "_o", outcomeId,
                                                         "_", databaseName,
                                                         ".rds"))
        if (!file.exists(fileName)) {
          balance <- CohortMethod::computeCovariateBalance(psAfterMatching, cmData)
          saveRDS(balance, fileName)
        }

        # Compute balance for multitherapy at index covariates
        fileName <-  file.path(shinyDataFolder, paste0("multiTherBal_a", analysisId,
                                                       "_t", targetId,
                                                       "_c", comparatorId,
                                                       "_o", outcomeId,
                                                       "_", databaseName,".rds"))
        if (!file.exists(fileName)) {
          dummyCmData <- cmData
          # idxff <- !is.na(ffbase::ffmatch(covariates$cohortDefinitionId, ff::as.ff(c(11,21))))
          # covarSubset <- covariates[ffbase::ffwhich(idxff, idxff == TRUE), ]
          cmData$cohorts$cohortDefinitionId <- ifelse(cmData$cohorts$treatment == 1, targetId, comparatorId)
          dummyCmData$covariates <- merge(covariates,
                                          ff::as.ffdf(cmData$cohorts[, c("rowId", "subjectId", "cohortDefinitionId", "cohortStartDate")]))
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
        fileName <-  file.path(shinyDataFolder, paste0("km_a", analysisId,
                                                       "_t", targetId,
                                                       "_c", comparatorId,
                                                       "_o", outcomeId,
                                                       "_", databaseName,
                                                       ".rds"))
        # if (!file.exists(fileName)) {
          plot <- sglt2iDka::plotKaplanMeier(psAfterMatching,
                                             targetLabel = sub("-90", "", chunk$targetName[chunk$targetId == targetId][1]),
                                             comparatorLabel = sub("-90", "", chunk$comparatorName[chunk$comparatorId == comparatorId][1]))
          saveRDS(plot, fileName)
        # }

        # Add cohort sizes before matching/stratification
        chunk$treatedBefore[idx] <- sum(cmData$cohorts$treatment == 1)
        chunk$comparatorBefore[idx] <- sum(cmData$cohorts$treatment == 0)

        # before matching IR data
        # covarRef <- as.data.frame(cmData$covariateRef)
        # covarRef <- covarRef[order(covarRef$covariateId), ]
        # covarRef[covarRef$analysisId==3, 1:2]
        covariatesForStrat <- as.data.frame(cmData$covariates)
        covariatesForStrat <- covariatesForStrat[covariatesForStrat$covariateId %in% c(8507001, 1998, 2998, 200999, 201999, # intentionally drop 8532001 as redundant
                                                               2003, 3003, 4003, 5003, 6003, 7003, 8003, 9003, 10003, 11003, 12003, 13003, 14003, 15003, 16003, 17003, 18003, 19003, 20003, 21003), ]
        covariatesForStrat <- reshape(covariatesForStrat, idvar = "rowId", timevar = "covariateId", direction = "wide")
        names(covariatesForStrat)[names(covariatesForStrat) == "covariateValue.8507001"] <- "Male"
        names(covariatesForStrat)[names(covariatesForStrat) == "covariateValue.1998"] <- "PriorInsulin"
        names(covariatesForStrat)[names(covariatesForStrat) == "covariateValue.2998"] <- "PriorAha"
        names(covariatesForStrat)[names(covariatesForStrat) == "covariateValue.200999"] <- "PriorDkaIpEr"
        names(covariatesForStrat)[names(covariatesForStrat) == "covariateValue.201999"] <- "PriorDkaIp"
        if (is.null(covariatesForStrat$covariateValue.2003)) covariatesForStrat$Age10_14 <- 0 else covariatesForStrat$Age10_14[covariatesForStrat$covariateValue.2003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.3003)) covariatesForStrat$Age15_19 <- 0 else covariatesForStrat$Age15_19[covariatesForStrat$covariateValue.3003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.4003)) covariatesForStrat$Age20_24 <- 0 else covariatesForStrat$Age20_24[covariatesForStrat$covariateValue.4003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.5003)) covariatesForStrat$Age25_29 <- 0 else covariatesForStrat$Age25_29[covariatesForStrat$covariateValue.5003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.6003)) covariatesForStrat$Age30_34 <- 0 else covariatesForStrat$Age30_34[covariatesForStrat$covariateValue.6003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.7003)) covariatesForStrat$Age35_39 <- 0 else covariatesForStrat$Age35_39[covariatesForStrat$covariateValue.7003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.8003)) covariatesForStrat$Age40_44 <- 0 else covariatesForStrat$Age40_44[covariatesForStrat$covariateValue.8003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.9003)) covariatesForStrat$Age45_49 <- 0 else covariatesForStrat$Age45_49[covariatesForStrat$covariateValue.9003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.10003)) covariatesForStrat$Age50_54 <- 0 else covariatesForStrat$Age50_54[covariatesForStrat$covariateValue.10003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.11003)) covariatesForStrat$Age55_59 <- 0 else covariatesForStrat$Age55_59[covariatesForStrat$covariateValue.11003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.12003)) covariatesForStrat$Age60_64 <- 0 else covariatesForStrat$Age60_64[covariatesForStrat$covariateValue.12003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.13003)) covariatesForStrat$Age65_69 <- 0 else covariatesForStrat$Age65_69[covariatesForStrat$covariateValue.13003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.14003)) covariatesForStrat$Age70_74 <- 0 else covariatesForStrat$Age70_74[covariatesForStrat$covariateValue.14003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.15003)) covariatesForStrat$Age75_79 <- 0 else covariatesForStrat$Age75_79[covariatesForStrat$covariateValue.15003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.16003)) covariatesForStrat$Age80_84 <- 0 else covariatesForStrat$Age80_84[covariatesForStrat$covariateValue.16003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.17003)) covariatesForStrat$Age85_89 <- 0 else covariatesForStrat$Age85_89[covariatesForStrat$covariateValue.17003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.18003)) covariatesForStrat$Age90_94 <- 0 else covariatesForStrat$Age90_94[covariatesForStrat$covariateValue.18003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.19003)) covariatesForStrat$Age95_99 <- 0 else covariatesForStrat$Age95_99[covariatesForStrat$covariateValue.19003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.20003)) covariatesForStrat$Age100_104 <- 0 else covariatesForStrat$Age100_104[covariatesForStrat$covariateValue.20003 == 1] <- 1
        if (is.null(covariatesForStrat$covariateValue.21003)) covariatesForStrat$Age105_109 <- 0 else covariatesForStrat$Age105_109[covariatesForStrat$covariateValue.21003 == 1] <- 1
        covariatesForStrat$Age10_19[covariatesForStrat$Age10_14 == 1 | covariatesForStrat$Age15_19 == 1] <- 1
        covariatesForStrat$Age20_29[covariatesForStrat$Age20_24 == 1 | covariatesForStrat$Age25_29 == 1] <- 1
        covariatesForStrat$Age30_39[covariatesForStrat$Age30_34 == 1 | covariatesForStrat$Age35_39 == 1] <- 1
        covariatesForStrat$Age40_49[covariatesForStrat$Age40_44 == 1 | covariatesForStrat$Age45_49 == 1] <- 1
        covariatesForStrat$Age50_59[covariatesForStrat$Age50_54 == 1 | covariatesForStrat$Age55_59 == 1] <- 1
        covariatesForStrat$Age60_69[covariatesForStrat$Age60_64 == 1 | covariatesForStrat$Age65_69 == 1] <- 1
        covariatesForStrat$Age70_79[covariatesForStrat$Age70_74 == 1 | covariatesForStrat$Age75_79 == 1] <- 1
        covariatesForStrat$Age80_89[covariatesForStrat$Age80_84 == 1 | covariatesForStrat$Age85_89 == 1] <- 1
        covariatesForStrat$Age90_99[covariatesForStrat$Age90_94 == 1 | covariatesForStrat$Age95_99 == 1] <- 1
        covariatesForStrat$Age100_109[covariatesForStrat$Age100_104 == 1 | covariatesForStrat$Age105_109 == 1] <- 1

        studyPop <- readRDS(refRow$studyPopFile)
        studyPop <- merge(studyPop, covariatesForStrat, by = "rowId", all.x = TRUE)
        studyPop[is.na(studyPop)] <- 0

        studyPop$outcomeCount[studyPop$outcomeCount != 0] <- 1
        studyPop$timeAtRisk <- studyPop$survivalTime

        # overall
        bmDistTarget <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1], c(0, 0.5, 1))
        chunk$bmTreated[idx] <- sum(studyPop$treatment == 1)
        chunk$bmTreatedDays[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1])
        chunk$bmEventsTreated[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1])
        chunk$bmTarTargetMean[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1])
        chunk$bmTarTargetSd[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1])
        chunk$bmTarTargetMin[idx] <- bmDistTarget[1]
        chunk$bmTarTargetMedian[idx] <- bmDistTarget[2]
        chunk$bmTarTargetMax[idx] <- bmDistTarget[3]

        bmDistComparator <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0], c(0, 0.5, 1))
        chunk$bmComparator[idx] <- sum(studyPop$treatment == 0)
        chunk$bmComparatorDays[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0])
        chunk$bmEventsComparator[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0])
        chunk$bmTarComparatorMean[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0])
        chunk$bmTarComparatorSd[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0])
        chunk$bmTarComparatorMin[idx] <- bmDistComparator[1]
        chunk$bmTarComparatorMedian[idx] <- bmDistComparator[2]
        chunk$bmTarComparatorMax[idx] <- bmDistComparator[3]

        # getBmIrStats <- function(chunk,
        #                          subgroupName,
        #                          subgroupValue,
        #                          subgroupLabel) {
        #   bmDistTargetSubgroup <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        #   chunk$bmTreatedSubgroup[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        #   chunk$bmTreatedDaysSubgroup[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmEventsTreatedSubgroup[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarTargetMeanSubgroup[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarTargetSdSubgroup[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarTargetMinSubgroup[idx] <- bmDistTargetSubgroup[1]
        #   chunk$bmTarTargetMedianSubgroup[idx] <- bmDistTargetSubgroup[2]
        #   chunk$bmTarTargetMaxSubgroup[idx] <- bmDistTargetSubgroup[3]
        #   bmDistComparatorSubgroup <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        #   chunk$bmComparatorSubgroup[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        #   chunk$bmComparatorDaysSubgroup[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmEventsComparatorSubgroup[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarComparatorMeanSubgroup[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarComparatorSdSubgroup[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        #   chunk$bmTarComparatorMinSubgroup[idx] <- bmDistComparatorSubgroup[1]
        #   chunk$bmTarComparatorMedianSubgroup[idx] <- bmDistComparatorSubgroup[2]
        #   chunk$bmTarComparatorMaxSubgroup[idx] <- bmDistComparatorSubgroup[3]
        #   colnames(chunk)[seq(length(chunk)-15, length(chunk))] <- sub(pattern = "Subgroup", replacement = subgroupLabel, x = colnames(chunk)[seq(length(chunk)-15, length(chunk))])
        #   return(chunk)
        # }
        #
        # chunk <- getBmIrStats("Male", 1, "Male")
        # chunk <- getBmIrStats("Male", 0, "Female")
        # chunk <- getBmIrStats("PriorInsulin", 1, "PriorInsulin")
        # chunk <- getBmIrStats("PriorInsulin", 0, "NoPriorInsulin")
        # chunk <- getBmIrStats("PriorDkaIpEr", 1, "PriorDkaIpEr")
        # chunk <- getBmIrStats("PriorDkaIpEr", 0, "NoPriorDkaIpEr")

        subgroupName = "Male"
        subgroupValue = 1
        bmDistTargetMale <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedMale[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysMale[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedMale[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanMale[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdMale[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinMale[idx] <- bmDistTargetMale[1]
        chunk$bmTarTargetMedianMale[idx] <- bmDistTargetMale[2]
        chunk$bmTarTargetMaxMale[idx] <- bmDistTargetMale[3]
        bmDistComparatorMale <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorMale[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysMale[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorMale[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanMale[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdMale[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinMale[idx] <- bmDistComparatorMale[1]
        chunk$bmTarComparatorMedianMale[idx] <- bmDistComparatorMale[2]
        chunk$bmTarComparatorMaxMale[idx] <- bmDistComparatorMale[3]

        subgroupName = "Male"
        subgroupValue = 0
        bmDistTargetFemale <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedFemale[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysFemale[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedFemale[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanFemale[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdFemale[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinFemale[idx] <- bmDistTargetFemale[1]
        chunk$bmTarTargetMedianFemale[idx] <- bmDistTargetFemale[2]
        chunk$bmTarTargetMaxFemale[idx] <- bmDistTargetFemale[3]
        bmDistComparatorFemale <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorFemale[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysFemale[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorFemale[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanFemale[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdFemale[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinFemale[idx] <- bmDistComparatorFemale[1]
        chunk$bmTarComparatorMedianFemale[idx] <- bmDistComparatorFemale[2]
        chunk$bmTarComparatorMaxFemale[idx] <- bmDistComparatorFemale[3]

        subgroupName = "PriorInsulin"
        subgroupValue = 1
        bmDistTargetPriorInsulin <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedPriorInsulin[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysPriorInsulin[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedPriorInsulin[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanPriorInsulin[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdPriorInsulin[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinPriorInsulin[idx] <- bmDistTargetPriorInsulin[1]
        chunk$bmTarTargetMedianPriorInsulin[idx] <- bmDistTargetPriorInsulin[2]
        chunk$bmTarTargetMaxPriorInsulin[idx] <- bmDistTargetPriorInsulin[3]
        bmDistComparatorPriorInsulin <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorPriorInsulin[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysPriorInsulin[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorPriorInsulin[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanPriorInsulin[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdPriorInsulin[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinPriorInsulin[idx] <- bmDistComparatorPriorInsulin[1]
        chunk$bmTarComparatorMedianPriorInsulin[idx] <- bmDistComparatorPriorInsulin[2]
        chunk$bmTarComparatorMaxPriorInsulin[idx] <- bmDistComparatorPriorInsulin[3]

        subgroupName = "PriorInsulin"
        subgroupValue = 0
        bmDistTargetNoPriorInsulin <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedNoPriorInsulin[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysNoPriorInsulin[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedNoPriorInsulin[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanNoPriorInsulin[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdNoPriorInsulin[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinNoPriorInsulin[idx] <- bmDistTargetNoPriorInsulin[1]
        chunk$bmTarTargetMedianNoPriorInsulin[idx] <- bmDistTargetNoPriorInsulin[2]
        chunk$bmTarTargetMaxNoPriorInsulin[idx] <- bmDistTargetNoPriorInsulin[3]
        bmDistComparatorNoPriorInsulin <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorNoPriorInsulin[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysNoPriorInsulin[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorNoPriorInsulin[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanNoPriorInsulin[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdNoPriorInsulin[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinNoPriorInsulin[idx] <- bmDistComparatorNoPriorInsulin[1]
        chunk$bmTarComparatorMedianNoPriorInsulin[idx] <- bmDistComparatorNoPriorInsulin[2]
        chunk$bmTarComparatorMaxNoPriorInsulin[idx] <- bmDistComparatorNoPriorInsulin[3]

        subgroupName = "PriorDkaIpEr"
        subgroupValue = 1
        bmDistTargetPriorDkaIpEr <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedPriorDkaIpEr[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysPriorDkaIpEr[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedPriorDkaIpEr[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanPriorDkaIpEr[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdPriorDkaIpEr[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinPriorDkaIpEr[idx] <- bmDistTargetPriorDkaIpEr[1]
        chunk$bmTarTargetMedianPriorDkaIpEr[idx] <- bmDistTargetPriorDkaIpEr[2]
        chunk$bmTarTargetMaxPriorDkaIpEr[idx] <- bmDistTargetPriorDkaIpEr[3]
        bmDistComparatorPriorDkaIpEr <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorPriorDkaIpEr[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysPriorDkaIpEr[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorPriorDkaIpEr[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanPriorDkaIpEr[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdPriorDkaIpEr[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinPriorDkaIpEr[idx] <- bmDistComparatorPriorDkaIpEr[1]
        chunk$bmTarComparatorMedianPriorDkaIpEr[idx] <- bmDistComparatorPriorDkaIpEr[2]
        chunk$bmTarComparatorMaxPriorDkaIpEr[idx] <- bmDistComparatorPriorDkaIpEr[3]

        subgroupName = "PriorDkaIpEr"
        subgroupValue = 0
        bmDistTargetNoPriorDkaIpEr <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreatedNoPriorDkaIpEr[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDaysNoPriorDkaIpEr[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreatedNoPriorDkaIpEr[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMeanNoPriorDkaIpEr[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSdNoPriorDkaIpEr[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMinNoPriorDkaIpEr[idx] <- bmDistTargetNoPriorDkaIpEr[1]
        chunk$bmTarTargetMedianNoPriorDkaIpEr[idx] <- bmDistTargetNoPriorDkaIpEr[2]
        chunk$bmTarTargetMaxNoPriorDkaIpEr[idx] <- bmDistTargetNoPriorDkaIpEr[3]
        bmDistComparatorNoPriorDkaIpEr <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparatorNoPriorDkaIpEr[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDaysNoPriorDkaIpEr[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparatorNoPriorDkaIpEr[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMeanNoPriorDkaIpEr[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSdNoPriorDkaIpEr[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMinNoPriorDkaIpEr[idx] <- bmDistComparatorNoPriorDkaIpEr[1]
        chunk$bmTarComparatorMedianNoPriorDkaIpEr[idx] <- bmDistComparatorNoPriorDkaIpEr[2]
        chunk$bmTarComparatorMaxNoPriorDkaIpEr[idx] <- bmDistComparatorNoPriorDkaIpEr[3]

        subgroupName = "Age10_19"
        subgroupValue = 1
        bmDistTarget1019 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated1019[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays1019[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated1019[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean1019[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd1019[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin1019[idx] <- bmDistTarget1019[1]
        chunk$bmTarTargetMedian1019[idx] <- bmDistTarget1019[2]
        chunk$bmTarTargetMax1019[idx] <- bmDistTarget1019[3]
        bmDistComparator1019 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator1019[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays1019[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator1019[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean1019[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd1019[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin1019[idx] <- bmDistComparator1019[1]
        chunk$bmTarComparatorMedian1019[idx] <- bmDistComparator1019[2]
        chunk$bmTarComparatorMax1019[idx] <- bmDistComparator1019[3]

        subgroupName = "Age20_29"
        subgroupValue = 1
        bmDistTarget2029 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated2029[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays2029[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated2029[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean2029[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd2029[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin2029[idx] <- bmDistTarget2029[1]
        chunk$bmTarTargetMedian2029[idx] <- bmDistTarget2029[2]
        chunk$bmTarTargetMax2029[idx] <- bmDistTarget2029[3]
        bmDistComparator2029 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator2029[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays2029[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator2029[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean2029[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd2029[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin2029[idx] <- bmDistComparator2029[1]
        chunk$bmTarComparatorMedian2029[idx] <- bmDistComparator2029[2]
        chunk$bmTarComparatorMax2029[idx] <- bmDistComparator2029[3]

        subgroupName = "Age30_39"
        subgroupValue = 1
        bmDistTarget3039 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated3039[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays3039[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated3039[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean3039[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd3039[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin3039[idx] <- bmDistTarget3039[1]
        chunk$bmTarTargetMedian3039[idx] <- bmDistTarget3039[2]
        chunk$bmTarTargetMax3039[idx] <- bmDistTarget3039[3]
        bmDistComparator3039 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator3039[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays3039[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator3039[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean3039[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd3039[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin3039[idx] <- bmDistComparator3039[1]
        chunk$bmTarComparatorMedian3039[idx] <- bmDistComparator3039[2]
        chunk$bmTarComparatorMax3039[idx] <- bmDistComparator3039[3]

        subgroupName = "Age40_49"
        subgroupValue = 1
        bmDistTarget4049 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated4049[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays4049[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated4049[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean4049[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd4049[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin4049[idx] <- bmDistTarget4049[1]
        chunk$bmTarTargetMedian4049[idx] <- bmDistTarget4049[2]
        chunk$bmTarTargetMax4049[idx] <- bmDistTarget4049[3]
        bmDistComparator4049 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator4049[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays4049[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator4049[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean4049[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd4049[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin4049[idx] <- bmDistComparator4049[1]
        chunk$bmTarComparatorMedian4049[idx] <- bmDistComparator4049[2]
        chunk$bmTarComparatorMax4049[idx] <- bmDistComparator4049[3]

        subgroupName = "Age50_59"
        subgroupValue = 1
        bmDistTarget5059 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated5059[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays5059[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated5059[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean5059[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd5059[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin5059[idx] <- bmDistTarget5059[1]
        chunk$bmTarTargetMedian5059[idx] <- bmDistTarget5059[2]
        chunk$bmTarTargetMax5059[idx] <- bmDistTarget5059[3]
        bmDistComparator5059 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator5059[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays5059[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator5059[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean5059[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd5059[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin5059[idx] <- bmDistComparator5059[1]
        chunk$bmTarComparatorMedian5059[idx] <- bmDistComparator5059[2]
        chunk$bmTarComparatorMax5059[idx] <- bmDistComparator5059[3]

        subgroupName = "Age60_69"
        subgroupValue = 1
        bmDistTarget6069 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated6069[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays6069[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated6069[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean6069[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd6069[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin6069[idx] <- bmDistTarget6069[1]
        chunk$bmTarTargetMedian6069[idx] <- bmDistTarget6069[2]
        chunk$bmTarTargetMax6069[idx] <- bmDistTarget6069[3]
        bmDistComparator6069 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator6069[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays6069[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator6069[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean6069[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd6069[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin6069[idx] <- bmDistComparator6069[1]
        chunk$bmTarComparatorMedian6069[idx] <- bmDistComparator6069[2]
        chunk$bmTarComparatorMax6069[idx] <- bmDistComparator6069[3]

        subgroupName = "Age70_79"
        subgroupValue = 1
        bmDistTarget7079 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated7079[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays7079[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated7079[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean7079[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd7079[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin7079[idx] <- bmDistTarget7079[1]
        chunk$bmTarTargetMedian7079[idx] <- bmDistTarget7079[2]
        chunk$bmTarTargetMax7079[idx] <- bmDistTarget7079[3]
        bmDistComparator7079 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator7079[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays7079[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator7079[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean7079[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd7079[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin7079[idx] <- bmDistComparator7079[1]
        chunk$bmTarComparatorMedian7079[idx] <- bmDistComparator7079[2]
        chunk$bmTarComparatorMax7079[idx] <- bmDistComparator7079[3]

        subgroupName = "Age80_89"
        subgroupValue = 1
        bmDistTarget8089 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated8089[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays8089[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated8089[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean8089[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd8089[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin8089[idx] <- bmDistTarget8089[1]
        chunk$bmTarTargetMedian8089[idx] <- bmDistTarget8089[2]
        chunk$bmTarTargetMax8089[idx] <- bmDistTarget8089[3]
        bmDistComparator8089 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator8089[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays8089[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator8089[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean8089[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd8089[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin8089[idx] <- bmDistComparator8089[1]
        chunk$bmTarComparatorMedian8089[idx] <- bmDistComparator8089[2]
        chunk$bmTarComparatorMax8089[idx] <- bmDistComparator8089[3]

        subgroupName = "Age90_99"
        subgroupValue = 1
        bmDistTarget9099 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated9099[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays9099[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated9099[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean9099[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd9099[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin9099[idx] <- bmDistTarget9099[1]
        chunk$bmTarTargetMedian9099[idx] <- bmDistTarget9099[2]
        chunk$bmTarTargetMax9099[idx] <- bmDistTarget9099[3]
        bmDistComparator9099 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator9099[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays9099[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator9099[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean9099[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd9099[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin9099[idx] <- bmDistComparator9099[1]
        chunk$bmTarComparatorMedian9099[idx] <- bmDistComparator9099[2]
        chunk$bmTarComparatorMax9099[idx] <- bmDistComparator9099[3]

        subgroupName = "Age100_109"
        subgroupValue = 1
        bmDistTarget100109 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmTreated100109[idx] <- nrow(studyPop[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmTreatedDays100109[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsTreated100109[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMean100109[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetSd100109[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 1 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarTargetMin100109[idx] <- bmDistTarget100109[1]
        chunk$bmTarTargetMedian100109[idx] <- bmDistTarget100109[2]
        chunk$bmTarTargetMax100109[idx] <- bmDistTarget100109[3]
        bmDistComparator100109 <- quantile(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue], c(0, 0.5, 1))
        chunk$bmComparator100109[idx] <- nrow(studyPop[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue, ])
        chunk$bmComparatorDays100109[idx] <- sum(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmEventsComparator100109[idx] <- sum(studyPop$outcomeCount[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMean100109[idx] <- mean(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorSd100109[idx] <- sd(studyPop$timeAtRisk[studyPop$treatment == 0 & studyPop[[subgroupName]] == subgroupValue])
        chunk$bmTarComparatorMin100109[idx] <- bmDistComparator100109[1]
        chunk$bmTarComparatorMedian100109[idx] <- bmDistComparator100109[2]
        chunk$bmTarComparatorMax100109[idx] <- bmDistComparator100109[3]
      }

      fileName <-  file.path(shinyDataFolder, paste0("ps_a", analysisId,
                                                     "_t", targetId,
                                                     "_c", comparatorId,
                                                     "_", databaseName,
                                                     ".rds"))
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

  ncs <- analysisSummary[analysisSummary$type == "Negative control",
                          c("targetId", "comparatorId", "outcomeId", "analysisId", "database", "logRr", "seLogRr")]
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

