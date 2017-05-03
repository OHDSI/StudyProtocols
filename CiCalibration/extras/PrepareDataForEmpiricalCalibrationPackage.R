# Estimates from Southworth and Graham replications ------------------------------

mdcrFolder <- "S:/Temp/CiCalibration_Mdcr"
optumFolder <- "S:/Temp/CiCalibration_Optum"
packageFolder <- "C:/Users/mschuemi/git/EmpiricalCalibration/data"

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
calibrated <- calibrated[!is.na(calibrated$seLogRr), c("outcomeName", "trueLogRr", "logRr", "seLogRr")]
southworthReplication <- calibrated
save(southworthReplication, file = file.path(packageFolder, "southworthReplication.rda"))

calibratedFile <- file.path(mdcrFolder, "Calibrated_Graham_cohort_method.csv")
calibrated <- read.csv(calibratedFile)
calibrated$outcomeId[!is.na(calibrated$oldOutcomeId)] <- calibrated$oldOutcomeId[!is.na(calibrated$oldOutcomeId)]
calibrated$study <- "Graham replication"
calibrated <- merge(calibrated, idToNames)
calibrated <- calibrated[!is.na(calibrated$seLogRr), c("outcomeName", "trueLogRr", "logRr", "seLogRr")]
grahamReplication <- calibrated
save(grahamReplication, file = file.path(packageFolder, "grahamReplication.rda"))
