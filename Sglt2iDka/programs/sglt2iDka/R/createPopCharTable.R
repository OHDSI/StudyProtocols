  #' @export
createPopCharTable <- function(outputFolders,
                               databaseNames,
                               reportFolder) {
  primaryAnalysisId <- 1 # ITT
  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  primaryTcos <- unique(tcosAnalyses[, c("targetCohortId", "targetDrugName", "targetCohortName", "comparatorCohortId", "comparatorDrugName", "comparatorCohortName",
                                            "outcomeCohortId", "outcomeCohortName")])
  names(primaryTcos) <- c("targetId", "targetDrugName", "targetName", "comparatorId", "comparatorDrugName", "comparatorName",
                             "outcomeId", "outcomeName")
  abbrevName <- function(x) {
    x <- sub("-90", "", x)
    x <- sub("gliflozin", "", x)
    x <- sub("BROAD", "BD", x)
    x <- sub("NARROW", "NW", x)
    x <- sub("inotropic", "", x)
  }
  primaryTcos$abbrevTargetName <- abbrevName(primaryTcos$targetName)
  primaryTcos$addrevComparatorName <- abbrevName(primaryTcos$comparatorName)

  addSheet <- function(mainTable,
                       sheetName) {
    sheet <- xlsx::createSheet(workBook, sheetName = sheetName)
    percentStyle <- xlsx::CellStyle(wb = workBook, dataFormat = xlsx::DataFormat("#,##0.0"))
    diffStyle <- xlsx::CellStyle(wb = workBook, dataFormat = xlsx::DataFormat("#,##0.00"))
    header0 <- rep("", 1+6*length(databaseNames))
    header0[2-6+6*(1:length(databaseNames))] <- databaseNames
    xlsx::addDataFrame(as.data.frame(t(header0)),
                       sheet = sheet,
                       startRow = 1,
                       startColumn = 1,
                       col.names = FALSE,
                       row.names = FALSE,
                       showNA = FALSE)
    for (k in 1:length(databaseNames)) {
      xlsx::addMergedRegion(sheet,
                            startRow = 1,
                            endRow = 1,
                            startColumn = (k-1)*6 + 2,
                            endColumn = (k-1)*6 + 7)
    }
    header1 <- c("", rep(c("Before matching", "", "", "After matching", "", ""), length(databaseNames)))
    xlsx::addDataFrame(as.data.frame(t(header1)),
                       sheet = sheet,
                       startRow = 2,
                       startColumn = 1,
                       col.names = FALSE,
                       row.names = FALSE,
                       showNA = FALSE)
    for (k in 1:length(databaseNames)) {
      xlsx::addMergedRegion(sheet,
                            startRow = 2,
                            endRow = 2,
                            startColumn = (k-1)*6 + 2,
                            endColumn = (k-1)*6 + 4)
      xlsx::addMergedRegion(sheet,
                            startRow = 2,
                            endRow = 2,
                            startColumn = (k-1)*6 + 5,
                            endColumn = (k-1)*6 + 7)
    }
    header2 <- c("", rep(c("T", "C", ""), 2*length(databaseNames)))
    xlsx::addDataFrame(as.data.frame(t(header2)),
                       sheet = sheet,
                       startRow = 3,
                       startColumn = 1,
                       col.names = FALSE,
                       row.names = FALSE,
                       showNA = FALSE)
    xlsx::addDataFrame(as.data.frame(t(header3)),
                       sheet = sheet,
                       startRow = 4,
                       startColumn = 1,
                       col.names = FALSE,
                       row.names = FALSE,
                       showNA = FALSE)
    styles <- rep(list(percentStyle, percentStyle, diffStyle,percentStyle, percentStyle, diffStyle), length(databaseNames))
    names(styles) <- 1+(1:length(styles))
    xlsx::addDataFrame(mainTable,
                       sheet = sheet,
                       startRow = 5,
                       startColumn = 1,
                       col.names = FALSE,
                       row.names = FALSE,
                       showNA = FALSE,
                       colStyle = styles)
    xlsx::setColumnWidth(sheet, 1, 45)
    xlsx::setColumnWidth(sheet, 2:25, 6)
  }

  for (abbrevTargetName in unique(primaryTcos$abbrevTargetName)) {
    # abbrevTargetName = "SGLT2i-BD"
    workBook <- xlsx::createWorkbook(type="xlsx")
    outcomeId <- 200 # only DKA IP/ER outcome
    primaryTcsByTarget <- primaryTcos[primaryTcos$abbrevTargetName == abbrevTargetName & primaryTcos$outcomeId == outcomeId, ]
    for (i in 1:nrow(primaryTcsByTarget)) {
      # i=5
      allBalance <- list()
      tables <- list()
      header3 <- c("Characteristic")
      for (k in 1:length(databaseNames)) {
        # k=3
        databaseName <- databaseNames[k]
        shinyDataFolder <- file.path(outputFolders[k], "results", "shinyData")
        fileName <-  paste0("bal_a", primaryAnalysisId,
                            "_t", primaryTcsByTarget$targetId[i],
                            "_c", primaryTcsByTarget$comparatorId[i],
                            "_o", outcomeId,
                            "_", databaseName,".rds")
        balance <- readRDS(file.path(outputFolders[k], "results", "balance", fileName))
        # Infer population sizes before matching:
        beforeTargetPopSize <- round(mean(balance$beforeMatchingSumTreated / balance$beforeMatchingMeanTreated, na.rm = TRUE))
        beforeComparatorPopSize <- round(mean(balance$beforeMatchingSumComparator / balance$beforeMatchingMeanComparator, na.rm = TRUE))

        fileName <-  paste0("multiTherBal_a", primaryAnalysisId,
                            "_t", primaryTcsByTarget$targetId[i],
                            "_c", primaryTcsByTarget$comparatorId[i],
                            "_o", outcomeId,
                            "_", databaseName,".rds")
        multiTherBalance  <- readRDS(file.path(shinyDataFolder, fileName))
        balance <- balance[, names(multiTherBalance)]
        balance <- rbind(balance, multiTherBalance)

        tables[[k]] <- prepareTable1(balance)
        allBalance[[k]] <- balance
        fileName <-  file.path(shinyDataFolder, paste0("resultsHois_", databaseName,".rds"))
        resultsHois <- readRDS(fileName)
        row <- resultsHois[resultsHois$targetId == primaryTcsByTarget$targetId[i] &
                             resultsHois$comparatorId == primaryTcsByTarget$comparatorId[i] &
                             resultsHois$outcomeId == outcomeId &
                             resultsHois$analysisId == primaryAnalysisId, ]

        header3 <- c(header3,
                     paste0("% (n = ",format(beforeTargetPopSize, big.mark = ","), ")"),
                     paste0("% (n = ",format(beforeComparatorPopSize, big.mark = ","), ")"),
                     "Std.diff",
                     paste0("% (n = ",format(row$treated, big.mark = ","), ")"),
                     paste0("% (n = ",format(row$comparator, big.mark = ","), ")"),
                     "Std.diff")

      }
      # Create main table by combining all balances to get complete list of covariates:
      allBalance <- do.call(rbind, allBalance)
      allBalance$covariateName <- as.character(allBalance$covariateName)
      allBalance$covariateName[allBalance$covariateId == 20003] <- "age group: 100-104"
      allBalance <- allBalance[order(nchar(allBalance$covariateName), allBalance$covariateName), ]
      #allBalance <- allBalance[order(allBalance$covariateName), ]
      allBalance <- allBalance[!duplicated(allBalance$covariateName), ]

      headerCol <- prepareTable1(allBalance)[, 1]
      mainTable <- matrix(NA, nrow = length(headerCol), ncol = length(tables) * 6)
      for (k in 1:length(databaseNames)) {
        mainTable[match(tables[[k]]$Characteristic, headerCol), ((k-1)*6)+(1:6)] <- as.matrix(tables[[k]][, 2:7])
      }
      mainTable <- as.data.frame(mainTable)
      mainTable <- cbind(data.frame(headerCol = headerCol), mainTable)
      sheetName <- paste(abbrevTargetName, primaryTcsByTarget$addrevComparatorName[i], sep = ", ")
      addSheet(mainTable = mainTable,
               sheetName = sheetName)

    }
    fileName <- paste0("Char_", sub("-90", "", primaryTcsByTarget$targetName[1]), ".xlsx")
    xlsx::saveWorkbook(workBook, file.path(reportFolder, fileName))
  }
}


