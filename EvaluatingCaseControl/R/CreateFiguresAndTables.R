# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of EvaluatingCaseControl
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

#' @title
#' Create figures and tables
#'
#' @description
#' Create figures and tables for the paper.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
createFiguresAndTables <- function(connectionDetails,
                                   cdmDatabaseSchema,
                                   oracleTempSchema,
                                   outputFolder) {
  connection <- DatabaseConnector::connect(connectionDetails)

  ParallelLogger::logInfo("Fetching population characteristics for Crockett study")
  getCharacteristics(ccFile = file.path(outputFolder, "ccIbd", "caseControls_cd1_cc1_o3.rds"),
                     connection = connection,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     oracleTempSchema = oracleTempSchema,
                     resultsFolder = file.path(outputFolder, "resultsIbd"))

  ParallelLogger::logInfo("Fetching population characteristics for Chou study")
  getCharacteristics(ccFile = file.path(outputFolder, "ccAp", "caseControls_cd1_n1_cc1_o2.rds"),
                     connection = connection,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     oracleTempSchema = oracleTempSchema,
                     resultsFolder = file.path(outputFolder, "resultsAp"))

  createVisitPlot(resultsFolder = file.path(outputFolder, "resultsIbd"))
  createVisitPlot(resultsFolder = file.path(outputFolder, "resultsAp"))
  createCharacteristicsTable(resultsFolder = file.path(outputFolder, "resultsIbd"))
  createCharacteristicsTable(resultsFolder = file.path(outputFolder, "resultsAp"))
  plotOddsRatios(ccSummaryFile = file.path(outputFolder, "ccSummaryIbd.rds"),
                 exposureId = 5,
                 exposureName = "Isotretinoin",
                 resultsFolder = file.path(outputFolder, "resultsIbd"),
                 pubOr = 4.36,
                 pubLb = 1.97,
                 pubUb = 9.66)
  plotOddsRatios(ccSummaryFile = file.path(outputFolder, "ccSummaryAp.rds"),
                 exposureId = 4,
                 exposureName = "DPP-4",
                 resultsFolder = file.path(outputFolder, "resultsAp"),
                 pubOr = 1.04,
                 pubLb = 0.89,
                 pubUb = 1.21)

  calibrateCi(ccSummaryFile = file.path(outputFolder, "ccSummaryIbd.rds"),
              exposureId = 5,
              allControlsFile = file.path(outputFolder, "AllControlsIbd.csv"),
              resultsFolder = file.path(outputFolder, "resultsIbd"))
  calibrateCi(ccSummaryFile = file.path(outputFolder, "ccSummaryAp.rds"),
              exposureId = 4,
              allControlsFile = file.path(outputFolder, "AllControlsAp.csv"),
              resultsFolder = file.path(outputFolder, "resultsAp"))

  createEstimatesAppendix(outputFolder = outputFolder)
}

calibrateCi <- function(ccSummaryFile, exposureId, allControlsFile, resultsFolder) {
  ccSummary <- readRDS(ccSummaryFile)
  allControls <- read.csv(allControlsFile)
  allControls <- allControls[, c("targetId", "outcomeId", "targetEffectSize")]
  colnames(allControls) <- c("exposureId", "outcomeId", "targetEffectSize")
  allControls <- merge(allControls, ccSummary)
  negativeControls <- allControls[allControls$targetEffectSize == 1, ]
  hoi <- ccSummary[ccSummary$exposureId == exposureId & ccSummary$outcomeId < 10000, ]
  null <- EmpiricalCalibration::fitNull(logRr = negativeControls$logRr,
                                        seLogRr = negativeControls$seLogRr)
  hoiCal <- EmpiricalCalibration::calibrateP(null,
                                             logRr = hoi$logRr,
                                             seLogRr = hoi$seLogRr)
  hoi$calP <- hoiCal
  model <- EmpiricalCalibration::fitSystematicErrorModel(logRr = allControls$logRr,
                                                         seLogRr = allControls$seLogRr,
                                                         trueLogRr = log(allControls$targetEffectSize))

  hoiCal <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = hoi$logRr,
                                                    seLogRr = hoi$seLogRr,
                                                    model = model)
  hoi$calRr <- exp(hoiCal$logRr)
  hoi$calCi95lb <- exp(hoiCal$logLb95Rr)
  hoi$calCi95ub <- exp(hoiCal$logUb95Rr)
  fileName <- file.path(resultsFolder, "EmpiricalCalibration.csv")
  write.csv(hoi, fileName, row.names = FALSE)
  fileName <- file.path(resultsFolder, "TrueAndObservedForest.png")
  EmpiricalCalibration::plotTrueAndObserved(logRr = allControls$logRr,
                                            seLogRr = allControls$seLogRr,
                                            trueLogRr = log(allControls$targetEffectSize),
                                            fileName = fileName)
}

