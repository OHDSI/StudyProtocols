#' @export
createHrTableFormatted <- function(outputFolders,
                                   databaseNames,
                                   maOutputFolder,
                                   reportFolder) {
  loadResultsHois <- function(outputFolder,
                              fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$targetCohort <- sub(pattern = "-90", replacement = "", x = results$targetName)
  results$comparatorCohort <- sub(pattern = "-90", replacement = "", x = results$comparatorName)
  results$comparison <- paste(results$targetCohort, results$comparatorCohort, sep = " - ")
  results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"
  results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "PP"
  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)  # for correct ordering
  tcosAnalyses$tOrder <- match(tcosAnalyses$targetCohortName, c("SGLT2i-BROAD-90",
                                                              "SGLT2i-NARROW-90",
                                                              "Canagliflozin-BROAD-90",
                                                              "Canagliflozin-NARROW-90",
                                                              "Dapagliflozin-BROAD-90",
                                                              "Dapagliflozin-NARROW-90",
                                                              "Empagliflozin-BROAD-90",
                                                              "Empagliflozin-NARROW-90"))
  tcosAnalyses$cOrder <- match(tcosAnalyses$comparatorCohortName, c("SU-BROAD-90",
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
  tcosAnalyses <- tcosAnalyses[order(tcosAnalyses$tOrder, tcosAnalyses$cOrder), ]
  tcosAnalyses$targetCohort <- sub(pattern = "-90", replacement = "", x = tcosAnalyses$targetCohortName)
  tcosAnalyses$comparatorCohort <- sub(pattern = "-90", replacement = "", x = tcosAnalyses$comparatorCohortName)
  comparisonsOfInterest <- unique(paste(tcosAnalyses$targetCohort, tcosAnalyses$comparatorCohort, sep = " - "))
  outcomeNames <- unique(results$outcomeName)
  timeAtRisks <- unique(results$timeAtRisk)

  fileName <- file.path(reportFolder, paste0("HRsFormatted.xlsx"))
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  for (outcomeName in outcomeNames) { # outcomeName <- outcomeNames[2]
    for (timeAtRisk in timeAtRisks) { # timeAtRisk <- timeAtRisks[1]

      results$dbOrder <- match(results$database, c("CCAE", "MDCD", "MDCR", "Optum", "Meta-analysis"))
      results$comparisonOrder <- match(results$comparison, comparisonsOfInterest)
      results <- results[order(results$comparisonOrder, results$dbOrder), ]

      idx <- results$outcomeName == outcomeName & results$timeAtRisk == timeAtRisk  # & results$comparison %in% comparisonsOfInterest

      results$rr[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA
      results$ci95lb[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA
      results$ci95ub[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA
      drops <- names(results) %in% grep("bm", names(results), value = TRUE)
      results <- results[!drops]

      outTarResults <- results[idx, ]

      outTarBroadResults <- outTarResults[grep("BROAD", outTarResults$targetName), ]
      outTarBroadResults$comparison <- gsub("-BROAD", "", outTarBroadResults$comparison)

      outTarNarrowResults <- outTarResults[grep("NARROW", outTarResults$targetName), ]
      outTarNarrowResults$comparison <- gsub("-NARROW", "", outTarNarrowResults$comparison)

      formatComparison  <- function(x) {
        result <- sub(pattern = " - ", replacement = " vs. ", x = x)
        return(result)
      }

      formatSampleSize <- function(subjects) {
        paste(formatC(subjects, big.mark = ",", format="d"))
      }

      formatEventCounts <- function(tEvents, cEvents) {
        paste(tEvents, cEvents, sep = " / ")
      }
      formatHr <- function(hr, lb, ub) {
        sprintf("%s (%s-%s)",
                formatC(hr, digits = 2, format = "f"),
                formatC(lb, digits = 2, format = "f"),
                formatC(ub, digits = 2, format = "f"))
      }

      mainTable <- data.frame(question = formatComparison(outTarBroadResults$comparison),
                              source = outTarBroadResults$database,
                              broadPairs = formatSampleSize(outTarBroadResults$treated),
                              broadEvents = formatEventCounts(outTarBroadResults$eventsTreated, outTarBroadResults$eventsComparator),
                              broadHr = formatHr(outTarBroadResults$rr, outTarBroadResults$ci95lb, outTarBroadResults$ci95ub),
                              broadP = round(outTarBroadResults$p, 2),
                              broadCalP = round(outTarBroadResults$calP, 2),

                              narrowPairs = formatSampleSize(outTarNarrowResults$treated),
                              narrowEvents = formatEventCounts(outTarNarrowResults$eventsTreated, outTarNarrowResults$eventsComparator),
                              narrowHr = formatHr(outTarNarrowResults$rr, outTarNarrowResults$ci95lb, outTarNarrowResults$ci95ub),
                              narrowP = round(outTarNarrowResults$p, 2),
                              narrowCalP = round(outTarNarrowResults$calP, 2))

      sheet <- paste(outcomeName, timeAtRisk)
      XLConnect::createSheet(wb, name = sheet)
      header0 <- rep("", 12)
      header0[3] <- "Broad T2DM"
      header0[8] <- "Narrow T2DM"
      XLConnect::writeWorksheet(wb,
                                sheet = sheet,
                                data = as.data.frame(t(header0)),
                                startRow = 1,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::mergeCells(wb, sheet = sheet, reference = "C1:G1")
      XLConnect::mergeCells(wb, sheet = sheet, reference = "H1:L1")
      header1 <- c("Comparison",
                   "Database",
                   "N pairs",
                   "N events (T/C)",
                   "HR (95% CI)",
                   "p",
                   "Cal. p",
                   "N pairs",
                   "N events (T/C)",
                   "HR (95% CI)",
                   "p",
                   "Cal. p")
      XLConnect::writeWorksheet(wb,
                                sheet = sheet,
                                data = as.data.frame(t(header1)),
                                startRow = 2,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::writeWorksheet(wb,
                                data = mainTable,
                                sheet = sheet,
                                startRow = 3,
                                startCol = 1,
                                header = FALSE,
                                rownames = FALSE)
      cells <- paste0("A", seq(from = 3, to = 153, by = 5), ":A", seq(from = 7, to = 157, by = 5))
      for (cell in cells) {
        XLConnect::mergeCells(wb, sheet = sheet, reference = cell)
      }
    }
  }
  XLConnect::saveWorkbook(wb)
}
