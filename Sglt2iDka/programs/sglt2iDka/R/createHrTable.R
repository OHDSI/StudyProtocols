#' @export
createHrTable <- function(outputFolders,
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

  fileName <- file.path(reportFolder, paste0("HRs.xlsx"))
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  for (outcomeName in outcomeNames) {
    # outcomeName <- outcomeNames[1]

    XLConnect::createSheet(wb, name = outcomeName)

    header0 <- rep("", 20)
    header0[3] <- "Intent-to-treat"
    header0[13] <- "Per protocol"
    XLConnect::writeWorksheet(wb,
                              sheet = outcomeName,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "C1:L1")
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "M1:T1")
    header1 <- c("",
                 "",
                 "Exposed (#/PY)",
                 "",
                 "Outcomes",
                 "",
                 "",
                 "",
                 "HR (95% CI)",
                 "p",
                 "Cal. p",
                 "Null",
                 "Exposed (#/PY)",
                 "",
                 "Outcomes",
                 "",
                 "",
                 "",
                 "HR (95% CI)",
                 "p",
                 "Cal. p",
                 "Null")
    XLConnect::writeWorksheet(wb,
                              sheet = outcomeName,
                              data = as.data.frame(t(header1)),
                              startRow = 2,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "C2:D2")
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "E2:H2")
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "M2:N2")
    XLConnect::mergeCells(wb, sheet = outcomeName, reference = "O2:R2")
    header2 <- c("Comparison",
                 "Source",
                 "T",
                 "C",
                 "T",
                 "T-IR",
                 "C",
                 "C-IR",
                 "",
                 "",
                 "",
                 "",
                 "T",
                 "C",
                 "T",
                 "T-IR",
                 "C",
                 "C-IR")
    XLConnect::writeWorksheet(wb,
                              sheet = outcomeName,
                              data = as.data.frame(t(header2)),
                              startRow = 3,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)

    idx <- results$outcomeName == outcomeName & results$comparison %in% comparisonsOfInterest

    results$dbOrder <- match(results$database, c("CCAE", "MDCD", "MDCR", "Optum", "Meta-analysis"))
    results$comparisonOrder <- match(results$comparison, comparisonsOfInterest)

    results$rr[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA
    results$ci95lb[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA
    results$ci95ub[results$eventsTreated == 0 | results$eventsComparator == 0 | is.na(results$seLogRr) | is.infinite(results$seLogRr)] <- NA

    intentToTreat <- results[idx & results$timeAtRisk == "ITT", ]
    intentToTreat <- intentToTreat[order(intentToTreat$comparisonOrder, intentToTreat$dbOrder), ]
    perProtocol <- results[idx & results$timeAtRisk == "PP", ]
    perProtocol <- perProtocol[order(perProtocol$comparisonOrder, perProtocol$dbOrder), ]

    if (!all.equal(perProtocol$comparison, intentToTreat$comparison) ||
        !all.equal(perProtocol$database, intentToTreat$database)) {
      stop("Problem with sorting of data")
    }

    formatComparison  <- function(x) {
      result <- sub(pattern = " - ", replacement = " vs. ", x = x)
      return(result)
    }
    formatSampleSize <- function(subjects, days) {
      paste(formatC(subjects, big.mark = ",", format="d"),
            formatC(days/365.25, big.mark = ",", format="d"),
            sep = " / ")
    }
    formatHr <- function(hr, lb, ub) {
      sprintf("%s (%s-%s)",
              formatC(hr, digits = 2, format = "f"),
              formatC(lb, digits = 2, format = "f"),
              formatC(ub, digits = 2, format = "f"))
    }

    mainTable <- data.frame(question = formatComparison(intentToTreat$comparison),
                            source = intentToTreat$database,
                            titt = formatSampleSize(intentToTreat$treated, intentToTreat$treatedDays),
                            citt = formatSampleSize(intentToTreat$comparator, intentToTreat$comparatorDays),
                            oTitt = intentToTreat$eventsTreated,
                            irTitt = round(intentToTreat$eventsTreated / (intentToTreat$treatedDays / 365.25) * 1000, 2) ,
                            oCitt = intentToTreat$eventsComparator,
                            irCitt = round(intentToTreat$eventsComparator / (intentToTreat$comparatorDays / 365.25) * 1000, 2),
                            hritt = formatHr(intentToTreat$rr, intentToTreat$ci95lb, intentToTreat$ci95ub),
                            pitt = round(intentToTreat$p, 2),
                            calitt = round(intentToTreat$calP, 2),
                            nullitt = round(exp(intentToTreat$null_mean), 2),
                            tpp = formatSampleSize(perProtocol$treated, perProtocol$treatedDays),
                            cpp = formatSampleSize(perProtocol$comparator, perProtocol$comparatorDays),
                            oTpp = perProtocol$eventsTreated,
                            irTpp = round(perProtocol$eventsTreated / (perProtocol$treatedDays / 365.25) * 1000, 2),
                            oCpp = perProtocol$eventsComparator,
                            irCpp = round(perProtocol$eventsComparator / (perProtocol$comparatorDays / 365.25) * 1000, 2),
                            hrpp = formatHr(perProtocol$rr, perProtocol$ci95lb, perProtocol$ci95ub),
                            ppp = round(perProtocol$p, 2),
                            calPpp = round(perProtocol$calP, 2),
                            nullpp = round(exp(perProtocol$null_mean), 2))

    XLConnect::writeWorksheet(wb,
                              data = mainTable,
                              sheet = outcomeName,
                              startRow = 4,
                              startCol = 1,
                              header = FALSE,
                              rownames = FALSE)
    cells <- paste0("A", seq(from = 4, to = 309, by = 5), ":A", seq(from = 8, to = 313, by = 5))
    for (cell in cells) {
      XLConnect::mergeCells(wb, sheet = outcomeName, reference = cell)
    }
  }
  XLConnect::saveWorkbook(wb)
}
