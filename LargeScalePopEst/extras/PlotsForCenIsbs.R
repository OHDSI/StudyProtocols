library(ggplot2)
calibrated <- read.csv("r:/DepressionResults.csv")
d1 <- calibrated[calibrated$analysisId == 3 & calibrated$outcomeType == "hoi", ]
d1$Significant <- d1$calCi95lb > 1 | d1$calCi95ub < 1

d2 <- read.csv("C:/home/Research/PublicationBias/AnalysisJitter.csv")
d2$Significant <-  !(is.na(d2$P.value) | d2$P.value >= 0.05) | !(is.na(d2$CI.LB) |  (d2$CI.LB <= 1 & d2$CI.UB >= 1))
seFromCI <- (log(d2$EffectEstimate_jitter)-log(d2$CI.LB_jitter))/qnorm(0.975)
seFromP <- abs(log(d2$EffectEstimate_jitter)/qnorm(d2$P.value_jitter))
d2$seLogRr <- seFromCI
d2$seLogRr[is.na(d2$seLogRr)] <- seFromP[is.na(d2$seLogRr)]
d2 <- d2[!is.na(d2$seLogRr), ]
d2 <- d2[d2$EffectEstimate_jitter > 0, ]
#d3 <- d2[d2$Depression == 1, ]
d3 <- d2[d2$DepressionTreatment == 1, ]

d <- rbind(data.frame(logRr = d1$calLogRr,
                      seLogRr = d1$calSeLogRr,
                      Group = "A\nOur large-scale study on depression treatments",
                      Significant = d1$Significant,
                      dummy = 1),
           data.frame(logRr = log(d2$EffectEstimate_jitter),
                      seLogRr = d2$seLogRr,
                      Group = "B\nAll observational literature",
                      Significant = d2$Significant,
                      dummy = 1),
           data.frame(logRr = log(d3$EffectEstimate_jitter),
                      seLogRr = d3$seLogRr,
                      Group = "C\nObservational literature on depression treatments",
                      Significant = d3$Significant,
                      dummy = 1))

d$Group <- factor(d$Group, levels = c("A\nOur large-scale study on depression treatments", "B\nAll observational literature", "C\nObservational literature on depression treatments"))

temp1 <- aggregate(dummy ~ Group, data = d, length)
temp1$nLabel <- paste0(formatC(temp1$dummy, big.mark = ","), " estimates")
temp1$dummy <- NULL
temp2 <- aggregate(Significant ~ Group, data = d, mean)
temp2$meanLabel <- paste0(formatC(100 * (1-temp2$Significant), digits = 1, format = "f"), "% of CIs include 1")
temp2$Significant <- NULL
dd <- merge(temp1, temp2)

breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- element_text(colour = "#000000", size = 12)
themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)

createPlot <- function(group, fileName, simplified = FALSE) {
    plot <- ggplot(d[d$Group == group, ], aes(x=logRr, y=seLogRr, alpha = Group), environment=environment())+
        geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
        geom_point(size=0.5, color = rgb(0,0,0), shape = 16) +
        geom_hline(yintercept=0) +
        geom_label(x = log(0.11), y = 0.99, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd[dd$Group == group, ]) +
        scale_x_continuous("Effect size",limits = log(c(0.1,10)), breaks=log(breaks),labels=breaks) +
        scale_y_continuous("Standard Error",limits = c(0,1)) +
        scale_alpha_manual(values = c(0.8, 0.8, 0.8)) +
        theme(
            panel.grid.minor = element_blank(),
            panel.background= element_blank(),
            panel.grid.major= element_blank(),
            axis.ticks = element_blank(),
            axis.text.y = themeRA,
            axis.text.x = theme,
            legend.key= element_blank(),
            strip.text.x = theme,
            strip.text.y = theme,
            strip.background = element_blank(),
            legend.position = "none"
        )

    if (!simplified) {
        plot <- plot +         geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
            geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
            geom_label(x = log(0.11), y = 0.99, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd[dd$Group == group, ]) +
            geom_label(x = log(0.11), y = 0.88, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = dd[dd$Group == group, ])
    }
    ggsave(plot = plot, fileName, width = 8, height = 4.5, dpi = 500)
}
createPlot("B\nAll observational literature", "s:/temp/lit1.png", TRUE)
createPlot("B\nAll observational literature", "s:/temp/lit2.png")
createPlot("A\nOur large-scale study on depression treatments", "s:/temp/us.png")
createPlot("C\nObservational literature on depression treatments", "s:/temp/litDep.png")



# Evaluation and calibration plots ----------------------------------------
workFolder <- "R:/PopEstDepression_Ccae"
exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
analysesSum <- read.csv(file.path(workFolder, "analysisSummary.csv"))
signalInjectionSum <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
negativeControlIds <- unique(signalInjectionSum$outcomeId)

row <- exposureSummary[exposureSummary$tCohortDefinitionName == "duloxetine" & exposureSummary$cCohortDefinitionName == "Sertraline", ]
treatmentId <- row$tprimeCohortDefinitionId
comparatorId <- row$cprimeCohortDefinitionId
estimates <- analysesSum[analysesSum$targetId == treatmentId & analysesSum$comparatorId == comparatorId, ]
calibrated <- read.csv(file.path(workFolder, "calibratedEstimates.csv"))
calibrated <- calibrated[calibrated$analysisId == 3 & calibrated$targetId == treatmentId & calibrated$comparatorId == comparatorId, ]

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              oldOutcomeId = injectedSignals$outcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControls <- data.frame(outcomeId = negativeControlIds,
                               oldOutcomeId = negativeControlIds,
                               trueLogRr = 0)

source("extras/SharedPlots.R")

d1 <- rbind(injectedSignals, negativeControls)
d1 <- merge(d1, estimates[estimates$analysisId == 3, ])
d1$trueRr <- exp(d1$trueLogRr)
d1$yGroup <- "Uncalibrated"

d2 <- rbind(injectedSignals, negativeControls)
d2 <- merge(d2, calibrated[calibrated$analysisId == 3, ])
d2$logRr <- d2$calLogRr
d2$seLogRr <- d2$calSeLogRr
d2$ci95lb <- d2$calCi95lb
d2$ci95ub <- d2$calCi95ub
d2$trueRr <- exp(d2$trueLogRr)
d2$Group <- as.factor(d2$trueRr)
d2$yGroup <- "Calibrated"
d <- rbind(d1[, c("logRr", "seLogRr", "ci95lb", "ci95ub", "yGroup", "trueRr")],
           d2[, c("logRr", "seLogRr", "ci95lb", "ci95ub", "yGroup", "trueRr")])
d$yGroup <- factor(d$yGroup, levels = c("Uncalibrated", "Calibrated"))
plotScatter(d[d$yGroup == "Uncalibrated", ], yPanelGroup = FALSE)
ggsave("s:/temp/eval.png", width = 13.5, height = 2.5, dpi = 500)
plotScatter(d[d$yGroup == "Calibrated", ], yPanelGroup = FALSE)
ggsave("s:/temp/cali.png", width = 13.5, height = 2.5, dpi = 500)





