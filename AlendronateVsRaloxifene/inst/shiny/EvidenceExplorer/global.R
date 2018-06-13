unlink("s:/temp/log.txt")
OhdsiRTools::addDefaultFileLogger("s:/temp/log.txt")

# shinySettings <- list(studyFolder = 'S:/SkeletonStudy', blind = TRUE)
studyFolder <- shinySettings$studyFolder
blind <- shinySettings$blind
OhdsiRTools::logDebug(studyFolder)

databases <- list.files(studyFolder, include.dirs = TRUE)

loadEstimates <- function(database) {
  fileName <- file.path(studyFolder, database, "AllCalibratedEstimates.rds")
  dbEstimates <- readRDS(fileName)
  dbEstimates$database <- database
  return(dbEstimates)
}
estimates <- lapply(databases, loadEstimates)
estimates <- do.call(rbind, estimates)

resultsControls <- estimates[!is.na(estimates$targetEffectSize), ]
resultsHois <- estimates[is.na(estimates$targetEffectSize), ]
if (blind) {
  resultsHois$rr <- as.numeric(NA)
  resultsHois$ci95lb <- as.numeric(NA)
  resultsHois$ci95ub <- as.numeric(NA)
  resultsHois$logRr <- as.numeric(NA)
  resultsHois$seLogRr <- as.numeric(NA)
  resultsHois$p <- as.numeric(NA)
  resultsHois$calP <- as.numeric(NA)
}
resultsHois$comparison <- paste(resultsHois$targetName, resultsHois$comparatorName, sep = " vs. ")
resultsHois$psStrategy <- "Stratification"

comparisons <- unique(resultsHois$comparison)
comparisons <- comparisons[order(comparisons)]

outcomes <- as.character(unique(resultsHois$outcomeName))
analyses <- as.character(unique(resultsHois$description))

loadMdrrs <- function(database) {
  fileName <- file.path(studyFolder, database, "Mdrrs.csv")
  dbMdrrs <- read.csv(fileName)
  dbMdrrs$database <- database
  return(dbMdrrs)
}
mdrrs <- lapply(databases, loadMdrrs)
mdrrs <- do.call(rbind, mdrrs)
resultsHois <- merge(resultsHois,
                     mdrrs[,
                     c("targetId", "comparatorId", "outcomeId", "analysisId", "database", "mdrr")])
