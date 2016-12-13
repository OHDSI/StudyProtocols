# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of CiCalibration
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


#' Perform empirical calibration
#'
#' @details
#' Performs empirical calibration of confidence intervals and p-values using the negative and positive
#' control outcomes.
#'
#' @param workFolder   The path to the output folder containing the results.
#'
#' @export
doEmpiricalCalibration <- function(workFolder, study) {
    if (study == "Southworth") {
        results <- read.csv(file.path(workFolder, "cmSummarySouthworth.csv"))

        # positive control outcomes:
        positiveControls <- read.csv(file.path(workFolder, "SignalInjectionSummary_Southworth.csv"))
        positiveControls <- data.frame(outcomeId = positiveControls$newOutcomeId,
                                       trueLogRr = log(positiveControls$targetEffectSize),
                                       oldOutcomeId = positiveControls$outcomeId)
        results <- merge(results, positiveControls, all.x = TRUE)

        # outcome of interest:
        pathToHoi <- system.file("settings", "cmHypothesisOfInterestSouthworth.txt", package = "CiCalibration")
        hoi <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)[[1]]$outcomeId

        # negative control outcomes:
        pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
        negativeControls <- read.csv(pathToCsv)
        negativeControls <- negativeControls[negativeControls$study == "Southworth", ]
        negativeControls <- negativeControls$conceptId
        results$trueLogRr[results$outcomeId %in% negativeControls] <- 0

        .empiricalCalibration(workFolder = workFolder, results = results, study = study, design = "cohort_method")
    } else if (study == "Graham") {
        results <- read.csv(file.path(workFolder, "cmSummaryGraham.csv"))

        # positive control outcomes:
        positiveControls <- read.csv(file.path(workFolder, "SignalInjectionSummary_Graham.csv"))
        positiveControls <- data.frame(outcomeId = positiveControls$newOutcomeId,
                                       trueLogRr = log(positiveControls$targetEffectSize),
                                       oldOutcomeId = positiveControls$outcomeId)
        results <- merge(results, positiveControls, all.x = TRUE)

        # outcome of interest:
        pathToHoi <- system.file("settings", "cmHypothesisOfInterestGraham.txt", package = "CiCalibration")
        hoi <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)[[1]]$outcomeId

        # negative control outcomes:
        pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
        negativeControls <- read.csv(pathToCsv)
        negativeControls <- negativeControls[negativeControls$study == "Graham", ]
        negativeControls <- negativeControls$conceptId
        results$trueLogRr[results$outcomeId %in% negativeControls] <- 0

        .empiricalCalibration(workFolder = workFolder, results = results, study = study, design = "cohort_method")
    } else if (study == "Tata") {
        # Case-control
        results <- read.csv(file.path(workFolder, "ccSummary.csv"))

        # positive control outcomes:
        positiveControls <- read.csv(file.path(workFolder, "SignalInjectionSummary_Tata.csv"))
        positiveControls <- data.frame(outcomeId = positiveControls$newOutcomeId,
                                       trueLogRr = log(positiveControls$targetEffectSize),
                                       oldOutcomeId = positiveControls$outcomeId)
        results <- merge(results, positiveControls, all.x = TRUE)

        # outcome of interest:
        pathToHoi <- system.file("settings", "ccHypothesisOfInterest.txt", package = "CiCalibration")
        hoi <- CaseControl::loadExposureOutcomeNestingCohortList(pathToHoi)[[1]]$outcomeId

        # negative control outcomes:
        pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
        negativeControls <- read.csv(pathToCsv)
        negativeControls <- negativeControls[negativeControls$study == "Tata", ]
        negativeControls <- negativeControls$conceptId
        results$trueLogRr[results$outcomeId %in% negativeControls] <- 0

        .empiricalCalibration(workFolder = workFolder, results = results, study = study, design = "case_control")


        # Self-Controlled Case Series
        results <- read.csv(file.path(workFolder, "sccsSummary.csv"))
        results$logRr <- results$logRr.Exposure.of.interest.
        results$seLogRr <- results$seLogRr.Exposure.of.interest.
        results$rr <- results$rr.Exposure.of.interest.
        results$ci95lb <- results$ci95lb.Exposure.of.interest.
        results$ci95ub <- results$ci95ub.Exposure.of.interest.

        # positive control outcomes:
        positiveControls <- read.csv(file.path(workFolder, "SignalInjectionSummary_Tata.csv"))
        positiveControls <- data.frame(outcomeId = positiveControls$newOutcomeId,
                                       trueLogRr = log(positiveControls$targetEffectSize),
                                       oldOutcomeId = positiveControls$outcomeId)
        results <- merge(results, positiveControls, all.x = TRUE)

        # outcome of interest:
        pathToHoi <- system.file("settings", "sccsHypothesisOfInterest.txt", package = "CiCalibration")
        hoi <- SelfControlledCaseSeries::loadExposureOutcomeList(pathToHoi)[[1]]$outcomeId

        # negative control outcomes:
        pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
        negativeControls <- read.csv(pathToCsv)
        negativeControls <- negativeControls[negativeControls$study == "Tata", ]
        negativeControls <- negativeControls$conceptId
        results$trueLogRr[results$outcomeId %in% negativeControls] <- 0

        .empiricalCalibration(workFolder = workFolder, results = results, study = study, design = "sccs")

    }
}

