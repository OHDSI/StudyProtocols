workFolder <- "R:/PopEstDepression_Ccae"
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
calibrated <- read.csv(file.path(workFolder, "calibratedEstimates.csv"))

# Get PS plot:
psFile <- outcomeModelReference$sharedPsFile[outcomeModelReference$analysisId == 3 & outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId][1]
ps <-readRDS(psFile)
fileName <- file.path(symposiumFolder, "Ps.png")
CohortMethod::plotPs(ps,
                     scale = "propensity",
                     treatmentLabel = as.character(row$tCohortDefinitionName),
                     comparatorLabel = as.character(row$cCohortDefinitionName),
                     fileName = fileName)
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
ingrownNail <- 139099

file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("negControls_a1_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "negControls_crude.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 1, ]
writeLines(paste0("Crude negative control p < 0.05: ",mean(negControls$p < 0.05)))

example <- negControls[negControls$outcomeId == ingrownNail, ]
print(example)
plotEstimates(example$logRr,
              example$seLogRr,
              xLabel = "Hazard ratio",
              title = "duloxestine vs. Sertraline - Crude",
              fileName = file.path(symposiumFolder, "ingrownNail_crude.png"))

file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("negControls_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "negControls_adjusted.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 3, ]
writeLines(paste0("Adjusted negative control p < 0.05: ",mean(negControls$p < 0.05)))

example <- negControls[negControls$outcomeId == ingrownNail, ]
print(example)
plotEstimates(example$logRr,
              example$seLogRr,
              xLabel = "Hazard ratio",
              title = "duloxestine vs. Sertraline - Adjusted",
              fileName = file.path(symposiumFolder, "ingrownNail_adjusted.png"))

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

negControls <- calibrated[calibrated$analysisId == 3 &
                           calibrated$targetId == treatmentId &
                           calibrated$comparatorId == comparatorId &
                           calibrated$outcomeId %in% negativeControlIds, ]
writeLines(paste0("Calibrated negative control p < 0.05: ",mean(negControls$calP < 0.05)))

# CI calibration

file.copy(from = file.path(workFolder, "figuresAndtables", "calibration", paste0("trueAndObs_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "trueAndObsCali.png"),
          overwrite = TRUE)

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControlIdSubsets <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId & signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIdSubsets,
                               trueLogRr = 0)
data <- rbind(injectedSignals, negativeControls)
data <- merge(data, calibrated[calibrated$analysisId == 3 &
                                   calibrated$targetId == treatmentId &
                                   calibrated$comparatorId == comparatorId, c("outcomeId", "calRr", "calCi95lb", "calCi95ub")])
data$trueRr <- exp(data$trueLogRr)
data$covered <- data$trueRr >= data$calCi95lb & data$trueRr <= data$calCi95ub
aggregate(covered ~ trueRr, data = data, mean)

# Get estimate for stroke
estimate <- calibrated[calibrated$analysisId == 3 &
                            calibrated$targetId == treatmentId &
                            calibrated$comparatorId == comparatorId &
                            calibrated$outcomeId == 2559, ]
print(estimate)

# Get estimates across databases
dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
dbs <- c("CCAE", "MDCD", "Optum")
calibrated <- data.frame()
for (db in dbs) {
  temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
  temp$db <- db
  calibrated <- rbind(calibrated, temp)
}
estimate <- calibrated[calibrated$analysisId == 3 &
                           calibrated$targetId == treatmentId &
                           calibrated$comparatorId == comparatorId &
                           calibrated$outcomeId == 2559, ]
print(estimate)
d1 <- data.frame(logRr = estimate$logRr,
                 seLogRr = estimate$seLogRr,
                 database = estimate$db,
                 type = "Uncalibrated")
d2 <- data.frame(logRr = estimate$calLogRr,
                 seLogRr = estimate$calSeLogRr,
                 database = estimate$db,
                 type = "Calibrated")

d <- rbind(d1, d2)
d$logLb95Rr <- d$logRr + qnorm(0.025) * d$seLogRr
d$logUb95Rr <- d$logRr + qnorm(0.975) * d$seLogRr
d$significant <- d$logLb95Rr > 0 | d$logUb95Rr < 0

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- ggplot2::element_text(colour = "#000000", size = 9)
themeRA <- ggplot2::element_text(colour = "#000000", size = 9, hjust = 1)
col <- c(rgb(0, 0, 0.8, alpha = 1), rgb(0.8, 0.4, 0, alpha = 1))
colFill <- c(rgb(0, 0, 1, alpha = 0.5), rgb(1, 0.4, 0, alpha = 0.5))
d$database <- as.factor(d$database)
d$database <- factor(d$database, levels = rev(levels(d$database)))
ggplot2::ggplot(d,
                ggplot2::aes(x = database,
                             y = exp(logRr),
                             ymin = exp(logLb95Rr),
                             ymax = exp(logUb95Rr),
                             colour = significant,
                             fill = significant),
                environment = environment()) +
    ggplot2::geom_hline(yintercept = breaks,
                        colour = "#AAAAAA",
                        lty = 1,
                        size = 0.2) +
    ggplot2::geom_hline(yintercept = 1, size = 0.5) +
    ggplot2::geom_pointrange(shape = 23, size = 0.5) +
    ggplot2::scale_colour_manual(values = col) +
    ggplot2::scale_fill_manual(values = colFill) +
    ggplot2::coord_flip(ylim = c(0.25, 10)) +
    ggplot2::scale_y_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = breaks) +
    ggplot2::facet_grid(~type) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA), panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"), axis.ticks = ggplot2::element_blank(), axis.title.y = ggplot2::element_blank(), axis.title.x = ggplot2::element_blank(), axis.text.y = themeRA, axis.text.x = theme, legend.key = ggplot2::element_blank(), strip.text.x = theme, strip.background = ggplot2::element_blank(), legend.position = "none")

