library(AlendronateVsRaloxifene)
library(gridExtra)

table.png <- function(obj, name) {

  obj <- crude
  name <- file.path(studyFolder, "countsItt")


  first <- name
  name <- paste(name,".tex",sep="")
  sink(file=name)
  cat('
      \\documentclass{report}
      \\usepackage[paperwidth=5.5in,paperheight=7in,noheadfoot,margin=0in]{geometry}
      \\begin{document}\\pagestyle{empty}
      ')
  print(xtable::xtable(obj))
  cat('
      \\end{document}
      ')
  sink()
  tools::texi2dvi(file=name)
  cmd <- paste("dvipng -T tight", shQuote(paste(first,".dvi",sep="")))
  invisible(system(cmd))
  cleaner <- c(".tex",".aux",".log",".dvi")
  invisible(file.remove(paste(first,cleaner,sep="")))
}

# Create per-database reports:
studyFolder <- "/Users/msuchard/Dropbox/OHDSI/hip_fracture"
folders <- c("MDCD_JRD", "CCAE_JRD", "MDCR_JRD", "MDCR_UNM", "Optum_JRD", "GEDA_XXX", "Columbia")
for (file in folders) {
    if (file.info(file.path(studyFolder, file))$isdir) {
        writeLines(paste("Processing", file))
        createTableAndFigures(file.path(studyFolder, file))
        # writeReport(file.path(studyFolder, file), file.path(studyFolder, paste0("Report_", file, ".docx")))
        writeReport(file.path(studyFolder, file),
                    file.path(studyFolder, paste0("Report_", file, ".pdf")),
                    outputFormat = "pdf_document")
    }
}

# Create summary csv file:
allResults <- data.frame()
outcomeId <- 99323 # Hip fracture
analysisId <- 1 # ITT
#skip <- c("IMEDS_MDCR", "Regenstrief", "Pplus")
skip <- c()
#for (file in list.files(path = studyFolder, include.dirs = TRUE)) {
for (file in folders) {
    if (!(file %in% skip)) {
        if (file.info(file.path(studyFolder, file))$isdir) {
            writeLines(paste("Processing", file))
            results <- read.csv(file.path(studyFolder, file, "tablesAndFigures", "EmpiricalCalibration.csv"))
            results <- results[results$outcomeId == outcomeId, ]
            results$db <- file
            results <- results[,c(ncol(results), 1:(ncol(results)-1))]
            allResults <- rbind(allResults, results)
        }
    }
}
write.csv(allResults, file.path(studyFolder, "AllResults.csv"), row.names = FALSE)



# Meta analysis -----------------------------------------------------------
allResults <- read.csv(file.path(studyFolder, "AllResults.csv"), stringsAsFactors = FALSE)
# allResults$db[allResults$db == "Ims_Amb_Emr"] <- "IMS Ambulatory"
# allResults$db[allResults$db == "Optum"] <- "Optum"
# allResults$db[allResults$db == "Pplus_Ims"] <- "IMS P-Plus"
# allResults$db[allResults$db == "Truven_CCAE"] <- "Truven CCAE"
# allResults$db[allResults$db == "Truven_MDCD"] <- "Truven MDCD"
# allResults$db[allResults$db == "Truven_MDCR"] <- "Truven MDCR"
# allResults$db[allResults$db == "UT_Cerner"] <- "UT EMR"
source("extras/MetaAnalysis.R")

fileName <- file.path(studyFolder, "ForestItt.png")
results <- allResults[allResults$analysisId == 1, ]
crude <- results[,c("db","treated","comparator","treatedDays","comparatorDays","eventsTreated","eventsComparator")]
table.png(crude, file.path(studyFolder, "countsItt"))

png(file.path(studyFolder, "counts.png"),
    height=30*nrow(crude), width=100*ncol(crude))
p<-tableGrob(crude)
grid.arrange(p)
dev.off()


results <- results[!is.na(results$seLogRr), ]
plotForest(logRr = results$logRr,
           logLb95Ci = log(results$ci95lb),
           logUb95Ci = log(results$ci95ub),
           names = results$db,
           xLabel = "Hazard Ratio",
           fileName = fileName)

fileName <- file.path(studyFolder, "ForestPp.png")
results <- allResults[allResults$analysisId == 2, ]
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


