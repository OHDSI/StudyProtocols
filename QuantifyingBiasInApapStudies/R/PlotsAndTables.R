# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of QuantifyingBiasInApapStudies
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

#' Generate plots and tables 
#' 
#' @details 
#' Requires that the CohortMethod and CaseControl analyses have been executed
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param blind                Blind results? If true, no real effect sizes will be shown. To be used during development.
#'
#' @export
createPlotsAndTables <- function(connectionDetails,
                                 cdmDatabaseSchema,
                                 oracleTempSchema,
                                 outputFolder,
                                 blind = TRUE) {
  plotsAndTablesFolder <- file.path(outputFolder, "plotsAndTables")
  ParallelLogger::logInfo("Generating plots and tables in folder ", plotsAndTablesFolder)
  if (!file.exists(plotsAndTablesFolder)) {
    dir.create(plotsAndTablesFolder)
  }
  
  # Cohort method ---------------------------------------------------------------------
  ParallelLogger::logInfo("Generating plots and tables for cohort design")
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  omr <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  
  # PS distribution plot
  ps <- readRDS(file.path(cmOutputFolder, omr$sharedPsFile[omr$analysisId ==  9][1]))
  CohortMethod::plotPs(ps, fileName = file.path(plotsAndTablesFolder, "ps.png"), targetLabel = "High use", comparatorLabel = "No use", showEquiposeLabel = TRUE)
  
  # PS model
  cmData <- CohortMethod::loadCohortMethodData(file.path(cmOutputFolder, omr$cohortMethodDataFolder[omr$analysisId ==  9][1]))
  model <- CohortMethod::getPsModel(ps, cmData)
  write.csv(model, file.path(plotsAndTablesFolder, "propensityModel.csv"), row.names = FALSE)
  
  # Balance
  pop <- cmData$cohorts
  pop$stratumId <- 0
  bal <- CohortMethod::computeCovariateBalance(pop, cmData)
  table <- bal[order(-abs(bal$beforeMatchingStdDiff)), c("covariateId", "covariateName", "beforeMatchingMeanTarget", "beforeMatchingMeanComparator", "beforeMatchingSd", "beforeMatchingStdDiff")]
  table$balanced <- abs(bal$beforeMatchingStdDiff) <= 0.1
  colnames(table) <- c("Covariate ID", "Covariate name", "Mean in high use", "Mean in no use", "Std. Dev.", "Standardized difference of the mean", "Balanced?")
  write.csv(table, file.path(plotsAndTablesFolder, "balance.csv"), row.names = FALSE)
  
  # Table 1
  table1 <- CohortMethod::createCmTable1(bal, beforeTargetPopSize = sum(pop$treatment), beforeComparatorPopSize = sum(!pop$treatment))
  table1 <- table1[, 1:4]
  write.csv(table1, file.path(plotsAndTablesFolder, "cmCharacteristicsTable.csv"), col.names = NULL, row.names = FALSE)
  
  # Analysis summary
  analysisSummary <- read.csv(file.path(outputFolder, "cmAnalysisSummary.csv"))
  
  if (blind) {
    analysisSummary <- blind(analysisSummary)
  }
  
  table <- analysisSummary[, c("analysisId", "analysisDescription", "outcomeName", "rr", "ci95lb", "ci95ub", "p", "target", "comparator", "targetDays", "comparatorDays", "eventsTarget", "eventsComparator")]
  colnames(table) <- c("Analysis ID", "Description", "Outcome", "HR", "95% CI LB", "95% CI UB", "P", "High-use subject count", "No-use subject count", "High-use follow-up days", "No-use follow-up days", "High-use outcome count", "No-use outcome count")
  write.csv(table, file.path(plotsAndTablesFolder, "cmAnalysisSummary.csv"), row.names = FALSE)
  
  # Forest plot
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  createAnalysisForestPlot <- function(subset) {
    subset$negativeControl <- FALSE
    subset$negativeControl[subset$outcomeId %in% negativeControls$outcomeId] <- TRUE  
    analysisId <- subset$analysisId[1]
    description <- subset$analysisDescription[1]
    plotForest(subset, 
               xLabel = "Hazard Ratio",
               fileName =  file.path(plotsAndTablesFolder, sprintf("forest_a%s.png", analysisId)))
  }
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  lapply(subsets, createAnalysisForestPlot)
  
  # Calibration plot and distribution parameter estimates
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  table <- lapply(subsets, createCalibrationPlot, negativeControls = negativeControls, plotsAndTablesFolder = plotsAndTablesFolder, xLabel = "Hazard Ratio")
  table <- do.call(rbind, table)
  write.csv(table, file.path(plotsAndTablesFolder, "cmEmpiricalNullParams.csv"), row.names = FALSE)
  
  # Fraction significant negative controls 
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  table <- lapply(subsets, computeFractionSignificant, negativeControls = negativeControls)
  table <- do.call(rbind, table)
  write.csv(table, file.path(plotsAndTablesFolder, "cmNcsSignificant.csv"), row.names = FALSE)
  
  # Case-control -----------------------------------------------------------------------
  ParallelLogger::logInfo("Generating plots and tables for case-control design")
  ccOutputFolder <- file.path(outputFolder, "ccOutput")
  omr <- readRDS(file.path(ccOutputFolder, "outcomeModelReference.rds"))
  
  # Table 1
  pathToCsv <- system.file("settings", "TosOfInterest.csv", package = "QuantifyingBiasInApapStudies")
  tosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  hois <- unique(as.integer(do.call(c, (strsplit(tosOfInterest$outcomeIds, ";")))))
  connection <- DatabaseConnector::connect(connectionDetails)
  
  for (outcomeId in hois) {
    for (analysisId in unique(omr$analysisId)) {
      ParallelLogger::logInfo("Generating population characteristics table for outcome ", outcomeId, " using analysis ", analysisId)
      fileName <- file.path(plotsAndTablesFolder, sprintf("ccCharacteristicsTable_a%s_o%s.csv", analysisId, outcomeId))
      createCharacteristicsByExposure(connection = connection, 
                                      cdmDatabaseSchema = cdmDatabaseSchema, 
                                      oracleTempSchema = oracleTempSchema,
                                      outputFolder = outputFolder, 
                                      analysisId = analysisId, 
                                      outcomeId = outcomeId,
                                      fileName = fileName)
    }
  }
  DatabaseConnector::disconnect(connection)
  
  # Analysis summary
  analysisSummary <- read.csv(file.path(outputFolder, "ccAnalysisSummary.csv"))
  
  if (blind) {
    analysisSummary <- blind(analysisSummary)
  }
  
  table <- analysisSummary[, c("analysisId", "analysisDescription", "outcomeName", "rr", "ci95lb", "ci95ub", "p", "cases", "controls", "exposedCases", "exposedControls")]
  colnames(table) <- c("Analysis ID", "Description", "Outcome", "OR", "95% CI LB", "95% CI UB", "P", "Cases", "Controls", "Exposed cases", "Exposed controls")
  write.csv(table, file.path(plotsAndTablesFolder, "ccAnalysisSummary.csv"), row.names = FALSE)
  
  # Forest plot
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  createAnalysisForestPlot <- function(subset) {
    subset$negativeControl <- FALSE
    subset$negativeControl[subset$outcomeId %in% negativeControls$outcomeId] <- TRUE  
    analysisId <- subset$analysisId[1]
    description <- subset$analysisDescription[1]
    plotForest(subset, 
               xLabel = "Odds Ratio",
               fileName =  file.path(plotsAndTablesFolder, sprintf("forest_a%s.png", analysisId)))
  }
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  lapply(subsets, createAnalysisForestPlot)
  
  # Calibration plot and distribution parameter estimates
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  table <- lapply(subsets, createCalibrationPlot, negativeControls = negativeControls, plotsAndTablesFolder = plotsAndTablesFolder, xLabel = "Odds Ratio")
  table <- do.call(rbind, table)
  write.csv(table, file.path(plotsAndTablesFolder, "ccEmpiricalNullParams.csv"), row.names = FALSE)
  
  # Fraction significant negative controls 
  subsets <- split(analysisSummary, analysisSummary$analysisId)
  table <- lapply(subsets, computeFractionSignificant, negativeControls = negativeControls)
  table <- do.call(rbind, table)
  write.csv(table, file.path(plotsAndTablesFolder, "ccNcsSignificant.csv"), row.names = FALSE)
}

