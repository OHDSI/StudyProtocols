#' @export
createIrDoseTable <- function(outputFolders,
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

  fileName <- file.path(reportFolder, paste0("IRsDose.xlsx"))
  unlink(fileName)

  outcomeNames <- unique(results$outcomeName)
  timeAtRisks <- unique(results$timeAtRisk)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  subgroups <- list(
    beforeMatching = c(
      "bmTreated", "bmTreatedDays", "bmEventsTreated",
      "bmTarTargetMean", "bmTarTargetSd", "bmTarTargetMin", "bmTarTargetMedian", "bmTarTargetMax",
      "bmComparator", "bmComparatorDays", "bmEventsComparator",
      "bmTarComparatorMean", "bmTarComparatorSd", "bmTarComparatorMin", "bmTarComparatorMedian", "bmTarComparatorMax"),
    afterMatching = c(
      "amTreated", "amTreatedDays", "amEventsTreated",
      "amTarTargetMean", "amTarTargetSd", "amTarTargetMin", "amTarTargetMedian", "amTarTargetMax",
      "amComparator", "amComparatorDays", "amEventsComparator",
      "amTarComparatorMean", "amTarComparatorSd", "amTarComparatorMin", "amTarComparatorMedian", "amTarComparatorMax"))

  for (i in 1) { # before matching only; if including after-matching, use 1:length(subgroups)) {
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
                                 subjects = c(cana100Broad[, 1],
                                              cana300Broad[, 1],
                                              canaOtherBroad[, 1],
                                              dapa5Broad[, 1],
                                              dapa10Broad[, 1],

                                              dapaOtherBroad[, 9],
                                              empa10Broad[, 9],
                                              empa25Broad[, 9],
                                              empaOtherBroad[, 9],

                                              cana100Narrow[, 1],
                                              cana300Narrow[, 1],
                                              canaOtherNarrow[, 1],
                                              dapa5Narrow[, 1],

                                              dapa10Narrow[, 9],
                                              dataOtherNarrow[, 9],
                                              empa10Narrow[, 9],
                                              empa25Narrow[, 9],
                                              empaOtherNarrow[, 9]),

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

                                 meanPersonTime = c(cana100Broad[, 4],
                                                    cana300Broad[, 4],
                                                    canaOtherBroad[, 4],
                                                    dapa5Broad[, 4],
                                                    dapa10Broad[, 4],

                                                    dapaOtherBroad[, 12],
                                                    empa10Broad[, 12],
                                                    empa25Broad[, 12],
                                                    empaOtherBroad[, 12],

                                                    cana100Narrow[, 4],
                                                    cana300Narrow[, 4],
                                                    canaOtherNarrow[, 4],
                                                    dapa5Narrow[, 4],

                                                    dapa10Narrow[, 12],
                                                    dataOtherNarrow[, 12],
                                                    empa10Narrow[, 12],
                                                    empa25Narrow[, 12],
                                                    empaOtherNarrow[, 12]) / 365.25,

                                 sdPersonTime = c(cana100Broad[, 5],
                                                  cana300Broad[, 5],
                                                  canaOtherBroad[, 5],
                                                  dapa5Broad[, 5],
                                                  dapa10Broad[, 5],

                                                  dapaOtherBroad[, 13],
                                                  empa10Broad[, 13],
                                                  empa25Broad[, 13],
                                                  empaOtherBroad[, 13],

                                                  cana100Narrow[, 5],
                                                  cana300Narrow[, 5],
                                                  canaOtherNarrow[, 5],
                                                  dapa5Narrow[, 5],

                                                  dapa10Narrow[, 13],
                                                  dataOtherNarrow[, 13],
                                                  empa10Narrow[, 13],
                                                  empa25Narrow[, 13],
                                                  empaOtherNarrow[, 13]) / 365.25,

                                 minPersonTime = c(cana100Broad[, 6],
                                                   cana300Broad[, 6],
                                                   canaOtherBroad[, 6],
                                                   dapa5Broad[, 6],
                                                   dapa10Broad[, 6],

                                                   dapaOtherBroad[, 14],
                                                   empa10Broad[, 14],
                                                   empa25Broad[, 14],
                                                   empaOtherBroad[, 14],

                                                   cana100Narrow[, 6],
                                                   cana300Narrow[, 6],
                                                   canaOtherNarrow[, 6],
                                                   dapa5Narrow[, 6],

                                                   dapa10Narrow[, 14],
                                                   dataOtherNarrow[, 14],
                                                   empa10Narrow[, 14],
                                                   empa25Narrow[, 14],
                                                   empaOtherNarrow[, 14]) / 365.25,

                                 medianPersonTime = c(cana100Broad[, 7],
                                                      cana300Broad[, 7],
                                                      canaOtherBroad[, 7],
                                                      dapa5Broad[, 7],
                                                      dapa10Broad[, 7],

                                                      dapaOtherBroad[, 15],
                                                      empa10Broad[, 15],
                                                      empa25Broad[, 15],
                                                      empaOtherBroad[, 15],

                                                      cana100Narrow[, 7],
                                                      cana300Narrow[, 7],
                                                      canaOtherNarrow[, 7],
                                                      dapa5Narrow[, 7],

                                                      dapa10Narrow[, 15],
                                                      dataOtherNarrow[, 15],
                                                      empa10Narrow[, 15],
                                                      empa25Narrow[, 15],
                                                      empaOtherNarrow[, 15]) / 365.25,

                                 maxPersonTime = c(cana100Broad[, 8],
                                                   cana300Broad[, 8],
                                                   canaOtherBroad[, 8],
                                                   dapa5Broad[, 8],
                                                   dapa10Broad[, 8],

                                                   dapaOtherBroad[, 15],
                                                   empa10Broad[, 15],
                                                   empa25Broad[, 15],
                                                   empaOtherBroad[, 15],

                                                   cana100Narrow[, 8],
                                                   cana300Narrow[, 8],
                                                   canaOtherNarrow[, 8],
                                                   dapa5Narrow[, 8],

                                                   dapa10Narrow[, 15],
                                                   dataOtherNarrow[, 15],
                                                   empa10Narrow[, 15],
                                                   empa25Narrow[, 15],
                                                   empaOtherNarrow[, 15]) / 365.25,

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
          dbTable <- rbind(dbTable, subTable)
        }
      }
      colnames(dbTable)[4:12] <- paste(colnames(dbTable)[4:12], database, sep = "_")
      if (ncol(mainTable) == 0) {
        mainTable <- dbTable
      } else {
        if (!all.equal(mainTable$outcomeName, dbTable$outcomeName) ||
            !all.equal(mainTable$timeAtRisk, dbTable$timeAtRisk) ||
            !all.equal(mainTable$exposure, dbTable$exposure)) {
          stop("Something wrong with data ordering")
        }
        mainTable <- cbind(mainTable, dbTable[, 4:12])
      }
    }
    mainTable[, c(5, 14, 23, 32)] <- round(mainTable[, c(5, 14, 23, 32)], 0) # total person years
    mainTable[, c(6:10, 15:19, 24:28, 33:37)] <- round(mainTable[, c(6:10, 15:19, 24:28, 33:37)], 1) # stats person years
    mainTable[, c(12, 21, 30, 39)] <- round(mainTable[, c(12, 21, 30, 39)], 1) # IRs

    XLConnect::createSheet(wb, name = subgroup)
    header0 <- c("", "", "", rep(databaseNames, each = 9))
    XLConnect::writeWorksheet(wb,
                              sheet = subgroup,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "D1:L1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "M1:U1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "V1:AD1")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "AE1:AM1")
    header1 <- c("Outcome",
                 "Time-at-risk",
                 "Exposure",
                 rep(c("Persons", "PY total", "PY mean", "PY SD", "PY min", "PY med", "PY max", "Events", "IR"), length(databaseNames)))
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
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A3:A20")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "B3:B20")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "A21:A38")
    XLConnect::mergeCells(wb, sheet = subgroup, reference = "B21:B38")
  }
  XLConnect::saveWorkbook(wb)
}
