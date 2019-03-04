studyFolder <- "S:/StudyResults/epi_535_4"
shinyDataFolder <- file.path(getwd(), "data")
appendixFolder <- file.path(studyFolder, "report2", "appendix")
tempFolder <- "S:/temp"
Sys.setenv(PATH = paste(Sys.getenv("PATH"), "C:\\Program Files\\MiKTeX 2.9\\miktex\\bin\\x64\\", sep=";"))

wd <- getwd()
setwd("..")
toPdfFolder <- file.path(getwd(), "AllResultsToPdf")
setwd(wd)

if (!file.exists(appendixFolder))
  dir.create(appendixFolder)
if (!file.exists(tempFolder))
  dir.create(tempFolder)

OhdsiRTools::addDefaultFileLogger(file.path(appendixFolder, "log.txt"))
source("global.R")

# Appendix A -------------------------------------------------------------------
convertToPdf <- function(appendixFolder, rmdFile) {
  wd <- setwd(appendixFolder)
  pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
  on.exit(setwd(wd))
  rmarkdown::render(rmdFile,
                    output_file = pdfFile,
                    rmarkdown::pdf_document(latex_engine = "pdflatex"))
}

mainColumns <- c("database",
                 "timeAtRisk",
                 "rr",
                 "ci95lb",
                 "ci95ub",
                 "p",
                 "calP",
                 "targetId",
                 "comparatorId",
                 "outcomeId",
                 "analysisId")
mainColumnNames <- c("Data source",
                     "Time-at-risk",
                     "HR (95% CI)",
                     "P",
                     "Cal. P",
                     "App.")

template <- SqlRender::readSql(file.path(toPdfFolder, "hazardRatioTableTemplate.rmd"))
aNumber <- 1
bNumber <- 1
aAppendices <- data.frame()
bAppendices <- data.frame()

for (comparison in comparisons) {
  for (outcome in outcomes) {
    table <- resultsHois[resultsHois$comparison == comparison & resultsHois$outcomeName == outcome, mainColumns]
    table$dbOrder <- match(table$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))
    table$timeAtRiskOrder <- match(table$timeAtRisk, c("Intent-to-Treat", "Per-Protocol"))
    table <- table[order(table$timeAtRisk, table$dbOrder), ]
    table$dbOrder <- NULL
    table$timeAtRiskOrder <- NULL
    table$rr[table$rr > 100] <- NA
    table$ci95ub[table$ci95ub > 100] <- NA
    table$rr <- sprintf("%.2f (%.2f - %.2f)", table$rr, table$ci95lb, table$ci95ub)
    table$ci95lb <- NULL
    table$ci95ub <- NULL
    table$p <- formatC(table$p, digits = 2, format = "f")
    table$p <- gsub("NA", "", table$p)
    table$calP <- formatC(table$calP, digits = 2, format = "f")
    table$calP <- gsub("NA", "", table$calP)
    table$appendix <- sprintf("b%05d", bNumber:(bNumber + nrow(table) - 1))
    bAppendices <- rbind(bAppendices, data.frame(targetId = table$targetId,
                                                 comparatorId = table$comparatorId,
                                                 outcomeId = table$outcomeId,
                                                 analysisId = table$analysisId,
                                                 database = table$database,
                                                 appendix = table$appendix))
    table$targetId <- NULL
    table$comparatorId <- NULL
    table$outcomeId <- NULL
    table$analysisId <- NULL
    colnames(table) <- mainColumnNames
    saveRDS(table, file.path(tempFolder, "temp.rds"))

    rmd <- template
    rmd <- gsub("%number%", sprintf("A%02d", aNumber), rmd)
    rmd <- gsub("%comparison%", comparison, rmd)
    rmd <- gsub("%outcome%", outcome, rmd)
    rmdFile <- sprintf("appendix-a%02d.Rmd", aNumber)
    sink(file.path(appendixFolder, rmdFile))
    writeLines(rmd)
    sink()
    convertToPdf(appendixFolder, rmdFile)

    aNumber <- aNumber + 1
    bNumber <- bNumber + nrow(table)

    # Cleanup
    unlink(file.path(appendixFolder, rmdFile))
    unlink(list.files(tempFolder, pattern = "^temp"))
  }
}
saveRDS(bAppendices, file.path(appendixFolder, "bAppendices.rds"))