computeFractionSignificant <- function(subset, negativeControls) {
  ncs <- subset[subset$outcomeId %in% negativeControls$outcomeId, ] 
  row <- data.frame(analysisId = subset$analysisId[1],
                    description = subset$analysisDescription[1],
                    controlsWithEstimates = sum(!is.na(ncs$ci95lb)),
                    controlsSignficant = sum(!is.na(ncs$ci95lb) & ncs$p < 0.05))
  row$fractionSignificant <- row$controlsSignficant / row$controlsWithEstimates
  colnames(row) <- c("Analysis ID", "Description", "Controls with estimate", "Controls significant", "Fraction significant (p < 0.05)")
  return(row)
}

createCalibrationPlot <- function(subset, negativeControls, plotsAndTablesFolder, xLabel) {
  ncs <- subset[subset$outcomeId %in% negativeControls$outcomeId, ]  
  pcs <- subset[!(subset$outcomeId %in% negativeControls$outcomeId), ]  
  analysisId <- subset$analysisId[1]
  EmpiricalCalibration::plotCalibrationEffect(ncs$logRr, ncs$seLogRr, pcs$logRr, pcs$seLogRr, 
                                              xLabel = xLabel, 
                                              showCis = TRUE,
                                              fileName =  file.path(plotsAndTablesFolder, sprintf("calibration_a%s.png", analysisId)))
  param <- EmpiricalCalibration::fitNull(ncs$logRr, ncs$seLogRr)
  row <- data.frame(analysisId = subset$analysisId[1],
                    description = subset$analysisDescription[1],
                    mean = param[1],
                    SD = param[2])
  colnames(row) <- c("Analysis ID", "Description", "Mean", "SD")
  return(row)
}