ggplot2::ggsave(filename = file.path(symposiumFolder, "stroke4Db.png"), width = 5, height = 2, dpi = 300)


pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)

estimate <- calibrated[calibrated$analysisId == 3 &
                           calibrated$targetId == treatmentId &
                           calibrated$comparatorId == comparatorId &
                           calibrated$outcomeId %in% outcomes$cohortDefinitionId, ]
estimate <- merge(estimate, outcomes, by.x = "outcomeId", by.y = "cohortDefinitionId")
d1 <- data.frame(logRr = estimate$logRr,
                 seLogRr = estimate$seLogRr,
                 database = estimate$db,
                 outcome = estimate$name,
                 type = "Uncalibrated")
d2 <- data.frame(logRr = estimate$calLogRr,
                 seLogRr = estimate$calSeLogRr,
                 database = estimate$db,
                 outcome = estimate$name,
                 type = "Calibrated")

d <- rbind(d1, d2)
alpha <- 0.05 / 22
d$logLb95Rr <- d$logRr + qnorm(alpha/2) * d$seLogRr
d$logUb95Rr <- d$logRr + qnorm(1-(alpha/2)) * d$seLogRr
d$significant <- d$logLb95Rr > 0 | d$logUb95Rr < 0

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- ggplot2::element_text(colour = "#000000", size = 9)
themeRA <- ggplot2::element_text(colour = "#000000", size = 9, hjust = 1)
col <- c(rgb(0, 0, 0.8, alpha = 1), rgb(0.8, 0.4, 0, alpha = 1))
colFill <- c(rgb(0, 0, 1, alpha = 0.5), rgb(1, 0.4, 0, alpha = 0.5))
d$database <- as.factor(d$database)
d$database <- factor(d$database, levels = rev(levels(d$database)))
d$outcome <- as.factor(d$outcome)
d$outcome <- factor(d$outcome, levels = rev(levels(d$outcome)))

ggplot2::ggplot(d[as.numeric(d$outcome) <= 11,],
                ggplot2::aes(x = database,
                             y = exp(logRr),
                             ymin = exp(logLb95Rr),
                             ymax = exp(logUb95Rr),
                             colour = significant,
                             fill = significant),
                environment = environment()) +
    ggplot2::geom_hline(yintercept = breaks,
                        colour = "#AAAAAA",
                        lty = 1,
                        size = 0.2) +
    ggplot2::geom_hline(yintercept = 1, size = 0.5) +
    ggplot2::geom_pointrange(shape = 23, size = 0.5) +
    ggplot2::scale_colour_manual(values = col) +
    ggplot2::scale_fill_manual(values = colFill) +
    ggplot2::coord_flip(ylim = c(0.25, 10)) +
    ggplot2::scale_y_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = breaks) +
    ggplot2::facet_grid(outcome~type) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA), panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"), axis.ticks = ggplot2::element_blank(), axis.title.y = ggplot2::element_blank(), axis.title.x = ggplot2::element_blank(), axis.text.y = themeRA, axis.text.x = theme, legend.key = ggplot2::element_blank(), strip.text.x = theme, strip.background = ggplot2::element_blank(), legend.position = "none")

ggplot2::ggsave(filename = file.path(symposiumFolder, "1st11Hois4Db.png"), width = 5, height = 8, dpi = 300)

ggplot2::ggplot(d[as.numeric(d$outcome) > 11,],
                ggplot2::aes(x = database,
                             y = exp(logRr),
                             ymin = exp(logLb95Rr),
                             ymax = exp(logUb95Rr),
                             colour = significant,
                             fill = significant),
                environment = environment()) +
    ggplot2::geom_hline(yintercept = breaks,
                        colour = "#AAAAAA",
                        lty = 1,
                        size = 0.2) +
    ggplot2::geom_hline(yintercept = 1, size = 0.5) +
    ggplot2::geom_pointrange(shape = 23, size = 0.5) +
    ggplot2::scale_colour_manual(values = col) +
    ggplot2::scale_fill_manual(values = colFill) +
    ggplot2::coord_flip(ylim = c(0.25, 10)) +
    ggplot2::scale_y_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = breaks) +
    ggplot2::facet_grid(outcome~type) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA), panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"), axis.ticks = ggplot2::element_blank(), axis.title.y = ggplot2::element_blank(), axis.title.x = ggplot2::element_blank(), axis.text.y = themeRA, axis.text.x = theme, legend.key = ggplot2::element_blank(), strip.text.x = theme, strip.background = ggplot2::element_blank(), legend.position = "none")

ggplot2::ggsave(filename = file.path(symposiumFolder, "2nd11Hois4Db.png"), width = 5, height = 8, dpi = 300)






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


