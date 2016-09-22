workFolder <- "R:/PopEstDepression_Ccae"
workFolder <- "s:/PopEstDepression_Ccae"
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

###########################################################################
# Get PS plot                                                             #
###########################################################################
psFile <- outcomeModelReference$sharedPsFile[outcomeModelReference$analysisId == 3 & outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId][1]
ps <-readRDS(psFile)
fileName <- file.path(symposiumFolder, "Ps.png")
CohortMethod::plotPs(ps,
                     scale = "preference",
                     treatmentLabel = as.character(row$tCohortDefinitionName),
                     comparatorLabel = as.character(row$cCohortDefinitionName),
                     fileName = fileName)
file.copy(from = file.path(workFolder, "figuresAndtables", "ps", paste0("ps_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "Ps.png"),
          overwrite = TRUE)
mean(ps$preferenceScore[ps$treatment == 1] > .3 & ps$preferenceScore[ps$treatment == 1] < .7)
mean(ps$preferenceScore[ps$treatment == 0] > .3 & ps$preferenceScore[ps$treatment == 0] < .7)

###########################################################################
# Create covariate balance plot                                           #
###########################################################################
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

###########################################################################
# Get negative control distribution plots                                 #
###########################################################################
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

###########################################################################
# Get signal injection plot                                               #
###########################################################################
file.copy(from = file.path(workFolder, "figuresAndtables", "controls", paste0("trueAndObs_a3_t",treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "trueAndObs.png"),
          overwrite = TRUE)

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              oldOutcomeId = injectedSignals$outcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControlIdSubsets <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId & signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIdSubsets,
                               oldOutcomeId = negativeControlIdSubsets,
                               trueLogRr = 0)
data <- rbind(injectedSignals, negativeControls)
data <- merge(data, estimates[estimates$analysisId == 3, c("outcomeId", "logRr", "seLogRr")])
data$trueRr <- exp(data$trueLogRr)
data$logLb <- data$logRr - (data$seLogRr * qnorm(0.975))
data$logUb <- data$logRr + (data$seLogRr * qnorm(0.975))
data$covered <- data$trueLogRr >= data$logLb & data$trueLogRr <= data$logUb
aggregate(covered ~ trueRr, data = data, mean)

ingrownNail <- 139099
data <- data[order(data$trueRr), ]
data$rr <- exp(data$logRr)
data$lb <- exp(data$logLb)
data$ub <- exp(data$logUb)
round(data[data$oldOutcomeId == ingrownNail, c("trueRr", "rr", "lb", "ub")],2)

###########################################################################
# P-value calibration                                                     #
###########################################################################
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

###########################################################################
# CI calibration                                                          #
###########################################################################
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
                                   calibrated$comparatorId == comparatorId, c("outcomeId", "calRr", "calCi95lb", "calCi95ub", "logRr", "seLogRr")])
data$trueRr <- exp(data$trueLogRr)
data$covered <- data$trueRr >= data$calCi95lb & data$trueRr <= data$calCi95ub
aggregate(covered ~ trueRr, data = data, mean)

ingrownNail <- 139099
data[data$outcomeId == ingrownNail, ]

model <- EmpiricalCalibration::fitSystematicErrorModel(data$logRr, data$seLogRr, log(data$trueRr))


###########################################################################
# Get estimate for stroke                                                 #
###########################################################################
estimate <- calibrated[calibrated$analysisId == 3 &
                           calibrated$targetId == treatmentId &
                           calibrated$comparatorId == comparatorId &
                           calibrated$outcomeId == 2559, ]
print(estimate)

# Get estimates across databases
dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
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

ggplot2::ggsave(filename = file.path(symposiumFolder, "stroke4Db.png"), width = 5, height = 1.5, dpi = 300)

###########################################################################
# Get estimate for all outcomes                                           #
###########################################################################

pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)
dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
calibrated <- data.frame()
for (db in dbs) {
    temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
    temp$db <- db
    calibrated <- rbind(calibrated, temp)
}

