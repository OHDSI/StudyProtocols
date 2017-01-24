library(KeppraAngioedema)

# Create per-database reports:
studyFolder <- "S:/Angioedema"
folders <- c("Truven_CCAE", "Truven_MDCD", "Truven_MDCR", "Optum")
folders <- "Ims_Amb_Emr"
folders <- "Pplus_Ims"
folders <- "Ims_Da_French_Emr"
#for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
for (file in folders) {
    if (file.info(file.path(studyFolder, file))$isdir) {
        writeLines(paste("Processing", file))
        createTableAndFigures(file.path(studyFolder, file))
        writeReport(file.path(studyFolder, file), file.path(studyFolder, paste0("Report_", file, ".docx")))
    }
}

# Create summary csv file:
allResults <- data.frame()
skip <- c("IMEDS_MDCR", "Regenstrief", "Pplus")
for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
    if (!(file %in% skip)) {
        if (file.info(file.path(studyFolder, file))$isdir) {
            writeLines(paste("Processing", file))
            results <- read.csv(file.path(studyFolder, file, "tablesAndFigures", "EmpiricalCalibration.csv"))
            results <- results[results$outcomeId == 3, ]
            results$db <- file
            results <- results[,c(ncol(results), 1:(ncol(results)-1))]
            allResults <- rbind(allResults, results)
        }
    }
}
write.csv(allResults, file.path(studyFolder, "AllResults.csv"), row.names = FALSE)

results <- allResults[allResults$analysisId == 3, ]
results <- results[!is.na(results$seLogRr), ]

library(meta)
meta <- metagen(results$logRr, results$seLogRr, studlab = results$db, sm = "RR")
forest(meta)


# exportFolder <- "S:/Angioedema/Regenstrief"
# mr <- read.csv(file.path(exportFolder, "MainResults.csv"))
# mr <- KeppraAngioedema:::addAnalysisDescriptions(mr)
mr <- KeppraAngioedema:::addCohortNames(mr, "outcomeId", "outcomeName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "targetId", "targetName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "comparatorId", "comparatorName")
# write.csv(mr, file.path(exportFolder, "MainResults.csv"), row.names = FALSE)
