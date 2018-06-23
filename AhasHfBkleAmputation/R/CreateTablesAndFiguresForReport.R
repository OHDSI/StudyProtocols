# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Create figures and tables for report
#'
#' @details
#' This function generates tables and figures for the report on the study results.
#'
#' @param outputFolders        Vector of names of local folders where the results were generated; make sure 
#'                             to use forward slashes (/). D
#' @param databaseNames        A vector of unique names for the databases.
#' @param maOutputFolder       A local folder where the meta-anlysis results were be written.
#' @param reportFolder         A local folder where the tables and figures will be written.
#'
#' @export
createTableAndFiguresForReport <- function(outputFolders, databaseNames, maOutputFolder, reportFolder) {
  # outputFolders = c(file.path(studyFolder, "ccae"), file.path(studyFolder, "mdcd"), file.path(studyFolder, "mdcr"), file.path(studyFolder, "optum"))
  # databaseNames = c("CCAE", "MDCD", "MDCR", "Optum")
  # reportFolder = file.path(studyFolder, "report")
  # maOutputFolder = file.path(studyFolder, "metaAnalysis")
  if (!file.exists(reportFolder))
    dir.create(reportFolder, recursive = TRUE)
  createPopCharTable(outputFolders, databaseNames, reportFolder)
  createHrTable(outputFolders, databaseNames, maOutputFolder, reportFolder)
  createSensAnalysesFigure(outputFolders, databaseNames, maOutputFolder, reportFolder)
  createIrTable(outputFolders, databaseNames, reportFolder)
  selectKaplanMeierPlots(outputFolders, databaseNames, reportFolder)
  createTimeAtRiskTable(outputFolders, databaseNames, reportFolder)
  outputAllEstimatesToSingleTable(outputFolders, databaseNames, reportFolder)
}

createIrTable <- function(outputFolders, databaseNames, reportFolder) {
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(outputFolders, loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  results <- results[results$psStrategy == "Stratification" &
                       results$priorExposure == "no restrictions" &
                       results$timeAtRisk %in% c("On Treatment", "Intent to Treat") &
                       results$evenType == "First Post Index Event" &
                       results$comparison %in% comparisonsOfInterest, ]
  for (establishedCvd in unique(results$establishedCvd)) {
    outcomeNames <- c("BKLE amputation", "Heart failure")
    timeAtRisks <-c("On Treatment", "Intent to Treat")   
    mainTable <- data.frame()
    for (database in databaseNames) {
      dbTable <- data.frame()
      for (outcomeName in outcomeNames) {
        # outcomeName <- outcomeNames[1]
        for (timeAtRisk in timeAtRisks) {
          # timeAtRisk <- timeAtRisks[1]
          subset <- results[results$database == database & 
                              results$outcomeName == outcomeName &
                              results$timeAtRisk == timeAtRisk &
                              results$establishedCvd == establishedCvd, ]
          cana <- subset[subset$targetDrug == "canagliflozin", ][1,]
          empaDapa <- subset[subset$targetDrug == "empagliflozin or dapagliflozin", ][1,]
          nonSglt2 <- subset[subset$comparatorDrug == "any DPP-4 inhibitor, GLP-1 agonist, or other select AHA", ][1,]
          nonSglt2All <- subset[subset$comparatorDrug == "any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA", ][1,]
          subTable <- data.frame(outcomeName = gsub("Heart failure", "Hospitalization for heart failure", outcomeName),
                                 timeAtRisk = timeAtRisk,
                                 exposure = c("canagliflozin", "other SGLT2i", "all non-SGLT2i", "select non-SGLT2i"),
                                 subjects = c(cana$treated, empaDapa$treated, nonSglt2All$comparator, nonSglt2$comparator),
                                 personTime = c(cana$treatedDays, empaDapa$treatedDays, nonSglt2All$comparatorDays, nonSglt2$comparatorDays) / 365.25,
                                 events = c(cana$eventsTreated, empaDapa$eventsTreated, nonSglt2All$eventsComparator, nonSglt2$eventsComparator)) 
          subTable$ir <- 1000 * subTable$events / subTable$personTime
          dbTable <- rbind(dbTable, subTable)
        }
      }
      colnames(dbTable)[4:7] <- paste(colnames(dbTable)[4:7], database, sep = "_")
      if (ncol(mainTable) == 0) {
        mainTable <- dbTable
      } else {
        if (!all.equal(mainTable$outcomeName, dbTable$outcomeName) ||
            !all.equal(mainTable$timeAtRisk, dbTable$timeAtRisk) ||
            !all.equal(mainTable$exposure, dbTable$exposure)) {
          stop("Something wrong with data ordering")
        }
        mainTable <- cbind(mainTable, dbTable[, 4:7])       
      }
    }
    
    fileName <- file.path(reportFolder, paste0("IRs_", if (establishedCvd == "required") "cvd" else "all", ".xlsx"))
    unlink(fileName)
    wb <- XLConnect::loadWorkbook(fileName, create = TRUE)
    XLConnect::createSheet(wb, name = "Incidence")
    
    header0 <- c("", "", "", rep(databaseNames, each = 4))
    XLConnect::writeWorksheet(wb, 
                              sheet = "Incidence",
                              data = as.data.frame(t(header0)),
                              startRow = 1,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "D1:G1")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "H1:K1")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "L1:O1")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "P1:S1")
    
    header1 <- c("Outcome", "Time-at-risk", "Exposure", rep(c("Persons", "Person-time", "Events", "IR"), length(databaseNames)))
    XLConnect::writeWorksheet(wb, 
                              sheet = "Incidence",
                              data = as.data.frame(t(header1)),
                              startRow = 2,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    
    XLConnect::writeWorksheet(wb, 
                              sheet = "Incidence",
                              data = mainTable,
                              startRow = 3,
                              startCol = 1,
                              rownames = FALSE,
                              header = FALSE)
    countStyle <- XLConnect::createCellStyle(wb)
    XLConnect::setDataFormat(countStyle, format = "###,###,##0")
    rateStyle <- XLConnect::createCellStyle(wb)
    XLConnect::setDataFormat(rateStyle, format = "##0.0")
    for (i in 1:length(databaseNames)) {
      XLConnect::setCellStyle(wb, sheet = "Incidence", row = 3:18, col = i*4 + rep(0, 30), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Incidence", row = 3:18, col = i*4 + rep(1, 30), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Incidence", row = 3:18, col = i*4 + rep(2, 30), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Incidence", row = 3:18, col = i*4 + rep(3, 30), cellstyle = rateStyle)
    }
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "A3:A10")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "A11:A18")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "B3:B6")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "B7:B10")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "B11:B14")
    XLConnect::mergeCells(wb, sheet = "Incidence", reference = "B15:B18")
    XLConnect::saveWorkbook(wb)
  }
}

