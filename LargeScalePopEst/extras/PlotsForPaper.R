workFolder <- "R:/PopEstDepression_Ccae"

paperFolder <- file.path(workFolder, "paper")
if (!file.exists(paperFolder)) {
    dir.create(paperFolder)
}

# Plot evaluation ---------------------------------------------------------
calibrated <- read.csv("r:/DepressionResults.csv")

source("extras/SharedPlots.R")
d <- calibrated[calibrated$analysisId == 3 & !is.na(calibrated$trueRr), ]
d <- data.frame(trueRr = d$trueRr,
                logRr = d$logRr,
                ci95lb = d$ci95lb,
                ci95ub = d$ci95ub,
                seLogRr = d$seLogRr)
plotScatter(d)
ggsave(file.path(paperFolder, "Eval.png"), width = 13.5, height = 3, dpi = 500)



# Plot calibration --------------------------------------------------------

calibrated <- read.csv("r:/DepressionResults.csv")

source("extras/SharedPlots.R")
d <- calibrated[calibrated$analysisId == 3 & !is.na(calibrated$trueRr), ]
d <- data.frame(trueRr = d$trueRr,
                logRr = d$calLogRr,
                ci95lb = d$calCi95lb,
                ci95ub = d$calCi95ub,
                seLogRr = d$calSeLogRr)
plotScatter(d)
ggsave(file.path(paperFolder, "EvalCal.png"), width = 13.5, height = 3, dpi = 500)

# Plot results for literature and our depression study ---------------------------------------------

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

pmids <- read.csv("C:/home/Research/PublicationBias/Pmids_main.txt")
writeLines(paste("Total number of hits on query: ", nrow(pmids)))

writeLines(paste("Total number of estimates: ", nrow(d2)))
writeLines(paste("Total number of abstracts: ", length(unique(d2$PMID))))

writeLines(paste("Total estimates  for our results: ", nrow(d1)))
writeLines(paste("Total estimates significant for our results: ", sum(d1$Significant, na.rm = TRUE)))
writeLines(paste("Total significant expected when null is true for all: ", nrow(d1)*0.05))

d <- rbind(data.frame(logRr = d1$calLogRr,
                      seLogRr = d1$calSeLogRr,
                      Group = "C\nOur large-scale study on depression treatments",
                      Significant = d1$Significant),
           data.frame(logRr = log(d2$EffectEstimate_jitter),
                      seLogRr = d2$seLogRr,
                      Group = "A\nAll observational literature",
                      Significant = d2$Significant),
           data.frame(logRr = log(d3$EffectEstimate_jitter),
                      seLogRr = d3$seLogRr,
                      Group = "B\nObservational literature on depression treatments",
                      Significant = d3$Significant))

d$Group <- factor(d$Group, levels = c("A\nAll observational literature", "B\nObservational literature on depression treatments", "C\nOur large-scale study on depression treatments"))

temp1 <- aggregate(Significant ~ Group, data = d, length)
temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
temp1$Significant <- NULL
temp2 <- aggregate(Significant ~ Group, data = d, mean)
temp2$meanLabel <- paste0(formatC(100 * (1-temp2$Significant), digits = 1, format = "f"), "% of CIs include 1")
temp2$Significant <- NULL
dd <- merge(temp1, temp2)

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- element_text(colour = "#000000", size = 12)
themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)

