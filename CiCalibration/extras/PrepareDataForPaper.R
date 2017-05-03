require(ggplot2)

mdcrFolder <- "S:/Temp/CiCalibration_Mdcr"
optumFolder <- "S:/Temp/CiCalibration_Optum"
cprdFolder <- "S:/Temp/CiCalibration_Cprd"

paperFolder <- "S:/temp/CiCalibrationPaper/data"
if (!file.exists(paperFolder))
    dir.create(paperFolder, recursive = TRUE)

# Ingrowing nail model and performance ------------------------------------

modelFile <- file.path(optumFolder, "signalInjection", "model_o139099", "betas.rds")
model <- readRDS(modelFile)
model$id <- NULL
saveRDS(model, file.path(paperFolder, "ingrownNailModel.rds"))

predictionFile <- file.path(optumFolder, "signalInjection", "model_o139099", "prediction.rds")
prediction <- readRDS(predictionFile)
exposuresFile <- file.path(optumFolder, "signalInjection", "exposures.rds")
exposures <- readRDS(exposuresFile)
m <- merge(prediction, exposures[, c("rowId", "personId", "cohortStartDate")])
m$subjectId <- m$personId

studyPopFile <- file.path(optumFolder, "cmOutputSouthworth", "StudyPop_l1_s1_t1_c2_o139099.rds")
studyPop <- readRDS(studyPopFile)
studyPop$y <- 0
studyPop$y[studyPop$daysToEvent <= 365] <- 1
m <- merge(studyPop[,c("subjectId","cohortStartDate", "y")], m)
m$propensityScore <- m$prediction
m$treatment <- m$y
auc <- CohortMethod::computePsAuc(m)
saveRDS(auc, file.path(paperFolder, "ingrownNailAuc.rds"))

# Ingrowing nail estimates ------------------------------------------------

calibratedFile <- file.path(optumFolder, "Calibrated_Southworth_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
ign <- calibrated[calibrated$outcomeId == 139099 | (!is.na(calibrated$oldOutcomeId) & calibrated$oldOutcomeId == 139099), ]
ign$trueRr <- exp(ign$trueLogRr)
ign <- ign[, c("rr", "ci95lb" ,"ci95ub", "trueRr")]
saveRDS(ign, file.path(paperFolder, "ingrownNailEstimates.rds"))

# Estimates for controls (calibrated and uncalibrated) --------------------------------

estimates <- data.frame()

calibratedFile <- file.path(optumFolder, "Calibrated_Southworth_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated <- calibrated[!is.na(calibrated$trueLogRr), c("outcomeId", "trueLogRr", "rr", "ci95lb", "ci95ub", "logRr", "seLogRr", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedLogRr", "calibratedSeLogRr")]
calibrated$study <- "Southworth"
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(mdcrFolder, "Calibrated_Graham_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated <- calibrated[!is.na(calibrated$trueLogRr), c("outcomeId", "trueLogRr", "rr", "ci95lb", "ci95ub", "logRr", "seLogRr", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedLogRr", "calibratedSeLogRr")]
calibrated$study <- "Graham"
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(cprdFolder, "Calibrated_Tata_case_control.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated <- calibrated[!is.na(calibrated$trueLogRr), c("outcomeId", "trueLogRr", "rr", "ci95lb", "ci95ub", "logRr", "seLogRr", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedLogRr", "calibratedSeLogRr")]
calibrated$study <- "Tata - CC"
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(cprdFolder, "Calibrated_Tata_sccs.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated <- calibrated[!is.na(calibrated$trueLogRr), c("outcomeId", "trueLogRr", "rr", "ci95lb", "ci95ub", "logRr", "seLogRr", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedLogRr", "calibratedSeLogRr")]
calibrated$study <- "Tata - SCCS"
estimates <- rbind(estimates, calibrated)

saveRDS(estimates, file.path(paperFolder, "controlEstimates.rds"))


# Leave one out cross validation ------------------------------------------

estimates <- readRDS(file.path(paperFolder, "controlEstimates.rds"))