blind <- function(data) {
  ParallelLogger::logInfo("Blinding results")
  data$logRr <- rnorm(nrow(data))
  seLogRr <- (log(data$ci95ub) - log(data$ci95lb))/(2 * qnorm(0.975))
  data$ci95lb <- exp(data$logRr + qnorm(0.025) * seLogRr)
  data$ci95ub <- exp(data$logRr + qnorm(0.975) * seLogRr)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  data$outcomeName <- "Simulated outcome of interest"
  data$outcomeName[data$outcomeId %in% negativeControls$outcomeId] <- "Simulated negative control"
  return(data)
}

plotForest <- function(data, 
                       xLabel = "Relative risk", 
                       limits = c(0.1, 10), 
                       fileName = NULL) {
  data <- data[!is.na(data$ci95lb), ]
  data$type <- "Outcome of interest"
  data$type[data$negativeControl] <- "Negative control"
  data <- data[order(-data$negativeControl, data$outcomeName), ]
  d1 <- data.frame(logRr = -100, logLb95Ci = -100, logUb95Ci = -100, 
                   name = "Outcome", type = "Outcome of interest")
  d2 <- data.frame(logRr = data$logRr, logLb95Ci = log(data$ci95lb), logUb95Ci = log(data$ci95ub), 
                   name = data$outcomeName, type = data$type)
  d <- rbind(d1, d2)
  d$y <- nrow(d):1
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = exp(logRr), y = y, xmin = exp(logLb95Ci), xmax = exp(logUb95Ci))) + 
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) + 
    ggplot2::geom_vline(xintercept = 1, size = 0.5) + 
    ggplot2::geom_errorbarh(height = 0.25) + 
    ggplot2::geom_point(size = 3, ggplot2::aes(shape = type, fill = type)) + 
    ggplot2::scale_fill_manual(values = c("#FFFF00", "#0000DD")) + 
    ggplot2::scale_shape_manual(values = c(23,21)) +
    ggplot2::scale_x_continuous(xLabel, trans = "log10", breaks = breaks, labels = breaks) + 
    ggplot2::coord_cartesian(xlim = limits) + 
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(), 
                   panel.grid.minor = ggplot2::element_blank(), 
                   panel.background = ggplot2::element_blank(), 
                   legend.position = "right", 
                   legend.title = ggplot2::element_blank(), 
                   panel.border = ggplot2::element_blank(), 
                   axis.text.y = ggplot2::element_blank(), 
                   axis.title.y = ggplot2::element_blank(), 
                   axis.ticks = ggplot2::element_blank(), 
                   plot.margin = grid::unit(c(0, 0, 0.1, 0), "lines"))
  labels <- paste0(formatC(exp(d$logRr), digits = 2, format = "f"), 
                   " (", 
                   formatC(exp(d$logLb95Ci), digits = 2, format = "f"), 
                   "-", 
                   formatC(exp(d$logUb95Ci), digits = 2, format = "f"), 
                   ")")
  labels <- data.frame(y = rep(d$y, 2), 
                       x = rep(c(1, 3), each = nrow(d)), 
                       label = c(as.character(d$name), labels), stringsAsFactors = FALSE)
  labels$label[nrow(d) + 1] <- paste(xLabel, "(95% CI)")
  data_table <- ggplot2::ggplot(labels, ggplot2::aes(x = x, y = y, label = label)) + 
    ggplot2::geom_text(size = 4, hjust = 0, vjust = 0.5) + 
    ggplot2::geom_hline(ggplot2::aes(yintercept = nrow(d) - 0.5)) + 
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(), 
                   panel.grid.minor = ggplot2::element_blank(), 
                   legend.position = "none",
                   panel.border = ggplot2::element_blank(), 
                   panel.background = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_text(colour = "white"), 
                   axis.text.y = ggplot2::element_blank(), 
                   axis.ticks = ggplot2::element_line(colour = "white"),
                   plot.margin = grid::unit(c(0, 0, 0.1, 0), "lines")) + 
    ggplot2::labs(x = "", y = "") + 
    ggplot2::coord_cartesian(xlim = c(1, 4))
  plot <- gridExtra::grid.arrange(data_table, p, ncol = 2)
  if (!is.null(fileName)) 
    ggplot2::ggsave(fileName, plot, width = 12, height = 1 + 
                      nrow(data) * 0.25, dpi = 300)
  return(plot)
}