createSensAnalysesFigure <- function(outputFolders, databaseNames, maOutputFolder, reportFolder) {
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- lapply(file, readRDS)
    x <- do.call(rbind, x)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  outcomeNames <- unique(results$outcomeName)
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  for (outcomeName in outcomeNames) {
    # outcomeName <- outcomeNames[1]
    
    results$dbOrder <- match(results$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis (HKSJ)", "Meta-analysis (DL)"))
    results$comparisonOrder <- match(results$comparison, comparisonsOfInterest)
    results$timeAtRiskOrder <- match(results$timeAtRisk, c("On Treatment", 
                                                           "On Treatment (no censor at switch)", 
                                                           "Lag", 
                                                           "Lag (no censor at switch)",
                                                           "Intent to Treat", 
                                                           "Modified ITT"))
    
    subset <- results[results$outcomeName == outcomeName &
                        results$comparison %in% comparisonsOfInterest, ]
    subset <- subset[order(subset$comparisonOrder,
                           subset$dbOrder,
                           subset$timeAtRiskOrder,
                           subset$establishedCvd,
                           subset$evenType,
                           subset$psStrategy,
                           subset$priorExposure), ]
    subset$rr[is.na(subset$seLogRr)] <- NA
    facetCount <- (length(unique(subset$comparison)) * length(unique(subset$database))) 
    subset$displayOrder <- rep((nrow(subset)/facetCount):1, facetCount)#nrow(subset):1
    formatQuestion  <- function(x) {
      result <- rep("canagliflozin vs. other SGLT2i", length(x))
      result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "canagliflozin vs. select non-SGLT2i"
      result[x == "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "other SGLT2i vs. all non-SGLT2"
      result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "canagliflozin vs. all non-SGLT2i"
      return(result)
    }
    formatTimeAtRisk  <- function(x) {
      result <- x
      result[x == "Intent to Treat"] <- "Intent-to-treat"
      result[x == "On Treatment"] <- "On treatment"
      result[x == "On Treatment (no censor at switch)"] <- "On treatment (no censor at switch)"
      result[x == "Lag"] <- "On treatment lagged"
      result[x == "Lag (no censor at switch)"] <- "On treatment lagged (no censor at switch)"
      return(result)
    }
    subset$comparison <- formatQuestion(subset$comparison)
    subset$timeAtRisk <- formatTimeAtRisk(subset$timeAtRisk)
    breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
    col <- c(rgb(0, 0, 0.8, alpha = 1), rgb(0.8, 0.4, 0, alpha = 1))
    colFill <- c(rgb(0, 0, 1, alpha = 0.5), rgb(1, 0.4, 0, alpha = 0.5))
    subset$database <- factor(subset$database, levels = c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis (HKSJ)", "Meta-analysis (DL)"))
    subset$comparison <- factor(subset$comparison, levels = c("canagliflozin vs. all non-SGLT2i", 
                                                              "canagliflozin vs. select non-SGLT2i", 
                                                              "canagliflozin vs. other SGLT2i",
                                                              "other SGLT2i vs. all non-SGLT2"))
    subset$timeAtRisk <- factor(subset$timeAtRisk, levels = c("On treatment", "On treatment (no censor at switch)", "On treatment lagged", "On treatment lagged (no censor at switch)", "Intent-to-treat", "Modified ITT"))
    plot <- ggplot2::ggplot(subset, ggplot2::aes(x = rr, 
                                                 y = displayOrder, 
                                                 xmin = ci95lb, 
                                                 xmax = ci95ub, 
                                                 colour = timeAtRisk, 
                                                 fill = timeAtRisk), environment = environment()) + 
      ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
      ggplot2::geom_vline(xintercept = 1, colour = "#000000", lty = 1, size = 0.5) + 
      ggplot2::geom_errorbarh(height = 0, alpha = 0.7) + 
      ggplot2::geom_point(shape = 16, size = 1, alpha = 0.7) + 
      # ggplot2::scale_colour_manual(values = col) +
      # ggplot2::scale_fill_manual(values = colFill) +
      ggplot2::coord_cartesian(xlim = c(0.1, 10)) + 
      ggplot2::scale_x_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = breaks) + 
      ggplot2::facet_grid(database ~ comparison, scales = "free_y", space = "free") + 
      ggplot2::labs(color = "Time-at-risk", fill = "Time-at-risk") +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), 
                     panel.background = ggplot2::element_rect(fill = "#FAFAFA",colour = NA), 
                     panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"), 
                     axis.ticks = ggplot2::element_blank(), 
                     axis.title.y = ggplot2::element_blank(), 
                     axis.title.x = ggplot2::element_blank(), 
                     axis.text.y = ggplot2::element_blank(),
                     legend.position = "top")    
    
    fileName <- file.path(reportFolder, paste0("SensAnalyses ", outcomeName, ".png"))
    ggplot2::ggsave(fileName, plot, width = 10, height = 14, dpi = 400)
  }
}