ggplot(d, aes(x=logRr, y=seLogRr, alpha = Group), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_point(size=0.5, color = rgb(0,0,0), shape = 16) +
    geom_hline(yintercept=0) +
    geom_label(x = log(0.3), y = 1, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd) +
    geom_label(x = log(0.3), y = 0.9, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = dd) +
    scale_x_continuous("Effect size",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    scale_alpha_manual(values = c(0.1, 0.8, 0.2)) +
    facet_grid(.~Group) +
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

ggsave(file.path(paperFolder, "LitVsUs.png"), width = 14, height = 3.75, dpi = 500)



# Treatment dendogram -----------------------------------------------------

library(meta)
library(ggplot2)
library(ggdendro)

calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$analysisId == 3 & calibrated$outcomeType == "hoi", ]

names <- as.character(unique(d$targetName))
names <- names[names != "Electroconvulsive therapy"]
names <- names[order(names)]
m <- combn(names, 2)
m <- data.frame(cohortName1 = m[1, ],
                cohortName2 = m[2, ],
                stringsAsFactors = FALSE)

computeDistance <- function(i, m, d) {
    subset <- d[(d$targetName ==  m$cohortName1[i] & d$comparatorName ==  m$cohortName2[i]) |
                    (d$targetName ==  m$cohortName2[i] & d$comparatorName ==  m$cohortName1[i]),
                c("calLogRr", "calSeLogRr")]
    if (nrow(subset) == 0)
        return(NA)
    subset <- subset[!is.na(subset$calSeLogRr), ]
    meta <- metagen(subset$calLogRr, subset$calSeLogRr, sm = "RR")
    return(meta$tau)
}

m$distance <- sapply(1:nrow(m), computeDistance, m, d)
m <- m[order(m$cohortName1, m$cohortName2), ]
d1 <- m$distance
attr(d1, "Size") <- length(names)
attr(d1, "Labels") <- names
attr(d1, "Diag") <- FALSE
attr(d1, "Upper") <- TRUE
attr(d1, "method") <- "binary"
class(d1) <- "dist"

model <- hclust(d1, method = "ward.D2")
dhc <- as.dendrogram(model)
ddata <- dendro_data(dhc, type = "rectangle")
pathToCsv <- system.file("settings", "ExposuresOfInterest.csv", package = "LargeScalePopEst")
exposuresOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
classes <- merge(ddata$labels, exposuresOfInterest, by.x = "label", by.y = "name")

ggplot(segment(ddata)) +
    geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) +
    geom_text(data = ddata$labels,
              aes(x = x, y = y-0.01, label = label), size = 3, hjust = 0) +
    geom_point(data = classes,
               aes(x = x, y = y, shape = class, color = class, fill = class), size = 2) +
    coord_flip() +
    scale_y_reverse(expand = c(0.2, 0)) +
    scale_shape_manual(values = c(21, 22, 23, 24, 25,26)) +
    theme_dendro()
ggsave("r:/temp/Dendo.png", width = 7, height = 4, dpi = 300)

# Within versus between class ---------------------------------------------

library(meta)
library(ggplot2)

calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$analysisId == 3 & calibrated$outcomeType == "hoi", ]

pathToCsv <- system.file("settings", "ExposuresOfInterest.csv", package = "LargeScalePopEst")
eoi <- read.csv(pathToCsv, stringsAsFactors = FALSE)
eoi <- eoi[eoi$class %in% c("TCA", "SSRI", "SNRI"), ]
d <- merge(d, data.frame(targetName = eoi$name, targetClass = eoi$class))
d <- merge(d, data.frame(comparatorName = eoi$name, comparatorClass = eoi$class))

names <- as.character(unique(d$targetClass))
names <- names[order(names)]
m <- combn(names, 2)
m <- data.frame(class1 = c(m[1, ], names),
                class2 = c(m[2, ], names),
                stringsAsFactors = FALSE)

computeDistance <- function(i, m, d) {
    subset <- d[(d$targetClass ==  m$class1[i] & d$comparatorClass ==  m$class2[i]) |
                    (d$targetClass ==  m$class2[i] & d$comparatorClass ==  m$class1[i]),]

    subset <- subset[!is.na(subset$calSeLogRr), ]

    # meta <- metagen(subset$calLogRr, subset$calSeLogRr, sm = "RR")
    # return(meta$tau)

    sign <- subset$calCi95lb > 1 | subset$calCi95ub < 1
    return(sum(sign) / length(sign))
}

m$distance <- sapply(1:nrow(m), computeDistance, m, d)

