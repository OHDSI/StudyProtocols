#' @export
createIrSubgroupsTableFormatted <- function(outputFolders,
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
  results <- lapply(outputFolders, loadResultsHois)
  results <- do.call(rbind, results)
  results$targetCohort <- sub(pattern = "-90", replacement = "", x = results$targetName)
  results$comparatorCohort <- sub(pattern = "-90", replacement = "", x = results$comparatorName)
  results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"
  results <- results[!results$analysisDescription == "Time to First Post Index Event Per Protocol Matching", ]

  outcomeNames <- unique(results$outcomeName)
  timeAtRisks <- unique(results$timeAtRisk)

  fileName <- file.path(reportFolder, paste0("IRsSubgroupsFormatted.xlsx"))
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  subgroups <- list(
    Age10_19 = c(
      "bmTreated1019", "bmTreatedDays1019", "bmEventsTreated1019",
      "bmTarTargetMean1019", "bmTarTargetSd1019", "bmTarTargetMin1019", "bmTarTargetMedian1019", "bmTarTargetMax1019",
      "bmComparator1019", "bmComparatorDays1019", "bmEventsComparator1019",
      "bmTarComparatorMean1019", "bmTarComparatorSd1019", "bmTarComparatorMin1019", "bmTarComparatorMedian1019", "bmTarComparatorMax1019"),
    Age20_29 = c(
      "bmTreated2029", "bmTreatedDays2029", "bmEventsTreated2029",
      "bmTarTargetMean2029", "bmTarTargetSd2029", "bmTarTargetMin2029", "bmTarTargetMedian2029", "bmTarTargetMax2029",
      "bmComparator2029", "bmComparatorDays2029", "bmEventsComparator2029",
      "bmTarComparatorMean2029", "bmTarComparatorSd2029", "bmTarComparatorMin2029", "bmTarComparatorMedian2029", "bmTarComparatorMax2029"),
    Age30_39 = c(
      "bmTreated3039", "bmTreatedDays3039", "bmEventsTreated3039",
      "bmTarTargetMean3039", "bmTarTargetSd3039", "bmTarTargetMin3039", "bmTarTargetMedian3039", "bmTarTargetMax3039",
      "bmComparator3039", "bmComparatorDays3039", "bmEventsComparator3039",
      "bmTarComparatorMean3039", "bmTarComparatorSd3039", "bmTarComparatorMin3039", "bmTarComparatorMedian3039", "bmTarComparatorMax3039"),
    Age40_49 = c(
      "bmTreated4049", "bmTreatedDays4049", "bmEventsTreated4049",
      "bmTarTargetMean4049", "bmTarTargetSd4049", "bmTarTargetMin4049", "bmTarTargetMedian4049", "bmTarTargetMax4049",
      "bmComparator4049", "bmComparatorDays4049", "bmEventsComparator4049",
      "bmTarComparatorMean4049", "bmTarComparatorSd4049", "bmTarComparatorMin4049", "bmTarComparatorMedian4049", "bmTarComparatorMax4049"),
    Age50_59 = c(
      "bmTreated5059", "bmTreatedDays5059", "bmEventsTreated5059",
      "bmTarTargetMean5059", "bmTarTargetSd5059", "bmTarTargetMin5059", "bmTarTargetMedian5059", "bmTarTargetMax5059",
      "bmComparator5059", "bmComparatorDays5059", "bmEventsComparator5059",
      "bmTarComparatorMean5059", "bmTarComparatorSd5059", "bmTarComparatorMin5059", "bmTarComparatorMedian5059", "bmTarComparatorMax5059"),
    Age60_69 = c(
      "bmTreated6069", "bmTreatedDays6069", "bmEventsTreated6069",
      "bmTarTargetMean6069", "bmTarTargetSd6069", "bmTarTargetMin6069", "bmTarTargetMedian6069", "bmTarTargetMax6069",
      "bmComparator6069", "bmComparatorDays6069", "bmEventsComparator6069",
      "bmTarComparatorMean6069", "bmTarComparatorSd6069", "bmTarComparatorMin6069", "bmTarComparatorMedian6069", "bmTarComparatorMax6069"),
    Age70_79 = c(
      "bmTreated7079", "bmTreatedDays7079", "bmEventsTreated7079",
      "bmTarTargetMean7079", "bmTarTargetSd7079", "bmTarTargetMin7079", "bmTarTargetMedian7079", "bmTarTargetMax7079",
      "bmComparator7079", "bmComparatorDays7079", "bmEventsComparator7079",
      "bmTarComparatorMean7079", "bmTarComparatorSd7079", "bmTarComparatorMin7079", "bmTarComparatorMedian7079", "bmTarComparatorMax7079"),
    Age80_89 = c(
      "bmTreated8089", "bmTreatedDays8089", "bmEventsTreated8089",
      "bmTarTargetMean8089", "bmTarTargetSd8089", "bmTarTargetMin8089", "bmTarTargetMedian8089", "bmTarTargetMax8089",
      "bmComparator8089", "bmComparatorDays8089", "bmEventsComparator8089",
      "bmTarComparatorMean8089", "bmTarComparatorSd8089", "bmTarComparatorMin8089", "bmTarComparatorMedian8089", "bmTarComparatorMax8089"),
    Age90_99 = c(
      "bmTreated9099", "bmTreatedDays9099", "bmEventsTreated9099",
      "bmTarTargetMean9099", "bmTarTargetSd9099", "bmTarTargetMin9099", "bmTarTargetMedian9099", "bmTarTargetMax9099",
      "bmComparator9099", "bmComparatorDays9099", "bmEventsComparator9099",
      "bmTarComparatorMean9099", "bmTarComparatorSd9099", "bmTarComparatorMin9099", "bmTarComparatorMedian9099", "bmTarComparatorMax9099"),
    Age100_109 = c(
      "bmTreated100109", "bmTreatedDays100109", "bmEventsTreated100109",
      "bmTarTargetMean100109", "bmTarTargetSd100109", "bmTarTargetMin100109", "bmTarTargetMedian100109", "bmTarTargetMax100109",
      "bmComparator100109", "bmComparatorDays100109", "bmEventsComparator100109",
      "bmTarComparatorMean100109", "bmTarComparatorSd100109", "bmTarComparatorMin100109", "bmTarComparatorMedian100109", "bmTarComparatorMax100109"),
    Male = c(
      "bmTreatedMale", "bmTreatedDaysMale", "bmEventsTreatedMale",
      "bmTarTargetMeanMale", "bmTarTargetSdMale", "bmTarTargetMinMale", "bmTarTargetMedianMale", "bmTarTargetMaxMale",
      "bmComparatorMale", "bmComparatorDaysMale", "bmEventsComparatorMale",
      "bmTarComparatorMeanMale", "bmTarComparatorSdMale", "bmTarComparatorMinMale", "bmTarComparatorMedianMale", "bmTarComparatorMaxMale"),
    Female = c(
      "bmTreatedFemale", "bmTreatedDaysFemale", "bmEventsTreatedFemale",
      "bmTarTargetMeanFemale", "bmTarTargetSdFemale", "bmTarTargetMinFemale", "bmTarTargetMedianFemale", "bmTarTargetMaxFemale",
      "bmComparatorFemale", "bmComparatorDaysFemale", "bmEventsComparatorFemale",
      "bmTarComparatorMeanFemale", "bmTarComparatorSdFemale", "bmTarComparatorMinFemale", "bmTarComparatorMedianFemale", "bmTarComparatorMaxFemale"),
    PriorInsulin = c(
      "bmTreatedPriorInsulin", "bmTreatedDaysPriorInsulin", "bmEventsTreatedPriorInsulin",
      "bmTarTargetMeanPriorInsulin", "bmTarTargetSdPriorInsulin", "bmTarTargetMinPriorInsulin", "bmTarTargetMedianPriorInsulin", "bmTarTargetMaxPriorInsulin",
      "bmComparatorPriorInsulin", "bmComparatorDaysPriorInsulin", "bmEventsComparatorPriorInsulin",
      "bmTarComparatorMeanPriorInsulin", "bmTarComparatorSdPriorInsulin", "bmTarComparatorMinPriorInsulin", "bmTarComparatorMedianPriorInsulin", "bmTarComparatorMaxPriorInsulin"),
    NoPriorInsulin = c(
      "bmTreatedNoPriorInsulin", "bmTreatedDaysNoPriorInsulin", "bmEventsTreatedNoPriorInsulin",
      "bmTarTargetMeanNoPriorInsulin", "bmTarTargetSdNoPriorInsulin", "bmTarTargetMinNoPriorInsulin", "bmTarTargetMedianNoPriorInsulin", "bmTarTargetMaxNoPriorInsulin",
      "bmComparatorNoPriorInsulin", "bmComparatorDaysNoPriorInsulin", "bmEventsComparatorNoPriorInsulin",
      "bmTarComparatorMeanNoPriorInsulin", "bmTarComparatorSdNoPriorInsulin", "bmTarComparatorMinNoPriorInsulin", "bmTarComparatorMedianNoPriorInsulin", "bmTarComparatorMaxNoPriorInsulin"),
    PriorDkaIpEr = c(
      "bmTreatedPriorDkaIpEr", "bmTreatedDaysPriorDkaIpEr", "bmEventsTreatedPriorDkaIpEr",
      "bmTarTargetMeanPriorDkaIpEr", "bmTarTargetSdPriorDkaIpEr", "bmTarTargetMinPriorDkaIpEr", "bmTarTargetMedianPriorDkaIpEr", "bmTarTargetMaxPriorDkaIpEr",
      "bmComparatorPriorDkaIpEr", "bmComparatorDaysPriorDkaIpEr", "bmEventsComparatorPriorDkaIpEr",
      "bmTarComparatorMeanPriorDkaIpEr", "bmTarComparatorSdPriorDkaIpEr", "bmTarComparatorMinPriorDkaIpEr", "bmTarComparatorMedianPriorDkaIpEr", "bmTarComparatorMaxPriorDkaIpEr"),
    NoPriorDkaIpEr = c(
      "bmTreatedNoPriorDkaIpEr", "bmTreatedDaysNoPriorDkaIpEr", "bmEventsTreatedNoPriorDkaIpEr",
      "bmTarTargetMeanNoPriorDkaIpEr", "bmTarTargetSdNoPriorDkaIpEr", "bmTarTargetMinNoPriorDkaIpEr", "bmTarTargetMedianNoPriorDkaIpEr", "bmTarTargetMaxNoPriorDkaIpEr",
      "bmComparatorNoPriorDkaIpEr", "bmComparatorDaysNoPriorDkaIpEr", "bmEventsComparatorNoPriorDkaIpEr",
      "bmTarComparatorMeanNoPriorDkaIpEr", "bmTarComparatorSdNoPriorDkaIpEr", "bmTarComparatorMinNoPriorDkaIpEr", "bmTarComparatorMedianNoPriorDkaIpEr", "bmTarComparatorMaxNoPriorDkaIpEr"))

  mainTable <- data.frame()
  for (i in 1:length(subgroups)) { # i=1
    subgroupTable <- data.frame()
    cols <- subgroups[[i]]
    subgroup <- names(subgroups)[i]
    for (database in databaseNames) { # database <- "CCAE"
      dbTable <- data.frame()
      for (outcomeName in outcomeNames) { # outcomeName <- outcomeNames[2]
        for (timeAtRisk in timeAtRisks[1]) { # timeAtRisk = timeAtRisks[1]
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

          subTable <- data.frame(outcomeName = outcomeName,
                                 exposure = c(
                                   "SGLT2i-BROAD", "Canagliflozin-BROAD", "Dapagliflozin-BROAD", "Empagliflozin-BROAD",
                                   "DPP-4i-BROAD", "GLP-1a-BROAD", "SU-BROAD", "TZDs-BROAD",
                                   "Insulin-BROAD", "Metformin-BROAD", "Insulinotropic AHAs-BROAD", "Other AHAs-BROAD",

                                   "SGLT2i-NARROW", "Canagliflozin-NARROW", "Dapagliflozin-NARROW", "Empagliflozin-NARROW",
                                   "DPP-4i-NARROW", "GLP-1a-NARROW", "SU-NARROW", "TZDs-NARROW",
                                   "Insulin-NARROW", "Metformin-NARROW", "Insulinotropic AHAs-NARROW", "Other AHAs-NARROW"),

                                 subgroup = subgroup,

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

          broadSubTable <- subTable[grep("BROAD", subTable$exposure), c("outcomeName", "exposure", "subgroup", "ir")]
          narrowSubTable <- subTable[grep("NARROW", subTable$exposure), c("ir")]
          wideSubTable <- cbind(broadSubTable, narrowSubTable)

          wideSubTable$exposure <- sub("-BROAD", "", wideSubTable$exposure)
          names(wideSubTable)[4:5] <- c(paste0("irBroad_", database), paste0("irNarrow_", database))

          dbTable <- rbind(dbTable, wideSubTable)
        }
      }
      if (ncol(subgroupTable) == 0) {
        subgroupTable <- dbTable
      } else {
        subgroupTable <- cbind(subgroupTable, dbTable[, 4:5])
      }
    }
    mainTable <- rbind(mainTable, subgroupTable)
  }
  mainTable[, 4:11] <- round(mainTable[, 4:11], 2) # IRs
  facs <- sapply(mainTable, is.factor)
  mainTable[facs] <- lapply(mainTable[facs], as.character)
  mainTable$outcomeOrder <- match(mainTable$outcomeName, c("DKA (IP & ER)", "DKA (IP)"))
  mainTable$exposureOrder <- match(mainTable$exposure, unique(mainTable$exposure))
  mainTable$subgroupOrder <- match(mainTable$subgroup, unique(mainTable$subgroup))
  mainTable <- mainTable[order(mainTable$outcomeOrder, mainTable$exposureOrder, mainTable$subgroupOrder), ]
  mainTable <- mainTable[, -c(12:14)]

  XLConnect::createSheet(wb, name = "subgroups")
  header0 <- c("", "", "", rep(databaseNames, each = 2))
  XLConnect::writeWorksheet(wb,
                            sheet = "subgroups",
                            data = as.data.frame(t(header0)),
                            startRow = 1,
                            startCol = 1,
                            rownames = FALSE,
                            header = FALSE)
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "D1:E1")
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "F1:G1")
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "H1:I1")
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "J1:K1")

  header1 <- c("Outcome", "Exposure", "Subgroup", rep(c("Broad T2DM", "Narrow T2DM"), length(databaseNames)))
  XLConnect::writeWorksheet(wb,
                            sheet = "subgroups",
                            data = as.data.frame(t(header1)),
                            startRow = 2,
                            startCol = 1,
                            rownames = FALSE,
                            header = FALSE)

  XLConnect::writeWorksheet(wb,
                            sheet = "subgroups",
                            data = mainTable,
                            startRow = 3,
                            startCol = 1,
                            rownames = FALSE,
                            header = FALSE)
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "A3:A194")
  XLConnect::mergeCells(wb, sheet = "subgroups", reference = "A195:A386")
  cells <- paste0("B", seq(from = 3, to = 371, by = 16), ":B", seq(from = 18, to = 386, by = 16))
  for (cell in cells) {
    XLConnect::mergeCells(wb, sheet = "subgroups", reference = cell)
  }
  XLConnect::saveWorkbook(wb)
}

