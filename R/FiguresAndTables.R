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
            fileName <- file.path(controlsFolder, paste0("calEffect_a", analysisId, "_t", treatmentId, "_c", comparatorId, ".png"))
            analysisLabel <- "Crude"
            if (analysisId != 1) {
                analysisLabel <- "Adjusted"
            }
            title <- paste(treatmentName, "vs.", comparatorName, "-", analysisLabel)
            EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = negControls$logRr,
                                                        seLogRrNegatives = negControls$seLogRr,
                                                        #title = title,
                                                        xLabel = "Hazard ratio",
                                                        fileName = fileName)
            fileName <- file.path(controlsFolder, paste0("calEffect_a", analysisId, "_t", comparatorId, "_c", treatmentId, ".png"))
            title <- paste(comparatorName, "vs.", treatmentName, "-", analysisLabel)
            EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = -negControls$logRr,
                                                        seLogRrNegatives = negControls$seLogRr,
                                                        #title = title,
                                                        xLabel = "Hazard ratio",
                                                        fileName = fileName)

            injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == treatmentConceptId, ]
            injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                          trueLogRr = log(injectedSignals$targetEffectSize))
            negativeControls <- data.frame(outcomeId = negativeControlIds,
                                           trueLogRr = 0)
            data <- rbind(injectedSignals, negativeControls)
            data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
            fileName <- file.path(controlsFolder, paste0("trueAndObs_a", analysisId, "_t", comparatorId, "_c", treatmentId, ".png"))

            EmpiricalCalibration::plotTrueAndObserved(logRr = data$logRr,
                                                      seLogRr = data$seLogRr,
                                                      trueLogRr = data$trueLogRr,
                                                      xLabel = "Hazard ratio",
                                                      fileName = fileName)
            injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == comparatorConceptId, ]
            injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                          trueLogRr = log(injectedSignals$targetEffectSize))
            negativeControls <- data.frame(outcomeId = negativeControlIds,
                                           trueLogRr = 0)
            data <- rbind(injectedSignals, negativeControls)
            data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
            fileName <- file.path(controlsFolder, paste0("trueAndObs_a", analysisId, "_t", comparatorId, "_c", treatmentId, ".png"))

            EmpiricalCalibration::plotTrueAndObserved(logRr = -data$logRr,
                                                      seLogRr = data$seLogRr,
                                                      trueLogRr = data$trueLogRr,
                                                      xLabel = "Hazard ratio",
                                                      fileName = fileName)
        }
    }
}