mSym <- rbind(m, data.frame(class1 = m$class2, class2 = m$class1, distance = m$distance))
ggplot(mSym, aes(class1, class2)) +
    geom_tile(aes(fill = distance), colour = "white") +
    geom_text(aes(label = formatC(distance, digits = 2,format = "f" )), size = 3) +
    scale_fill_gradient(low = "white", high = "red") +
    theme(plot.background = element_blank(),
          panel.background = element_blank(),
          axis.title = element_blank(),
          legend.position = "none")

ggsave(file.path(paperFolder, "ClassSim.png"), width = 2, height = 2, dpi = 300)


# Transitivity (significance) ------------------------------------------------------------

calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$analysisId == 3 & calibrated$outcomeType == "hoi", ]
d <- d[!is.na(d$calRr), ]
d$sign <- d$calCi95lb > 1 | d$calCi95ub < 1
sign <- d[d$sign, ]
ab <- data.frame(nameA = sign$targetName,
                 nameB = sign$comparatorName,
                 outcome = sign$outcomeName,
                 db = sign$db,
                 increase = sign$calRr > 1,
                 rrAB = sign$calRr,
                 lbAB = sign$calCi95lb,
                 ubAB = sign$calCi95ub)
bc <- data.frame(nameB = sign$targetName,
                 nameC = sign$comparatorName,
                 outcome = sign$outcomeName,
                 db = sign$db,
                 increase = sign$calRr > 1,
                 rrBC = sign$calRr,
                 lbBC = sign$calCi95lb,
                 ubBC = sign$calCi95ub)
abc <- merge(ab, bc)
ac <- data.frame(nameA = d$targetName,
                 nameC = d$comparatorName,
                 outcome = d$outcomeName,
                 db = d$db,
                 rrAC = d$calRr,
                 lbAC = d$calCi95lb,
                 ubAC = d$calCi95ub)
abcPlusAc <- merge(abc, ac)

agree <- (abcPlusAc$increase & abcPlusAc$lbAC > 1) | (!abcPlusAc$increase & abcPlusAc$ubAC < 1)
mean(agree)
length(agree)
sum(agree)
expected <- 2 * 0.025 * 0.025 * 180852


# Transitivity (estimate) -------------------------------------------------

calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$analysisId == 3 & calibrated$outcomeType == "hoi", ]
d <- d[!is.na(d$calRr), ]

ab <- data.frame(nameA = d$targetName,
                 nameB = d$comparatorName,
                 outcome = d$outcomeName,
                 db = d$db,
                 rrAB = d$calRr,
                 lbAB = d$calCi95lb,
                 ubAB = d$calCi95ub,
                 seLogRrAB = d$calSeLogRr)
bc <- data.frame(nameB = d$targetName,
                 nameC = d$comparatorName,
                 outcome = d$outcomeName,
                 db = d$db,
                 rrBC = d$calRr,
                 lbBC = d$calCi95lb,
                 ubBC = d$calCi95ub,
                 seLogRrBC = d$calSeLogRr)
abc <- merge(ab, bc)
abc$rrACInferred <- abc$rrAB * abc$rrBC
abc$seLogRrACInferred <- sqrt(abc$seLogRrAB^2 + abc$seLogRrBC^2)
abc$lbACInferred <- exp(log(abc$rrACInferred) + qnorm(0.025) * abc$seLogRrACInferred)
abc$ubACInferred <- exp(log(abc$rrACInferred) + qnorm(0.975) * abc$seLogRrACInferred)
ac <- data.frame(nameA = d$targetName,
                 nameC = d$comparatorName,
                 outcome = d$outcomeName,
                 db = d$db,
                 rrAC = d$calRr,
                 lbAC = d$calCi95lb,
                 ubAC = d$calCi95ub,
                 seLogRrAC = d$calSeLogRr)
abcPlusAc <- merge(abc, ac)
z <- (log(abcPlusAc$rrAC) - log(abcPlusAc$rrACInferred)) / sqrt(abcPlusAc$seLogRrAC^2 + abcPlusAc$seLogRrACInferred^2)
diff <- abs(z) > qnorm(0.975)
mean(diff)


# P-value calibration effect ------------------------------------------------------

calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$outcomeType == "hoi" | calibrated$outcomeType == "negative control", ]
d <- d[!is.na(d$calP), ]
d$sign <- d$p < 0.05
d$calSign <- d$calP < 0.05
dUncal <- aggregate(sign ~ outcomeType + analysisId, data = d, mean)
dUncal$estimateType <- "Uncalibrated"
dCal <- aggregate(calSign ~ outcomeType + analysisId, data = d, mean)
names(dCal)[names(dCal) == "calSign"] <- "sign"
dCal$estimateType <- "Calibrated"

dd <- rbind(dUncal, dCal)
dd$analysis <- "Crude"
dd$analysis[dd$analysisId == 3] <- "Adjusted"
dd$analysis <- factor(dd$analysis, levels = c("Crude", "Adjusted"))
dd$estimateType <- factor(dd$estimateType, levels = c("Uncalibrated", "Calibrated"))
dd$outcome <- "Negative controls"
dd$outcome[dd$outcomeType == "hoi"] <- "Outcomes of interest"
dd$label <- paste0(formatC(dd$sign*100, digits = 1,format = "f" ),"%")
dd$textY <- dd$sign
dd$textY[dd$outcome == "Negative controls" & dd$estimateType == "Calibrated" & dd$analysis == "Crude"] <- 0.04
dd$textY[dd$outcome == "Negative controls" & dd$estimateType == "Calibrated" & dd$analysis == "Adjusted"] <- 0.06
library(ggplot2)
breaks <- c(0.05, 0.1, 0.2, 0.3, 0.4)
labels <- paste0(breaks*100, "%")
ggplot(dd, aes(x = estimateType, y = sign, color = analysis, group = analysis, shape = analysis, fill = analysis)) +
    geom_hline(yintercept = 0.05, linetype = "dashed") +
    geom_line(alpha = 0.6) +
    geom_point(alpha = 0.6) +
    geom_text(data = dd[dd$estimateType == "Uncalibrated",], aes(label = label, y = textY), hjust = 1, nudge_x = -0.1, show.legend = FALSE) +
    geom_text(data = dd[dd$estimateType == "Calibrated",], aes(label = label, y = textY), hjust = 0, nudge_x = 0.1, show.legend = FALSE) +
    scale_y_continuous("Percent significant", breaks = breaks, labels = labels) +
    scale_color_manual(values = c(rgb(0.8,0,0), rgb(0,0,0.8))) +
    scale_fill_manual(values = c(rgb(0.8,0,0), rgb(0,0,0.8))) +
    facet_wrap(~outcome) +
    theme(axis.title.x = element_blank(),
          panel.background = element_blank(),
          panel.grid.major.y = element_line(color = rgb(0.25,0.25,0.25, alpha = 0.2)),
          panel.grid.major.x = element_blank())

ggsave("r:/temp/RCali.png", width = 6, height = 3, dpi=300)


# Between database heterogeneity ------------------------------------------

library(meta)
library(ggplot2)
calibrated <- read.csv("r:/DepressionResults.csv")
d <- calibrated[calibrated$outcomeType == "hoi" & calibrated$analysisId == 3, ]
dd <- aggregate(calLogRr ~ targetName + comparatorName + outcomeName, data = d, length)
dd <- dd[dd$calLogRr == 4, ]
dd$calLogRr <- NULL
nrow(dd)

computeI2 <- function(i, dd, d, calibrated = TRUE) {
    triplet <- dd[i,]
    studies <- d[d$targetName == triplet$targetName & d$comparatorName == triplet$comparatorName & d$outcomeName == triplet$outcomeName, ]
    if (calibrated) {
        meta <- metagen(studies$calLogRr, studies$calSeLogRr, sm = "RR")
    } else {
        meta <- metagen(studies$logRr, studies$seLogRr, sm = "RR")
    }
    return( meta$I2)
    #forest(meta)
}

i2Cal <- sapply(1:nrow(dd), computeI2, dd = dd, d = d, calibrated = TRUE)
i2 <- sapply(1:nrow(dd), computeI2, dd = dd, d = d, calibrated = FALSE)

