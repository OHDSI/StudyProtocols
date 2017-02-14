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



# Meta analysis -----------------------------------------------------------
allResults <- read.csv(file.path(studyFolder, "AllResults.csv"), stringsAsFactors = FALSE)
allResults$db[allResults$db == "Ims_Amb_Emr"] <- "IMS Ambulatory"
allResults$db[allResults$db == "Optum"] <- "Optum"
allResults$db[allResults$db == "Pplus_Ims"] <- "IMS P-Plus"
allResults$db[allResults$db == "Truven_CCAE"] <- "Truven CCAE"
allResults$db[allResults$db == "Truven_MDCD"] <- "Truven MDCD"
allResults$db[allResults$db == "Truven_MDCR"] <- "Truven MDCR"
allResults$db[allResults$db == "UT_Cerner"] <- "UT EMR"
source("extras/MetaAnalysis.R")

fileName <- file.path(studyFolder, "ForestPp.png")
results <- allResults[allResults$analysisId == 3, ]
results <- results[!is.na(results$seLogRr), ]
plotForest(logRr = results$logRr,
           logLb95Ci = log(results$ci95lb),
           logUb95Ci = log(results$ci95ub),
           names = results$db,
           xLabel = "Hazard Ratio",
           fileName = fileName)

fileName <- file.path(studyFolder, "ForestItt.png")
results <- allResults[allResults$analysisId == 7, ]
results <- results[!is.na(results$seLogRr), ]
plotForest(logRr = results$logRr,
           logLb95Ci = log(results$ci95lb),
           logUb95Ci = log(results$ci95ub),
           names = results$db,
           xLabel = "Hazard Ratio",
           fileName = fileName)

meta <- metagen(results$logRr, results$seLogRr, studlab = results$db, sm = "RR")
s <- summary(meta)$random
exp(s$TE)

forest(meta)

results <- allResults[allResults$analysisId == 7, ]
results <- results[!is.na(results$seLogRr), ]
meta <- metagen(results$logRr, results$seLogRr, studlab = results$db, sm = "RR")
forest(meta)


# exportFolder <- "S:/Angioedema/Regenstrief"
# mr <- read.csv(file.path(exportFolder, "MainResults.csv"))
# mr <- KeppraAngioedema:::addAnalysisDescriptions(mr)
mr <- KeppraAngioedema:::addCohortNames(mr, "outcomeId", "outcomeName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "targetId", "targetName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "comparatorId", "comparatorName")
# write.csv(mr, file.path(exportFolder, "MainResults.csv"), row.names = FALSE)
