workFolder <- "R:/PopEstDepression_Mdcd"
symposiumFolder <- file.path(workFolder, "symposium")
if (!file.exists(symposiumFolder)){
  dir.create(symposiumFolder)
}
exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
analysesSum <- read.csv(file.path(workFolder, "analysisSummary.csv"))
signalInjectionSum <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
negativeControlIds <- unique(signalInjectionSum$outcomeId)

row <- exposureSummary[exposureSummary$tCohortDefinitionName == "duloxetine" & exposureSummary$cCohortDefinitionName == "Sertraline",]
treatmentId <- row$tprimeCohortDefinitionId
comparatorId <- row$cprimeCohortDefinitionId
estimates <- analysesSum[analysesSum$targetId == treatmentId & analysesSum$comparatorId == comparatorId, ]

# Get PS plot:
file.copy(from = file.path(workFolder, "figuresAndtables", "ps", paste0("ps_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "Ps.png"),
          overwrite = TRUE)

# Create covariate balance plots:
cohortMethodDataFolder <- outcomeModelReference$cohortMethodDataFolder[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3 & outcomeModelReference$outcomeId == 2559]
strataFile <- outcomeModelReference$strataFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3 & outcomeModelReference$outcomeId == 2559]

cohortMethodDataFolder <- gsub("^S:", "R:", cohortMethodDataFolder)
strataFile <- gsub("^S:", "R:", strataFile)

cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)
strata <- readRDS(strataFile)

balance <- CohortMethod::computeCovariateBalance(strata, cohortMethodData)

tableFileName <- file.path(workFolder, "symposium", "balance.csv")
write.csv(balance, tableFileName, row.names = FALSE)

plotFileName <- file.path(workFolder, "symposium", "balanceScatterPlot.png")
CohortMethod::plotCovariateBalanceScatterPlot(balance, fileName = plotFileName)

plotFileName <- file.path(workFolder, "symposium", "balanceTop.png")
CohortMethod::plotCovariateBalanceOfTopVariables(balance, fileName = plotFileName)

# Get negative control distribution plots:
file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("negControls_a1_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "negControls_crude.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 1, ]
writeLines(paste0("Crude negative control p < 0.05: ",mean(negControls$p < 0.05)))

file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("negControls_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "negControls_adjusted.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 3, ]
writeLines(paste0("Adjusted negative control p < 0.05: ",mean(negControls$p < 0.05)))

# Get signal injection plot:
file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("trueAndObs_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "trueAndObs.png"),
          overwrite = TRUE)

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControlIdSubsets <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId & signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIdSubsets,
                               trueLogRr = 0)
data <- rbind(injectedSignals, negativeControls)
data <- merge(data, estimates[estimates$analysisId == 3, c("outcomeId", "logRr", "seLogRr")])
data$trueRr <- exp(data$trueLogRr)
data$logLb <- data$logRr - (data$seLogRr * qnorm(0.975))
data$logUb <- data$logRr + (data$seLogRr * qnorm(0.975))
data$covered <- data$trueLogRr >= data$logLb & data$trueLogRr <= data$logUb
aggregate(covered ~ trueRr, data = data, mean)

# P-value calibration
file.copy(from = file.path(workFolder, "figuresAndtables", "calibration", paste0("negControls_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "pCalEffectPlot.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 3, ]
EmpiricalCalibration::plotCalibration(logRr = negControls$logRr,
                                      seLogRr = negControls$seLogRr,
                                      useMcmc = TRUE)
writeLines(paste0("Adjusted negative control p < 0.05: ",mean(negControls$p < 0.05)))









psFileName <- outcomeModelReference$sharedPsFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3][1]
ps <- readRDS(psFileName)

plotFileName <- file.path(workFolder, "symposium", "ps.png")
CohortMethod::plotPs(ps,
                     treatmentLabel = as.character(row$tCohortDefinitionName),
                     comparatorLabel = as.character(row$cCohortDefinitionName),
                     fileName = plotFileName)

# Bias plots


analysesSum <- read.csv(file.path(workFolder, "analysisSummary.csv"))
signalInjectionSum <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
negativeControlIds <- unique(signalInjectionSum$outcomeId)
estimates <- analysesSum[analysesSum$analysisId == 1 &
                             analysesSum$targetId == treatmentId &
                             analysesSum$comparatorId == comparatorId, ]

negControls <- estimates[estimates$outcomeId %in% negativeControlIds, ]
mean(negControls$p < 0.05)
fileName <- file.path(workFolder, "symposium", "bias_crude.png")
plotEstimates(logRrNegatives = negControls$logRr,
              seLogRrNegatives = negControls$seLogRr,
              #title = title,
              xLabel = "Hazard ratio",
              fileName = fileName)

estimates <- analysesSum[analysesSum$analysisId == 3 &
                             analysesSum$targetId == treatmentId &
                             analysesSum$comparatorId == comparatorId, ]

negControls <- estimates[estimates$outcomeId %in% negativeControlIds, ]
mean(negControls$p < 0.05)
fileName <- file.path(workFolder, "symposium", "bias_adjusted.png")
plotEstimates(logRrNegatives = negControls$logRr,
              seLogRrNegatives = negControls$seLogRr,
              #title = title,
              xLabel = "Hazard ratio",
              fileName = fileName)

# True and observed plots
injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControlIds <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId & signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIds,
                               trueLogRr = 0)
estimates <- analysesSum[analysesSum$analysisId == 1 &
                             analysesSum$targetId == treatmentId &
                             analysesSum$comparatorId == comparatorId, ]
data <- rbind(injectedSignals, negativeControls)
data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
fileName <-file.path(workFolder, "symposium", "trueAndObs_crude.png")

EmpiricalCalibration::plotTrueAndObserved(logRr = data$logRr,
                                          seLogRr = data$seLogRr,
                                          trueLogRr = data$trueLogRr,
                                          xLabel = "Hazard ratio",
                                          fileName = fileName)

estimates <- analysesSum[analysesSum$analysisId == 3 &
                             analysesSum$targetId == treatmentId &
                             analysesSum$comparatorId == comparatorId, ]
data <- rbind(injectedSignals, negativeControls)
data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
fileName <-file.path(workFolder, "symposium", "trueAndObs_adjusted.png")

EmpiricalCalibration::plotTrueAndObserved(logRr = data$logRr,
                                          seLogRr = data$seLogRr,
                                          trueLogRr = data$trueLogRr,
                                          xLabel = "Hazard ratio",
                                          fileName = fileName)

# Get estimate for stroke
estimates <- analysesSum[analysesSum$analysisId == 3 &
                             analysesSum$targetId == treatmentId &
                             analysesSum$comparatorId == comparatorId &
                             analysesSum$outcomeId == 2559, ]