library(EmpiricalCalibration)
prepareCalibration <- function(logRr,
                               seLogRr,
                               trueLogRr,
                               strata = as.factor(trueLogRr),
                               crossValidationGroup = 1:length(logRr),
                               legendPosition = "top",
                               title,
                               fileName = NULL) {
    if (!is.null(strata) && !is.factor(strata))
        stop("Strata argument should be a factor (or null)")
    if (is.null(strata))
        strata = as.factor(-1)
    data <- data.frame(logRr = logRr,
                       seLogRr = seLogRr,
                       trueLogRr = trueLogRr,
                       strata = strata,
                       crossValidationGroup = crossValidationGroup)
    if (any(is.infinite(data$seLogRr))) {
        warning("Estimate(s) with infinite standard error detected. Removing before fitting error model")
        data <- data[!is.infinite(seLogRr), ]
    }
    if (any(is.infinite(data$logRr))) {
        warning("Estimate(s) with infinite logRr detected. Removing before fitting error model")
        data <- data[!is.infinite(logRr), ]
    }
    if (any(is.na(data$seLogRr))) {
        warning("Estimate(s) with NA standard error detected. Removing before fitting error model")
        data <- data[!is.na(seLogRr), ]
    }
    if (any(is.na(data$logRr))) {
        warning("Estimate(s) with NA logRr detected. Removing before fitting error model")
        data <- data[!is.na(logRr), ]
    }
    computeCoverage <- function(j, subResult, dataLeftOut, model) {
        subset <- dataLeftOut[dataLeftOut$strata == subResult$strata[j],]
        if (nrow(subset) == 0)
            return(0)
        #writeLines(paste0("ciWidth: ", subResult$ciWidth[j], ", strata: ", subResult$strata[j], ", model: ", paste(model, collapse = ",")))
        #writeLines(paste0("ciWidth: ", subResult$ciWidth[j], ", logRr: ", paste(subset$logRr, collapse = ","), ", seLogRr:", paste(subset$seLogRr, collapse = ","), ", model: ", paste(model, collapse = ",")))
        ci <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = subset$logRr,
                                                                seLogRr = subset$seLogRr,
                                                                ciWidth = subResult$ciWidth[j],
                                                                model = model)
        below <- sum(subset$trueLogRr < ci$logLb95Rr)
        within <- sum(ci$logLb95Rr <= subset$trueLogRr & ci$logUb95Rr >= subset$trueLogRr)
        above <- sum(subset$trueLogRr > ci$logUb95Rr)
        return(c(below, within, above))
    }

    computeTheoreticalCoverage <- function(j, subResult, dataLeftOut) {
        subset <- dataLeftOut[dataLeftOut$strata == subResult$strata[j],]
        ciWidth <- subResult$ciWidth[j]
        logLb95Rr <- subset$logRr + qnorm((1-ciWidth)/2)*subset$seLogRr
        logUb95Rr <- subset$logRr - qnorm((1-ciWidth)/2)*subset$seLogRr
        below <- sum(subset$trueLogRr < logLb95Rr)
        within <- sum(subset$trueLogRr >= logLb95Rr & subset$trueLogRr <= logUb95Rr)
        above <- sum(subset$trueLogRr > logUb95Rr)
        return(c(below, within, above))
    }

    computeLooCoverage <- function(leaveOutGroup, data) {
        dataLeaveOneOut <- data[data$crossValidationGroup != leaveOutGroup, ]
        dataLeftOut <- data[data$crossValidationGroup == leaveOutGroup, ]
        if (nrow(dataLeaveOneOut) == 0 || nrow(dataLeftOut) == 0)
            return(data.frame())

        model <- fitSystematicErrorModel(logRr = dataLeaveOneOut$logRr,
                                         seLogRr = dataLeaveOneOut$seLogRr,
                                         trueLogRr = dataLeaveOneOut$trueLogRr,
                                         estimateCovarianceMatrix = FALSE)

        strata <- unique(dataLeftOut$strata)
        ciWidth <- seq(0.01, 0.99, by = 0.01)
        subResult <- expand.grid(strata, ciWidth)
        names(subResult) <- c("strata", "ciWidth")
        coverage <- sapply(1:nrow(subResult), computeCoverage, subResult = subResult, dataLeftOut = dataLeftOut, model = model)
        subResult$below <- coverage[1,]
        subResult$within <- coverage[2,]
        subResult$above <- coverage[3,]
        theoreticalCoverage <- sapply(1:nrow(subResult), computeTheoreticalCoverage, subResult = subResult, dataLeftOut = dataLeftOut)
        subResult$theoreticalBelow <- theoreticalCoverage[1, ]
        subResult$theoreticalWithin <- theoreticalCoverage[2, ]
        subResult$theoreticalAbove <- theoreticalCoverage[3, ]
        return(subResult)
    }
    writeLines("Fitting error models within leave-one-out cross-validation")
    coverages <- lapply(unique(data$crossValidationGroup), computeLooCoverage, data = data)
    coverage <- do.call("rbind", coverages)
    data$count <- 1
    counts <- aggregate(count ~ strata, data = data, sum)
    belowCali <- aggregate(below ~ strata + ciWidth, data = coverage, sum)
    belowCali <- merge(belowCali, counts, by = "strata")
    belowCali$coverage <- belowCali$below / belowCali$count
    belowCali$label <- "Below confidence interval"
    belowCali$type <- "Calibrated"
    withinCali <- aggregate(within ~ strata + ciWidth, data = coverage, sum)
    withinCali <- merge(withinCali, counts, by = "strata")
    withinCali$coverage <- withinCali$within / withinCali$count
    withinCali$label <- "Within confidence interval"
    withinCali$type <- "Calibrated"
    aboveCali <- aggregate(above ~ strata + ciWidth, data = coverage, sum)
    aboveCali <- merge(aboveCali, counts, by = "strata")
    aboveCali$coverage <- aboveCali$above / aboveCali$count
    aboveCali$label <- "Above confidence interval"
    aboveCali$type <- "Calibrated"
    belowUncali <- aggregate(theoreticalBelow ~ strata + ciWidth, data = coverage, sum)
    belowUncali <- merge(belowUncali, counts, by = "strata")
    belowUncali$coverage <- belowUncali$theoreticalBelow / belowUncali$count
    belowUncali$label <- "Below confidence interval"
    belowUncali$type <- "Uncalibrated"
    withinUncali <- aggregate(theoreticalWithin ~ strata + ciWidth, data = coverage, sum)
    withinUncali <- merge(withinUncali, counts, by = "strata")
    withinUncali$coverage <- withinUncali$theoreticalWithin / withinUncali$count
    withinUncali$label <- "Within confidence interval"
    withinUncali$type <- "Uncalibrated"
    aboveUncali <- aggregate(theoreticalAbove ~ strata + ciWidth, data = coverage, sum)
    aboveUncali <- merge(aboveUncali, counts, by = "strata")
    aboveUncali$coverage <- aboveUncali$theoreticalAbove / aboveUncali$count
    aboveUncali$label <- "Above confidence interval"
    aboveUncali$type <- "Uncalibrated"
    vizData <- rbind(belowCali[, c("strata", "label", "type", "ciWidth", "coverage")],
                     withinCali[, c("strata", "label", "type", "ciWidth", "coverage")],
                     aboveCali[, c("strata", "label", "type", "ciWidth", "coverage")],
                     belowUncali[, c("strata", "label", "type", "ciWidth", "coverage")],
                     withinUncali[, c("strata", "label", "type", "ciWidth", "coverage")],
                     aboveUncali[, c("strata", "label", "type", "ciWidth", "coverage")])
    names(vizData)[names(vizData) == "type"] <- "Confidence interval calculation"
    vizData$trueRr <- as.factor(exp(as.numeric(as.character(vizData$strata))))
    return(vizData)
}

