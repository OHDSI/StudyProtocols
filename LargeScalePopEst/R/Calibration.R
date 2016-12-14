# @file Calibration.R
#
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

#' Created calibrated confidence intervals, estimates, and p-values.
#'
#' @param workFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#'
#' @export
calibrateEstimatesAndPvalues <- function(workFolder) {
  figuresAndTablesFolder <- file.path(workFolder, "figuresAndtables")
  if (!file.exists(figuresAndTablesFolder)) {
    dir.create(figuresAndTablesFolder)
  }
  calibrationFolder <- file.path(figuresAndTablesFolder, "calibration")
  if (!file.exists(calibrationFolder)) {
    dir.create(calibrationFolder)
  }

  exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
  exposureSummary <- exposureSummary[exposureSummary$tCohortDefinitionName != "Psychotherapy" & exposureSummary$tCohortDefinitionName !=
    "Electroconvulsive therapy" & exposureSummary$cCohortDefinitionName != "Psychotherapy" & exposureSummary$cCohortDefinitionName !=
    "Electroconvulsive therapy", ]
  analysesSum <- read.csv(file.path(workFolder, "analysisSummary.csv"))
  analysesSumRev <- data.frame(analysisId = analysesSum$analysisId,
                               targetId = analysesSum$comparatorId,
                               comparatorId = analysesSum$targetId,
                               outcomeId = analysesSum$outcomeId,
                               rr = 1/analysesSum$rr,
                               ci95lb = 1/analysesSum$ci95ub,
                               ci95ub = 1/analysesSum$ci95lb,
                               p = analysesSum$p,
                               treated = analysesSum$comparator,
                               comparator = analysesSum$treated,
                               treatedDays = analysesSum$comparatorDays,
                               comparatorDays = analysesSum$treatedDays,
                               eventsTreated = analysesSum$eventsComparator,
                               eventsComparator = analysesSum$eventsTreated,
                               logRr = -analysesSum$logRr,
                               seLogRr = analysesSum$seLogRr)
  results <- rbind(analysesSum, analysesSumRev)
  results$calP <- NA
  results$calPlb <- NA
  results$calPub <- NA
  results$calLogRr <- NA
  results$calSeLogRr <- NA
  results$calRr <- NA
  results$calCi95lb <- NA
  results$calCi95ub <- NA
  signalInjectionSum <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
  negativeControlIds <- unique(signalInjectionSum$outcomeId)
  # i <- which(exposureSummary$tprimeCohortDefinitionId == 721724071)
  for (i in 1:nrow(exposureSummary)) {
    treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    treatmentConceptId <- exposureSummary$tCohortDefinitionId[i]
    comparatorConceptId <- exposureSummary$cCohortDefinitionId[i]
    treatmentName <- exposureSummary$tCohortDefinitionName[i]
    comparatorName <- exposureSummary$cCohortDefinitionName[i]
    for (analysisId in c(1, 3)) {
      estimates <- analysesSum[analysesSum$analysisId == analysisId & analysesSum$targetId == treatmentId &
        analysesSum$comparatorId == comparatorId, ]

      negControls <- estimates[estimates$outcomeId %in% negativeControlIds, ]
      null <- EmpiricalCalibration::fitMcmcNull(logRr = negControls$logRr,
                                                seLogRr = negControls$seLogRr)
      calibratedP <- EmpiricalCalibration::calibrateP(null = null,
                                                      logRr = estimates$logRr,
                                                      seLogRr = estimates$seLogRr)
      idx <- which(results$analysisId == analysisId & results$targetId == treatmentId & results$comparatorId ==
        comparatorId)
      idx <- idx[match(estimates$outcomeId, results$outcomeId[idx])]
      results$calP[idx] <- calibratedP$p
      results$calPlb[idx] <- calibratedP$lb95ci
      results$calPub[idx] <- calibratedP$ub95ci
      idx <- which(results$analysisId == analysisId & results$targetId == comparatorId & results$comparatorId ==
        treatmentId)
      idx <- idx[match(estimates$outcomeId, results$outcomeId[idx])]
      results$calP[idx] <- calibratedP$p
      results$calPlb[idx] <- calibratedP$lb95ci
      results$calPub[idx] <- calibratedP$ub95ci

      fileName <- file.path(calibrationFolder, paste0("negControls_a",
                                                      analysisId,
                                                      "_t",
                                                      treatmentId,
                                                      "_c",
                                                      comparatorId,
                                                      ".png"))
      analysisLabel <- "Crude"
      if (analysisId != 1) {
        analysisLabel <- "Adjusted"
      }
      title <- paste(treatmentName, "vs.", comparatorName, "-", analysisLabel)
      EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = negControls$logRr,
                                                  seLogRrNegatives = negControls$seLogRr,
                                                  title = title,
                                                  xLabel = "Hazard ratio",
                                                  fileName = fileName)
      fileName <- file.path(calibrationFolder, paste0("negControls_a",
                                                      analysisId,
                                                      "_t",
                                                      comparatorId,
                                                      "_c",
                                                      treatmentId,
                                                      ".png"))
      title <- paste(comparatorName, "vs.", treatmentName, "-", analysisLabel)
      EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = -negControls$logRr,
                                                  seLogRrNegatives = negControls$seLogRr,
                                                  title = title,
                                                  xLabel = "Hazard ratio",
                                                  fileName = fileName)

      injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == treatmentConceptId &
        signalInjectionSum$injectedOutcomes != 0, ]
      negativeControlIdSubsets <- unique(injectedSignals$outcomeId)
      injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                    trueLogRr = log(injectedSignals$targetEffectSize))
      negativeControls <- data.frame(outcomeId = negativeControlIds, trueLogRr = 0)
      data <- rbind(injectedSignals, negativeControls)
      data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
      if (length(unique(data$trueLogRr)) > 1) {
        model <- EmpiricalCalibration::fitSystematicErrorModel(logRr = data$logRr,
                                                               seLogRr = data$seLogRr,
                                                               trueLogRr = data$trueLogRr)
        calibratedCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = estimates$logRr,
                                                                          seLogRr = estimates$seLogRr,
                                                                          model = model)
        idx <- which(results$analysisId == analysisId & results$targetId == treatmentId & results$comparatorId ==
          comparatorId)
        idx <- idx[match(estimates$outcomeId, results$outcomeId[idx])]
        results$calLogRr[idx] <- calibratedCi$logRr
        results$calSeLogRr[idx] <- calibratedCi$seLogRr
        results$calRr[idx] <- exp(calibratedCi$logRr)
        results$calCi95lb[idx] <- exp(calibratedCi$logLb95Rr)
        results$calCi95ub[idx] <- exp(calibratedCi$logUb95Rr)

        calibratedCi$outcomeId <- estimates$outcomeId
        data <- rbind(injectedSignals,
                      negativeControls[negativeControls$outcomeId %in% negativeControlIdSubsets,
                      ])
        data <- merge(data, calibratedCi)
        fileName <- file.path(calibrationFolder, paste0("trueAndObs_a",
                                                        analysisId,
                                                        "_t",
                                                        treatmentId,
                                                        "_c",
                                                        comparatorId,
                                                        ".png"))
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
      }

      injectedSignals <- signalInjectionSum[signalInjectionSum$exposureId == comparatorConceptId &
        signalInjectionSum$injectedOutcomes != 0, ]
      negativeControlIdSubsets <- unique(injectedSignals$outcomeId)
      injectedSignals <- data.frame(outcomeId = injectedSignals$newOutcomeId,
                                    trueLogRr = log(injectedSignals$targetEffectSize))
      negativeControls <- data.frame(outcomeId = negativeControlIds,
                                     trueLogRr = rep(0, length(negativeControlIds)))
      data <- rbind(injectedSignals, negativeControls)
      data <- merge(data, estimates[, c("outcomeId", "logRr", "seLogRr")])
      if (length(unique(data$trueLogRr)) > 1) {
        model <- EmpiricalCalibration::fitSystematicErrorModel(logRr = -data$logRr,
                                                               seLogRr = data$seLogRr,
                                                               trueLogRr = data$trueLogRr)
        calibratedCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = -estimates$logRr,
                                                                          seLogRr = estimates$seLogRr,
                                                                          model = model)
        idx <- which(results$analysisId == analysisId & results$targetId == comparatorId & results$comparatorId ==
          treatmentId)
        idx <- idx[match(estimates$outcomeId, results$outcomeId[idx])]
        results$calLogRr[idx] <- calibratedCi$logRr
        results$calSeLogRr[idx] <- calibratedCi$seLogRr
        results$calRr[idx] <- exp(calibratedCi$logRr)
        results$calCi95lb[idx] <- exp(calibratedCi$logLb95Rr)
        results$calCi95ub[idx] <- exp(calibratedCi$logUb95Rr)

        calibratedCi$outcomeId <- estimates$outcomeId
        data <- rbind(injectedSignals,
                      negativeControls[negativeControls$outcomeId %in% negativeControlIdSubsets,
                      ])
        data <- merge(data, calibratedCi)

        fileName <- file.path(calibrationFolder, paste0("trueAndObs_a",
                                                        analysisId,
                                                        "_t",
                                                        comparatorId,
                                                        "_c",
                                                        treatmentId,
                                                        ".png"))
        title <- paste(comparatorName, "vs.", treatmentName, "-", analysisLabel)
        EmpiricalCalibration::plotTrueAndObserved(logRr = data$logRr,
                                                  seLogRr = data$seLogRr,
                                                  trueLogRr = data$trueLogRr,
                                                  xLabel = "Hazard ratio",
                                                  title = title,
                                                  fileName = fileName)
      }
    }
  }
  write.csv(results, file.path(workFolder, "calibratedEstimates.csv"), row.names = FALSE)
}
