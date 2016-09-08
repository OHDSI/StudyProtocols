workFolder <- "S:/PopEstDepression_Mdcd"

exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))


row <- exposureSummary[exposureSummary$tCohortDefinitionName == "duloxetine" & exposureSummary$cCohortDefinitionName == "Sertraline",]

treatmentId <- row$tprimeCohortDefinitionId
comparatorId <- row$cprimeCohortDefinitionId
psFileName <- outcomeModelReference$sharedPsFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3][1]
ps <- readRDS(psFileName)

plotFileName <- file.path(workFolder, "symposium", "ps.png")
CohortMethod::plotPs(ps,
                     treatmentLabel = as.character(row$tCohortDefinitionName),
                     comparatorLabel = as.character(row$cCohortDefinitionName),
                     fileName = plotFileName)

# Bias plots
plotEstimates <- function (logRrNegatives, seLogRrNegatives, xLabel = "Relative risk", fileName = NULL) {

    x <- exp(seq(log(0.25), log(10), by = 0.01))
    seTheoretical <- sapply(x, FUN = function(x) {
        abs(log(x))/qnorm(0.975)
    })
    breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
    theme <- ggplot2::element_text(colour = "#000000", size = 12)
    themeRA <- ggplot2::element_text(colour = "#000000", size = 12,
                                     hjust = 1)
    plot <- ggplot2::ggplot(data.frame(x, seTheoretical), ggplot2::aes(x = x, y = seTheoretical), environment = environment()) +
        ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
        ggplot2::geom_vline(xintercept = 1, size = 1) +
        ggplot2::geom_area(fill = rgb(0, 0, 0), colour = rgb(0, 0, 0, alpha = 0.1), alpha = 0.1) +
        ggplot2::geom_line(colour = rgb(0, 0, 0), linetype = "dashed", size = 1, alpha = 0.5) +
        ggplot2::geom_point(shape = 21, ggplot2::aes(x, y), data = data.frame(x = exp(logRrNegatives), y = seLogRrNegatives), size = 2, fill = rgb(0, 0, 1, alpha = 0.5), colour = rgb(0, 0, 0.8)) +
        ggplot2::geom_hline(yintercept = 0) +
        ggplot2::scale_x_continuous(xLabel, trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
        ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
        ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                       panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA), panel.grid.major = ggplot2::element_blank(),
                       axis.ticks = ggplot2::element_blank(), axis.text.y = themeRA,
                       axis.text.x = theme, legend.key = ggplot2::element_blank(),
                       strip.text.x = theme, strip.background = ggplot2::element_blank(),
                       legend.position = "none")
    if (!is.null(fileName))
        ggplot2::ggsave(fileName, plot, width = 6, height = 4.5,
                        dpi = 400)
    return(plot)
}

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