plotOddsRatios <- function(ccSummaryFile, exposureId, exposureName, resultsFolder, pubOr, pubLb, pubUb) {
  ccSummary <- readRDS(ccSummaryFile)
  ccSummary <- ccSummary[ccSummary$outcomeId < 10000, ] # No positive controls
  estimates <- data.frame(logRr = ccSummary$logRr,
                          seLogRr = ccSummary$seLogRr,
                          label = "Negative control (our replication)",
                          stringsAsFactors = FALSE)
  estimates$label[ccSummary$exposureId == exposureId] <- paste(exposureName, "(our replication)")
  estimates <- rbind(estimates,
                     data.frame(logRr = log(pubOr),
                                seLogRr = -(log(pubUb) - log(pubLb)) / (2*qnorm(0.025)),
                                label = paste(exposureName, "(original study)"),
                                stringsAsFactors = FALSE))

  alpha <- 0.05
  idx <- estimates$label == "Negative control (our replication)"
  null <- EmpiricalCalibration::fitNull(estimates$logRr[idx], estimates$seLogRr[idx])
  x <- exp(seq(log(0.25), log(10), by = 0.01))
  y <- EmpiricalCalibration:::logRrtoSE(log(x), alpha, null[1], null[2])
  seTheoretical <- sapply(x, FUN = function(x) {
    abs(log(x))/qnorm(1 - alpha/2)
  })
  breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 12)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 12, hjust = 1)
  plot <- ggplot2::ggplot(data.frame(x, y, seTheoretical), ggplot2::aes(x = x, y = y), environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 0.7) +
    ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5), color = rgb(1, 0.5, 0), size = 1, alpha = 0.5) +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5) +
    ggplot2::geom_point(ggplot2::aes(x, y, shape = label, color = label, fill = label, size = label),
                        data = data.frame(x = exp(estimates$logRr), y = estimates$seLogRr, label = estimates$label),
                        alpha = 0.7) +
    ggplot2::scale_color_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0.8, alpha = 0.8), rgb(1, 1, 0, alpha = 0.8), rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_shape_manual(values = c(24, 23, 21)) +
    ggplot2::scale_size_manual(values = c(3, 3, 2)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous("Odds ratio", trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(), axis.text.y = themeRA,
                   axis.text.x = theme, legend.key = ggplot2::element_blank(),
                   strip.text.x = theme, strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank())

  fileName <- file.path(resultsFolder, "estimates.png")
  ggplot2::ggsave(fileName, plot, width = 6.1, height = 4.5, dpi = 400)

  estimates$seLogRr[estimates$label == "Negative control (our replication)"] <- 3
  plot <- ggplot2::ggplot(data.frame(x, y, seTheoretical), ggplot2::aes(x = x, y = y), environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 0.7) +
    # ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5), color = rgb(1, 0.5, 0), size = 1, alpha = 0.5) +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5) +
    ggplot2::geom_point(ggplot2::aes(x, y, shape = label, color = label, fill = label, size = label),
                        data = data.frame(x = exp(estimates$logRr), y = estimates$seLogRr, label = estimates$label),
                        alpha = 0.7) +
    ggplot2::scale_color_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0.8, alpha = 0.8), rgb(1, 1, 0, alpha = 0.8), rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_shape_manual(values = c(24, 23, 21)) +
    ggplot2::scale_size_manual(values = c(3, 3, 2)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous("Odds ratio", trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(), axis.text.y = themeRA,
                   axis.text.x = theme, legend.key = ggplot2::element_blank(),
                   strip.text.x = theme, strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank())

  fileName <- file.path(resultsFolder, "estimatesOriginalOur.png")
  ggplot2::ggsave(fileName, plot, width = 6.1, height = 4.5, dpi = 400)

  estimates$seLogRr[estimates$label != paste(exposureName, "(original study)")] <- 3
  plot <- ggplot2::ggplot(data.frame(x, y, seTheoretical), ggplot2::aes(x = x, y = y), environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 0.7) +
    # ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5), color = rgb(1, 0.5, 0), size = 1, alpha = 0.5) +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5) +
    ggplot2::geom_point(ggplot2::aes(x, y, shape = label, color = label, fill = label, size = label),
                        data = data.frame(x = exp(estimates$logRr), y = estimates$seLogRr, label = estimates$label),
                        alpha = 0.7) +
    ggplot2::scale_color_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0.8, alpha = 0.8), rgb(1, 1, 0, alpha = 0.8), rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_shape_manual(values = c(24, 23, 21)) +
    ggplot2::scale_size_manual(values = c(3, 3, 2)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous("Odds ratio", trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(), axis.text.y = themeRA,
                   axis.text.x = theme, legend.key = ggplot2::element_blank(),
                   strip.text.x = theme, strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank())

  fileName <- file.path(resultsFolder, "estimatesOriginal.png")
  ggplot2::ggsave(fileName, plot, width = 6.1, height = 4.5, dpi = 400)
}

createCharacteristicsTable <- function(resultsFolder) {
  covariateData1 <- FeatureExtraction::loadCovariateData(file.path(resultsFolder, "covsCases"))
  covariateData2 <- FeatureExtraction::loadCovariateData(file.path(resultsFolder, "covsControls"))
  table1 <- FeatureExtraction::createTable1(covariateData1 = covariateData1, covariateData2 = covariateData2)
  write.csv(table1, file.path(resultsFolder, "characteristics.csv"), row.names = FALSE)
}