.empiricalCalibration <- function(workFolder, results, study, design) {
    calibrationFolder = file.path(workFolder, paste0("calibration_", study, "_", design))
    if (!file.exists(calibrationFolder))
        dir.create(calibrationFolder)

    negativeControls <- results[!is.na(results$trueLogRr) & results$trueLogRr == 0,]
    positiveControls <- results[!is.na(results$trueLogRr) & results$trueLogRr > 0,]
    allControls <- rbind(negativeControls, positiveControls)
    hoi <- results[is.na(results$trueLogRr),]

    null <- EmpiricalCalibration::fitMcmcNull(negativeControls$logRr, negativeControls$seLogRr)

    calibratedP <- EmpiricalCalibration::calibrateP(null, results$logRr, results$seLogRr)

    results$calibratedP <- calibratedP$p
    results$calibratedP_lb95ci <- calibratedP$lb95ci
    results$calibratedP_ub95ci <- calibratedP$ub95ci
    mcmc <- attr(null, "mcmc")
    results$null_mean <- mean(mcmc$chain[, 1])
    results$null_sd <- 1/sqrt(mean(mcmc$chain[, 2]))

    fileName <- file.path(calibrationFolder, "pValueCalibration.png")
    EmpiricalCalibration::plotCalibration(negativeControls$logRr, negativeControls$seLogRr, fileName = fileName)

    fileName <- file.path(calibrationFolder, "pValueCalEffect.png")
    EmpiricalCalibration::plotCalibrationEffect(negativeControls$logRr, negativeControls$seLogRr, hoi$logRr, hoi$seLogRr, fileName = fileName)

    # fileName <- file.path(calibrationFolder, "pValueCalEffectWithCis.png")
    # EmpiricalCalibration::plotCalibrationEffect(negativeControls$logRr, negativeControls$seLogRr, hoi$logRr, hoi$seLogRr, fileName = fileName, showCis = TRUE)

    fileName <- file.path(calibrationFolder, "mcmcTrace.png")
    EmpiricalCalibration::plotMcmcTrace(null, fileName = fileName)

    errorModel <- EmpiricalCalibration::fitSystematicErrorModel(logRr = allControls$logRr,
                                                                seLogRr = allControls$seLogRr,
                                                                trueLogRr = allControls$trueLogRr)
    calibratedCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = results$logRr,
                                                                      seLogRr = results$seLogRr,
                                                                      model = errorModel)
    results$calibratedRr <- exp(calibratedCi$logRr)
    results$calibratedCi95lb <- exp(calibratedCi$logLb95Rr)
    results$calibratedCi95ub <- exp(calibratedCi$logUb95Rr)
    results$calibratedSe <- exp(calibratedCi$seLogRr)
    results$calibratedLogRr <- calibratedCi$logRr
    results$calibratedSeLogRr <- calibratedCi$seLogRr

    fileName <- file.path(calibrationFolder, "ciCalibration.png")
    EmpiricalCalibration::plotCiCalibration(logRr = allControls$logRr,
                                            seLogRr = allControls$seLogRr,
                                            trueLogRr = allControls$trueLogRr,
                                            fileName = fileName)

    fileName <- file.path(calibrationFolder, "trueAndObserved.png")
    EmpiricalCalibration::plotTrueAndObserved(logRr = allControls$logRr,
                                              seLogRr = allControls$seLogRr,
                                              trueLogRr = allControls$trueLogRr,
                                              fileName = fileName)

    allControls <- results[results$outcomeId %in% allControls$outcomeId, ]
    fileName <- file.path(calibrationFolder, "trueAndObservedCalibrated.png")
    EmpiricalCalibration::plotTrueAndObserved(logRr = allControls$calibratedLogRr,
                                              seLogRr = allControls$calibratedSeLogRr,
                                              trueLogRr = allControls$trueLogRr,
                                              fileName = fileName)

    write.csv(results, file.path(workFolder, paste0("Calibrated_", study, "_", design,".csv")), row.names = FALSE)
}
