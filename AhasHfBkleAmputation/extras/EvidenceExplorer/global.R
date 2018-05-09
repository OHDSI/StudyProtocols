blind <- FALSE

fileNames <- list.files(path = "data", pattern = "resultsHois_.*.rds", full.names = TRUE)
resultsHois <- lapply(fileNames, readRDS)
allColumns <- unique(unlist(lapply(resultsHois, colnames)))
addMissingColumns <- function(results) {
  presentCols <- colnames(results)
  missingCols <- allColumns[!(allColumns %in% presentCols)]
  for (missingCol in missingCols) {
    results[, missingCol] <- rep(NA, nrow(results))
  }
  return(results)
}
resultsHois <- lapply(resultsHois, addMissingColumns)
resultsHois <- do.call(rbind, resultsHois)

fileNames <- list.files(path = "data", pattern = "resultsNcs_.*.rds", full.names = TRUE)
resultsNcs <- lapply(fileNames, readRDS)
resultsNcs <- do.call(rbind, resultsNcs)

fileNames <- list.files(path = "data", pattern = "covarNames_.*.rds", full.names = TRUE)
covarNames <- lapply(fileNames, readRDS)
covarNames <- do.call(rbind, covarNames)
covarNames <- unique(covarNames)

formatDrug  <- function(x) {
  result <- x
  result[x == "empagliflozin or dapagliflozin"] <- "other SGLT2i"
  result[x == "any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "select non-SGLT2i"
  result[x == "any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "all non-SGLT2i"
  return(result)
}
resultsHois$targetDrug <- formatDrug(resultsHois$targetDrug)
resultsHois$comparatorDrug <- formatDrug(resultsHois$comparatorDrug)
resultsHois$comparison <- paste(resultsHois$targetDrug, resultsHois$comparatorDrug, sep = " vs. ")

comparisons <- unique(resultsHois$comparison)
comparisons <- comparisons[order(comparisons)]
outcomes <- unique(resultsHois$outcomeName)
establishCvds <- unique(resultsHois$establishedCvd)
priorExposures <- unique(resultsHois$priorExposure)
timeAtRisks <- unique(resultsHois$timeAtRisk)
timeAtRisks <- timeAtRisks[order(timeAtRisks)]
evenTypes <- unique(resultsHois$evenType)
psStrategies <- unique(resultsHois$psStrategy)
dbs <- unique(resultsHois$database)

heterogeneous <- resultsHois[resultsHois$database == "Meta-analysis (DL)" & !is.na(resultsHois$i2) & resultsHois$i2 > 0.4, c("targetId", "comparatorId", "outcomeId", "analysisId")]
heterogeneous$heterogeneous <- "<span style=\"color:red\">yes</span>"
resultsHois <- merge(resultsHois, heterogeneous, all.x = TRUE)
resultsHois$heterogeneous[is.na(resultsHois$heterogeneous)] <- ""

dbInfoHtml <- readChar("DataSources.html", file.info("DataSources.html")$size)
comparisonsInfoHtml <- readChar("Comparisons.html", file.info("Comparisons.html")$size)
outcomesInfoHtml <- readChar("Outcomes.html", file.info("Outcomes.html")$size)
cvdInfoHtml <- readChar("Cvd.html", file.info("Cvd.html")$size)
priorExposureInfoHtml <- readChar("PriorExposure.html", file.info("PriorExposure.html")$size)
tarInfoHtml <- readChar("Tar.html", file.info("Tar.html")$size)
eventInfoHtml <- readChar("Event.html", file.info("Event.html")$size)
psInfoHtml <- readChar("Ps.html", file.info("Ps.html")$size)