createCharacteristicsByExposureTable <- function(resultsFolder) {
  covariateData1 <- FeatureExtraction::loadCovariateData(file.path(resultsFolder, "covsExposed"))
  covariateData2 <- FeatureExtraction::loadCovariateData(file.path(resultsFolder, "covsUnexposed"))
  table1 <- FeatureExtraction::createTable1(covariateData1 = covariateData1, covariateData2 = covariateData2)
  write.csv(table1, file.path(resultsFolder, "characteristicsByExposure.csv"), row.names = FALSE)
}

createVisitPlot <- function(resultsFolder) {
  visitCounts <- readRDS(file.path(resultsFolder, "visitCounts.rds"))
  visitCounts$label <- "Cases"
  visitCounts$label[!visitCounts$isCase] <- "Controls"
  plot <- ggplot2::ggplot(visitCounts, ggplot2::aes(x = day, y = rate, group = label, color = label)) +
    ggplot2::geom_vline(xintercept = 0, color = rgb(0, 0, 0), size = 0.5) +
    ggplot2::geom_line(alpha = 0.7, size = 1) +
    ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::labs(x = "Days relative to index date", y = "Visits / persons") +
    ggplot2::theme(legend.title = ggplot2::element_blank(),
                   legend.position = "top")
  ggplot2::ggsave(file.path(resultsFolder, "priorVisitRates.png"), plot, width = 5, height = 4, dpi = 400)
}


getCharacteristics <- function(ccFile, connection, cdmDatabaseSchema, oracleTempSchema, resultsFolder) {
  if (!file.exists(resultsFolder))
    dir.create(resultsFolder)
  cc <- readRDS(ccFile)
  # stratumIds <- unique(cc$stratumId)
  # sampledStratumIds <- sample(stratumIds, 10000, replace = FALSE)
  # cc <- cc[cc$stratumId %in% sampledStratumIds, ]
  tableToUpload <- data.frame(subjectId = cc$personId,
                              cohortStartDate = cc$indexDate,
                              cohortDefinitionId = as.integer(cc$isCase))

  colnames(tableToUpload) <- SqlRender::camelCaseToSnakeCase(colnames(tableToUpload))

  connection <- DatabaseConnector::connect(connectionDetails)
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = "scratch.dbo.mschuemi_temp",
                                 data = tableToUpload,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = FALSE,
                                 oracleTempSchema = oracleTempSchema,
                                 useMppBulkLoad = TRUE)
  disconnect(connection)
  executeSql(connection, "DROP TABLE scratch.dbo.mschuemi_temp")
  querySql(connection, "SELECT COUNT(*) FROM scratch.dbo.mschuemi_temp")

  covariateSettings <- FeatureExtraction::createCovariateSettings(useConditionGroupEraLongTerm = TRUE,
                                                                  useDrugGroupEraLongTerm = TRUE,
                                                                  useProcedureOccurrenceLongTerm = TRUE,
                                                                  useMeasurementLongTerm = TRUE,
                                                                  useMeasurementRangeGroupLongTerm = TRUE,
                                                                  useObservationLongTerm = TRUE,
                                                                  endDays = -30,
                                                                  longTermStartDays = -365)
  covsCases <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                     oracleTempSchema = oracleTempSchema,
                                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                                     cohortTable = "#temp",
                                                     cohortTableIsTemp = TRUE,
                                                     cohortId = 1,
                                                     covariateSettings = covariateSettings,
                                                     aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsCases, file.path(resultsFolder, "covsCases"))
  covsControls <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                        oracleTempSchema = oracleTempSchema,
                                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                                        cohortTable = "#temp",
                                                        cohortTableIsTemp = TRUE,
                                                        cohortId = 0,
                                                        covariateSettings = covariateSettings,
                                                        aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsControls, file.path(resultsFolder, "covsControls"))

  sql <- "SELECT DATEDIFF(DAY, cohort_start_date, visit_start_date) AS day,
  cohort_definition_id AS is_case,
  COUNT(*) AS visit_count
  FROM #temp
  INNER JOIN @cdm_database_schema.visit_occurrence
  ON subject_id = person_id
  WHERE cohort_start_date > visit_start_date
  AND DATEDIFF(DAY, cohort_start_date, visit_start_date) > -365
  GROUP BY DATEDIFF(DAY, cohort_start_date, visit_start_date),
  cohort_definition_id;"
  sql <- SqlRender::renderSql(sql = sql,
                              cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  visitCounts <- querySql(connection = connection, sql = sql)
  colnames(visitCounts) <- SqlRender::snakeCaseToCamelCase(colnames(visitCounts))
  cc$personCount <- 1
  personCounts <- aggregate(personCount ~ isCase, cc, sum)
  visitCounts <- merge(visitCounts, personCounts)
  visitCounts$rate <- visitCounts$visitCount / visitCounts$personCount
  saveRDS(visitCounts, file.path(resultsFolder, "visitCounts.rds"))

  sql <- "TRUNCATE TABLE #temp; DROP TABLE #temp;"
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection = connection,
                                sql = sql,
                                progressBar = FALSE,
                                reportOverallTime = FALSE)
}