createHrTable <- function(outputFolders, databaseNames, maOutputFolder, reportFolder) {
  requireNamespace("XLConnect")
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  outcomeNames <- unique(results$outcomeName)
  establishedCvds <- unique(results$establishedCvd)
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  for (outcomeName in outcomeNames) {
    # outcomeName <- outcomeNames[1]
    for (establishedCvd in establishedCvds) {
      #establishedCvd <- establishedCvds[1]
      fileName <- file.path(reportFolder, paste0("HRs ", outcomeName, if (establishedCvd == "required") "_cvd" else "_all", ".xlsx"))
      unlink(fileName)
      wb <- XLConnect::loadWorkbook(fileName, create = TRUE)
      XLConnect::createSheet(wb, name = "Hazard ratios")
      
      header0 <- rep("", 14)
      header0[5] <- "On treatment"
      header0[10] <- "Intent-to-treat"
      XLConnect::writeWorksheet(wb, 
                                sheet = "Hazard ratios",
                                data = as.data.frame(t(header0)),
                                startRow = 1,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "E1:I1")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "J1:N1")
      header1 <- c("", "", "Exposed (#/PY)", "", "Outcomes", "", "HR (95% CI)", "p", "Cal. p", "Outcomes", " ", "HR (95% CI)", "p", "Cal. p")
      XLConnect::writeWorksheet(wb, 
                                sheet = "Hazard ratios",
                                data = as.data.frame(t(header1)),
                                startRow = 2,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "C2:D2")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "E2:F2")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "J2:K2")
      header2 <- c("Question", 
                   "Source",
                   "T", 
                   "C",
                   "T", 
                   "C",
                   "",
                   "",
                   "",
                   "T", 
                   "C")
      XLConnect::writeWorksheet(wb, 
                                sheet = "Hazard ratios",
                                data = as.data.frame(t(header2)),
                                startRow = 3,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      idx <- results$outcomeName == outcomeName &
        results$comparison %in% comparisonsOfInterest &
        results$psStrategy == "Matching" &
        results$priorExposure == "no restrictions" &
        results$evenType == "First Post Index Event" &
        results$establishedCvd == establishedCvd
      
      results$dbOrder <- match(results$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))
      results$comparisonOrder <- match(results$comparison, comparisonsOfInterest)
      onTreatment <- results[idx & results$timeAtRisk == "On Treatment", ]
      itt <- results[idx & results$timeAtRisk == "Intent to Treat", ]
      onTreatment <- onTreatment[order(onTreatment$establishedCvd, 
                                       onTreatment$comparisonOrder,
                                       onTreatment$dbOrder), ]
      itt <- itt[order(itt$establishedCvd, 
                       itt$comparisonOrder,
                       itt$dbOrder), ]
      if (!all.equal(onTreatment$establishedCvd, itt$establishedCvd) ||
          !all.equal(onTreatment$comparison, itt$comparison) ||
          !all.equal(onTreatment$database, itt$database)) {
        stop("Problem with sorting of data")
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
      formatEstablishCvd <- function(x) {
        result <- rep("With established CV disease", length(x))
        result[x == "not required"] <- "All"
        return(result)
      }
      formatQuestion  <- function(x) {
        result <- rep("canagliflozin vs. other SGLT2i", length(x))
        result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "canagliflozin vs. select non-SGLT2i"
        result[x == "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "other SGLT2i vs. all non-SGLT2"
        result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "canagliflozin vs. all non-SGLT2i"
        return(result)
      }
      
      mainTable <- data.frame(question = formatQuestion(onTreatment$comparison),
                              source = onTreatment$database,
                              t = formatSampleSize(onTreatment$treated, onTreatment$treatedDays),
                              c = formatSampleSize(onTreatment$comparator, onTreatment$comparatorDays),
                              oTonTreatment = onTreatment$eventsTreated,
                              oConTreatment = onTreatment$eventsComparator,
                              hrOnTreatment = formatHr(onTreatment$rr, onTreatment$ci95lb, onTreatment$ci95ub),
                              pOnTreatment = onTreatment$p,
                              calPOnTreatment = onTreatment$calP,
                              oTitt = itt$eventsTreated,
                              oCitt = itt$eventsComparator,
                              hrItt = formatHr(itt$rr, itt$ci95lb, itt$ci95ub),
                              pItt = itt$p,
                              calItt = itt$calP)
      XLConnect::writeWorksheet(wb,
                                data = mainTable,
                                sheet = "Hazard ratios",
                                startRow = 4,
                                startCol = 1,
                                header = FALSE,
                                rownames = FALSE)
      pStyle <- XLConnect::createCellStyle(wb)
      XLConnect::setDataFormat(pStyle, format = "0.00")
      countStyle <- XLConnect::createCellStyle(wb)
      XLConnect::setDataFormat(countStyle, format = "#,##0")
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(5, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(6, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(8, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(9, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(10, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(11, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(13, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Hazard ratios", row = 4:23, col = rep(14, 19), cellstyle = pStyle)
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "A4:A8")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "A9:A13")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "A14:A18")
      XLConnect::mergeCells(wb, sheet = "Hazard ratios", reference = "A19:A23")
      XLConnect::setColumnWidth(wb, sheet = "Hazard ratios", column = 1, width = -1)
      XLConnect::setColumnWidth(wb, sheet = "Hazard ratios", column = 2, width = -1)
      XLConnect::saveWorkbook(wb)
    }
  }
}

createPopCharTable <- function(outputFolders, databaseNames, reportFolder) {
  primaryAnalysisId <- 2 #Time to First Post Index Event On Treatment, Matching
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AhasHfBkleAmputation")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  tcosOfInterest$comparison <- paste(tcosOfInterest$targetDrug, tcosOfInterest$comparatorDrug, sep = " - ")
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  primaryTcos <- tcosOfInterest[tcosOfInterest$censorAtSwitch == TRUE &
                                  tcosOfInterest$priorExposure == "no restrictions" &
                                  tcosOfInterest$comparison %in% comparisonsOfInterest, ]
  pathToCsv <- system.file("settings", "Analyses.csv", package = "AhasHfBkleAmputation")
  analyses <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  loadBalance <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = fileName, full.names = TRUE)
    return(readRDS(file))
  }
  
  for (i in 1:nrow(primaryTcos)) {
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[i])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeNames <- as.character(tcosOfInterest$outcomeNames[i])
    outcomeNames <- strsplit(outcomeNames, split = ";")[[1]]
    # One outcome only:
    for (j in 1:1){#length(outcomeIds)) {
      outcomeId <- outcomeIds[j]
      outcomeName <- outcomeNames[j]
      allBalance <- list()
      tables <- list()
      header3 <- c("Characteristic")
      for (k in 1:length(databaseNames)) {
        databaseName <- databaseNames[k]
        shinyDataFolder <- file.path(outputFolders[k], "results", "shinyData")
        fileName <-  paste0("bal_a",primaryAnalysisId,"_t",primaryTcos$targetId[i],"_c",primaryTcos$comparatorId[i],"_o",outcomeId,"_",databaseName,".rds")
        balance <- readRDS(file.path(outputFolders[k], "results", "balance", fileName))
        # Infer population sizes before matching:
        beforeTargetPopSize <- round(mean(balance$beforeMatchingSumTreated / balance$beforeMatchingMeanTreated, na.rm = TRUE))
        beforeComparatorPopSize <- round(mean(balance$beforeMatchingSumComparator / balance$beforeMatchingMeanComparator, na.rm = TRUE))
        
        fileName <-  paste0("ahaBal_a",primaryAnalysisId,"_t",primaryTcos$targetId[i],"_c",primaryTcos$comparatorId[i],"_o",outcomeId,"_",databaseName,".rds")
        priorAhaBalance  <- readRDS(file.path(shinyDataFolder, fileName))
        balance <- balance[, names(priorAhaBalance)]
        balance <- rbind(balance, priorAhaBalance)
        # Abbreviate some covariate names:
        balance$covariateName <- gsub("hospitalizations for heart failure.*", "Hospitalization for heart failure", balance$covariateName)
        balance$covariateName <- gsub("Below Knee Lower Extremity Amputation events", "BKLE amputations", balance$covariateName)
        balance$covariateName <- gsub("Neurologic disorder associated with diabetes mellitus", "Neurologic disorder associated with DM", balance$covariateName)
        tables[[k]] <- prepareTable1(balance)
        allBalance[[k]] <- balance
        fileName <-  file.path(shinyDataFolder, paste0("resultsHois_", databaseName,".rds"))
        resultsHois <- readRDS(fileName)
        row <- resultsHois[resultsHois$targetId == primaryTcos$targetId[i] &
                             resultsHois$comparatorId == primaryTcos$comparatorId[i] &
                             resultsHois$outcomeId == outcomeId &
                             resultsHois$analysisId == primaryAnalysisId, ]
        # header3 <- c(header3,
        #              paste0("% (n = ",format(beforeTargetPopSize, big.mark = ","), ")"),
        #              paste0("% (n = ",format(beforeComparatorPopSize, big.mark = ","), ")"),
        #              "Std.diff",
        #              paste0("% (n = ",format(row$treated, big.mark = ","), ")"),
        #              paste0("% (n = ",format(row$comparator, big.mark = ","), ")"),
        #              "Std.diff")
        header3 <- c(header3,
                     "%",
                     "%",
                     "Std.d.",
                     "%",
                     "%",
                     "Std.d.")
      }
      # Create main table by combining all balances to get complete list of covariates:
      allBalance <- do.call(rbind, allBalance)
      allBalance <- allBalance[order(allBalance$covariateName), ]
      allBalance <- allBalance[!duplicated(allBalance$covariateName), ]
      headerCol <- prepareTable1(allBalance)[, 1]
      mainTable <- matrix(NA, nrow = length(headerCol), ncol = length(tables) * 6)
      for (k in 1:length(databaseNames)) {
        mainTable[match(tables[[k]]$Characteristic, headerCol), ((k-1)*6)+(1:6)] <- as.matrix(tables[[k]][, 2:7])
      }
      mainTable <- as.data.frame(mainTable)
      mainTable <- cbind(data.frame(headerCol = headerCol), mainTable)
      
      createExcelTable <- function(mainTable, part) {
        library(xlsx)
        workBook <- xlsx::createWorkbook(type="xlsx")
        sheet <- xlsx::createSheet(workBook, sheetName = "Population characteristics")
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
          addMergedRegion(sheet, 
                          startRow = 2, 
                          endRow = 2, 
                          startColumn = (k-1)*6 + 2, 
                          endColumn = (k-1)*6 + 4)
          addMergedRegion(sheet, 
                          startRow = 2, 
                          endRow = 2, 
                          startColumn = (k-1)*6 + 5, 
                          endColumn = (k-1)*6 + 7)
        }
        header2 <- c("", rep(c("T", "c", ""), 2*length(databaseNames)))
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
        fileName <- paste0("Chars ", primaryTcos$targetDrug[i], "_", primaryTcos$comparatorDrug[i],if (primaryTcos$establishedCvd[i] == "required") "_cvd" else "_all", "_part",part,".xlsx")
        xlsx::saveWorkbook(workBook, file.path(reportFolder, fileName))
      }
      
      half <- ceiling(nrow(mainTable) / 2)
      createExcelTable(mainTable[1:half, ], 1)
      createExcelTable(mainTable[(half+1):nrow(mainTable), ], 2)
    }
  }
}


