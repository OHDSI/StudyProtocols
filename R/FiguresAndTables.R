# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Analyse propensity score distributions
#'
#' @details
#' This function plots all propensity score distributions, and computes AUC
#' and equipoise for every exposure pair.
#'
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
analysePsDistributions <- function(workFolder) {
    writeLines("Plotting propensity score distributions")
    figuresAndTablesFolder <- file.path(workFolder, "figuresAndtables")
    if (!file.exists(figuresAndTablesFolder)) {
        dir.create(figuresAndTablesFolder)
    }
    psResultsFolder <- file.path(figuresAndTablesFolder, "ps")
    if (!file.exists(psResultsFolder)) {
        dir.create(psResultsFolder)
    }

    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
    matrix1 <- data.frame(cohortId1 = exposureSummary$tprimeCohortDefinitionId,
                          cohortName1 = exposureSummary$tCohortDefinitionName,
                          cohortId2 = exposureSummary$cprimeCohortDefinitionId,
                          cohortName2 = exposureSummary$cCohortDefinitionName,
                          equipoise = 0,
                          auc = 1)
    matrix2 <- data.frame(cohortId1 = exposureSummary$cprimeCohortDefinitionId,
                          cohortName1 = exposureSummary$cCohortDefinitionName,
                          cohortId2 = exposureSummary$tprimeCohortDefinitionId,
                          cohortName2 = exposureSummary$tCohortDefinitionName,
                          equipoise = 0,
                          auc = 1)
    matrix <- rbind(matrix1, matrix2)
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        psFileName <- outcomeModelReference$sharedPsFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 3][1]
        ### REMOVE THIS ###
        psFileName <- gsub("^s:", "R:", psFileName)
        if (file.exists(psFileName)){
            ps <- readRDS(psFileName)

            plotFileName <- file.path(psResultsFolder, paste0("ps_t", treatmentId, "_c", comparatorId, ".png"))
            CohortMethod::plotPs(ps,
                                 treatmentLabel = as.character(exposureSummary$tCohortDefinitionName[i]),
                                 comparatorLabel = as.character(exposureSummary$cCohortDefinitionName[i]),
                                 fileName = plotFileName)

            ps$treatment <- 1 - ps$treatment
            ps$propensityScore <- 1 - ps$propensityScore
            plotFileName <- file.path(psResultsFolder, paste0("ps_t", comparatorId, "_c", treatmentId, ".png"))
            CohortMethod::plotPs(ps,
                                 treatmentLabel = as.character(exposureSummary$cCohortDefinitionName[i]),
                                 comparatorLabel = as.character(exposureSummary$tCohortDefinitionName[i]),
                                 fileName = plotFileName)
            idx <- (matrix$cohortId1 == treatmentId & matrix$cohortId2 == comparatorId) |
                (matrix$cohortId2 == treatmentId & matrix$cohortId1 == comparatorId)
            matrix$auc[idx] <- CohortMethod::computePsAuc(ps, confidenceIntervals = FALSE)
            prefScore <- computePreferenceScore(ps)
            matrix$equipoise[idx] <- mean(prefScore$preferenceScore >= 0.3 & prefScore$preferenceScore < 0.7)
        }
    }
    psSummaryFileName <- file.path(psResultsFolder, "psSummary.csv")
    write.csv(matrix, psSummaryFileName, row.names = FALSE)
}

computePreferenceScore <- function(data) {
    proportion <- sum(data$treatment)/nrow(data)
    propensityScore <- data$propensityScore
    propensityScore[propensityScore > 0.9999999] <- 0.9999999
    x <- exp(log(propensityScore/(1 - propensityScore)) - log(proportion/(1 - proportion)))
    data$preferenceScore <- x/(x + 1)
    return(data)
}