getCharacteristicsByExposure <- function(ccFile, connection, cdmDatabaseSchema, oracleTempSchema, resultsFolder) {
  ccdFile <- file.path(outputFolder, "ccAp", "ccd_cd1_n1_cc1_o2_ed1_e4_ccd1.rds")
  ccFile <- file.path(outputFolder, "ccAp", "caseControls_cd1_n1_cc1_o2.rds")
  resultsFolder = file.path(outputFolder, "resultsAp")

  ccdFile <- file.path(outputFolder, "ccIbd", "ccd_cd1_cc1_o3_ed1_e5_ccd1.rds")
  ccFile <- file.path(outputFolder, "ccIbd", "caseControls_cd1_cc1_o3.rds")
  resultsFolder = file.path(outputFolder, "resultsIbd")

  ccd <- readRDS(ccdFile)
  cc <- readRDS(ccFile)

  # ccd <- ccd[!ccd$isCase, ]
  # cc <- cc[!cc$isCase, ]
  tableToUpload <- data.frame(subjectId = cc$personId,
                              cohortStartDate = cc$indexDate,
                              cohortDefinitionId = as.integer(ccd$exposed),
                              exposed = as.integer(ccd$exposed),
                              isCase = as.integer(cc$isCase))

  colnames(tableToUpload) <- SqlRender::camelCaseToSnakeCase(colnames(tableToUpload))

  # connection <- DatabaseConnector::connect(connectionDetails)
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = "scratch.dbo.mschuemi_temp",
                                 data = tableToUpload,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = FALSE,
                                 oracleTempSchema = oracleTempSchema,
                                 useMppBulkLoad = TRUE)
  # disconnect(connection)
  # executeSql(connection, "DROP TABLE scratch.dbo.mschuemi_temp")
  # querySql(connection, "SELECT COUNT(*) FROM scratch.dbo.mschuemi_temp")

  covariateSettings <- FeatureExtraction::createCovariateSettings(useConditionGroupEraLongTerm = TRUE,
                                                                  useDrugGroupEraLongTerm = TRUE,
                                                                  useProcedureOccurrenceLongTerm = TRUE,
                                                                  useMeasurementLongTerm = TRUE,
                                                                  useMeasurementRangeGroupLongTerm = TRUE,
                                                                  useObservationLongTerm = TRUE,
                                                                  endDays = -30,
                                                                  longTermStartDays = -365)
  covsExposed <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                       oracleTempSchema = oracleTempSchema,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       cohortDatabaseSchema = "scratch.dbo",
                                                       cohortTable = "mschuemi_temp",
                                                       cohortTableIsTemp = FALSE,
                                                       cohortId = 1,
                                                       covariateSettings = covariateSettings,
                                                       aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsExposed, file.path(resultsFolder, "covsExposed"))
  covsUnexposed <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                        oracleTempSchema = oracleTempSchema,
                                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                                        cohortDatabaseSchema = "scratch.dbo",
                                                        cohortTable = "mschuemi_temp",
                                                        cohortTableIsTemp = FALSE,
                                                        cohortId = 0,
                                                        covariateSettings = covariateSettings,
                                                        aggregated = TRUE)
  FeatureExtraction::saveCovariateData(covsUnexposed, file.path(resultsFolder, "covsUnexposed"))

  sql <- "SELECT DATEDIFF(DAY, cohort_start_date, visit_start_date) AS day,
  exposed,
  is_case,
  COUNT(*) AS visit_count
  FROM scratch.dbo.mschuemi_temp
  INNER JOIN @cdm_database_schema.visit_occurrence
  ON subject_id = person_id
  WHERE cohort_start_date > visit_start_date
  AND DATEDIFF(DAY, cohort_start_date, visit_start_date) > -365
  GROUP BY DATEDIFF(DAY, cohort_start_date, visit_start_date),
  exposed,
  is_case;"
  sql <- SqlRender::renderSql(sql = sql,
                              cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  visitCounts <- querySql(connection = connection, sql = sql)
  colnames(visitCounts) <- SqlRender::snakeCaseToCamelCase(colnames(visitCounts))
  ccd$personCount <- 1
  personCounts <- aggregate(personCount ~ exposed + isCase, ccd, sum)
  visitCounts <- merge(visitCounts, personCounts)
  visitCounts$rate <- visitCounts$visitCount / visitCounts$personCount
  saveRDS(visitCounts, file.path(resultsFolder, "visitCountsByExposure.rds"))

  executeSql(connection, "DROP TABLE scratch.dbo.mschuemi_temp")
  # disconnect(connection)
}


