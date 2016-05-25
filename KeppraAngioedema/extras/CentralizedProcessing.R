library(KeppraAngioedema)

# Create per-database reports:
studyFolder <- "S:/Angioedema"
for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
    writeLines(paste("Processing", file))
    createTableAndFigures(file.path(studyFolder, file))
    writeReport(file.path(studyFolder, file), file.path(studyFolder, paste0("Report_", file, ".docx")))
}







# exportFolder <- "S:/Angioedema/Regenstrief"
# mr <- read.csv(file.path(exportFolder, "MainResults.csv"))
# mr <- KeppraAngioedema:::addAnalysisDescriptions(mr)
# mr <- KeppraAngioedema:::addCohortNames(mr, "outcomeId", "outcomeName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "targetId", "targetName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "comparatorId", "comparatorName")
# write.csv(mr, file.path(exportFolder, "MainResults.csv"), row.names = FALSE)