estimate <- calibrated[calibrated$analysisId == 3 &
                           calibrated$targetId == treatmentId &
                           calibrated$comparatorId == comparatorId &
                           calibrated$outcomeId %in% outcomes$cohortDefinitionId, ]
estimate <- merge(estimate, outcomes, by.x = "outcomeId", by.y = "cohortDefinitionId")
# d1 <- data.frame(logRr = estimate$logRr,
#                  seLogRr = estimate$seLogRr,
#                  database = estimate$db,
#                  outcome = estimate$name,
#                  type = "Uncalibrated")
d2 <- data.frame(logRr = estimate$calLogRr,
                 seLogRr = estimate$calSeLogRr,
                 database = estimate$db,
                 outcome = estimate$name,
                 type = "Calibrated")

# d <- rbind(d1, d2)
d <- d2
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
d$outcome <- as.character(d$outcome)
d$outcome[d$outcome == "Ventricular arrhythmia and sudden cardiac death"] <- "Vent. arr. & SCD"
d$outcome[d$outcome == "Suicide and suicidal ideation"] <- "Suicide & SI"
d$outcome[d$outcome == "Gastrointestinal hemhorrage"] <- "GI hemhorrage"
d$outcome[d$outcome == "Acute liver injury"] <- "ALI"
d$outcome[d$outcome == "Acute myocardial infarction"] <- "Acute MI"
d$outcome[d$outcome == "Open-angle glaucoma"] <- "OA glaucoma"
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
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                   axis.ticks = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank(),
                   axis.title.x = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "none",
                   strip.text.y = element_text(size = 9, angle = 0, hjust = 0))

ggplot2::ggsave(filename = file.path(symposiumFolder, "1st11Hois4Db.png"), width = 4.5, height = 6, dpi = 300)

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
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                   axis.ticks = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank(),
                   axis.title.x = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "none",
                   strip.text.y = element_text(size = 9, angle = 0, hjust = 0))

ggplot2::ggsave(filename = file.path(symposiumFolder, "2nd11Hois4Db.png"), width = 4.5, height = 6, dpi = 300)

###########################################################################
# Create big plot with all estimates                                      #
###########################################################################
dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
dbs <- c("MDCD", "MDCR")
calibrated <- data.frame()
for (db in dbs) {
    temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
    temp$db <- db
    calibrated <- rbind(calibrated, temp)
}
pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)


est <- calibrated[calibrated$analysisId == 3 &
                      calibrated$outcomeId %in% outcomes$cohortDefinitionId,]