createPsPlot <- function(ccFile, ccdFile, connection, cdmDatabaseSchema, oracleTempSchema, resultsFolder) {
  resultsFolder <- file.path(outputFolder, "resultsIbd")
  ccdFile <- "r:/EvaluatingCaseControl_ccae/ccIbd/ccd_cd1_cc1_o3_ed1_e5_ccd1.rds"
  ccFile = file.path(outputFolder, "ccIbd", "caseControls_cd1_cc1_o3.rds")

  resultsFolder <- file.path(outputFolder, "resultsAp")
  ccdFile <- "r:/EvaluatingCaseControl_ccae/ccAp/ccd_cd1_n1_cc1_o2_ed1_e4_ccd1.rds"
  ccFile = file.path(outputFolder, "ccAp", "caseControls_cd1_n1_cc1_o2.rds")
  cc <- readRDS(ccFile)
  ccd <- readRDS(ccdFile)
  cc$rowId <- 1:nrow(cc)
  m <- merge(cc, ccd)
  tableToUpload <- data.frame(rowId = cc$rowId,
                              subjectId = cc$personId,
                              cohortStartDate = cc$indexDate,
                              cohortDefinitionId = as.integer(cc$isCase))

  colnames(tableToUpload) <- SqlRender::camelCaseToSnakeCase(colnames(tableToUpload))

  connection <- DatabaseConnector::connect(connectionDetails)
  # debug(DatabaseConnector:::.bulkLoadPdw)
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = "scratch.dbo.mschuemi_temp",
                                 data = tableToUpload,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = FALSE,
                                 oracleTempSchema = oracleTempSchema,
                                 useMppBulkLoad = TRUE)
  # disconnect(connection)
  # executeSql(connection, "DROP TABLE scratch.dbo.mschuemi_temp")
  # querySql(connection, "SELECT COUNT(*) FROM scratch.dbo.mschuemi_temp")

  covariateSettings <- FeatureExtraction::createCovariateSettings(useConditionGroupEraLongTerm = TRUE,
                                                                  useDrugGroupEraLongTerm = TRUE,
                                                                  useProcedureOccurrenceLongTerm = TRUE,
                                                                  useMeasurementLongTerm = TRUE,
                                                                  useMeasurementRangeGroupLongTerm = TRUE,
                                                                  useObservationLongTerm = TRUE,
                                                                  endDays = -30,
                                                                  longTermStartDays = -365)
  covs <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                oracleTempSchema = oracleTempSchema,
                                                cdmDatabaseSchema = cdmDatabaseSchema,
                                                cohortDatabaseSchema = "scratch.dbo",
                                                cohortTable = "mschuemi_temp",
                                                cohortTableIsTemp = FALSE,
                                                rowIdField = "row_id",
                                                covariateSettings = covariateSettings,
                                                aggregated = FALSE)
  DatabaseConnector::executeSql(connection, "DROP TABLE scratch.dbo.mschuemi_temp")
  DatabaseConnector::disconnect(connection)
  FeatureExtraction::saveCovariateData(covs, file.path(resultsFolder, "covsNotAggregated"))

  tidyCovs <- FeatureExtraction::tidyCovariateData(covs)

  # Model probability of exposure ---------------------------------
  outcomes <- data.frame(rowId = m$rowId,
                         y = m$exposed)
  prior <- Cyclops::createPrior("laplace", useCrossValidation = TRUE, exclude = c(0))
  control <- Cyclops::createControl(cvRepetitions = 1,
                                    threads = 10,
                                    fold = 5,
                                    cvType = "auto")
  cyclopsData <- Cyclops::convertToCyclopsData(ff::as.ffdf(outcomes), tidyCovs$covariates, modelType = "lr")
  fit <- Cyclops::fitCyclopsModel(cyclopsData = cyclopsData,
                                  prior = prior,
                                  control = control)
  p <- predict(fit)
  p <- data.frame(rowId = as.numeric(names(p)),
                  propensityScore = as.vector(p))
  ps <- merge(outcomes, p)
  ps$treatment <- ps$y
  fileName <- file.path(resultsFolder, "predictabilityExposure.png")
  CohortMethod::plotPs(ps, fileName = fileName, targetLabel = "Exposed", comparatorLabel = "Unexposed")
  CohortMethod::computePsAuc(ps)

  # Model probability of case vs control ---------------------------------
  outcomes <- data.frame(rowId = m$rowId,
                         y = as.integer(m$isCase))
  prior <- Cyclops::createPrior("laplace", useCrossValidation = TRUE, exclude = c(0))
  control <- Cyclops::createControl(cvRepetitions = 1,
                                    threads = 10,
                                    fold = 5,
                                    cvType = "auto")
  cyclopsData <- Cyclops::convertToCyclopsData(ff::as.ffdf(outcomes), tidyCovs$covariates, modelType = "lr")
  fit <- Cyclops::fitCyclopsModel(cyclopsData = cyclopsData,
                                  prior = prior,
                                  control = control)
  p <- predict(fit)
  p <- data.frame(rowId = as.numeric(names(p)),
                  propensityScore = as.vector(p))
  ps <- merge(outcomes, p)
  ps$treatment <- ps$y
  fileName <- file.path(resultsFolder, "predictabilityCaseControl.png")
  CohortMethod::plotPs(ps, fileName = fileName, targetLabel = "Cases", comparatorLabel = "Controls")
  CohortMethod::computePsAuc(ps)
}