ddd <- data.frame(i2 = c(i2, i2Cal),
                  group = c(rep("Uncalibrated", length(i2)), rep("Calibrated", length(i2Cal))))

# ggplot(ddd, aes(x=i2, group = group, color = group, fill = group)) +
#     geom_density() +
#     scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
#     scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
#     theme(legend.title = ggplot2::element_blank())

ggplot(ddd, aes(x=i2, group = group, color = group, fill = group)) +
    geom_histogram(binwidth = 0.05, boundary = 0, position = "identity") +
    scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_x_continuous(expression(i^2)) +
    scale_y_continuous("Target - comparator - outcome triplets") +
    theme(legend.title = ggplot2::element_blank(),
          panel.background = element_blank(),
          panel.grid.major.y = element_line(color = rgb(0.25,0.25,0.25, alpha = 0.2)),
          panel.grid.major.x = element_line(color = rgb(0.25,0.25,0.25, alpha = 0.2)))

ggsave(file.path(paperFolder, "I2.png"), width = 6, height = 3, dpi=300)

mean(i2Cal < 0.25)
mean(i2 <0.25)



# Exemplar study: duloxetine vs sertraline for stroke in CCAE -------------

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

########################################################################### Get PS plot #
psFile <- outcomeModelReference$sharedPsFile[outcomeModelReference$analysisId == 3 & outcomeModelReference$targetId ==
                                                 treatmentId & outcomeModelReference$comparatorId == comparatorId][1]
ps <- readRDS(psFile)
fileName <- file.path(paperFolder, "PsExamplar.png")
CohortMethod::plotPs(ps,
                     scale = "preference",
                     treatmentLabel = "Duloxetine",
                     comparatorLabel = "Sertraline",
                     fileName = fileName)

########################################################################### Create covariate balance plot #
cohortMethodDataFolder <- outcomeModelReference$cohortMethodDataFolder[outcomeModelReference$targetId ==
                                                                           treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId ==
                                                                           3 & outcomeModelReference$outcomeId == 2559]
strataFile <- outcomeModelReference$strataFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId ==
                                                   comparatorId & outcomeModelReference$analysisId == 3 & outcomeModelReference$outcomeId == 2559]

cohortMethodDataFolder <- gsub("^S:", "R:", cohortMethodDataFolder)
strataFile <- gsub("^S:", "R:", strataFile)
cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)
strata <- readRDS(strataFile)
balance <- CohortMethod::computeCovariateBalance(strata, cohortMethodData)
nrow(balance)
tableFileName <- file.path(paperFolder, "balance.csv")
write.csv(balance, tableFileName, row.names = FALSE)

plotFileName <- file.path(paperFolder, "balanceScatterPlot.png")
balance$beforeMatchingStdDiff <- abs(balance$beforeMatchingStdDiff)
balance$afterMatchingStdDiff <- abs(balance$afterMatchingStdDiff)
limits <- c(min(c(balance$beforeMatchingStdDiff, balance$afterMatchingStdDiff), na.rm = TRUE),
            max(c(balance$beforeMatchingStdDiff, balance$afterMatchingStdDiff), na.rm = TRUE))
plot <- ggplot2::ggplot(balance,
                        ggplot2::aes(x = beforeMatchingStdDiff, y = afterMatchingStdDiff)) +
    ggplot2::geom_point(color = rgb(0, 0, 0.8, alpha = 0.3)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_vline(xintercept = 0) +
    #ggplot2::ggtitle("Standardized difference of mean") +
    ggplot2::scale_x_continuous("Before stratification", limits = limits) +
    ggplot2::scale_y_continuous("After stratification", limits = limits)

plot <- plot + ggplot2::geom_hline(yintercept = 0.1, alpha = 0.5, linetype = "dotted")

ggplot2::ggsave(plotFileName, plot, width = 4, height = 4, dpi = 400)


###################################################################### Get signal injection and calibration plots #

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              oldOutcomeId = injectedSignals$outcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
# negativeControlIdSubsets <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId &
#                                                                     signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIds,
                               oldOutcomeId = negativeControlIds,
                               trueLogRr = 0)

