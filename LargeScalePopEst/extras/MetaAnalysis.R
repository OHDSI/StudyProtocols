require(meta)

folder <- "s:/temp/Depression"
calibrated <- read.csv(file.path(folder, "DepressionResults.csv"))
calibrated <- calibrated[calibrated$analysisId == 3, ]

performMa <- function(i, tcos, calibrated) {
    tco <- tcos[i, ]
    subset <- calibrated[calibrated$targetId == tco$targetId &
                             calibrated$comparatorId == tco$comparatorId &
                             calibrated$outcomeName == tco$outcomeName, c("logRr", "seLogRr")]
    subset <- subset[!is.na(subset$seLogRr), ]
    if (nrow(subset) != 4)
        return(NULL)
    meta <- meta::metagen(subset$logRr, subset$seLogRr, sm = "RR")
    s <- summary(meta)$random
    result <- data.frame(targetId = tco$targetId,
                         comparatorId = tco$comparatorId,
                         outcomeId = tco$outcomeId,
                         targetName = tco$targetName,
                         comparatorName = tco$comparatorName,
                         outcomeName = tco$outcomeName,
                         outcomeType = tco$outcomeType,
                         trueRr = tco$trueRr,
                         rr = exp(s$TE),
                         ci95lb = exp(s$lower),
                         ci95ub = exp(s$upper),
                         logRr = s$TE,
                         seLogRr = (s$upper - s$lower)/(2*qnorm(0.975)),
                         i2 = meta$I2)
    return(result)
}

calibrated$outcomeId[calibrated$outcomeType == "positive control"] <- NA
tcos <- unique(calibrated[, c("targetId", "comparatorId", "outcomeId", "targetName", "comparatorName", "outcomeName", "outcomeType", "trueRr")])
meta <- lapply(1:nrow(tcos), performMa, tcos = tcos, calibrated = calibrated)
meta <- do.call("rbind", meta)

write.csv(meta, file.path(folder, "MetaAnalysis.csv"), row.names = FALSE)


calibrateMa <- function(i, tcs, meta) {
    tc <- tcs[i, ]
    subset <- meta[meta$targetId == tc$targetId & meta$comparatorId == tc$comparatorId, ]

    negControls <- subset[!is.na(subset$trueRr) & subset$trueRr == 1, ]
    null <- EmpiricalCalibration::fitMcmcNull(logRr = negControls$logRr,
                                              seLogRr = negControls$seLogRr)
    calibratedP <- EmpiricalCalibration::calibrateP(null = null,
                                                    logRr = subset$logRr,
                                                    seLogRr = subset$seLogRr)
    subset$calP <- calibratedP$p
    subset$calPlb <- calibratedP$lb95ci
    subset$calPub <- calibratedP$ub95ci

    controls <- subset[!is.na(subset$trueRr), ]
    model <- EmpiricalCalibration::fitSystematicErrorModel(logRr = controls$logRr,
                                                           seLogRr = controls$seLogRr,
                                                           trueLogRr = log(controls$trueRr))
    calibratedCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = subset$logRr,
                                                                      seLogRr = subset$seLogRr,
                                                                      model = model)
    subset$calLogRr <- calibratedCi$logRr
    subset$calSeLogRr <- calibratedCi$seLogRr
    subset$calRr <- exp(calibratedCi$logRr)
    subset$calCi95lb <- exp(calibratedCi$logLb95Rr)
    subset$calCi95ub <- exp(calibratedCi$logUb95Rr)
    return(subset)
}

tcs <- unique(meta[, c("targetId", "comparatorId")])
metaCalibrated <- lapply(1:nrow(tcs), calibrateMa, tcs = tcs, meta = meta)
metaCalibrated <- do.call("rbind", metaCalibrated)

write.csv(meta, file.path(folder, "MetaAnalysisCalibrated.csv"), row.names = FALSE)