createCombinedEstimatesTable <- function(outputFolder) {
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
  negativeControls <- read.csv(pathToCsv, stringsAsFactors = FALSE)


  ccSummary <- readRDS(file.path(outputFolder, "ccSummaryIbd.rds"))
  ccSummary <- ccSummary[ccSummary$outcomeId < 10000, ] # No positive controls

  estimatesIbd <- merge(ccSummary,
                        data.frame(exposureId = negativeControls$targetId,
                                   outcomeId = negativeControls$outcomeId,
                                   nestingCohortId = negativeControls$nestingId,
                                   exposureName = negativeControls$targetName,
                                   nestingName = negativeControls$nestingName,
                                   outcomeName = negativeControls$outcomeName,
                                   stringsAsFactors = FALSE),
                        all.x = TRUE)
  estimatesIbd$type <- "Negative control"
  estimatesIbd$type[estimatesIbd$exposureId == 5] <- "Exposure of interest"
  estimatesIbd$exposureName[estimatesIbd$exposureId == 5] <- "Isotretinoin"
  estimatesIbd$nestingName[estimatesIbd$exposureId == 5] <- ""
  estimatesIbd$outcomeName[estimatesIbd$exposureId == 5] <- "Ulcerative colitis"
  null <- EmpiricalCalibration::fitNull(logRr = estimatesIbd$logRr[estimatesIbd$type == "Negative control"],
                                        seLogRr = estimatesIbd$seLogRr[estimatesIbd$type == "Negative control"])
  estimatesIbd$calP <- EmpiricalCalibration::calibrateP(null = null,
                                                        logRr = estimatesIbd$logRr,
                                                        seLogRr = estimatesIbd$seLogRr)

  ccSummary <- readRDS(file.path(outputFolder, "ccSummaryAp.rds"))
  ccSummary <- ccSummary[ccSummary$outcomeId < 10000, ] # No positive controls

  estimatesAp <- merge(ccSummary,
                       data.frame(exposureId = negativeControls$targetId,
                                  outcomeId = negativeControls$outcomeId,
                                  nestingCohortId = negativeControls$nestingId,
                                  exposureName = negativeControls$targetName,
                                  nestingName = negativeControls$nestingName,
                                  outcomeName = negativeControls$outcomeName,
                                  stringsAsFactors = FALSE),
                       all.x = TRUE)
  estimatesAp$type <- "Negative control"
  estimatesAp$type[estimatesAp$exposureId == 4] <- "Exposure of interest"
  estimatesAp$exposureName[estimatesAp$exposureId == 4] <- "DPP-4 inhibitors"
  estimatesAp$nestingName[estimatesAp$exposureId == 4] <- "Type 2 Diabetes Mellitus"
  estimatesAp$outcomeName[estimatesAp$exposureId == 4] <- "Acute pancreatitis"
  null <- EmpiricalCalibration::fitNull(logRr = estimatesAp$logRr[estimatesAp$type == "Negative control"],
                                        seLogRr = estimatesAp$seLogRr[estimatesAp$type == "Negative control"])
  estimatesAp$calP <- EmpiricalCalibration::calibrateP(null = null,
                                                       logRr = estimatesAp$logRr,
                                                       seLogRr = estimatesAp$seLogRr)

  estimates <- rbind(estimatesIbd, estimatesAp)
  write.csv(estimates, file.path(outputFolder, "AllEstimates.csv"), row.names = FALSE)
}




createEstimatesAppendix <- function(outputFolder) {
  estimates <- read.csv(file.path(outputFolder, "AllEstimates.csv"))
  estimates <- estimates[, c("outcomeName", "exposureName", "nestingName", "type", "cases", "controls", "exposedCases", "exposedControls", "rr", "ci95lb", "ci95ub", "p", "calP")]
  colnames(estimates) <- c("Outcome", "Exposure", "Nesting cohort", "Type", "Cases", "Controls", "Exposed cases", "Exposed controls", "Odds Ratio", "CI95LB", "CI95UB", "P", "Calibrated P")
  write.csv(estimates, file.path(outputFolder, "SupplementaryTableS1.csv"), row.names = FALSE)
}



plotOddsRatiosCombined <- function(outputFolder) {
  estimates <- read.csv(file.path(outputFolder, "AllEstimates.csv"), stringsAsFactors = FALSE)
  estimates <- estimates[, c("type", "outcomeName", "logRr", "seLogRr")]
  estimates$type[estimates$type == "Negative control"] <- "Negative control (our replication)"
  estimates$type[estimates$type == "Exposure of interest"] <- "Exposure of interest (our replication)"
  estimates$study <- "Crockett"
  estimates$study[estimates$outcomeName == "Acute pancreatitis"] <- "Chou"
  estimates$outcomeName <- NULL
  estimates <- rbind(estimates,
                     data.frame(type = "Exposure of interest (original study)",
                                logRr = log(c(4.36, 1.04)),
                                seLogRr = c(-(log(9.66) - log(1.97)) / (2*qnorm(0.025)), -(log(1.21) - log(0.89)) / (2*qnorm(0.025))),
                                study = c("Crockett", "Chou"),
                                stringsAsFactors = FALSE))
  estimates$x <- exp(estimates$logRr)
  estimates$y <- estimates$seLogRr
  estimates$study <- factor(estimates$study, levels = c("Crockett", "Chou"))

  getArea <- function(study, alpha = 0.05) {
    idx <- estimates$type == "Negative control (our replication)" & estimates$study == study
    null <- EmpiricalCalibration::fitNull(estimates$logRr[idx], estimates$seLogRr[idx])
    x <- exp(seq(log(0.25), log(10), by = 0.01))
    y <- EmpiricalCalibration:::logRrtoSE(log(x), alpha, null[1], null[2])
    seTheoretical <- sapply(x, FUN = function(x) {
      abs(log(x))/qnorm(1 - 0.05/2)
    })
    return(data.frame(study = study, x = x, y = y, seTheoretical = seTheoretical))
  }
  area <- rbind(getArea("Crockett"), getArea("Chou"))



  breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 10)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 10, hjust = 1)
  plot <- ggplot2::ggplot(estimates, ggplot2::aes(x = x, y = y), environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 0.7) +
    ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5), color = rgb(1, 0.5, 0), size = 0.5, alpha = 0.5, data = area) +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1,
                       data = area) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5,
                       data = area) +
    ggplot2::geom_point(ggplot2::aes(shape = type, color = type, fill = type, size = type), alpha = 0.6) +
    ggplot2::geom_point(ggplot2::aes(shape = type, color = type, fill = type, size = type), alpha = 0.6, data = estimates[estimates$type != "Negative control (our replication)", ]) +
    ggplot2::scale_color_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0.8, alpha = 0.8), rgb(1, 1, 0, alpha = 0.8), rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_shape_manual(values = c(24, 23, 21)) +
    ggplot2::scale_size_manual(values = c(3, 3, 2)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous("Odds ratio", trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
    ggplot2::facet_grid(.~study) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank(),
                   legend.text = theme,
                   legend.direction = "horizontal")

  fileName <- file.path(outputFolder, "estimatesCaseControl.png")
  ggplot2::ggsave(fileName, plot, width = 8, height = 3.5, dpi = 400)
}