allCali <- data.frame()
for (study in unique(estimates$study)) {
    print(study)
    studyData <- estimates[estimates$study == study, ]
    cali <- prepareCalibration(logRr = studyData$logRr,
                               seLogRr = studyData$seLogRr,
                               trueLogRr = studyData$trueLogRr,
                               crossValidationGroup = studyData$outcomeId)
    cali$study <- study
    allCali <- rbind(allCali, cali)
}
saveRDS(allCali, file.path(paperFolder, "calibration.rds"))


# Estimates for HOIs ------------------------------------------------------

results <- data.frame()

result <- data.frame(group = "Original study",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "Original study",
                     estimate = "Uncalibrated",
                     rr = 1.6 / 3.5,
                     lb = 1.6 / 3.5,
                     ub = 1.6 / 3.5)
results <- rbind(results, result)

result <- data.frame(group = "Original study",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "Original study",
                     estimate = "Uncalibrated",
                     rr = 1.28,
                     lb = 1.14,
                     ub = 1.44)
results <- rbind(results, result)

cal <- read.csv(file.path(optumFolder, "Calibrated_Southworth_cohort_method.csv"))
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "Our replication",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

cal <- read.csv(file.path(mdcrFolder, "Calibrated_Graham_cohort_method.csv"))
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "Our replication",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

