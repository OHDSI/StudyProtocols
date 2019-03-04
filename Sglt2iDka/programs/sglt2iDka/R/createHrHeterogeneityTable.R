#' @export
createHrHeterogeneityTable <- function(outputFolders,
                                       databaseNames,
                                       reportFolder) {
  loadResultsHrsByQ <- function(outputFolder) {
    file <- file.path(outputFolder, "diagnostics", "effectHeterogeneity.csv")
    x <- read.csv(file, stringsAsFactors = FALSE)
    return(x)
  }
  results <- lapply(outputFolders, loadResultsHrsByQ)

  fileName <- file.path(reportFolder, paste0("HRsByQuintile.xlsx"))
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)

  for (i in 1:length(results)) {
    result <- results[[i]]
    database <- databaseNames[i]

    result$analysisDescription[result$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"
    result$analysisDescription[result$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "PP"
    result$targetName <- sub(pattern = "-90", replacement = "", x = result$targetName)
    result$comparatorName <- sub(pattern = "-90", replacement = "", x = result$comparatorName)
    result$rr[result$rr > 10000] <- NA
    result <- result[, -c(1,3,5,7,19,20)]
    result <- result[, c(3, 4, 2, 1, 15, 9, 11, 13, 10, 12, 14, 5:8)]
    result[, c("rr", "ci95lb", "ci95ub", "p")] <- round(result[, c("rr", "ci95lb", "ci95ub", "p")], 2)

    header0 <- c("Target Cohort",
                 "Comparator Cohort",
                 "Outcome",
                 "TAR",
                 "PS Quintile",
                 "T Persons",
                 "T Days",
                 "T Events",
                 "C Persons",
                 "C Days",
                 "C Events",
                 "RR",
                 "95% CI LB",
                 "95% CI UB",
                 "p" )
    XLConnect::createSheet(wb, name = database)
    XLConnect::writeWorksheet(wb,
                              sheet = database,
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::writeWorksheet(wb,
                              sheet = database,
                              data = result,
                              startRow = 2,
                              startCol = 1,
                              header = FALSE,
                              rownames = FALSE)
  }
  XLConnect::saveWorkbook(wb)


  loadResultsHrsByQTest <- function(outputFolder) {
    file <- file.path(outputFolder, "diagnostics", "effectHeterogeneityTest.csv")
    x <- read.csv(file, stringsAsFactors = FALSE)
    return(x)
  }
  results <- lapply(outputFolders, loadResultsHrsByQTest)

  hrHeterogeneityTestResult <- data.frame()
  for (i in 1:length(results)) { # i=1
    result <- results[[i]]
    database <- databaseNames[i]
    dbHrTest <- data.frame(database = database, percentLessP005 = round(sum(result$hrHetero)/nrow(result), 5) * 100)
    hrHeterogeneityTestResult <- rbind(hrHeterogeneityTestResult, dbHrTest)
  }
  fileNameTestResult <- file.path(reportFolder, paste0("HRsByQuintileTestResult.csv"))
  write.csv(hrHeterogeneityTestResult, fileNameTestResult, row.names = FALSE)

  fileNameTest <- file.path(reportFolder, paste0("HRsByQuintileTest.csv"))
  hrHeterogeneityTest <- do.call(rbind, results)
  write.csv(hrHeterogeneityTest, fileNameTest, row.names = FALSE)
}