plotIrrsCombined <- function(outputFolder) {
  sccsSummary <- readRDS(file.path(outputFolder, "sccsSummaryAp.rds"))
  estimatesAp <- data.frame(logRr = sccsSummary$`logRr(Exposure of interest)`,
                            seLogRr = sccsSummary$`seLogRr(Exposure of interest)`,
                            irr = sccsSummary$`rr(Exposure of interest)`,
                            CI95LB = sccsSummary$`ci95lb(Exposure of interest)`,
                            CI95UB = sccsSummary$`ci95ub(Exposure of interest)`,
                            exposureId = sccsSummary$exposureId,
                            outcomeId = sccsSummary$outcomeId,
                            caseCount = sccsSummary$caseCount,
                            eventCount = sccsSummary$eventCount,
                            type = "Negative control",
                            study = "Chou",
                            stringsAsFactors = FALSE)
  estimatesAp$type[sccsSummary$exposureId == 4] <- "Exposure of interest"

  sccsSummary <- readRDS(file.path(outputFolder, "sccsSummaryIbd.rds"))
  estimatesIbd <- data.frame(logRr = sccsSummary$`logRr(Exposure of interest)`,
                             seLogRr = sccsSummary$`seLogRr(Exposure of interest)`,
                             irr = sccsSummary$`rr(Exposure of interest)`,
                             CI95LB = sccsSummary$`ci95lb(Exposure of interest)`,
                             CI95UB = sccsSummary$`ci95ub(Exposure of interest)`,
                             exposureId = sccsSummary$exposureId,
                             outcomeId = sccsSummary$outcomeId,
                             caseCount = sccsSummary$caseCount,
                             eventCount = sccsSummary$eventCount,
                             type = "Negative control",
                             study = "Crockett",
                             stringsAsFactors = FALSE)
  estimatesIbd$type[sccsSummary$exposureId == 5] <- "Exposure of interest"
  estimates <- rbind(estimatesAp, estimatesIbd)

  estimates$x <- exp(estimates$logRr)
  estimates$y <- estimates$seLogRr
  estimates$study <- factor(estimates$study, levels = c("Crockett", "Chou"))

  getArea <- function(study, alpha = 0.05) {
    idx <- estimates$type == "Negative control" & estimates$study == study
    null <- EmpiricalCalibration::fitNull(estimates$logRr[idx], estimates$seLogRr[idx])
    x <- exp(seq(log(0.25), log(10), by = 0.01))
    y <- EmpiricalCalibration:::logRrtoSE(log(x), alpha, null[1], null[2])
    seTheoretical <- sapply(x, FUN = function(x) {
      abs(log(x))/qnorm(1 - 0.05/2)
    })
    return(data.frame(study = study, x = x, y = y, seTheoretical = seTheoretical))
  }
  area <- rbind(getArea("Crockett"), getArea("Chou"))

  breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 10)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 10, hjust = 1)
  plot <- ggplot2::ggplot(estimates, ggplot2::aes(x = x, y = y), environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 1, size = 0.7) +
    ggplot2::geom_area(fill = rgb(1, 0.5, 0, alpha = 0.5), color = rgb(1, 0.5, 0), size = 0.5, alpha = 0.5, data = area) +
    ggplot2::geom_area(ggplot2::aes(y = seTheoretical),
                       fill = rgb(0, 0, 0),
                       colour = rgb(0, 0, 0, alpha = 0.1),
                       alpha = 0.1,
                       data = area) +
    ggplot2::geom_line(ggplot2::aes(y = seTheoretical),
                       colour = rgb(0, 0, 0),
                       linetype = "dashed",
                       size = 1,
                       alpha = 0.5,
                       data = area) +
    ggplot2::geom_point(ggplot2::aes(shape = type, color = type, fill = type, size = type), alpha = 0.6) +
    ggplot2::geom_point(ggplot2::aes(shape = type, color = type, fill = type, size = type), alpha = 0.6, data = estimates[estimates$type != "Negative control", ]) +
    ggplot2::scale_color_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(1, 1, 0, alpha = 0.8), rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_shape_manual(values = c(23, 21)) +
    ggplot2::scale_size_manual(values = c(3, 2)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous("Incidence rate ratio", trans = "log10", limits = c(0.25, 10), breaks = breaks, labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1.5)) +
    ggplot2::facet_grid(.~study) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank(),
                   legend.text = theme,
                   legend.direction = "horizontal")

  fileName <- file.path(outputFolder, "estimatesSccs.png")
  ggplot2::ggsave(fileName, plot, width = 8, height = 3.5, dpi = 400)
  write.csv(estimates, file.path(outputFolder, "AllSccsEstimates.csv"), row.names = FALSE)
}