source("extras/SharedPlots.R")

d <- rbind(injectedSignals, negativeControls)
d <- merge(d, estimates[estimates$analysisId == 3, ])
d$trueRr <- exp(d$trueLogRr)
plotScatter(d)
ggsave(file.path(paperFolder, "exemplarEval.png"), width = 13.5, height = 3, dpi = 500)

d <- rbind(injectedSignals, negativeControls)
d <- merge(d, estimates[estimates$analysisId == 3, ])
d$logRr <- d$calLogRr
d$seLogRr <- d$calSeLogRr
d$ci95lb <- d$calCi95lb
d$ci95ub <- d$calCi95ub
d$trueRr <- exp(d$trueLogRr)
d$Group <- as.factor(d$trueRr)
plotScatter(d)
ggsave(file.path(paperFolder, "exemplarCalibration.png"), width = 13.5, height = 3, dpi = 500)

calibrated[calibrated$outcomeId == 2559 & calibrated$db == "CCAE",]






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
round(data[data$oldOutcomeId == ingrownNail, c("trueRr", "rr", "lb", "ub")], 2)

########################################################################### P-value calibration #
file.copy(from = file.path(workFolder,
                           "figuresAndtables",
                           "calibration",
                           paste0("negControls_a3_t", treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "pCalEffectPlot.png"),
          overwrite = TRUE)

negControls <- estimates[estimates$outcomeId %in% negativeControlIds & estimates$analysisId == 3, ]
EmpiricalCalibration::plotCalibration(logRr = negControls$logRr,
                                      seLogRr = negControls$seLogRr,
                                      useMcmc = TRUE)
writeLines(paste0("Adjusted negative control p < 0.05: ", mean(negControls$p < 0.05)))

negControls <- calibrated[calibrated$analysisId == 3 & calibrated$targetId == treatmentId & calibrated$comparatorId ==
                              comparatorId & calibrated$outcomeId %in% negativeControlIds, ]
writeLines(paste0("Calibrated negative control p < 0.05: ", mean(negControls$calP < 0.05)))

########################################################################### CI calibration #
file.copy(from = file.path(workFolder,
                           "figuresAndtables",
                           "calibration",
                           paste0("trueAndObs_a3_t", treatmentId, "_c", comparatorId, ".png")),
          to = file.path(symposiumFolder, "trueAndObsCali.png"),
          overwrite = TRUE)

injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == row$tCohortDefinitionId, ]
injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                              trueLogRr = log(injectedSignals$targetEffectSize))
negativeControlIdSubsets <- unique(signalInjectionSum$outcomeId[signalInjectionSum$exposureId == row$tCohortDefinitionId &
                                                                    signalInjectionSum$injectedOutcomes != 0])
negativeControls <- data.frame(outcomeId = negativeControlIdSubsets, trueLogRr = 0)
data <- rbind(injectedSignals, negativeControls)
data <- merge(data,
              calibrated[calibrated$analysisId == 3 & calibrated$targetId == treatmentId & calibrated$comparatorId ==
                             comparatorId, c("outcomeId", "calRr", "calCi95lb", "calCi95ub", "logRr", "seLogRr")])
data$trueRr <- exp(data$trueLogRr)
data$covered <- data$trueRr >= data$calCi95lb & data$trueRr <= data$calCi95ub
aggregate(covered ~ trueRr, data = data, mean)

ingrownNail <- 139099
data[data$outcomeId == ingrownNail, ]

model <- EmpiricalCalibration::fitSystematicErrorModel(data$logRr, data$seLogRr, log(data$trueRr))

















### Fit mixture model ###

