#' @export
createIrTableFormatted <- function(outputFolders,
                                   databaseNames,
                                   reportFolder,
                                   sensitivity) {
  if (sensitivity == FALSE) {
    loadResultsHois <- function(outputFolder,
                                fileName) {
      shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
      file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
      x <- readRDS(file)
      if (is.null(x$i2))
        x$i2 <- NA
      return(x)
    }
    results <- lapply(outputFolders, loadResultsHois)
    results <- do.call(rbind, results)
    results$targetCohort <- sub(pattern = "-90", replacement = "", x = results$targetName)
    results$comparatorCohort <- sub(pattern = "-90", replacement = "", x = results$comparatorName)
    results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"
    results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "PP"
    fileName <- file.path(reportFolder, paste0("IRsFormatted.xlsx"))
    unlink(fileName)
  }

  if (sensitivity == TRUE) {
    loadIrSensitivityResults <- function(outputFolder) {
      shinyDataFolder <- file.path(outputFolder, "results", "irSensitivityData")
      file <- list.files(shinyDataFolder, pattern = "irSensitivityData_.*.rds", full.names = TRUE)
      x <- readRDS(file)
      return(x)
    }
    results <- lapply(outputFolders, loadIrSensitivityResults)
    results <- do.call(rbind, results)
    results$timeAtRisk <- ""
    results[grep("-60", results$targetName), "timeAtRisk"] <- "PP-60"
    results[grep("-120", results$targetName), "timeAtRisk"] <- "PP-120"
    results$targetCohort <- sub(pattern = "-60", replacement = "", x = results$targetName)
    results$targetCohort <- sub(pattern = "-120", replacement = "", x = results$targetCohort)
    results$comparatorCohort <- sub(pattern = "-60", replacement = "", x = results$comparatorName)
    results$comparatorCohort <- sub(pattern = "-120", replacement = "", x = results$comparatorCohort)
    fileName <- file.path(reportFolder, paste0("IRsSensitivityFormatted.xlsx"))
    unlink(fileName)
  }

  outcomeNames <- unique(results$outcomeName)
  timeAtRisks <- unique(results$timeAtRisk)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  subgroups <- list(
    Overall = c(
      "bmTreated", "bmTreatedDays", "bmEventsTreated",
      "bmTarTargetMean", "bmTarTargetSd", "bmTarTargetMin", "bmTarTargetMedian", "bmTarTargetMax",
      "bmComparator", "bmComparatorDays", "bmEventsComparator",
      "bmTarComparatorMean", "bmTarComparatorSd", "bmTarComparatorMin", "bmTarComparatorMedian", "bmTarComparatorMax"))

  for (i in 1:length(subgroups)) { # i=1
    mainTable <- data.frame()
    cols <- subgroups[[i]]
    subgroup <- names(subgroups)[i]
    for (database in databaseNames) { # database <- "CCAE"
      dbTable <- data.frame()
      for (outcomeName in outcomeNames[[2]]) { # outcomeName <- outcomeNames[2], only DKA IP/ER
        for (timeAtRisk in timeAtRisks[[1]]) { # timeAtRisk <- timeAtRisks[[1]],  only ITT
          subset <- results[results$database == database &
                              results$outcomeName == outcomeName &
                              results$timeAtRisk == timeAtRisk, ]

          # Ts broad
          sglt2iBroad <- subset[subset$targetCohort == "SGLT2i-BROAD", ][1, cols]
          canaBroad <- subset[subset$targetCohort == "Canagliflozin-BROAD", ][1, cols]
          dapaBroad <- subset[subset$targetCohort == "Dapagliflozin-BROAD", ][1, cols]
          empaBroad <- subset[subset$targetCohort == "Empagliflozin-BROAD", ][1, cols]

          # Cs broad
          dpp4Broad <- subset[subset$comparatorCohort == "DPP-4i-BROAD", ][1, cols]
          glp1Broad <- subset[subset$comparatorCohort == "GLP-1a-BROAD", ][1, cols]
          suBroad <- subset[subset$comparatorCohort == "SU-BROAD", ][1, cols]
          tzdBroad <- subset[subset$comparatorCohort == "TZDs-BROAD", ][1, cols]
          insulinBroad <- subset[subset$comparatorCohort == "Insulin-BROAD", ][1, cols]
          metforminBroad <- subset[subset$comparatorCohort == "Metformin-BROAD", ][1, cols]
          insAhasBroad <- subset[subset$comparatorCohort == "Insulinotropic AHAs-BROAD", ][1, cols]
          otherAhasBroad <- subset[subset$comparatorCohort == "Other AHAs-BROAD", ][1, cols]

          # Ts narrow
          sglt2iNarrow <- subset[subset$targetCohort == "SGLT2i-NARROW", ][1, cols]
          canaNarrow <- subset[subset$targetCohort == "Canagliflozin-NARROW", ][1, cols]
          empaNarrow <- subset[subset$targetCohort == "Empagliflozin-NARROW", ][1, cols]
          dapaNarrow <- subset[subset$targetCohort ==  "Dapagliflozin-NARROW", ][1, cols]

          # Cs narrow
          dpp4Narrow <- subset[subset$comparatorCohort == "DPP-4i-NARROW", ][1, cols]
          glp1Narrow <- subset[subset$comparatorCohort == "GLP-1a-NARROW", ][1, cols]
          suNarrow <- subset[subset$comparatorCohort == "SU-NARROW", ][1, cols]
          tzdNarrow <- subset[subset$comparatorCohort == "TZDs-NARROW", ][1, cols]
          insulinNarrow <- subset[subset$comparatorCohort == "Insulin-NARROW", ][1, cols]
          metforminNarrow <- subset[subset$comparatorCohort == "Metformin-NARROW", ][1, cols]
          insAhasNarrow <- subset[subset$comparatorCohort == "Insulinotropic AHAs-NARROW", ][1, cols]
          otherAhasNarrow <- subset[subset$comparatorCohort == "Other AHAs-NARROW", ][1, cols]

          subTable <- data.frame(exposure = c(
                                   "SGLT2i-BROAD", "Canagliflozin-BROAD", "Dapagliflozin-BROAD", "Empagliflozin-BROAD",
                                   "DPP-4i-BROAD", "GLP-1a-BROAD", "SU-BROAD", "TZDs-BROAD",
                                   "Insulin-BROAD", "Metformin-BROAD", "Insulinotropic AHAs-BROAD", "Other AHAs-BROAD",

                                   "SGLT2i-NARROW", "Canagliflozin-NARROW", "Dapagliflozin-NARROW", "Empagliflozin-NARROW",
                                   "DPP-4i-NARROW", "GLP-1a-NARROW", "SU-NARROW", "TZDs-NARROW",
                                   "Insulin-NARROW", "Metformin-NARROW", "Insulinotropic AHAs-NARROW", "Other AHAs-NARROW"),

                                 database = database,

                                 events = c(
                                   sglt2iBroad[, 3], canaBroad[, 3], dapaBroad[, 3], empaBroad[, 3],
                                   dpp4Broad[, 11], glp1Broad[, 11], suBroad[, 11], tzdBroad[, 11],
                                   insulinBroad[, 11], metforminBroad[, 11], insAhasBroad[, 11], otherAhasBroad[, 11],

                                   sglt2iNarrow[, 3], canaNarrow[, 3], dapaNarrow[, 3], empaNarrow[, 3],
                                   dpp4Narrow[, 11], glp1Narrow[, 11], suNarrow[, 11], tzdNarrow[, 11],
                                   insulinNarrow[, 11], metforminNarrow[, 11], insAhasNarrow[, 11], otherAhasNarrow[, 11]),

                                 personTime = c(
                                   sglt2iBroad[, 2], canaBroad[, 2], dapaBroad[, 2], empaBroad[, 2],
                                   dpp4Broad[, 10], glp1Broad[, 10], suBroad[, 10], tzdBroad[, 10],
                                   insulinBroad[, 10], metforminBroad[, 10], insAhasBroad[, 10], otherAhasBroad[, 10],

                                   sglt2iNarrow[, 2], canaNarrow[, 2], dapaNarrow[, 2], empaNarrow[, 2],
                                   dpp4Narrow[, 10], glp1Narrow[, 10], suNarrow[, 10], tzdNarrow[, 10],
                                   insulinNarrow[, 10], metforminNarrow[, 10], insAhasNarrow[, 10], otherAhasNarrow[, 10]) / 365.25)

          subTable$ir <- 1000 * subTable$events / subTable$personTime

          broadSubTable <- subTable[grep("BROAD", subTable$exposure), c("exposure", "database", "events", "personTime", "ir")]
          narrowSubTable <- subTable[grep("NARROW", subTable$exposure), c("events", "personTime", "ir")]

          formattedSubTable <- cbind(broadSubTable, narrowSubTable)
          formattedSubTable$exposure <- sub("-BROAD", "", formattedSubTable$exposure)
          names(formattedSubTable) <- c("exposure", "database", "eventsBroad", "personTimeBroad", "irBroad", "eventsNarrow", "personTimeNarrow", "irNarrow")

          dbTable <- rbind(dbTable, formattedSubTable)
        }
      }

      if (ncol(mainTable) == 0) {
        mainTable <- dbTable
      } else {
        mainTable <- rbind(mainTable, dbTable)
      }
    }
    mainTable[, c(4, 7)] <- round(mainTable[, c(4, 7)], 0) # PYs
    mainTable[, c(5, 8)] <- round(mainTable[, c(5, 8)], 2) # IRs
    mainTable$exposureOrder <- match(mainTable$exposure, unique(mainTable$exposure))
    mainTable$dbOrder <- match(mainTable$database, c("CCAE", "MDCD", "MDCR", "Optum"))
    mainTable <- mainTable[order(mainTable$exposureOrder, mainTable$dbOrder), ]
    mainTable <- mainTable[, -c(9,10)]

    XLConnect::createSheet(wb, name = subgroup)
    header0 <- c("", "", rep("Broad T2DM", 3), rep("Narrow T2DM", 3))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "C1:E1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "F1:H1")

    header1 <- c("Exposure",
                 "Database",
                 rep(c("Events", "Time-at-risk", "IR"), 2))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header1)),
                              startRow = 2,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = mainTable,
                              startRow = 3,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    cells <- paste0("A", seq(from = 3, to = 47, by = 4), ":A", seq(from = 6, to = 50, by = 4))
    for (cell in cells) {
      XLConnect::mergeCells(wb, sheet = subgroup, reference = cell)
    }
  }
  XLConnect::saveWorkbook(wb)
}