results$label <- factor(results$label,
                        levels = c("Our replication (calibrated)","Our replication","Original study"))
saveRDS(results, file.path(paperFolder, "hoiEstimatesDabi.rds"))

results <- data.frame()

result <- data.frame(group = "Original study",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "Original study",
                     estimate = "Uncalibrated",
                     rr = 2.38,
                     lb = 2.08,
                     ub = 2.72)
results <- rbind(results, result)

result <- data.frame(group = "Original study",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "Original study",
                     estimate = "Uncalibrated",
                     rr = 1.71,
                     lb = 1.48,
                     ub = 1.98)
results <- rbind(results, result)

cal <- read.csv(file.path(cprdFolder, "Calibrated_Tata_case_control.csv"))
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "Our replication",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

cal <- read.csv(file.path(cprdFolder, "Calibrated_Tata_sccs.csv"))
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "Our replication",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

results$label <- factor(results$label,
                        levels = c("Our replication (calibrated)","Our replication","Original study"))

saveRDS(results, file.path(paperFolder, "hoiEstimatesTata.rds"))


# Negative controls -------------------------------------------------------

pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
negativeControls <- read.csv(pathToCsv)
negativeControlsSouthworth <- negativeControls[negativeControls$study == "Southworth", ]

negativeControlsTata <- negativeControls[negativeControls$study == "Tata", ]


# Fitted error models -----------------------------------------------------

library(EmpiricalCalibration)
estimates <- readRDS(file.path(paperFolder, "controlEstimates.rds"))

models <- data.frame()
for (study in unique(estimates$study)) {
    print(study)
    studyData <- estimates[estimates$study == study, ]
    m <- fitSystematicErrorModel(logRr = studyData$logRr,
                                 seLogRr = studyData$seLogRr,
                                 trueLogRr = studyData$trueLogRr,
                                 estimateCovarianceMatrix = TRUE)
    model <- paste0(formatC(as.vector(m), digits = 2, format = "f"),
                    " (",
                    formatC(attr(m, "LB95CI"), digits = 2, format = "f"),
                    "-",
                    formatC(attr(m, "UB95CI"), digits = 2, format = "f"),
                    ")")
    names(model) <- names(m)
    model <- as.data.frame(t(model))
    model$study <- study
    models <- rbind(models, model)
}
saveRDS(models, file.path(paperFolder, "models.rds"))


# Covariate counts in all studies -----------------------------------------

library(ffbase)
load.ffdf(file.path(cprdFolder, "signalInjection", "covariates"))
cprdCovs <- nrow(covariateRef)

load.ffdf(file.path(optumFolder, "signalInjection", "covariates"))
optumCovs <- nrow(covariateRef)

load.ffdf(file.path(mdcrFolder, "signalInjection", "covariates"))
mdcrCovs <- nrow(covariateRef)

covCounts <- data.frame(study = c("Tata - SCCS", "Tata - CC", "Southworth", "Graham"),
                        covariateCount = c(cprdCovs, cprdCovs, optumCovs, mdcrCovs))