createSccsEstimatesAppendix <- function(outputFolder) {
  estimates <- read.csv(file.path(outputFolder, "AllSccsEstimates.csv"))
  estimatesCc <- read.csv(file.path(outputFolder, "AllEstimates.csv"))
  estimates <- merge(estimates, estimatesCc[, c("exposureId", "exposureName", "nestingCohortId", "nestingName", "outcomeId", "outcomeName", "type")], all.x = TRUE)
  estimates$p <- EmpiricalCalibration::computeTraditionalP(estimates$logRr, estimates$seLogRr)
  estimates <- estimates[, c("outcomeName", "exposureName", "nestingName", "type", "caseCount", "eventCount", "irr", "CI95LB", "CI95UB", "p")]
  colnames(estimates) <- c("Outcome", "Exposure", "Nesting cohort", "Type", "Cases", "Events", "Incidence rate ratio", "CI95LB", "CI95UB", "P")
  write.csv(estimates, file.path(outputFolder, "SupplementaryTableS2.csv"), row.names = FALSE)
}


createVisitPlotCombined <- function(outputFolder) {
  visitCounts1 <- readRDS(file.path(outputFolder, "resultsIbd", "visitCounts.rds"))
  visitCounts1$study <- "Crockett"
  visitCounts2 <- readRDS(file.path(outputFolder, "resultsAp", "visitCounts.rds"))
  visitCounts2$study <- "Chou"
  visitCounts <- rbind(visitCounts1, visitCounts2)
  visitCounts$label <- "Cases"
  visitCounts$label[!visitCounts$isCase] <- "Controls"
  visitCounts$study <- factor(visitCounts$study, levels = c("Crockett", "Chou"))
  theme <- ggplot2::element_text(colour = "#000000", size = 10)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 10, hjust = 1)
  plot <- ggplot2::ggplot(visitCounts, ggplot2::aes(x = day, y = rate, group = label, color = label)) +
    ggplot2::geom_vline(xintercept = 0, color = rgb(0, 0, 0), size = 0.5) +
    ggplot2::geom_line(alpha = 0.7, size = 1) +
    ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::labs(x = "Days relative to index date", y = "Visits / persons") +
    ggplot2::facet_grid(.~study) +
    ggplot2::theme(axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank(),
                   legend.text = theme,
                   legend.direction = "horizontal")
  ggplot2::ggsave(file.path(outputFolder, "priorVisitRates.jpg"), plot, width = 8, height = 4, dpi = 1000)
}

createVisitPlotByExposureCombined <- function(outputFolder) {
  visitCounts1 <- readRDS(file.path(outputFolder, "resultsIbd", "visitCountsByExposure.rds"))
  visitCounts1$study <- "Crockett"
  visitCounts2 <- readRDS(file.path(outputFolder, "resultsAp", "visitCountsByExposure.rds"))
  visitCounts2$study <- "Chou"
  visitCounts <- rbind(visitCounts1, visitCounts2)
  visitCounts$exposure <- "Unexposed"
  visitCounts$exposure[visitCounts$exposed == 1] <- "Exposed"
  visitCounts$case <- "Control"
  visitCounts$case[visitCounts$isCase == 1] <- "Case"
  visitCounts$study <- factor(visitCounts$study, levels = c("Crockett", "Chou"))
  theme <- ggplot2::element_text(colour = "#000000", size = 10)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 10, hjust = 1)
  plot <- ggplot2::ggplot(visitCounts, ggplot2::aes(x = day, y = rate, group = exposure, color = exposure)) +
    ggplot2::geom_vline(xintercept = 0, color = rgb(0, 0, 0), size = 0.5) +
    ggplot2::geom_line(alpha = 0.7, size = 1) +
    ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0), rgb(0, 0, 0.8))) +
    ggplot2::labs(x = "Days relative to index date", y = "Visits / persons") +
    ggplot2::facet_grid(study~case) +
    ggplot2::theme(axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "top",
                   legend.title = ggplot2::element_blank(),
                   legend.text = theme,
                   legend.direction = "horizontal")
  ggplot2::ggsave(file.path(outputFolder, "priorVisitRatesByExposure.jpg"), plot, width = 8, height = 4, dpi = 1000)
}
