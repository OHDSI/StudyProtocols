#' @export
prepareIrDoseResultsForAnalysis <- function(outputFolder,
                                            databaseName,
                                            maxCores) {
  packageName <- "sglt2iDka"
  cmIrDoseOutputFolder <- file.path(outputFolder, "cmIrDoseOutput")
  resultsFolder <- file.path(outputFolder, "results")
  if (!file.exists(resultsFolder))
    dir.create(resultsFolder)
  irDoseDataFolder <- file.path(resultsFolder, "irDoseData")
  if (!file.exists(irDoseDataFolder))
    dir.create(irDoseDataFolder)

  # TCOs of interest
  tcosOfInterest <- read.csv(system.file("settings", "tcoIrDoseVariants.csv", package = packageName), stringsAsFactors = FALSE)
  tcosOfInterest <- unique(tcosOfInterest[, c("targetCohortId", "targetDrugName", "targetCohortName", "comparatorCohortId", "comparatorDrugName", "comparatorCohortName",
                                              "outcomeCohortId", "outcomeCohortName")])
  names(tcosOfInterest) <- c("targetId", "targetDrugName", "targetName", "comparatorId", "comparatorDrugName", "comparatorName",
                             "outcomeId", "outcomeName")

  reference <- readRDS(file.path(cmIrDoseOutputFolder, "outcomeModelReference.rds"))
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = TRUE, "outcomeId", "outcomeName")
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = TRUE, "comparatorId", "comparatorName")
  analysisSummary <- sglt2iDka::addCohortNames(analysisSummary, dose = TRUE, "targetId", "targetName")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmIrDoseAnalysisList.json", package = packageName))
  analyses <- data.frame(analysisId = unique(reference$analysisId),
                         analysisDescription = "",
                         stringsAsFactors = FALSE)
  for (i in 1:length(cmAnalysisList)) {
    analyses$analysisDescription[analyses$analysisId == cmAnalysisList[[i]]$analysisId] <- cmAnalysisList[[i]]$description
  }
  analysisSummary <- merge(analysisSummary, analyses)
  analysisSummary <- analysisSummary[, c(1,20,2:19)]
  analysisSummary <- analysisSummary[, -which(names(analysisSummary) %in% c("rr", "ci95lb", "ci95ub", "p", "logRr", "seLogRr"))]
  analysisSummary$database <- databaseName

  # reference to full sglt2i aftermatching cohorts
  fullCmOutputFolder <- file.path(outputFolder, "cmOutput")
  fullReference <- readRDS(file.path(fullCmOutputFolder, "outcomeModelReference.rds"))
  fullReference <- fullReference[fullReference$analysisId == 1 &
                                   fullReference$targetId %in% c(101, 104, 111, 114, 121, 124) &
                                   fullReference$outcomeId %in% c(200, 201), ] # sglt2i ingredients with censor=90

  fullReference <- aggregate(.~ targetId + outcomeId, fullReference, FUN = head, 1)
  facs <- sapply(fullReference, is.factor)
  fullReference[facs] <- lapply(fullReference[facs], as.character)
  fullReference$analysisId <- as.integer(fullReference$analysisId)
  fullReference$comparatorId <- as.integer(fullReference$comparatorId)

  runTc <- function(chunk,
                    tcosOfInterest,
                    reference) {
    targetId <- chunk$targetId[1]
    comparatorId <- chunk$comparatorId[1]
    outcomeIds <- unique(tcosOfInterest$outcomeId)
    outcomeNames <- unique(tcosOfInterest$outcomeName)
    OhdsiRTools::logTrace("Preparing results for target ID ", targetId, ", comparator ID", comparatorId)

    for (analysisId in unique(reference$analysisId)) { # only 1 analysis
      # analysisId=1

      OhdsiRTools::logTrace("Analysis ID ", analysisId)

      for (outcomeId in outcomeIds) {
        # outcomeId=200

        OhdsiRTools::logTrace("Outcome ID ", outcomeId)
        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        idx <- chunk$analysisId == analysisId &
          chunk$targetId == targetId &
          chunk$comparatorId == comparatorId &
          chunk$outcomeId == outcomeId
        refRow <- reference[reference$analysisId == analysisId &
                              reference$targetId == targetId &
                              reference$comparatorId == comparatorId &
                              reference$outcomeId == outcomeId, ]

        # before matching
        studyPop <- readRDS(refRow$studyPopFile)
        studyPop$outcomeCount[studyPop$outcomeCount != 0] <- 1  # first event
        studyPop$timeAtRisk <- studyPop$survivalTime # TAR ends at first event

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

        # after matching dose-specific IRs
        # crosswalk between dose-specific cohort IDs and full cohort IDs; dose-specific cohorts are subset of full cohorts per ID link
        crossWalk <- function(id) {
          if (id %in% c(300, 302, 304)) { # cana broad
            fullTargetId <- 101
            fullComparatorId <- 21
          }
          if (id %in% c(301, 303, 305)) { # cana narrow
            fullTargetId <- 104
            fullComparatorId <- 24
          }
          if (id %in% c(310, 312, 314)) { # dapa broad
            fullTargetId <- 111
            fullComparatorId <- 21
          }
          if (id %in% c(311, 313, 315)) { # dapa narrow
            fullTargetId <- 114
            fullComparatorId <- 24
          }
          if (id %in% c(320, 322, 324)) { # empa broad
            fullTargetId <- 121
            fullComparatorId <- 21
          }
          if (id %in% c(321, 323, 325)) { # empa narrow
            fullTargetId <- 124
            fullComparatorId <- 24
          }
          return(list(fullTargetId = fullTargetId, fullComparatorId = fullComparatorId))
        }
        tIds <- crossWalk(targetId)
        cIds <- crossWalk(comparatorId)

        tFullRefRow <- fullReference[fullReference$analysisId == analysisId &
                                       fullReference$targetId == tIds$fullTargetId &
                                       fullReference$comparatorId == tIds$fullComparatorId &
                                       fullReference$outcomeId == outcomeId, ]
        tStrataPop <- readRDS(tFullRefRow$strataFile)
        tStrataPop$outcomeCount[tStrataPop$outcomeCount != 0] <- 1  # first event
        tStrataPop$timeAtRisk <- tStrataPop$survivalTime  # TAR ends at first event
        tStrataPop <- tStrataPop[tStrataPop$treatment == 1, ]
        tStrataPopDose <- merge(studyPop[studyPop$treatment == 1, ], tStrataPop, by = "subjectId", suffixes = c("Study", "Strata"))

        cFullRefRow <- fullReference[fullReference$analysisId == analysisId &
                                       fullReference$targetId == cIds$fullTargetId &
                                       fullReference$comparatorId == cIds$fullComparatorId &
                                       fullReference$outcomeId == outcomeId, ]
        cStrataPop <- readRDS(cFullRefRow$strataFile)
        cStrataPop$outcomeCount[cStrataPop$outcomeCount != 0] <- 1  # first event
        cStrataPop$timeAtRisk <- cStrataPop$survivalTime  # TAR ends at first event
        cStrataPop <- cStrataPop[cStrataPop$treatment == 1, ]
        cStrataPopDose <- merge(studyPop[studyPop$treatment == 0, ], cStrataPop, by = "subjectId", suffixes = c("Study", "Strata"))

        amDistTarget <- quantile(tStrataPopDose$timeAtRiskStrata, c(0, 0.5, 1))
        chunk$amTreated[idx] <- sum(tStrataPopDose$treatmentStrata == 1)
        chunk$amTreatedDays[idx] <- sum(tStrataPopDose$timeAtRiskStrata)
        chunk$amEventsTreated[idx] <- sum(tStrataPopDose$outcomeCountStrata)
        chunk$amTarTargetMean[idx] <- mean(tStrataPopDose$timeAtRiskStrata)
        chunk$amTarTargetSd[idx] <- sd(tStrataPopDose$timeAtRiskStrata)
        chunk$amTarTargetMin[idx] <- amDistTarget[1]
        chunk$amTarTargetMedian[idx] <- amDistTarget[2]
        chunk$amTarTargetMax[idx] <- amDistTarget[3]

        amDistComparator <- quantile(cStrataPopDose$timeAtRiskStrata, c(0, 0.5, 1))
        chunk$amComparator[idx] <- sum(cStrataPopDose$treatmentStrata == 1)
        chunk$amComparatorDays[idx] <- sum(cStrataPopDose$timeAtRiskStrata)
        chunk$amEventsComparator[idx] <- sum(cStrataPopDose$outcomeCountStrata)
        chunk$amTarComparatorMean[idx] <- mean(cStrataPopDose$timeAtRiskStrata)
        chunk$amTarComparatorSd[idx] <- sd(cStrataPopDose$timeAtRiskStrata)
        chunk$amTarComparatorMin[idx] <- amDistComparator[1]
        chunk$amTarComparatorMedian[idx] <- amDistComparator[2]
        chunk$amTarComparatorMax[idx] <- amDistComparator[3]
      }
    }
    OhdsiRTools::logDebug("Finished chunk with ", nrow(chunk), " rows")
    return(chunk)
  }

  cluster <- OhdsiRTools::makeCluster(min(maxCores, 10))
  comparison <- paste(analysisSummary$targetId, analysisSummary$comparatorId)
  chunks <- split(analysisSummary, comparison)
  analysisSummaries <- OhdsiRTools::clusterApply(cluster = cluster,
                                                 x = chunks,
                                                 fun = runTc,
                                                 tcosOfInterest = tcosOfInterest,
                                                 reference = reference)
  OhdsiRTools::stopCluster(cluster)
  analysisSummary <- do.call(rbind, analysisSummaries)
  fileName <- file.path(irDoseDataFolder, paste0("irDoseData_", databaseName,".rds"))
  saveRDS(analysisSummary, fileName)
}