fitMix <- function(logRr, seLogRr) {
    if (any(is.infinite(seLogRr))) {
        warning("Estimate(s) with infinite standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.infinite(seLogRr)]
        seLogRr <- seLogRr[!is.infinite(seLogRr)]
    }
    if (any(is.infinite(logRr))) {
        warning("Estimate(s) with infinite logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.infinite(logRr)]
        logRr <- logRr[!is.infinite(logRr)]
    }
    if (any(is.na(seLogRr))) {
        warning("Estimate(s) with NA standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.na(seLogRr)]
        seLogRr <- seLogRr[!is.na(seLogRr)]
    }
    if (any(is.na(logRr))) {
        warning("Estimate(s) with NA logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.na(logRr)]
        logRr <- logRr[!is.na(logRr)]
    }

    gaussianProduct <- function(mu1, mu2, sd1, sd2) {
        (2 * pi)^(-1/2) * (sd1^2 + sd2^2)^(-1/2) * exp(-(mu1 - mu2)^2/(2 * (sd1^2 + sd2^2)))
    }

    # Use logit function to prevent mixture fraction from straying from [0,1]
    link <- function(x) {
        return(exp(x)/(exp(x) + 1))
    }

    LL <- function(theta, estimate, se) {
        result <- 0
        for (i in 1:length(estimate)) {
            result <- result - log(link(theta[1]) * gaussianProduct(estimate[i],
                                                                    theta[2],
                                                                    se[i],
                                                                    exp(theta[3])) + (1 - link(theta[1])) * gaussianProduct(estimate[i],
                                                                                                                            theta[4],
                                                                                                                            se[i],
                                                                                                                            exp(theta[5])))
        }
        if (is.infinite(result))
            result <- 99999
        result
    }
    theta <- c(0, 0, -2, 1, -0.5)
    fit <- optim(theta, LL, estimate = logRr, se = seLogRr)

    result <- data.frame(mix = link(fit$par[1]),
                         mean1 = fit$par[2],
                         sd1 = exp(fit$par[3]),
                         mean2 = fit$par[4],
                         sd2 = exp(fit$par[5]))


    return(result)
}

fitMix(d$logRr, d$seLogRr)


fitMixFix1 <- function(logRr, seLogRr) {
    if (any(is.infinite(seLogRr))) {
        warning("Estimate(s) with infinite standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.infinite(seLogRr)]
        seLogRr <- seLogRr[!is.infinite(seLogRr)]
    }
    if (any(is.infinite(logRr))) {
        warning("Estimate(s) with infinite logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.infinite(logRr)]
        logRr <- logRr[!is.infinite(logRr)]
    }
    if (any(is.na(seLogRr))) {
        warning("Estimate(s) with NA standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.na(seLogRr)]
        seLogRr <- seLogRr[!is.na(seLogRr)]
    }
    if (any(is.na(logRr))) {
        warning("Estimate(s) with NA logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.na(logRr)]
        logRr <- logRr[!is.na(logRr)]
    }

    gaussianProduct <- function(mu1, mu2, sd1, sd2) {
        (2 * pi)^(-1/2) * (sd1^2 + sd2^2)^(-1/2) * exp(-(mu1 - mu2)^2/(2 * (sd1^2 + sd2^2)))
    }

    # Use logit function to prevent mixture fraction from straying from [0,1]
    link <- function(x) {
        return(exp(x)/(exp(x) + 1))
    }

    LL <- function(theta, estimate, se) {
        result <- 0
        for (i in 1:length(estimate)) {
            result <- result - log(link(theta[1]) * dnorm(0,
                                                          mean = estimate[i],
                                                          sd = se[i]) + (1 - link(theta[1])) *
                                       gaussianProduct(estimate[i], theta[2], se[i], exp(theta[3])))
        }
        if (is.infinite(result))
            result <- 99999
        result
    }
    theta <- c(0, 1, -0.5)
    fit <- optim(theta, LL, estimate = logRr, se = seLogRr)

    result <- data.frame(mix = link(fit$par[1]),
                         mean1 = 0,
                         sd1 = 0,
                         mean2 = fit$par[2],
                         sd2 = exp(fit$par[3]))


    return(result)
}

fitMixFix1(d$logRr, d$seLogRr)
