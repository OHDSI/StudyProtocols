workFolder <- "R:/PopEstDepression_Ccae_old"

dbs <- c("CCAE_old", "MDCD", "MDCR", "Optum")

exposures <- read.csv(paste0(workFolder, "/exposureSummaryFilteredBySize.csv"))
exposures1 <- data.frame(targetId = exposures$tprimeCohortDefinitionId,
                               comparatorId = exposures$cprimeCohortDefinitionId,
                               targetName = exposures$tCohortDefinitionName,
                               comparatorName = exposures$cCohortDefinitionName)
exposures2 <- data.frame(targetId = exposures$cprimeCohortDefinitionId,
                               comparatorId = exposures$tprimeCohortDefinitionId,
                               targetName = exposures$cCohortDefinitionName,
                               comparatorName = exposures$tCohortDefinitionName)
exposures <- rbind(exposures1, exposures2)

pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
hois <- read.csv(pathToCsv)
hois <- data.frame(outcomeId = hois$cohortDefinitionId,
                   outcomeName = hois$name,
                   outcomeType = "hoi",
                   trueRr = NA)

pathToCsv <- system.file("settings", "NegativeControls.csv", package = "LargeScalePopEst")
negativeControls <- read.csv(pathToCsv)
negativeControls <- data.frame(outcomeId = negativeControls$conceptId,
                        outcomeName = negativeControls$name,
                        outcomeType = "negative control",
                        trueRr = 1)

calibrated <- data.frame()
for (db in dbs) {
    temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
    temp$db <- db
    temp <- merge(temp, exposures)

    tempHois <- merge(temp, hois)
    tempNegativeControls <- merge(temp, negativeControls)

    positiveControls <- read.csv(paste0("R:/PopEstDepression_", db, "/signalInjectionSummary.csv"))
    positiveControls <- merge(positiveControls, negativeControls[, c("outcomeId", "outcomeName")])
    positiveControls <- data.frame(outcomeId = positiveControls$newOutcomeId,
                                   exposureId = positiveControls$exposureId,
                                   outcomeName = paste0(positiveControls$outcomeName, "_rr", positiveControls$targetEffectSize),
                                   outcomeType = "positive control",
                                   trueRr = positiveControls$targetEffectSize)
    tempPositiveControls <- temp
    tempPositiveControls$exposureId <- as.character(tempPositiveControls$targetId)
    tempPositiveControls$exposureId <- substr(tempPositiveControls$exposureId, 1, nchar(tempPositiveControls$exposureId)-3)
    tempPositiveControls$exposureId <- as.numeric(tempPositiveControls$exposureId)
    tempPositiveControls <- merge(tempPositiveControls, positiveControls)
    tempPositiveControls$exposureId <- NULL

    calibrated <- rbind(calibrated, tempHois, tempNegativeControls, tempPositiveControls)
}
#temp[temp$outcomeId == 436634 & temp$targetId == 710062026 & temp$analysisId == 3, ]

calibrated <- calibrated[!(calibrated$targetName %in% c("Psychotherapy" , "Electroconvulsive therapy")) & !(calibrated$comparatorName %in% c("Psychotherapy" , "Electroconvulsive therapy")), ]
write.csv(calibrated, "r:/DepressionResults.csv", row.names = FALSE)




# Dataset checks ----------------------------------------------------------
#result <- calibrated
result <- read.csv("r:/DepressionResults.csv")
# Are all rows unique?
nrow(result) == nrow(unique(result[, c("analysisId", "db", "targetName", "comparatorName", "outcomeName")]))

# Symmetrical?
half1 <- result[result$targetId < result$comparatorId & result$outcomeType == "hoi", ]
half2 <- result[result$targetId > result$comparatorId & result$outcomeType == "hoi", ]
nrow(half1) == nrow(half2)

# All DBs?
aggregate(analysisId ~ db, data = result, length)

#Negative SEs?
!any(result$calSeLogRr < 0, na.rm = TRUE)

# calibrated and uncalibrated are correlated?
library(ggplot2)
ggplot(result, aes(x = rr, y = calRr)) +
    geom_point() +
    scale_x_log10(limits = c(0.1,10)) +
    scale_y_log10(limits = c(0.1,10)) +
    facet_wrap(~db)

# A to B correlated with B to A?
half1 <- result[result$targetId < result$comparatorId & result$outcomeType == "hoi", c("targetId", "comparatorId", "outcomeId", "analysisId", "db", "calRr")]
half2 <- result[result$targetId > result$comparatorId & result$outcomeType == "hoi", c("targetId", "comparatorId", "outcomeId", "analysisId", "db", "calRr")]
d <- merge(half1, half2, by.x = c("targetId", "comparatorId", "outcomeId", "analysisId", "db"), by.y = c("comparatorId", "targetId", "outcomeId", "analysisId", "db"))
library(ggplot2)
ggplot(d, aes(x = calRr.x, y = calRr.y)) +
    geom_point() +
    scale_x_log10(limits = c(0.1,10)) +
    scale_y_log10(limits = c(0.1,10)) +
    facet_wrap(~db)
