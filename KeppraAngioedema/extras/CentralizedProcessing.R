library(KeppraAngioedema)

# Create per-database reports:
studyFolder <- "S:/Angioedema"
for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
    if (file.info(file.path(studyFolder, file))$isdir) {
        writeLines(paste("Processing", file))
        createTableAndFigures(file.path(studyFolder, file))
        writeReport(file.path(studyFolder, file), file.path(studyFolder, paste0("Report_", file, ".docx")))
    }
}

# Create summary csv file:
allResults <- data.frame()
for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
    if (file.info(file.path(studyFolder, file))$isdir) {
        writeLines(paste("Processing", file))
        results <- read.csv(file.path(studyFolder, file, "tablesAndFigures", "EmpiricalCalibration.csv"))
        results <- results[results$outcomeId == 3, ]
        results$db <- file
        results <- results[,c(ncol(results), 1:(ncol(results)-1))]
        allResults <- rbind(allResults, results)
    }
}
write.csv(allResults, file.path(studyFolder, "AllResults.csv"), row.names = FALSE)





# exportFolder <- "S:/Angioedema/Regenstrief"
# mr <- read.csv(file.path(exportFolder, "MainResults.csv"))
# mr <- KeppraAngioedema:::addAnalysisDescriptions(mr)
mr <- KeppraAngioedema:::addCohortNames(mr, "outcomeId", "outcomeName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "targetId", "targetName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "comparatorId", "comparatorName")
# write.csv(mr, file.path(exportFolder, "MainResults.csv"), row.names = FALSE)
