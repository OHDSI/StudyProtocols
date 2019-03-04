#' @export
createIrDoseTableFormatted <- function(outputFolders,
                                       databaseNames,
                                       reportFolder) {
  loadIrDoseResults <- function(outputFolder) {
    shinyDataFolder <- file.path(outputFolder, "results", "irDoseData")
    file <- list.files(shinyDataFolder, pattern = "irDoseData_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    return(x)
  }
  results <- lapply(outputFolders, loadIrDoseResults)
  results <- do.call(rbind, results)
  results$timeAtRisk <- "ITT"
  results$targetCohort <- sub(pattern = "-90", replacement = "", x = results$targetName)
  results$comparatorCohort <- sub(pattern = "-90", replacement = "", x = results$comparatorName)

  fileName <- file.path(reportFolder, paste0("IRsDoseFormatted.xlsx"))
  unlink(fileName)

  outcomeNames <- unique(results$outcomeName)
  timeAtRisks <- unique(results$timeAtRisk)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  subgroups <- list(
    beforeMatching = c(
      "bmTreated", "bmTreatedDays", "bmEventsTreated",
      "bmTarTargetMean", "bmTarTargetSd", "bmTarTargetMin", "bmTarTargetMedian", "bmTarTargetMax",
      "bmComparator", "bmComparatorDays", "bmEventsComparator",
      "bmTarComparatorMean", "bmTarComparatorSd", "bmTarComparatorMin", "bmTarComparatorMedian", "bmTarComparatorMax"))

  for (i in 1) { # i=1
    mainTable <- data.frame()
    cols <- subgroups[[i]]
    subgroup <- names(subgroups)[i]
    for (database in databaseNames) { # database = "CCAE"
      dbTable <- data.frame()
      for (outcomeName in outcomeNames) { # outcomeName <- outcomeNames[1]
        for (timeAtRisk in timeAtRisks) { # timeAtRisk <- timeAtRisks[1]
          subset <- results[results$database == database &
                              results$outcomeName == outcomeName &
                              results$timeAtRisk == timeAtRisk, ]

          # Broad
          # Ts
          cana100Broad <- subset[subset$targetCohort =="Canagliflozin-100 mg-BROAD", ][1, cols]
          cana300Broad <- subset[subset$targetCohort =="Canagliflozin-300 mg-BROAD", ][1, cols]
          canaOtherBroad <- subset[subset$targetCohort =="Canagliflozin-Other-BROAD", ][1, cols]
          dapa5Broad <- subset[subset$targetCohort =="Dapagliflozin-5 mg-BROAD", ][1, cols]
          dapa10Broad <- subset[subset$targetCohort =="Dapagliflozin-10 mg-BROAD", ][1, cols]
          # Cs
          dapaOtherBroad <- subset[subset$comparatorCohort == "Dapagliflozin-Other-BROAD", ][1, cols]
          empa10Broad <- subset[subset$comparatorCohort == "Empagliflozin-10 mg-BROAD", ][1, cols]
          empa25Broad <- subset[subset$comparatorCohort == "Empagliflozin-25 mg-BROAD", ][1, cols]
          empaOtherBroad <- subset[subset$comparatorCohort == "Empagliflozin-Other-BROAD", ][1, cols]

          # Narrow
          # Ts
          cana100Narrow <- subset[subset$targetCohort =="Canagliflozin-100 mg-NARROW", ][1, cols]
          cana300Narrow <- subset[subset$targetCohort =="Canagliflozin-300 mg-NARROW", ][1, cols]
          canaOtherNarrow <- subset[subset$targetCohort =="Canagliflozin-Other-NARROW", ][1, cols]
          dapa5Narrow <- subset[subset$targetCohort =="Dapagliflozin-5 mg-NARROW", ][1, cols]
          # Cs
          dapa10Narrow <- subset[subset$comparatorCohort == "Dapagliflozin-10 mg-NARROW", ][1, cols]
          dataOtherNarrow <- subset[subset$comparatorCohort == "Dapagliflozin-Other-NARROW", ][1, cols]
          empa10Narrow <- subset[subset$comparatorCohort == "Empagliflozin-10 mg-NARROW", ][1, cols]
          empa25Narrow <- subset[subset$comparatorCohort == "Empagliflozin-25 mg-NARROW", ][1, cols]
          empaOtherNarrow <- subset[subset$comparatorCohort == "Empagliflozin-Other-NARROW", ][1, cols]

          subTable <- data.frame(outcomeName = outcomeName,
                                 timeAtRisk = timeAtRisk,
                                 exposure = c("Canagliflozin-100 mg-BROAD",
                                              "Canagliflozin-300 mg-BROAD",
                                              "Canagliflozin-Other-BROAD",
                                              "Dapagliflozin-5 mg-BROAD",
                                              "Dapagliflozin-10 mg-BROAD",

                                              "Dapagliflozin-Other-BROAD",
                                              "Empagliflozin-10 mg-BROAD",
                                              "Empagliflozin-25 mg-BROAD",
                                              "Empagliflozin-Other-BROAD",

                                              "Canagliflozin-100 mg-NARROW",
                                              "Canagliflozin-300 mg-NARROW",
                                              "Canagliflozin-Other-NARROW",
                                              "Dapagliflozin-5 mg-NARROW",

                                              "Dapagliflozin-10 mg-NARROW",
                                              "Dapagliflozin-Other-NARROW",
                                              "Empagliflozin-10 mg-NARROW",
                                              "Empagliflozin-25 mg-NARROW",
                                              "Empagliflozin-Other-NARROW"),
                                 personTime = c(cana100Broad[, 2],
                                                cana300Broad[, 2],
                                                canaOtherBroad[, 2],
                                                dapa5Broad[, 2],
                                                dapa10Broad[, 2],

                                                dapaOtherBroad[, 10],
                                                empa10Broad[, 10],
                                                empa25Broad[, 10],
                                                empaOtherBroad[, 10],

                                                cana100Narrow[, 2],
                                                cana300Narrow[, 2],
                                                canaOtherNarrow[, 2],
                                                dapa5Narrow[, 2],

                                                dapa10Narrow[, 10],
                                                dataOtherNarrow[, 10],
                                                empa10Narrow[, 10],
                                                empa25Narrow[, 10],
                                                empaOtherNarrow[, 10]) / 365.25,
                                 events = c(cana100Broad[, 3],
                                            cana300Broad[, 3],
                                            canaOtherBroad[, 3],
                                            dapa5Broad[, 3],
                                            dapa10Broad[, 3],

                                            dapaOtherBroad[, 11],
                                            empa10Broad[, 11],
                                            empa25Broad[, 11],
                                            empaOtherBroad[, 11],

                                            cana100Narrow[, 3],
                                            cana300Narrow[, 3],
                                            canaOtherNarrow[, 3],
                                            dapa5Narrow[, 3],

                                            dapa10Narrow[, 11],
                                            dataOtherNarrow[, 11],
                                            empa10Narrow[, 11],
                                            empa25Narrow[, 11],
                                            empaOtherNarrow[, 11]))

          subTable$ir <- 1000 * subTable$events / subTable$personTime
          broadSubTable <- subTable[grep("BROAD", subTable$exposure), c("outcomeName", "exposure", "events", "ir")]
          narrowSubTable <- subTable[grep("NARROW", subTable$exposure), c("events", "ir")]
          formattedSubTable <- cbind(broadSubTable, narrowSubTable)
          formattedSubTable$exposure <- sub("-BROAD", "", formattedSubTable$exposure)
          names(formattedSubTable) <- c("outcomeName", "exposure", "eventsBroad", "irBroad", "eventsNarrow", "irNarrow")
          formattedSubTable$exposureOrder <- match(formattedSubTable$exposure, c("Canagliflozin-300 mg",
                                                                                 "Canagliflozin-100 mg",
                                                                                 "Canagliflozin-Other",
                                                                                 "Dapagliflozin-10 mg",
                                                                                 "Dapagliflozin-5 mg",
                                                                                 "Dapagliflozin-Other",
                                                                                 "Empagliflozin-25 mg",
                                                                                 "Empagliflozin-10 mg",
                                                                                 "Empagliflozin-Other"))
          formattedSubTable <- formattedSubTable[order(formattedSubTable$exposureOrder), ]
          formattedSubTable <- formattedSubTable[, -7]
          dbTable <- rbind(dbTable, formattedSubTable)
        }
      }
      colnames(dbTable)[3:6] <- paste(colnames(dbTable)[3:6], database, sep = "_")
      if (ncol(mainTable) == 0) {
        mainTable <- dbTable
      } else {
        if (!all.equal(mainTable$outcomeName, dbTable$outcomeName) ||
            !all.equal(mainTable$timeAtRisk, dbTable$timeAtRisk) ||
            !all.equal(mainTable$exposure, dbTable$exposure)) {
          stop("Something wrong with data ordering")
        }
        mainTable <- cbind(mainTable, dbTable[, 3:6])
      }
    }
    mainTable[, seq(4,18,2)] <- round(mainTable[, seq(4,18,2)], 2) # IRs

    XLConnect::createSheet(wb, name = subgroup)
    header0 <- c("", "", rep(databaseNames, each = 4))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "C1:F1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "G1:J1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "K1:N1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "O1:R1")

    header1 <- c("", "", rep("Broad",2), rep("Narrow",2), rep("Broad",2), rep("Narrow",2), rep("Broad",2), rep("Narrow",2), rep("Broad",2), rep("Narrow",2))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header1)),
                              startRow = 2,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "C2:D2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "E2:F2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "G2:H2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "I2:J2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "K2:L2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "M2:N2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "O2:P2")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "Q2:R2")

    header2 <- c("Outcome", "Exposure", rep(c("Events", "IR"), length(databaseNames) *2 ))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header2)),
                              startRow = 3,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = mainTable,
                              startRow = 4,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A4:A12")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A13:A21")
  }
  XLConnect::saveWorkbook(wb)
}
