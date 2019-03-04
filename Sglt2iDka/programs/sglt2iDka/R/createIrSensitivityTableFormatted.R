#' @export
createIrSensitivityTableFormatted <- function(outputFolders,
                                              databaseNames,
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
  resultsITT90 <- lapply(outputFolders, loadResultsHois)
  resultsITT90 <- do.call(rbind, resultsITT90)
  resultsITT90$targetCohort <- sub(pattern = "-90", replacement = "", x = resultsITT90$targetName)
  resultsITT90$comparatorCohort <- sub(pattern = "-90", replacement = "", x = resultsITT90$comparatorName)
  resultsITT90$timeAtRisk[resultsITT90$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "90day"
  resultsITT90$timeAtRisk[resultsITT90$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"

  loadIrSensitivityResults <- function(outputFolder) {
    shinyDataFolder <- file.path(outputFolder, "results", "irSensitivityData")
    file <- list.files(shinyDataFolder, pattern = "irSensitivityData_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    return(x)
  }
  results60120 <- lapply(outputFolders, loadIrSensitivityResults)
  results60120 <- do.call(rbind, results60120)
  results60120$timeAtRisk <- ""
  results60120[grep("-60", results60120$targetName), "timeAtRisk"] <- "60day"
  results60120[grep("-120", results60120$targetName), "timeAtRisk"] <- "120day"
  results60120$targetCohort <- sub(pattern = "-60", replacement = "", x = results60120$targetName)
  results60120$targetCohort <- sub(pattern = "-120", replacement = "", x = results60120$targetCohort)
  results60120$comparatorCohort <- sub(pattern = "-60", replacement = "", x = results60120$comparatorName)
  results60120$comparatorCohort <- sub(pattern = "-120", replacement = "", x = results60120$comparatorCohort)

  dropCols <- names(resultsITT90) %in% setdiff(names(resultsITT90), names(results60120))
  resultsITT90 <- resultsITT90[!dropCols]
  resultsITT6090120 <- rbind(resultsITT90, results60120)

  outcomeNames <- unique(resultsITT6090120$outcomeName)
  timeAtRisks <- unique(resultsITT6090120$timeAtRisk)

  fileName <- file.path(reportFolder, paste0("IRsSensitivityFormatted.xlsx"))
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  subgroups <- list(
    Overall = c(
      "bmTreated", "bmTreatedDays", "bmEventsTreated",
      "bmTarTargetMean", "bmTarTargetSd", "bmTarTargetMin", "bmTarTargetMedian", "bmTarTargetMax",
      "bmComparator", "bmComparatorDays", "bmEventsComparator",
      "bmTarComparatorMean", "bmTarComparatorSd", "bmTarComparatorMin", "bmTarComparatorMedian", "bmTarComparatorMax"))

  for (i in 1:length(subgroups)) { # i=1
    cols <- subgroups[[i]]
    subgroup <- names(subgroups)[i]
    mainTable <- data.frame()
    for (database in databaseNames) { # database <- "CCAE"
      outcomeTable <- data.frame()
      for (outcomeName in outcomeNames) { # outcomeName <- outcomeNames[2]
        tarTable <- data.frame()
        for (timeAtRisk in timeAtRisks) { # timeAtRisk <- timeAtRisks[1]
          subset <- resultsITT6090120[resultsITT6090120$database == database &
                                        resultsITT6090120$outcomeName == outcomeName &
                                        resultsITT6090120$timeAtRisk == timeAtRisk, ]

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

          subTable <- data.frame(outcomeName = outcomeName,
                                 exposure = c(
                                   "SGLT2i-BROAD", "Canagliflozin-BROAD", "Dapagliflozin-BROAD", "Empagliflozin-BROAD",
                                   "DPP-4i-BROAD", "GLP-1a-BROAD", "SU-BROAD", "TZDs-BROAD",
                                   "Insulin-BROAD", "Metformin-BROAD", "Insulinotropic AHAs-BROAD", "Other AHAs-BROAD",

                                   "SGLT2i-NARROW", "Canagliflozin-NARROW", "Dapagliflozin-NARROW", "Empagliflozin-NARROW",
                                   "DPP-4i-NARROW", "GLP-1a-NARROW", "SU-NARROW", "TZDs-NARROW",
                                   "Insulin-NARROW", "Metformin-NARROW", "Insulinotropic AHAs-NARROW", "Other AHAs-NARROW"),

                                 database = database,

                                 personTime = c(
                                   sglt2iBroad[, 2], canaBroad[, 2], dapaBroad[, 2], empaBroad[, 2],
                                   dpp4Broad[, 10], glp1Broad[, 10], suBroad[, 10], tzdBroad[, 10],
                                   insulinBroad[, 10], metforminBroad[, 10], insAhasBroad[, 10], otherAhasBroad[, 10],

                                   sglt2iNarrow[, 2], canaNarrow[, 2], dapaNarrow[, 2], empaNarrow[, 2],
                                   dpp4Narrow[, 10], glp1Narrow[, 10], suNarrow[, 10], tzdNarrow[, 10],
                                   insulinNarrow[, 10], metforminNarrow[, 10], insAhasNarrow[, 10], otherAhasNarrow[, 10]) / 365.25,

                                 events = c(
                                   sglt2iBroad[, 3], canaBroad[, 3], dapaBroad[, 3], empaBroad[, 3],
                                   dpp4Broad[, 11], glp1Broad[, 11], suBroad[, 11], tzdBroad[, 11],
                                   insulinBroad[, 11], metforminBroad[, 11], insAhasBroad[, 11], otherAhasBroad[, 11],

                                   sglt2iNarrow[, 3], canaNarrow[, 3], dapaNarrow[, 3], empaNarrow[, 3],
                                   dpp4Narrow[, 11], glp1Narrow[, 11], suNarrow[, 11], tzdNarrow[, 11],
                                   insulinNarrow[, 11], metforminNarrow[, 11], insAhasNarrow[, 11], otherAhasNarrow[, 11]))

          subTable$ir <- 1000 * subTable$events / subTable$personTime

          broadSubTable <- subTable[grep("BROAD", subTable$exposure), c("outcomeName", "exposure", "database", "ir")]
          narrowSubTable <- subTable[grep("NARROW", subTable$exposure), "ir"]
          wideSubTable <- cbind(broadSubTable, narrowSubTable)
          wideSubTable$exposure <- sub("-BROAD", "", wideSubTable$exposure)
          names(wideSubTable)[4:5] <- c(paste0("irBroad_", timeAtRisk), paste0("irNarrow_", timeAtRisk))

          if (ncol(tarTable) == 0) {
            tarTable <- wideSubTable
          } else {
            tarTable <- cbind(tarTable, wideSubTable[, 4:5])
          }
        }
        outcomeTable <- rbind(outcomeTable, tarTable)
      }
      mainTable <- rbind(mainTable, outcomeTable)
    }

    facs <- sapply(mainTable, is.factor)
    mainTable[facs] <- lapply(mainTable[facs], as.character)
    mainTable[, 4:11] <- round(mainTable[, 4:11], 2) # IRs
    mainTable$outcomeOrder <- match(mainTable$outcomeName, c("DKA (IP)", "DKA (IP & ER)"))
    mainTable$dbOrder <- match(mainTable$database, c("CCAE", "MDCD", "MDCR", "Optum"))
    mainTable$exposureOrder <- match(mainTable$exposure, c("SGLT2i",
                                                           "Canagliflozin",
                                                           "Dapagliflozin",
                                                           "Empagliflozin",
                                                           "SU",
                                                           "DPP-4i",
                                                           "GLP-1a",
                                                           "TZDs",
                                                           "Insulin",
                                                           "Metformin",
                                                           "Insulinotropic AHAs",
                                                           "Other AHAs"))
    mainTable <- mainTable[order(mainTable$outcomeOrder, mainTable$exposureOrder, mainTable$dbOrder), ]
    mainTable <- mainTable[, -c(12:14)]
    mainTable <- mainTable[, c("outcomeName", "exposure", "database",
                               "irBroad_ITT", "irBroad_90day", "irBroad_60day", "irBroad_120day",
                               "irNarrow_ITT", "irNarrow_90day", "irNarrow_60day", "irNarrow_120day")]

    XLConnect::createSheet(wb, name = subgroup)
    header0 <- c("", "", "", rep("Broad T2DM", 4), rep("Narrow T2DM", 4))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "D1:G1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "H1:K1")

    header1 <- c("Outcome", "Exposure", "Database", rep(c("ITT", "90 day", "60 day", "120 day"), 2))
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
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A3:A50")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A51:A98")
    cells <- paste0("B", seq(from = 3, to = 95, by = 4), ":B", seq(from = 6, to = 98, by = 4))
    for (cell in cells) {
      XLConnect::mergeCells(wb, sheet = subgroup, reference = cell)
    }
  }
  XLConnect::saveWorkbook(wb)
}
