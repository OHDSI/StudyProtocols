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

resultsHois$comparison <- paste(resultsHois$targetDrug, resultsHois$comparatorDrug, sep = " - ")
comparisons <- unique(resultsHois$comparison)
comparisons <- comparisons[order(comparisons)]
outcomes <- unique(resultsHois$outcomeName)
establishCvds <- unique(resultsHois$establishedCvd)
priorExposures <- unique(resultsHois$priorExposure)
timeAtRisks <- unique(resultsHois$timeAtRisk)
evenTypes <- unique(resultsHois$evenType)
psStrategies <- unique(resultsHois$psStrategy)
dbs <- unique(resultsHois$database)