prepareTable1 <- function(balance) {
  pathToCsv <- system.file("settings", "Table1Specs.csv", package = "sglt2iDka")
  specifications <- read.csv(pathToCsv, stringsAsFactors = FALSE)

  fixCase <- function(label) {
    idx <- (toupper(label) == label)
    if (any(idx)) {
      label[idx] <- paste0(substr(label[idx], 1, 1),
                           tolower(substr(label[idx], 2, nchar(label[idx]))))
    }
    return(label)
  }
  resultsTable <- data.frame()
  for (i in 1:nrow(specifications)) { # i=1
    if (specifications$analysisId[i] == "") {
      resultsTable <- rbind(resultsTable,
                            data.frame(Characteristic = specifications$label[i], value = ""))
    } else {
      idx <- balance$analysisId == specifications$analysisId[i]
      if (any(idx)) {
        if (specifications$covariateIds[i] != "") {
          covariateIds <- as.numeric(strsplit(specifications$covariateIds[i], ",")[[1]])
          idx <- balance$covariateId %in% covariateIds
        } else {
          covariateIds <- NULL
        }
        if (any(idx)) {
          balanceSubset <- balance[idx, ]
          if (is.null(covariateIds)) {
            balanceSubset <- balanceSubset[order(balanceSubset$covariateId), ]
          } else {
            balanceSubset <- merge(balanceSubset, data.frame(covariateId = covariateIds,
                                                             rn = 1:length(covariateIds)))
            balanceSubset <- balanceSubset[order(balanceSubset$rn,
                                                 balanceSubset$covariateId), ]
          }
          balanceSubset$covariateName <- fixCase(gsub("^.*: ",
                                                      "",
                                                      balanceSubset$covariateName))
          balanceSubset$covariateName[balanceSubset$covariateId == 20003] <- "100-104"
          if (specifications$covariateIds[i] == "" || length(covariateIds) > 1) {
            resultsTable <- rbind(resultsTable, data.frame(Characteristic = specifications$label[i],
                                                           beforeMatchingMeanTreated = NA,
                                                           beforeMatchingMeanComparator = NA,
                                                           beforeMatchingStdDiff = NA,
                                                           afterMatchingMeanTreated = NA,
                                                           afterMatchingMeanComparator = NA,
                                                           afterMatchingStdDiff = NA,
                                                           stringsAsFactors = FALSE))
            resultsTable <- rbind(resultsTable,
                                  data.frame(Characteristic = paste0("    ", balanceSubset$covariateName),
                                             beforeMatchingMeanTreated = balanceSubset$beforeMatchingMeanTreated,
                                             beforeMatchingMeanComparator = balanceSubset$beforeMatchingMeanComparator,
                                             beforeMatchingStdDiff = balanceSubset$beforeMatchingStdDiff,
                                             afterMatchingMeanTreated = balanceSubset$afterMatchingMeanTreated,
                                             afterMatchingMeanComparator = balanceSubset$afterMatchingMeanComparator,
                                             afterMatchingStdDiff = balanceSubset$afterMatchingStdDiff,
                                             stringsAsFactors = FALSE))
          } else {
            resultsTable <- rbind(resultsTable, data.frame(Characteristic = specifications$label[i],
                                                           beforeMatchingMeanTreated = balanceSubset$beforeMatchingMeanTreated,
                                                           beforeMatchingMeanComparator = balanceSubset$beforeMatchingMeanComparator,
                                                           beforeMatchingStdDiff = balanceSubset$beforeMatchingStdDiff,
                                                           afterMatchingMeanTreated = balanceSubset$afterMatchingMeanTreated,
                                                           afterMatchingMeanComparator = balanceSubset$afterMatchingMeanComparator,
                                                           afterMatchingStdDiff = balanceSubset$afterMatchingStdDiff,
                                                           stringsAsFactors = FALSE))
          }
        }
      }
    }
  }
  idx <- resultsTable$Characteristic == "CHADS2Vasc (mean)" |  resultsTable$Characteristic == "Charlson comorbidity index (mean)" | resultsTable$Characteristic == "DCSI (mean)"
  resultsTable$beforeMatchingMeanTreated[!idx] <- resultsTable$beforeMatchingMeanTreated[!idx] * 100
  resultsTable$beforeMatchingMeanComparator[!idx] <- resultsTable$beforeMatchingMeanComparator[!idx] * 100
  resultsTable$afterMatchingMeanTreated[!idx] <- resultsTable$afterMatchingMeanTreated[!idx] * 100
  resultsTable$afterMatchingMeanComparator[!idx] <- resultsTable$afterMatchingMeanComparator[!idx] * 100
  return(resultsTable)
}