saveRDS(covCounts, file.path(paperFolder, "covCounts.rds"))


# Population counts -------------------------------------------------------


cal <- read.csv(file.path(optumFolder, "Calibrated_Southworth_cohort_method.csv"))
cal <- cal[cal$outcomeId == 3, ]
southworthCounts <- c(cal$treated, cal$comparator)

cal <- read.csv(file.path(mdcrFolder, "Calibrated_Graham_cohort_method.csv"))
cal <- cal[cal$outcomeId == 6, ]
grahamCounts <- c(cal$treated, cal$comparator)

cal <- read.csv(file.path(cprdFolder, "Calibrated_Tata_case_control.csv"))
cal <- cal[cal$outcomeId == 14, ]
tataCcCounts <- c(cal$cases, cal$control)

cal <- read.csv(file.path(cprdFolder, "Calibrated_Tata_sccs.csv"))
cal <- cal[cal$outcomeId == 14, ]
tataSccsCounts <- c(cal$caseCount)

popCounts <- data.frame(southworthTarget = southworthCounts[1],
                     southworthComparator = southworthCounts[2],
                     grahamTarget = grahamCounts[1],
                     grahamComparator = grahamCounts[2],
                     ccCases = tataCcCounts[1],
                     ccControls = tataCcCounts[2],
                     sccsCases = tataSccsCounts[1])
saveRDS(popCounts, file.path(paperFolder, "popCounts.rds"))


# All estimates for supporting information --------------------------------

pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
negativeControls <- read.csv(pathToCsv)
pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "CiCalibration")
cohortsToCreate <- read.csv(pathToCsv)
idToNames <- data.frame(outcomeId = c(negativeControls$conceptId, cohortsToCreate$cohortId),
                        outcomeName = c(as.character(negativeControls$name), as.character(cohortsToCreate$name)))
idToNames <- unique(idToNames)
estimates <- data.frame()

calibratedFile <- file.path(optumFolder, "Calibrated_Southworth_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated$study <- "Southworth replication"
calibrated <- merge(calibrated, idToNames)
calibrated$trueRr <- exp(calibrated$trueLogRr)
calibrated <- calibrated[, c("study", "outcomeName", "trueRr", "rr", "ci95lb", "ci95ub", "p", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedP")]
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(mdcrFolder, "Calibrated_Graham_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated$study <- "Graham replication"
calibrated <- merge(calibrated, idToNames)
calibrated$trueRr <- exp(calibrated$trueLogRr)
calibrated <- calibrated[, c("study", "outcomeName", "trueRr", "rr", "ci95lb", "ci95ub", "p", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedP")]
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(cprdFolder, "Calibrated_Tata_case_control.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated$study <- "Tata case-control replication"
calibrated <- merge(calibrated, idToNames)
calibrated$trueRr <- exp(calibrated$trueLogRr)
calibrated <- calibrated[, c("study", "outcomeName", "trueRr", "rr", "ci95lb", "ci95ub", "p", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedP")]
estimates <- rbind(estimates, calibrated)

calibratedFile <- file.path(cprdFolder, "Calibrated_Tata_sccs.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated$study <- "Tata SCCS replication"
calibrated <- merge(calibrated, idToNames)
calibrated$trueRr <- exp(calibrated$trueLogRr)
calibrated$p <- EmpiricalCalibration::computeTraditionalP(calibrated$logRr, calibrated$seLogRr)
calibrated <- calibrated[, c("study", "outcomeName", "trueRr", "rr", "ci95lb", "ci95ub", "p", "calibratedRr", "calibratedCi95lb", "calibratedCi95ub", "calibratedP")]
estimates <- rbind(estimates, calibrated)

idx <- !is.na(estimates$trueRr) & !estimates$trueRr == 1
estimates$outcomeName <- as.character(estimates$outcomeName)
estimates$outcomeName[idx] <- paste0(estimates$outcomeName[idx], "(RR=", estimates$trueRr[idx], ")")
write.csv(estimates, file.path(paperFolder, "AllEstimates.csv"), row.names = FALSE)
