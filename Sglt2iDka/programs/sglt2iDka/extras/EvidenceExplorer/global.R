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
resultsHois <- resultsHois[, -c(41:312)] # drop TAR distribution columns

fileNames <- list.files(path = "data", pattern = "resultsNcs_.*.rds", full.names = TRUE)
resultsNcs <- lapply(fileNames, readRDS)
resultsNcs <- do.call(rbind, resultsNcs)

fileNames <- list.files(path = "data", pattern = "covarNames_.*.rds", full.names = TRUE)
covarNames <- lapply(fileNames, readRDS)
covarNames <- do.call(rbind, covarNames)
covarNames <- unique(covarNames)

formatDrug <- function(x) {
  x <- sub("-90", "", x)
  x <- sub("Insulinotropic", "Insul.", x)
}
resultsHois$targetDrug <- formatDrug(resultsHois$targetName)
resultsHois$comparatorDrug <- formatDrug(resultsHois$comparatorName)

resultsHois$tOrder <- match(resultsHois$targetName, c("SGLT2i-BROAD-90",
                                                      "SGLT2i-NARROW-90",
                                                      "Canagliflozin-BROAD-90",
                                                      "Canagliflozin-NARROW-90",
                                                      "Dapagliflozin-BROAD-90",
                                                      "Dapagliflozin-NARROW-90",
                                                      "Empagliflozin-BROAD-90",
                                                      "Empagliflozin-NARROW-90"))
resultsHois$cOrder <- match(resultsHois$comparatorName, c("SU-BROAD-90",
                                                          "SU-NARROW-90",
                                                          "DPP-4i-BROAD-90",
                                                          "DPP-4i-NARROW-90",
                                                          "GLP-1a-BROAD-90",
                                                          "GLP-1a-NARROW-90",
                                                          "TZDs-BROAD-90",
                                                          "TZDs-NARROW-90",
                                                          "Insulin-BROAD-90",
                                                          "Insulin-NARROW-90",
                                                          "Metformin-BROAD-90",
                                                          "Metformin-NARROW-90",
                                                          "Insulinotropic AHAs-BROAD-90",
                                                          "Insulinotropic AHAs-NARROW-90",
                                                          "Other AHAs-BROAD-90",
                                                          "Other AHAs-NARROW-90"))
resultsHois$dbOrder <- match(resultsHois$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))

resultsHois <- resultsHois[order(resultsHois$tOrder, resultsHois$cOrder, resultsHois$dbOrder), ]

resultsHois$rr[resultsHois$eventsTreated == 0 | resultsHois$eventsComparator == 0 | is.na(resultsHois$seLogRr) | is.infinite(resultsHois$seLogRr)] <- NA
resultsHois$ci95lb[resultsHois$eventsTreated == 0 | resultsHois$eventsComparator == 0 | is.na(resultsHois$seLogRr) | is.infinite(resultsHois$seLogRr)] <- NA
resultsHois$ci95ub[resultsHois$eventsTreated == 0 | resultsHois$eventsComparator == 0 | is.na(resultsHois$seLogRr) | is.infinite(resultsHois$seLogRr)] <- NA

resultsHois$comparison <- paste(resultsHois$targetDrug, resultsHois$comparatorDrug, sep = " vs. ")
comparisons <- unique(resultsHois$comparison)
outcomes <- unique(resultsHois$outcomeName)

outcomes[outcomes == "DKA (IP & ER)"] <- "DKA (IP or ER)"
resultsHois$outcomeName[resultsHois$outcomeName == "DKA (IP & ER)"] <- "DKA (IP or ER)"

resultsHois$timeAtRisk[resultsHois$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "Intent-to-Treat"
resultsHois$timeAtRisk[resultsHois$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "Per-Protocol"
timeAtRisks <- unique(resultsHois$timeAtRisk)
timeAtRisks <- timeAtRisks[order(timeAtRisks)]
dbs <- unique(resultsHois$database)

heterogeneous <- resultsHois[resultsHois$database == "Meta-analysis" & !is.na(resultsHois$i2) & resultsHois$i2 > 0.4, c("targetId", "comparatorId", "outcomeId", "analysisId")]
heterogeneous$heterogeneous <- "<span style=\"color:red\">yes</span>"
resultsHois <- merge(resultsHois, heterogeneous, all.x = TRUE)
resultsHois$heterogeneous[is.na(resultsHois$heterogeneous)] <- ""

dbInfoHtml <- readChar("DataSources.html", file.info("DataSources.html")$size)
comparisonsInfoHtml <- readChar("Comparisons.html", file.info("Comparisons.html")$size)
outcomesInfoHtml <- readChar("Outcomes.html", file.info("Outcomes.html")$size)
tarInfoHtml <- readChar("Tar.html", file.info("Tar.html")$size)

