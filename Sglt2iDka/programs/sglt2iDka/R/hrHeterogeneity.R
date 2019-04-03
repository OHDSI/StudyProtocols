#' @export
hrHeterogeneity <- function(outputFolder,
                            databaseName,
                            primaryOnly = FALSE) {
  packageName <- "sglt2iDka"
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  diagnosticsFolder <- file.path(outputFolder, "diagnostics")
  if (!file.exists(diagnosticsFolder))
    dir.create(diagnosticsFolder)

  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  tcosAnalyses$tOrder <- match(tcosAnalyses$targetCohortName, c("SGLT2i-BROAD-90",
                                                                "SGLT2i-NARROW-90",
                                                                "Canagliflozin-BROAD-90",
                                                                "Canagliflozin-NARROW-90",
                                                                "Dapagliflozin-BROAD-90",
                                                                "Dapagliflozin-NARROW-90",
                                                                "Empagliflozin-BROAD-90",
                                                                "Empagliflozin-NARROW-90"))
  tcosAnalyses$cOrder <- match(tcosAnalyses$comparatorCohortName, c("SU-BROAD-90",
                                                                    "SU-NARROW-90",
                                                                    "DPP-4i-BROAD-90",
                                                                    "DPP-4i-NARROW-90",
                                                                    "GLP-1a-BROAD-90",
                                                                    "GLP-1a-NARROW-90",
                                                                    "TZDs-BROAD-90",
                                                                    "TZDs-NARROW-90",
                                                                    "Insulin-BROAD-90",
                                                                    "Insulin-NARROW-90",
                                                                    "Metformin-BROAD-90",
                                                                    "Metformin-NARROW-90",
                                                                    "Insulinotropic AHAs-BROAD-90",
                                                                    "Insulinotropic AHAs-NARROW-90",
                                                                    "Other AHAs-BROAD-90",
                                                                    "Other AHAs-NARROW-90"))
  tcosAnalyses <- tcosAnalyses[order(tcosAnalyses$tOrder, tcosAnalyses$cOrder), ]

  if (primaryOnly == TRUE) {
    tcosAnalyses <- tcosAnalyses[tcosAnalyses$timeAtRisk == "Intent to Treat" & tcosAnalyses$targetCohortId %in% c(11, 14) & tcosAnalyses$outcomeCohortId == 200, ]
  }

  tcosOfInterest <- unique(tcosAnalyses[, c("targetCohortId", "targetDrugName", "targetCohortName",
                                            "comparatorCohortId", "comparatorDrugName", "comparatorCohortName",
                                            "outcomeCohortId", "outcomeCohortName")])
  names(tcosOfInterest) <- c("targetId", "targetDrugName", "targetName",
                             "comparatorId", "comparatorDrugName", "comparatorName",
                             "outcomeId", "outcomeName")
  tcosOfInterest$targetName <- sub(pattern = "-90", replacement = "", x = tcosOfInterest$targetName)
  tcosOfInterest$comparatorName <- sub(pattern = "-90", replacement = "", x = tcosOfInterest$comparatorName)
  tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  outcomeIds <- unique(tcosOfInterest$outcomeId)
  outcomeNames <- unique(tcosOfInterest$outcomeName)

  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  effectHeterogeneityFileName <- file.path(diagnosticsFolder, paste0("effectHeterogeneityTest.csv"))

  effectHeterogeneity <- data.frame()
  for (i in 1:nrow(tcsOfInterest)) {
    targetId <- tcsOfInterest$targetId[i]
    comparatorId <- tcsOfInterest$comparatorId[i]
    idx <- which(tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId)[1]
    targetLabel <- tcosOfInterest$targetName[idx]
    comparatorLabel <- tcosOfInterest$comparatorName[idx]
    for (analysisId in unique(reference$analysisId)) {
      analysisDescription <- ifelse(analysisId == 1, "ITT", "PP")
      for (outcomeId in outcomeIds) {
        outcomeName <- outcomeNames[outcomeIds == outcomeId]
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        population <- readRDS(strataFile)

        refData <- data.frame(analysisId = 0,
                              analysisDescription = "",
                              targetId = 0,
                              targetName = "",
                              comparatorId = 0,
                              comparatorName = "",
                              outcomeId = 0,
                              outcomeName = "")
        refData$analysisId <- analysisId
        refData$analysisDescription <- analysisDescription
        refData$targetId <- targetId
        refData$targetName <- targetLabel
        refData$comparatorId <- comparatorId
        refData$comparatorName <- comparatorLabel
        refData$outcomeId <- outcomeId
        refData$outcomeName <- outcomeName

        strataPop <- CohortMethod::stratifyByPs(population = population, numberOfStrata = 5, baseSelection = "all")
        strataPop$y <- ifelse(strataPop$outcomeCount != 0, 1, 0)
        strataPop$stratumId <- relevel(as.factor(strataPop$stratumId), ref = 3)

        formula <- as.formula(survival::Surv(survivalTime, y) ~ treatment + stratumId + treatment:stratumId)
        tryCatch({
          fit <- survival::coxph(formula, strataPop)
        }, error = function(e) {
          print(as.character(e))
        })
        coefs <- as.data.frame(summary(fit)$coefficients)
        coefs <- cbind(terms = row.names(coefs), coefs)
        row.names(coefs) <- NULL
        coefs <- merge(refData, coefs)
        intPValues <- coefs[coefs$terms %in% c("treatment:stratumId1", "treatment:stratumId2", "treatment:stratumId4", "treatment:stratumId5"), ]$`Pr(>|z|)`
        coefs$hrHetero <- ifelse(length(intPValues[intPValues < 0.05]), 1, 0)

        effectHeterogeneity <- rbind(effectHeterogeneity, coefs)
      }
    }
  }
  effectHeterogeneity <- cbind(effectHeterogeneity, database = databaseName)
  write.csv(effectHeterogeneity, effectHeterogeneityFileName, row.names = FALSE)
}