prepareTable1 <- function(balance) {
  pathToCsv <- system.file("settings", "Table1Specs.csv", package = "AhasHfBkleAmputation")
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
  for (i in 1:nrow(specifications)) {
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
  resultsTable$beforeMatchingMeanTreated <- resultsTable$beforeMatchingMeanTreated * 100
  resultsTable$beforeMatchingMeanComparator <- resultsTable$beforeMatchingMeanComparator * 100
  resultsTable$afterMatchingMeanTreated <- resultsTable$afterMatchingMeanTreated * 100
  resultsTable$afterMatchingMeanComparator <- resultsTable$afterMatchingMeanComparator * 100
  return(resultsTable)
}

selectKaplanMeierPlots <- function() {
  
  plotKm <- function(database, outputFolder, establishedCvd, analysisId, outcomeId) {
    cmOutputFolder <- file.path(outputFolder, "cmOutput")
    reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
    pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AhasHfBkleAmputation")
    tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
    row <- tcosOfInterest[tcosOfInterest$targetDrug =="canagliflozin" & 
                            tcosOfInterest$comparatorDrug == "any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA" &
                            tcosOfInterest$establishedCvd == establishedCvd &
                            tcosOfInterest$priorExposure == "no restrictions" &
                            tcosOfInterest$censorAtSwitch == TRUE, ]
    strataFile <- reference$strataFile[reference$targetId == row$targetId &
                                         reference$comparatorId == row$comparatorId &
                                         reference$analysisId == analysisId &
                                         reference$outcomeId == outcomeId]
    strataFile <- gsub("^[a-z]:/", "r:/",  strataFile)
    strata <- readRDS(strataFile)
    plot <- CohortMethod::plotKaplanMeier(strata,
                                          title = database,
                                          treatmentLabel = "canagliflozin",
                                          comparatorLabel = "non-SGLT2i")
    return(plot)
  }
  
  plot4Plots <- function(establishedCvd, analysisId, outcomeId) {
    plot1 <- plotKm(database = databaseNames[1],
                    outputFolder = outputFolders[1],
                    establishedCvd = establishedCvd,
                    analysisId = analysisId,
                    outcomeId = outcomeId)
    plot2 <-plotKm(database = databaseNames[2],
                   outputFolder = outputFolders[2],
                   establishedCvd = establishedCvd,
                   analysisId = analysisId,
                   outcomeId = outcomeId)
    plot3 <-plotKm(database = databaseNames[3],
                   outputFolder = outputFolders[3],
                   establishedCvd = establishedCvd,
                   analysisId = analysisId,
                   outcomeId = outcomeId)
    plot4 <-plotKm(database = databaseNames[4],
                   outputFolder = outputFolders[4],
                   establishedCvd = establishedCvd,
                   analysisId = analysisId,
                   outcomeId = outcomeId)
    
    g <- gridExtra::grid.arrange(plot1$grobs[[1]], 
                                 plot2$grobs[[1]], 
                                 plot1$grobs[[2]],
                                 plot2$grobs[[2]],
                                 plot3$grobs[[1]],
                                 plot4$grobs[[1]],
                                 plot3$grobs[[2]],
                                 plot4$grobs[[2]],
                                 heights = c(400,125, 400, 125),
                                 nrow = 4,
                                 ncol = 2)
    fileName <- paste0("KM_",
                       if (analysisId == 2) "_onTreatment" else "_itt",
                       if (outcomeId == 5433) "_BkleAmputation" else "_heartFailure",
                       if (establishedCvd == "required") "_cvd" else "_all",
                       ".png")
    ggplot2::ggsave(plot = g, filename = file.path(reportFolder, fileName), width = 13, height = 9)
  }
  # analysisId 2 = on treatment first post-index event
  # analysisId 4 = ITT first post-index event
  # outcomeId 5432 = Heart Failure
  # outcomeId 5433 = BKLE amputations
  plot4Plots(establishedCvd = "not required", analysisId = 2, outcomeId = 5432)
  plot4Plots(establishedCvd = "not required", analysisId = 4, outcomeId = 5432)
  plot4Plots(establishedCvd = "required", analysisId = 2, outcomeId = 5432)
  plot4Plots(establishedCvd = "required", analysisId = 4, outcomeId = 5432)
  plot4Plots(establishedCvd = "not required", analysisId = 2, outcomeId = 5433)
  plot4Plots(establishedCvd = "not required", analysisId = 4, outcomeId = 5433)
  plot4Plots(establishedCvd = "required", analysisId = 2, outcomeId = 5433)
  plot4Plots(establishedCvd = "required", analysisId = 4, outcomeId = 5433)
}


createTimeAtRiskTable <- function(outputFolders, databaseNames, reportFolder) {
  requireNamespace("XLConnect")
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(outputFolders, loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  outcomeNames <- unique(results$outcomeName)
  establishedCvds <- unique(results$establishedCvd)
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  for (outcomeName in outcomeNames) {
    # outcomeName <- outcomeNames[1]
    for (establishedCvd in establishedCvds) {
      #establishedCvd <- establishedCvds[1]
      fileName <- file.path(reportFolder, paste0("TAR ", outcomeName, if (establishedCvd == "required") "_cvd" else "_all", ".xlsx"))
      unlink(fileName)
      wb <- XLConnect::loadWorkbook(fileName, create = TRUE)
      XLConnect::createSheet(wb, name = "Time-at-risk")
      
      header0 <- rep("", 14)
      header0[3] <- "On treatment"
      header0[17] <- "Intent-to-treat"
      XLConnect::writeWorksheet(wb,
                                sheet = "Time-at-risk",
                                data = as.data.frame(t(header0)),
                                startRow = 1,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "C1:P1")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "Q1:AD1")
      header1 <- c("", "", "Target", "", "", "", "", "", "", "Comparator", "", "", "", "", "", "", "Target", "", "", "", "", "", "", "Comparator", "", "", "", "", "", "")
      XLConnect::writeWorksheet(wb,
                                sheet = "Time-at-risk",
                                data = as.data.frame(t(header1)),
                                startRow = 2,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "C2:I2")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "J2:P2")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "Q2:W2")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "X2:AD2")
      header2 <- c("Question",
                   "Source",
                   "Mean",
                   "SD",
                   "Min",
                   "P25",
                   "Med",
                   "P75",
                   "Max",
                   "Mean",
                   "SD",
                   "Min",
                   "P25",
                   "Med",
                   "P75",
                   "Max",
                   "Mean",
                   "SD",
                   "Min",
                   "P25",
                   "Med",
                   "P75",
                   "Max",
                   "Mean",
                   "SD",
                   "Min",
                   "P25",
                   "Med",
                   "P75",
                   "Max")
      XLConnect::writeWorksheet(wb,
                                sheet = "Time-at-risk",
                                data = as.data.frame(t(header2)),
                                startRow = 3,
                                startCol = 1,
                                rownames = FALSE,
                                header = FALSE)
      idx <- results$outcomeName == outcomeName &
        results$comparison %in% comparisonsOfInterest &
        results$psStrategy == "Matching" &
        results$priorExposure == "no restrictions" &
        results$evenType == "First Post Index Event" &
        results$establishedCvd == establishedCvd
      
      results$dbOrder <- match(results$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))
      results$comparisonOrder <- match(results$comparison, comparisonsOfInterest)
      onTreatment <- results[idx & results$timeAtRisk == "On Treatment", ]
      itt <- results[idx & results$timeAtRisk == "Intent to Treat", ]
      onTreatment <- onTreatment[order(onTreatment$establishedCvd, 
                                       onTreatment$comparisonOrder,
                                       onTreatment$dbOrder), ]
      itt <- itt[order(itt$establishedCvd, 
                       itt$comparisonOrder,
                       itt$dbOrder), ]
      if (!all.equal(onTreatment$establishedCvd, itt$establishedCvd) ||
          !all.equal(onTreatment$comparison, itt$comparison) ||
          !all.equal(onTreatment$database, itt$database)) {
        stop("Problem with sorting of data")
      }
      formatDays <- function(days) {
        formatC(days, big.mark = ",", format="d")
      }
      formatMeanSd <- function(days) {
        formatC(days, digits = 1, format = "f")
      }
      formatEstablishCvd <- function(x) {
        result <- rep("With established CV disease", length(x))
        result[x == "not required"] <- "All"
        return(result)
      }
      formatQuestion  <- function(x) {
        result <- rep("canagliflozin vs. other SGLT2i", length(x))
        result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "canagliflozin vs. select non-SGLT2i"
        result[x == "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "other SGLT2i vs. all non-SGLT2"
        result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "canagliflozin vs. all non-SGLT2i"
        return(result)
      }
      
      mainTable <- data.frame(question = formatQuestion(onTreatment$comparison),
                              source = onTreatment$database,
                              meanTOnTreatment = onTreatment$tarTargetMean,
                              sdTOnTreatment = onTreatment$tarTargetSd,
                              minTOnTreatment = onTreatment$tarTargetMin,
                              p25TOnTreatment = onTreatment$tarTargetP25,
                              medianTOnTreatment = onTreatment$tarTargetMedian,
                              p75TOnTreatment = onTreatment$tarTargetP75,
                              maxTOnTreatment = onTreatment$tarTargetMax,
                              meanCOnTreatment = onTreatment$tarComparatorMean,
                              sdCOnTreatment = onTreatment$tarComparatorSd,
                              minCOnTreatment = onTreatment$tarComparatorMin,
                              p25COnTreatment = onTreatment$tarComparatorP25,
                              medianCOnTreatment = onTreatment$tarComparatorMedian,
                              p75COnTreatment = onTreatment$tarComparatorP75,
                              maxCOnTreatment = onTreatment$tarComparatorMax,
                              meanTItt = itt$tarTargetMean,
                              sdTItt = itt$tarTargetSd,
                              minTItt = itt$tarTargetMin,
                              p25TItt = itt$tarTargetP25,
                              medianTItt = itt$tarTargetMedian,
                              p75TItt = itt$tarTargetP75,
                              maxTItt = itt$tarTargetMax,
                              meanCItt = itt$tarComparatorMean,
                              sdCItt = itt$tarComparatorSd,
                              minCItt = itt$tarComparatorMin,
                              p25CItt = itt$tarComparatorP25,
                              medianCItt = itt$tarComparatorMedian,
                              p75CItt = itt$tarComparatorP75,
                              maxCItt = itt$tarComparatorMax)
      XLConnect::writeWorksheet(wb,
                                data = mainTable,
                                sheet = "Time-at-risk",
                                startRow = 4,
                                startCol = 1,
                                header = FALSE,
                                rownames = FALSE)
      pStyle <- XLConnect::createCellStyle(wb)
      XLConnect::setDataFormat(pStyle, format = "#,##0.0")
      countStyle <- XLConnect::createCellStyle(wb)
      XLConnect::setDataFormat(countStyle, format = "#,##0")
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(3, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(4, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(5, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(6, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(7, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(8, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(9, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(10, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(11, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(12, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(13, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(14, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(15, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(16, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(17, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(18, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(19, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(20, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(21, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(22, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(23, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(24, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(25, 19), cellstyle = pStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(26, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(27, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(28, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(29, 19), cellstyle = countStyle)
      XLConnect::setCellStyle(wb, sheet = "Time-at-risk", row = 4:19, col = rep(30, 19), cellstyle = countStyle)
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "A4:A7")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "A8:A11")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "A12:A15")
      XLConnect::mergeCells(wb, sheet = "Time-at-risk", reference = "A16:A19")
      XLConnect::setColumnWidth(wb, sheet = "Time-at-risk", column = 1, width = -1)
      XLConnect::setColumnWidth(wb, sheet = "Time-at-risk", column = 2, width = -1)
      XLConnect::saveWorkbook(wb)
    }
  }
}

outputAllEstimatesToSingleTable <- function(outputFolders, databaseNames, maOutputFolder, reportFolder) {
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    files <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    result <- data.frame()
    for (file in files) {
      x <- readRDS(file)
      if (is.null(x$i2))
        x$i2 <- NA
      result <- rbind(result, x)
    }
    return(result)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$rr[is.na(results$seLogRr)] <- NA
  
  formatDrug  <- function(x) {
    result <- x
    result[x == "empagliflozin or dapagliflozin"] <- "other SGLT2i"
    result[x == "any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "select non-SGLT2i"
    result[x == "any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "all non-SGLT2i"
    return(result)
  }
  results$targetDrug <- formatDrug(results$targetDrug)
  results$comparatorDrug <- formatDrug(results$comparatorDrug)
  table <- results[, c("targetDrug",
                       "comparatorDrug",
                       "outcomeName",
                       "establishedCvd", 
                       "priorExposure", 
                       "timeAtRisk", 
                       "evenType",
                       "psStrategy",
                       "database",
                       "rr", 
                       "ci95lb",
                       "ci95ub",
                       "p",
                       "calP")]
  
  colnames(table) <- c("Target", "Comparator", "Outcome",
                       "Established cardiovascular disease", 
                       "Prior exposure", 
                       "Time at risk", 
                       "Event type", 
                       "Propensity score strategy",
                       "Database",
                       "Hazard ratio", 
                       "Lower bound of the 95 confidence interval",
                       "Upper bound of the 95 confidence interval",
                       "P-value (uncalibrated)",
                       "Calibrated p-value")
  fileName <- file.path(reportFolder, "AllEffectSizeEstimates.xlsx")
  unlink(fileName)
  wb <- XLConnect::loadWorkbook(fileName, create = TRUE)
  XLConnect::createSheet(wb, name = "Effect size estimates")
  XLConnect::writeWorksheet(wb,
                            data = table,
                            sheet = "Effect size estimates",
                            startRow = 1,
                            startCol = 1,
                            header = TRUE,
                            rownames = FALSE)
  style <- XLConnect::createCellStyle(wb)
  XLConnect::setDataFormat(style, format = "#,##0.00")
  XLConnect::setCellStyle(wb, sheet = "Effect size estimates", row = 1+1:nrow(results), col = 10, cellstyle = style)
  XLConnect::setCellStyle(wb, sheet = "Effect size estimates", row = 1+1:nrow(results), col = 11, cellstyle = style)
  XLConnect::setCellStyle(wb, sheet = "Effect size estimates", row = 1+1:nrow(results), col = 12, cellstyle = style)
  XLConnect::setCellStyle(wb, sheet = "Effect size estimates", row = 1+1:nrow(results), col = 13, cellstyle = style)
  XLConnect::setCellStyle(wb, sheet = "Effect size estimates", row = 1+1:nrow(results), col = 14, cellstyle = style)
  XLConnect::saveWorkbook(wb)              
}


createEstimateScatterPlots <- function(outputFolders, databaseNames, maOutputFolder, reportFolder) {
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- lapply(file, readRDS)
    x <- do.call(rbind, x)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  
  loadResultsNcs <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsNcs_.*.rds", full.names = TRUE)
    x <- lapply(file, readRDS)
    x <- do.call(rbind, x)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  resultsNcs <- lapply(c(outputFolders, maOutputFolder), loadResultsNcs)
  resultsNcs <- do.call(rbind, resultsNcs)
  resultsNcs <- merge(resultsNcs, unique(results[, c("targetId", "comparatorId", "comparison")]))
  resultsNcs$outcomeName <- "Negative control"
  
  
  allResults <- rbind(results[, c("comparison", "outcomeName", "logRr", "seLogRr", "database")],
                      resultsNcs[, c("comparison", "outcomeName", "logRr", "seLogRr", "database")])
  
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  subset <- allResults[allResults$comparison %in% comparisonsOfInterest, ]
  formatQuestion  <- function(x) {
    result <- rep("canagliflozin vs.\n other SGLT2i", length(x))
    result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "canagliflozin vs.\n select non-SGLT2i"
    result[x == "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "other SGLT2i vs\n. all non-SGLT2"
    result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "canagliflozin vs.\n all non-SGLT2i"
    return(result)
  }
  subset$comparison <- formatQuestion(subset$comparison)
  
  subset$dummy <- 1
  temp1 <- aggregate(dummy ~ comparison + outcomeName, data = subset, sum)
  temp1$nLabel <- paste0(formatC(temp1$dummy, big.mark = ",", format = "d"), " estimates")
  temp1$dummy <- NULL
  subset$Significant <- abs(subset$logRr) > qnorm(0.975)*subset$seLogRr
  temp2 <- aggregate(Significant~ comparison + outcomeName, data = subset, mean)
  temp2$meanLabel <- paste0(formatC(100 * (1-temp2$Significant), digits = 1, format = "f"), "% of CIs include 1")
  temp2$Significant <- NULL
  dd <- merge(temp1, temp2)
  
  
  library(ggplot2)
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- element_text(colour = "#000000", size = 12)
  themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
  themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)
  plot <- ggplot(subset, aes(x=logRr, y=seLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_point(size=1, color = rgb(0,0,0), shape = 16, aes(alpha = outcomeName)) +
    geom_hline(yintercept=0) +
    geom_label(x = log(0.11), y = 0.99, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd) +
    geom_label(x = log(0.11), y = 0.88, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = dd) +
    scale_x_continuous("Hazard ratio",limits = log(c(0.1,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    facet_grid(comparison~outcomeName) +
    scale_alpha_manual(values = c(0.4, 0.4, 0.1)) +
    theme(
      panel.grid.minor = element_blank(),
      panel.background= element_blank(),
      panel.grid.major= element_blank(),
      axis.ticks = element_blank(),
      axis.text.y = themeRA,
      axis.text.x = theme,
      legend.key= element_blank(),
      strip.text.x = theme,
      strip.text.y = theme,
      strip.background = element_blank(),
      legend.position = "none"
    )
  fileName <- file.path(reportFolder, "EstimateScatterPlot.png")
  ggsave(plot = plot, fileName, width = 14, height = 10, dpi = 500)
  
  # Primary analysis only ----------------------------
  createPlot <- function(data, fileName) {
    plot <- ggplot(data, aes(x=logRr, y=seLogRr), environment=environment())+
      geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
      geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
      geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
      geom_point(size=2, color = rgb(0,0,0), shape = 16) +
      geom_hline(yintercept=0) +
      scale_x_continuous("Hazard ratio",limits = log(c(0.1,10)), breaks=log(breaks),labels=breaks) +
      scale_y_continuous("Standard Error",limits = c(0,1)) +
      facet_grid(.~outcomeName) +
      theme(
        panel.grid.minor = element_blank(),
        panel.background= element_blank(),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = themeRA,
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.text.y = theme,
        strip.background = element_blank(),
        legend.position = "none"
      )
    ggsave(plot = plot, fileName, width = 7, height = 4, dpi = 500)
  }
  primary <- results[results$comparison == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA" & 
                       results$establishedCvd == "not required" &
                       results$priorExposure == "no restrictions" &
                       !grepl("no censor at switch", results$timeAtRisk) &
                       !grepl("Meta-analysis", results$database) &
                       results$analysisId == 2, ]
  
  createPlot(primary[primary$outcomeId == 5432, ], file.path(reportFolder, "EstimateScatterPlot_CanaVsNonSglt2_HeartFailure.png"))
  createPlot(primary[primary$outcomeId == 5433, ], file.path(reportFolder, "EstimateScatterPlot_CanaVsNonSglt2_BkleAmpuation.png"))
  
  primary <- results[results$comparison == "canagliflozin - empagliflozin or dapagliflozin" & 
                       results$establishedCvd == "not required" &
                       results$priorExposure == "no restrictions" &
                       !grepl("no censor at switch", results$timeAtRisk) &
                       !grepl("Meta-analysis", results$database) &
                       results$analysisId == 2, ]
  
  createPlot(primary[primary$outcomeId == 5432, ], file.path(reportFolder, "EstimateScatterPlot_CanaVsOtherSglt2_HeartFailure.png"))
  createPlot(primary[primary$outcomeId == 5433, ], file.path(reportFolder, "EstimateScatterPlot_CanaVsOtherSglt2_BkleAmpuation.png"))
  
  
  
  
  plot <- ggplot(primary[primary$outcomeId == 5433, ], aes(x=logRr, y=seLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1,alpha=0.5) +
    geom_point(size=2, color = rgb(0,0,0), shape = 16) +
    geom_hline(yintercept=0) +
    scale_x_continuous("Hazard ratio",limits = log(c(0.1,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    facet_grid(.~outcomeName) +
    theme(
      panel.grid.minor = element_blank(),
      panel.background= element_blank(),
      panel.grid.major= element_blank(),
      axis.ticks = element_blank(),
      axis.text.y = themeRA,
      axis.text.x = theme,
      legend.key= element_blank(),
      strip.text.x = theme,
      strip.text.y = theme,
      strip.background = element_blank(),
      legend.position = "none"
    )
  fileName <- file.path(reportFolder, "EstimateScatterPlot_BKLEAmputation.png")
  ggsave(plot = plot, fileName, width = 7, height = 4, dpi = 500)
}

pot3DScatter <- function() {
  loadResultsHois <- function(outputFolder, fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- lapply(file, readRDS)
    x <- do.call(rbind, x)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
  results <- do.call(rbind, results)
  results$comparison <- paste(results$targetDrug, results$comparatorDrug, sep = " - ")
  comparisonsOfInterest <- c("canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA",
                             "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA",
                             "canagliflozin - empagliflozin or dapagliflozin",
                             "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA")
  subset <- results[results$comparison %in% comparisonsOfInterest, ]
  
  formatQuestion  <- function(x) {
    result <- rep("canagliflozin vs. other SGLT2i", length(x))
    result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, or other select AHA"] <- "canagliflozin vs. select non-SGLT2i"
    result[x == "empagliflozin or dapagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "other SGLT2i vs. all non-SGLT2"
    result[x == "canagliflozin - any DPP-4 inhibitor, GLP-1 agonist, TZD, SU, insulin, or other select AHA"] <- "canagliflozin vs. all non-SGLT2i"
    return(result)
  }
  subset$comparison <- formatQuestion(subset$comparison)
  subset <- subset[!is.na(subset$seLogRr), ]
  subset <- subset[subset$seLogRr < 1, ]
  subset <- subset[abs(subset$logRr) < 3, ]
  idx <- subset$comparison == "canagliflozin vs. all non-SGLT2i"

  d1 <- data.frame(logRr1 = subset$logRr[idx],
                   seLogRr1 = subset$seLogRr[idx],
                   outcomeName = subset$outcomeName[idx],
                   targetId = subset$targetId[idx],
                   analysisId = subset$analysisId[idx],
                   database = subset$database[idx])
  idx <- subset$comparison == "canagliflozin vs. other SGLT2i"
  d2 <- data.frame(logRr2 = subset$logRr[idx],
                   seLogRr2 = subset$seLogRr[idx],
                   outcomeName = subset$outcomeName[idx],
                   targetId = subset$targetId[idx],
                   analysisId = subset$analysisId[idx],
                   database = subset$database[idx])
  d <- merge(d1, d2)
  d <- d[!is.na(d$seLogRr1) & !is.na(d$seLogRr2), ]
  
  library(scatterplot3d)
  
  
  plot(d$seLogRr1, d$seLogRr2)
  cor(d$seLogRr1, d$seLogRr2)
  plot(d$logRr1, d$logRr2)
  cor(d$logRr1, d$logRr2)
  idx <- d$outcomeName == "Heart failure"
  s3d <- scatterplot3d(d$logRr1[idx], d$logRr2[idx], d$seLogRr1[idx], col.axis = "blue",
                col.grid = "lightblue", main = "Helix", pch = 16, color = "#66000066", size = 2)
  idx <- d$outcomeName == "BKLE amputation"
  s3d$points3d(d$logRr1[idx], d$logRr2[idx], d$seLogRr1[idx], pch = 16, col = "#00006666", size = 2)
  
  d$o <- as.numeric(d$outcomeName == "Heart failure")
  d$z <- (max(d$logRr2) - d$logRr2) / (max(d$logRr2) - min(d$logRr2))
  d$color <- hsv(0 + d$o*0.667, d$z^2, 0.5, alpha = 0.5)
  scatterplot3d(d$logRr1, d$logRr2, d$seLogRr1, col.axis = "blue",
                col.grid = "lightblue", main = "Helix", pch = 16, color = d$color, cex.symbols = 2)
}