require(ggplot2)
breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)
ggplot(est, aes(x=calLogRr,y=calSeLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_point(size=1,alpha=0.2, color =rgb(0,0,0,alpha=0.2), shape = 16) +
    geom_hline(yintercept=0) +
    scale_x_continuous("Effect size",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_rect(fill="#FAFAFA", colour = NA),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = themeRA,
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )
ggsave(file.path(symposiumFolder, "All.png"), width=8, height=5, dpi = 500)
nrow(est)
est <- est[!is.na(est$calSeLogRr), ]
mean(est$calCi95lb > 1 | est$calCi95ub < 1)
mean(est$calP < 0.05)

###########################################################################
# Highlight two example                                                   #
###########################################################################
set.seed(0)
workFolders <- c("R:/PopEstDepression_Mdcr", "R:/PopEstDepression_Mdcd")
temp <- read.csv(file.path(workFolders[1], "exposureSummaryFilteredBySize.csv"))
rnd <- est[sample.int(nrow(temp), 2), ]
rnd <- data.frame(tprimeCohortDefinitionId = c(755695129, 725131097),
                  cprimeCohortDefinitionId = c(4327941129, 797617097),
                  outcomeId = c(2820, 2826)) # suicide ideation, constipation

merge(rnd, exposureSummary)[, c("tCohortDefinitionName", "cCohortDefinitionName")]

for (i in 1:length(rnd)){
    print(paste("Target: ", exposureSummary$tCohortDefinitionName[exposureSummary$tprimeCohortDefinitionId == rnd$tprimeCohortDefinitionId[i]]))
    print(paste("Comparator: ", exposureSummary$cCohortDefinitionName[exposureSummary$cprimeCohortDefinitionId == rnd$cprimeCohortDefinitionId[i]]))
    treatmentId <- rnd$tprimeCohortDefinitionId[i]
    comparatorId <- rnd$cprimeCohortDefinitionId[i]
    outcomeId <- rnd$outcomeId[i]
    file.copy(from = file.path(workFolders[i], "figuresAndtables", "ps", paste0("ps_t", treatmentId, "_c", comparatorId, ".png")),
              to = file.path(symposiumFolder, paste0("Ps_example",i,".png")),
              overwrite = TRUE)

    omr <- readRDS(file.path(workFolders[i], "cmOutput", "outcomeModelReference.rds"))

    cohortMethodDataFolder <- omr$cohortMethodDataFolder[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3 & outcomeModelReference$outcomeId == outcomeId]
    strataFile <- outcomeModelReference$strataFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3 & outcomeModelReference$outcomeId == outcomeId]

    cohortMethodDataFolder <- gsub("^[sS]:", "R:", cohortMethodDataFolder)
    strataFile <- gsub("^[sS]:", "R:", strataFile)

    cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)
    strata <- readRDS(strataFile)

    balance <- CohortMethod::computeCovariateBalance(strata, cohortMethodData)

    plotFileName <- file.path(workFolder, "symposium", paste0("balanceScatterPlot_example", i, ".png"))
    CohortMethod::plotCovariateBalanceScatterPlot(balance, fileName = plotFileName)

    file.copy(from = file.path(workFolders[i], "figuresAndtables", "calibration", paste0("negControls_a3_t",treatmentId, "_c", comparatorId, ".png")),
              to = file.path(symposiumFolder, paste0("negControls_example", i, ".png")),
              overwrite = TRUE)

    file.copy(from = file.path(workFolders[i], "figuresAndtables", "controls", paste0("trueAndObs_a3_t",treatmentId, "_c", comparatorId, ".png")),
              to = file.path(symposiumFolder, paste0("trueAndObs_example", i, ".png")),
              overwrite = TRUE)

    file.copy(from = file.path(workFolders[i], "figuresAndtables", "calibration", paste0("trueAndObs_a3_t",treatmentId, "_c", comparatorId, ".png")),
              to = file.path(symposiumFolder, paste0("trueAndObsCali_example", i, ".png")),
              overwrite = TRUE)

    temp <- read.csv(file.path(workFolders[i], "calibratedEstimates.csv"))
    temp <- temp[temp$targetId == treatmentId & temp$comparatorId == comparatorId & temp$analysisId == 3 & temp$outcomeId == outcomeId, c("calRr","calCi95lb","calCi95ub", "calLogRr", "calSeLogRr")]
    print(temp)

    require(ggplot2)
    breaks <- c(0.25,0.5,1,2,4,6,8,10)
    theme <- element_text(colour="#000000", size=12)
    themeRA <- element_text(colour="#000000", size=12,hjust=1)
    themeLA <- element_text(colour="#000000", size=12,hjust=0)
    ggplot(est, aes(x=calLogRr,y=calSeLogRr), environment=environment())+
        geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
        geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
        geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
        geom_point(size=1, alpha=0.2, color =rgb(0,0,0,alpha=0.2), shape = 16) +
        geom_point(size=4, fill = rgb(1, 1, 0), shape = 23, data = temp) +
        geom_hline(yintercept=0) +
        scale_x_continuous("Effect size",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
        scale_y_continuous("Standard Error",limits = c(0,1)) +
        theme(
            panel.grid.minor = element_blank(),
            panel.background= element_rect(fill="#FAFAFA", colour = NA),
            panel.grid.major= element_blank(),
            axis.ticks = element_blank(),
            axis.text.y = themeRA,
            axis.text.x = theme,
            legend.key= element_blank(),
            strip.text.x = theme,
            strip.background = element_blank(),
            legend.position = "none"
        )
    ggsave(file.path(symposiumFolder, paste0("All_example",i,".png")), width=8, height=5, dpi = 500)
}

###########################################################################
# Overview of PS plots                                                    #
###########################################################################
exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
datas <- list()
for (i in 1:nrow(exposureSummary)) {
    treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    psFileName <- outcomeModelReference$sharedPsFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3][1]
    ps <- readRDS(psFileName)
    if (min(ps$propensityScore) < max(ps$propensityScore)){
        ps <- CohortMethod:::computePreferenceScore(ps)

        d1 <- density(ps$preferenceScore[ps$treatment == 1], from = 0, to = 1, n = 100)
        d0 <- density(ps$preferenceScore[ps$treatment == 0], from = 0, to = 1, n = 100)

        d <- data.frame(x = c(d1$x, d0$x), y = c(d1$y, d0$y), treatment = c(rep(1, length(d1$x)), rep(0, length(d0$x))))
        d$y <- d$y / max(d$y)
        d$treatmentName <- exposureSummary$tCohortDefinitionName[i]
        d$comparatorName <- exposureSummary$cCohortDefinitionName[i]
        datas[[length(datas) + 1]] <- d

        d$x <- 1-d$x
        d$treatment <- 1 - d$treatment
        d$treatmentName <- exposureSummary$cCohortDefinitionName[i]
        d$comparatorName <- exposureSummary$tCohortDefinitionName[i]
        datas[[length(datas) + 1]] <- d
    }
}
data <- do.call("rbind", datas)
saveRDS(data, file.path(symposiumFolder, "ps.rds"))
#data <- ps
data$GROUP <- "Target"
data$GROUP[data$treatment == 0] <- "Comparator"
data$GROUP <- factor(data$GROUP, levels = c("Target", "Comparator"))
library(ggplot2)
ggplot(data, aes(x = x, y = y, color = GROUP, group = GROUP, fill = GROUP)) +
    geom_density(stat = "identity") +
    scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_x_continuous("Preference score", limits = c(0, 1)) +
    scale_y_continuous("Density") +
    facet_grid(treatmentName~comparatorName) +
    theme(legend.title = element_blank(),
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          strip.text.y = element_text(size = 8, angle = 0),
          panel.margin = unit(0.1, "lines"),
          legend.position="none")