# Annex: list of Appendix A supporting documents -------------------------------
aNumber <- 1
appendicesFile <- file.path(appendixFolder, "aAppendices.txt")
sink(appendicesFile)

for (comparison in comparisons) {
  for (outcome in outcomes) {
    title <- "%number%. Appendix %appendixNumber%: Estimates for the comparison of %comparison% for the outcome of %outcome%"
    title <- gsub("%number%", aNumber, title)
    title <- gsub("%appendixNumber%", sprintf("a%02d", aNumber), title)
    title <- gsub("%comparison%", comparison, title)
    title <- gsub("%outcome%", outcome, title)
    print(title, quote = FALSE)
    aNumber <- aNumber + 1
  }
}
sink()


# Appendix B -------------------------------------------------------------------
bAppendices <- readRDS(file.path(appendixFolder, "bAppendices.rds"))

generateAppendixB <- function(i) {
  pdfFile <- sprintf("appendix%s.pdf", bAppendices$appendix[i])
  if (!file.exists(file.path(appendixFolder, pdfFile))) {
    OhdsiRTools::logInfo("Generating ", pdfFile)

    tempFolder <- paste0("S:/temp/cana",i)
    dir.create(tempFolder)
    source("Table1.R")


    convertToPdf <- function(appendixFolder, rmdFile) {
      wd <- setwd(appendixFolder)
      pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
      on.exit(setwd(wd))
      rmarkdown::render(rmdFile,
                        output_file = pdfFile,
                        rmarkdown::pdf_document(latex_engine = "pdflatex"))
    }

    row <- resultsHois[resultsHois$targetId == bAppendices$targetId[i] &
                       resultsHois$comparatorId == bAppendices$comparatorId[i] &
                       resultsHois$outcomeId == bAppendices$outcomeId[i] &
                       resultsHois$analysisId == bAppendices$analysisId[i] &
                       resultsHois$database == bAppendices$database[i], ]
    isMetaAnalysis <- row$database == "Meta-analysis"

    # Power table
    powerColumns <- c("treated",
                      "comparator",
                      "treatedDays",
                      "comparatorDays",
                      "eventsTreated",
                      "eventsComparator",
                      "irTreated",
                      "irComparator",
                      "mdrr")
    powerColumnNames <- c("Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "MDRR")
    table <- row
    table$irTreated <- formatC(1000 * table$eventsTreated / (table$treatedDays / 365.25), digits = 2, format = "f")
    table$irComparator <- formatC(1000 * table$eventsComparator / (table$comparatorDays / 365.25), digits = 2, format = "f")
    table$treated <- formatC(table$treated, big.mark = ",", format = "d")
    table$comparator <- formatC(table$comparator, big.mark = ",", format = "d")
    table$treatedDays <- formatC(table$treatedDays, big.mark = ",", format = "d")
    table$comparatorDays <- formatC(table$comparatorDays, big.mark = ",", format = "d")
    table$eventsTreated <- formatC(table$eventsTreated, big.mark = ",", format = "d")
    table$eventsComparator <- formatC(table$eventsComparator, big.mark = ",", format = "d")
    table$mdrr <- formatC(table$mdrr, digits = 2, format = "f")
    if (table$database == "Meta-analysis") {
      table <- table[, c(powerColumns, "i2")]
      colnames(table) <- c(powerColumnNames, "I2")
    } else {
      table <- table[, powerColumns]
      colnames(table) <- powerColumnNames
    }
    saveRDS(table, file.path(tempFolder, "tempPower.rds"))

    # Follow-up table
    if (!isMetaAnalysis) {
      table <- data.frame(Cohort = c("Target", "Comparator"),
                          Mean = formatC(c(row$tarTargetMean, row$tarComparatorMean), digits = 1, format = "f"),
                          SD = formatC(c(row$tarTargetSd, row$tarComparatorSd), digits = 1, format = "f"),
                          Min = formatC(c(row$tarTargetMin, row$tarComparatorMin), big.mark = ",", format = "d"),
                          Median = formatC(c(row$tarTargetMedian, row$tarComparatorMedian), big.mark = ",", format = "d"),
                          Max = formatC(c(row$tarTargetMax, row$tarComparatorMax), big.mark = ",", format = "d"))
      saveRDS(table, file.path(tempFolder, "tempTar.rds"))
    }

    # Population characteristics
    if (!isMetaAnalysis) {
      fileName <- paste0("bal_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database,".rds")
      bal  <- readRDS(file.path(shinyDataFolder, fileName))
      bal$absBeforeMatchingStdDiff <- abs(bal$beforeMatchingStdDiff)
      bal$absAfterMatchingStdDiff <- abs(bal$afterMatchingStdDiff)
      bal <- merge(bal, covarNames)
      fileName <- paste0("multiTherBal_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database,".rds")
      multiTherBalance  <- readRDS(file.path(shinyDataFolder, fileName))
      bal$absBeforeMatchingStdDiff <- NULL
      bal$absAfterMatchingStdDiff <- NULL
      multiTherBalance <- multiTherBalance[, colnames(bal)]
      bal <- rbind(bal, multiTherBalance)
      bal$covariateName <- as.character(bal$covariateName)
      bal$covariateName[bal$covariateId == 20003] <- "age group: 100-104"
      bal <- bal[order(nchar(bal$covariateName), bal$covariateName), ]
      table <- prepareTable1(bal,
                             beforeTargetPopSize = row$treatedBefore,
                             beforeComparatorPopSize = row$comparatorBefore,
                             afterTargetPopSize = row$treated,
                             afterComparatorPopSize = row$comparator,
                             beforeLabel = "Before matching",
                             afterLabel = "After matching")
      table <- cbind(apply(table, 2, function(x) gsub("&nbsp;", " ", x)))
      colnames(table) <- table[2, ]
      table <- table[3:nrow(table), ]
      saveRDS(table, file.path(tempFolder, "tempPopChar.rds"))

      fileName <- paste0("ps_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_", row$database, ".rds")
      data <- readRDS(file.path(shinyDataFolder, fileName))
      data$GROUP <- row$targetDrug
      data$GROUP[data$treatment == 0] <- row$comparatorDrug
      data$GROUP <- factor(data$GROUP, levels = c(row$targetDrug, row$comparatorDrug))
      saveRDS(data, file.path(tempFolder, "tempPs.rds"))
    }

    # Covariate balance
    if (!isMetaAnalysis) {
      fileName <- paste0("bal_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database, ".rds")
      bal <- readRDS(file.path(shinyDataFolder, fileName))
      bal$absBeforeMatchingStdDiff <- abs(bal$beforeMatchingStdDiff)
      bal$absAfterMatchingStdDiff <- abs(bal$afterMatchingStdDiff)
      saveRDS(bal, file.path(tempFolder, "tempBalance.rds"))
    }

    # Negative controls
    ncs <- resultsNcs[resultsNcs$targetId == row$targetId &
                      resultsNcs$comparatorId == row$comparatorId &
                      resultsNcs$analysisId == row$analysisId &
                      resultsNcs$database == row$database, ]
    saveRDS(ncs, file.path(tempFolder, "tempNcs.rds"))

    # Kaplan Meier
    if (!isMetaAnalysis) {
      fileName <- paste0("km_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database,".rds")
      plot <- readRDS(file.path(shinyDataFolder, fileName))
      saveRDS(plot, file.path(tempFolder, "tempKm.rds"))
    }

    wd <- getwd()
    setwd("..")
    template <- SqlRender::readSql("AllResultsToPdf/detailsTemplate.rmd")
    setwd(wd)
    rmd <- template
    rmd <- gsub("%tempFolder%", tempFolder, rmd)
    rmd <- gsub("%number%", bAppendices$appendix[i], rmd)
    rmd <- gsub("%comparison%", row$comparison, rmd)
    rmd <- gsub("%outcome%", row$outcomeName, rmd)
    rmd <- gsub("%target%", row$targetDrug, rmd)
    rmd <- gsub("%comparator%", row$comparatorDrug, rmd)
    rmd <- gsub("%logRr%", if (is.na(row$logRr)) 999 else row$logRr, rmd)
    rmd <- gsub("%seLogRr%", if (is.na(row$seLogRr)) 999 else row$seLogRr, rmd)
    rmd <- gsub("%timeAtRisk%", row$timeAtRisk, rmd)
    rmd <- gsub("%database%", row$database, rmd)
    rmd <- gsub("%isMetaAnalysis%", isMetaAnalysis, rmd)

    rmdFile <- sprintf("appendix-%s.Rmd", bAppendices$appendix[i])
    sink(file.path(appendixFolder, rmdFile))
    writeLines(rmd)
    sink()
    convertToPdf(appendixFolder, rmdFile)

    # Cleanup
    unlink(file.path(appendixFolder, rmdFile))
    unlink(tempFolder, recursive = TRUE)
  }
}

nThreads <- 15
cluster <- OhdsiRTools::makeCluster(nThreads)
setGlobalVars <- function(i, bAppendices, resultsHois, resultsNcs, covarNames, appendixFolder, shinyDataFolder){
  bAppendices <<- bAppendices
  resultsHois <<- resultsHois
  resultsNcs <<- resultsNcs
  covarNames <<- covarNames
  appendixFolder <<- appendixFolder
  shinyDataFolder <<- shinyDataFolder
}
dummy <- OhdsiRTools::clusterApply(cluster = cluster,
                                   x = 1:nThreads,
                                   fun = setGlobalVars,
                                   bAppendices = bAppendices,
                                   resultsHois = resultsHois,
                                   resultsNcs = resultsNcs,
                                   covarNames = covarNames,
                                   appendixFolder = appendixFolder,
                                   shinyDataFolder = shinyDataFolder)
n <- nrow(bAppendices)
# when running clusterApply, the context of a function (in this case the global environment)
# is also transmitted with every function call. Making sure it doesn't contain anything big:
bAppendices <- NULL
resultsHois <- NULL
resultsNcs <- NULL
covarNames <- NULL
appendixFolder <- NULL
heterogeneous <- NULL
dummy <- NULL

dummy <- OhdsiRTools::clusterApply(cluster = cluster,
                                   x = 1:n,
                                   fun = generateAppendixB)

OhdsiRTools::stopCluster(cluster)

# Post processing using GhostScript -------------------------------------------------------------
# gsPath <- "\"C:/Program Files/gs/gs9.23/bin/gswin64.exe\""
# studyFolder <- "r:/AhasHfBkleAmputation"
# appendixFolder <- file.path(studyFolder, "report", "appendix")
# tempFolder <- file.path(appendixFolder, "optimized")
# if (!file.exists(tempFolder))
#   dir.create(tempFolder)
#
# fileName <- "AppendixA01.pdf"
# fileName <- "AppendixB00001.pdf"
# files <- list.files(appendixFolder, pattern = ".*\\.pdf", recursive = FALSE)
#
# for (fileName in files) {
#   args <- "-dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dFastWebView -sOutputFile=%s %s %s"
#   command <- paste(gsPath, sprintf(args, file.path(tempFolder, fileName), file.path(appendixFolder, fileName), file.path(getwd(), "extras/AllResultsToPdf/pdfmarks")))
#   shell(command)
# }
#
# unlink(file.path(appendixFolder, files))
# file.rename(from = file.path(tempFolder, files), to = file.path(appendixFolder, files))
# unlink(tempFolder, recursive = TRUE)