#' @export
plotControlDistributions <- function(workFolder) {
    writeLines("Plotting control distributions")
    figuresAndTablesFolder <- file.path(workFolder, "figuresAndtables")
    if (!file.exists(figuresAndTablesFolder)) {
        dir.create(figuresAndTablesFolder)
    }
    controlsFolder <- file.path(figuresAndTablesFolder, "controls")
    if (!file.exists(controlsFolder)) {
        dir.create(controlsFolder)
    }

    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    analysesSum <- read.csv(file.path(workFolder, "analysisSummary.csv"))
    signalInjectionSum <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
    negativeControlIds <- unique(signalInjectionSum$outcomeId)
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        treatmentConceptId <- exposureSummary$tCohortDefinitionId[i]
        comparatorConceptId <- exposureSummary$cCohortDefinitionId[i]
        treatmentName <- exposureSummary$tCohortDefinitionName[i]
        comparatorName <- exposureSummary$cCohortDefinitionName[i]
        for (analysisId in c(1,3)){
            estimates <- analysesSum[analysesSum$analysisId == analysisId &
                                         analysesSum$targetId == treatmentId &
                                         analysesSum$comparatorId == comparatorId, ]

            negControls <- estimates[estimates$outcomeId %in% negativeControlIds, ]
            fileName <- file.path(controlsFolder, paste0("negControls_a", analysisId, "_t", treatmentId, "_c", comparatorId, ".png"))
            analysisLabel <- "Crude"
            if (analysisId != 1) {
                analysisLabel <- "Adjusted"
            }
            title <- paste(treatmentName, "vs.", comparatorName, "-", analysisLabel)
            plotEstimates(logRrNegatives = negControls$logRr,
                          seLogRrNegatives = negControls$seLogRr,
                          title = title,
                          xLabel = "Hazard ratio",
                          fileName = fileName)
            fileName <- file.path(controlsFolder, paste0("negControls_a", analysisId, "_t", comparatorId, "_c", treatmentId, ".png"))
            title <- paste(comparatorName, "vs.", treatmentName, "-", analysisLabel)
            plotEstimates(logRrNegatives = -negControls$logRr,
                          seLogRrNegatives = negControls$seLogRr,
                          title = title,
                          xLabel = "Hazard ratio",
                          fileName = fileName)

            injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == treatmentConceptId & signalInjectionSum$injectedOutcomes != 0, ]
            negativeControlIdSubsets <- unique(injectedSignals$outcomeId)
            injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                          trueLogRr = log(injectedSignals$targetEffectSize))
            negativeControls <- data.frame(outcomeId = negativeControlIdSubsets,
                                           trueLogRr = 0)
            data <- rbind(injectedSignals, negativeControls)
            data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
            fileName <- file.path(controlsFolder, paste0("trueAndObs_a", analysisId, "_t", treatmentId, "_c", comparatorId, ".png"))
            analysisLabel <- "Crude"
            if (analysisId != 1) {
                analysisLabel <- "Adjusted"
            }
            title <- paste(treatmentName, "vs.", comparatorName, "-", analysisLabel)
            EmpiricalCalibration::plotTrueAndObserved(logRr = data$logRr,
                                                      seLogRr = data$seLogRr,
                                                      trueLogRr = data$trueLogRr,
                                                      xLabel = "Hazard ratio",
                                                      title = title,
                                                      fileName = fileName)
            injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == comparatorConceptId & signalInjectionSum$injectedOutcomes != 0, ]
            negativeControlIdSubsets <- unique(injectedSignals$outcomeId)
            injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                          trueLogRr = log(injectedSignals$targetEffectSize))
            negativeControls <- data.frame(outcomeId = negativeControlIdSubsets,
                                           trueLogRr = 0)
            data <- rbind(injectedSignals, negativeControls)
            data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
            fileName <- file.path(controlsFolder, paste0("trueAndObs_a", analysisId, "_t", comparatorId, "_c", treatmentId, ".png"))
            title <- paste(comparatorName, "vs.", treatmentName, "-", analysisLabel)
            EmpiricalCalibration::plotTrueAndObserved(logRr = -data$logRr,
                                                      seLogRr = data$seLogRr,
                                                      trueLogRr = data$trueLogRr,
                                                      xLabel = "Hazard ratio",
                                                      title = title,
                                                      fileName = fileName)
        }
    }
}

plotEstimates <- function (logRrNegatives, seLogRrNegatives, xLabel = "Relative risk", title, fileName = NULL) {

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
    if (!missing(title)) {
        plot <- plot + ggplot2::ggtitle(title)
    }
    if (!is.null(fileName))
        ggplot2::ggsave(fileName, plot, width = 6, height = 4.5,
                        dpi = 400)
    return(plot)
}