ggsave(filename = file.path(symposiumFolder, "allPs.png"), width = 15, height = 9, dpi = 300)




###########################################################################
# Example error distribution plots                                        #
###########################################################################


require(ggplot2)
x <- seq(from = 0.25, to = 10, by = 0.01)
y <- dnorm(log(x), mean = log(1.5), sd = 0.25)
d <- data.frame(x = x,
                logX = log(x),
                y = y)

breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)
ggplot(d, aes(x=logX,y=y), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_density(stat = "identity", color = rgb(0, 0, 0.8), fill = rgb(0, 0, 0.8, alpha = 0.5)) +
    geom_hline(yintercept=0) +
    geom_vline(xintercept=0) +
    scale_x_continuous("Effect size",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_rect(fill="#FAFAFA", colour = NA),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )
ggsave(file.path(symposiumFolder, "ErrorDistExample1.png"), width=5, height=2, dpi = 500)

y <- dnorm(log(x), mean = log(2.5), sd = 0.35)
d <- data.frame(x = x,
                logX = log(x),
                y = y)

breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)
ggplot(d, aes(x=logX,y=y), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_density(stat = "identity", color = rgb(0, 0, 0.8), fill = rgb(0, 0, 0.8, alpha = 0.5)) +
    geom_hline(yintercept=0) +
    geom_vline(xintercept=log(2)) +
    scale_x_continuous("Effect size",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_rect(fill="#FAFAFA", colour = NA),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )
ggsave(file.path(symposiumFolder, "ErrorDistExample2.png"), width=5, height=2, dpi = 500)