createCharacteristicsByExposure <- function(connection, cdmDatabaseSchema, oracleTempSchema, outputFolder, analysisId, outcomeId, fileName) {
  
  # Fetch data from server ---------------------------------------------------------------------------------------
  ccOutputFolder <- file.path(outputFolder, "ccOutput")
  dataFolder <- file.path(ccOutputFolder, sprintf("covariatesForChar_a%s_o%s", analysisId, outcomeId))
  dir.create(dataFolder)
  omr <- readRDS(file.path(ccOutputFolder, "outcomeModelReference.rds"))
  
  idx <- omr$outcomeId == outcomeId & omr$analysisId == analysisId
  ccdFile <- file.path(ccOutputFolder, omr$caseControlDataFile[idx])
  ccFile <- file.path(ccOutputFolder, omr$caseControlsFile[idx])
  ccd <- readRDS(ccdFile)
  cc <- readRDS(ccFile)
  
  tableToUpload <- data.frame(subjectId = cc$personId,
                              cohortStartDate = cc$indexDate,
                              cohortDefinitionId = as.integer(ccd$exposed),
                              exposed = as.integer(ccd$exposed),
                              isCase = as.integer(cc$isCase))
  
  colnames(tableToUpload) <- SqlRender::camelCaseToSnakeCase(colnames(tableToUpload))
  
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = "scratch.dbo.mschuemi_temp",
                                 data = tableToUpload,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = FALSE,
                                 oracleTempSchema = oracleTempSchema,
                                 useMppBulkLoad = TRUE)
  
  covariateSettings <- FeatureExtraction::createTable1CovariateSettings()
  
  covsExposed <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                       oracleTempSchema = oracleTempSchema,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       cohortDatabaseSchema = "scratch.dbo",
                                                       cohortTable = "mschuemi_temp",
                                                       cohortTableIsTemp = FALSE,
                                                       cohortId = 1,
                                                       covariateSettings = covariateSettings,
                                                       aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsExposed, file.path(dataFolder, "covsExposed"))
  covsUnexposed <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                         oracleTempSchema = oracleTempSchema,
                                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                                         cohortDatabaseSchema = "scratch.dbo",
                                                         cohortTable = "mschuemi_temp",
                                                         cohortTableIsTemp = FALSE,
                                                         cohortId = 0,
                                                         covariateSettings = covariateSettings,
                                                         aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsUnexposed, file.path(dataFolder, "covsUnexposed"))
  
  executeSql(connection, "TRUNCATE TABLE scratch.dbo.mschuemi_temp; DROP TABLE scratch.dbo.mschuemi_temp;")
  
  # Create table ----------------------------------------------------------------------------------
  covariateData1 <- FeatureExtraction::loadCovariateData(file.path(dataFolder, "covsExposed"))
  covariateData2 <- FeatureExtraction::loadCovariateData(file.path(dataFolder, "covsUnexposed"))
  table1 <- FeatureExtraction::createTable1(covariateData1 = covariateData1, covariateData2 = covariateData2)
  write.csv(table1, fileName, row.names = FALSE)
}