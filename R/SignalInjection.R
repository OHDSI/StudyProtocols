# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
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

#' Inject outcomes on top of negative controls
#'
#' @details
#' This function injects outcomes on top of negative controls to create controls with predefined relative risks greater than one.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param workDatabaseSchema   Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param studyCohortTable     The name of the study cohort table  in the work database schema.
#' @param exposureCohortSummaryTable     The name of the exposure summary table in the work database schema.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
injectSignals <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_cohorts",
                          oracleTempSchema,
                          workFolder,
                          exposureOutcomePairs = NULL,
                          maxCores = 4) {
    signalInjectionFolder <- file.path(workFolder, "signalInjection")
    if (!file.exists(signalInjectionFolder))
        dir.create(signalInjectionFolder)

    createSignalInjectionDataFiles(connectionDetails,
                                   cdmDatabaseSchema,
                                   workDatabaseSchema,
                                   studyCohortTable = "ohdsi_cohorts",
                                   oracleTempSchema,
                                   workFolder,
                                   signalInjectionFolder)

    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))

    exposureCohortIds <- unique(c(exposureSummary$tCohortDefinitionId, exposureSummary$cCohortDefinitionId))

    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "LargeScalePopEst")
    negativeControls <- read.csv(pathToCsv)
    negativeControlIds <- negativeControls$conceptId
    if (is.null(exposureOutcomePairs)) {
        exposureOutcomePairs <- data.frame(exposureId = rep(exposureCohortIds, each = length(negativeControlIds)),
                                           outcomeId = rep(negativeControlIds, length(exposureCohortIds)))
    }
    summ <- MethodEvaluation::injectSignals(connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            oracleTempSchema = cdmDatabaseSchema,
                                            outcomeDatabaseSchema = workDatabaseSchema,
                                            outcomeTable = studyCohortTable,
                                            outputDatabaseSchema = workDatabaseSchema,
                                            outputTable = studyCohortTable,
                                            createOutputTable = FALSE,
                                            exposureOutcomePairs = exposureOutcomePairs,
                                            modelType = "survival",
                                            buildOutcomeModel = TRUE,
                                            buildModelPerExposure = FALSE,
                                            minOutcomeCountForModel = 100,
                                            minOutcomeCountForInjection = 25,
                                            prior = Cyclops::createPrior("laplace", exclude = 0, useCrossValidation = TRUE),
                                            control = Cyclops::createControl(cvType = "auto",
                                                                             startingVariance = 0.01,
                                                                             tolerance = 2e-07,
                                                                             cvRepetitions = 1,
                                                                             noiseLevel = "silent",
                                                                             threads = min(10, maxCores)),
                                            firstExposureOnly = TRUE,
                                            washoutPeriod = 183,
                                            riskWindowStart = 0,
                                            riskWindowEnd = 0,
                                            addExposureDaysToEnd = TRUE,
                                            firstOutcomeOnly = TRUE,
                                            removePeopleWithPriorOutcomes = TRUE,
                                            effectSizes = c(1.5, 2, 4),
                                            precision = 0.01,
                                            outputIdOffset = 10000,
                                            workFolder = signalInjectionFolder,
                                            cdmVersion = "5",
                                            modelThreads = max(1, round(maxCores/4)),
                                            generationThreads = min(6, maxCores))
    # summ <- readRDS(file.path(signalInjectionFolder, "summary.rds"))
    write.csv(summ, file.path(workFolder, "signalInjectionSummary.csv"), row.names = FALSE)

    ffbase::load.ffdf(dir = file.path(workFolder, "allCohorts"))
    subjectIds <- ffbase::unique.ff(cohorts$subjectId)
    subjectIds <- data.frame(subject_id = ff::as.ram(subjectIds))
    conn <- DatabaseConnector::connect(connectionDetails)
    DatabaseConnector::insertTable(connection = conn,
                                   tableName = "#subjects",
                                   data = subjectIds,
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
    sql <- SqlRender::loadRenderTranslateSql("GetInjectedOutcomes.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             output_database_schema = workDatabaseSchema,
                                             output_table = studyCohortTable,
                                             min_id = min(summ$newOutcomeId),
                                             max_id = max(summ$newOutcomeId))
    injectedOutcomes <- DatabaseConnector::querySql.ffdf(conn, sql)
    colnames(injectedOutcomes) <- SqlRender::snakeCaseToCamelCase(colnames(injectedOutcomes))
    ffbase::save.ffdf(injectedOutcomes, dir = file.path(workFolder, "injectedOutcomes"))
}

createSignalInjectionDataFiles <- function(connectionDetails,
                                           cdmDatabaseSchema,
                                           workDatabaseSchema,
                                           studyCohortTable = "ohdsi_cohorts",
                                           oracleTempSchema,
                                           workFolder,
                                           signalInjectionFolder) {
    # Creating all data files needed by MethodEvaluation::injectSignals from our big data fetch.
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    cohortDefinitionIdToConceptId <- rbind(data.frame(cohortDefinitionId = exposureSummary$tprimeCohortDefinitionId,
                                                      conceptId = exposureSummary$tCohortDefinitionId),
                                           data.frame(cohortDefinitionId = exposureSummary$cprimeCohortDefinitionId,
                                                      conceptId = exposureSummary$cCohortDefinitionId))



    # Create exposures file:
    ffbase::load.ffdf(dir = file.path(workFolder, "allCohorts"))
    rowIds <- ffbase::unique.ff(cohorts$rowId)
    cohortsDedupe <- ff::as.ram(ffbase::merge.ffdf(ff::ffdf(rowId = rowIds), cohorts))
    exposures <- merge(cohortsDedupe, cohortDefinitionIdToConceptId)
    exposures$daysToCohortEnd[exposures$daysToCohortEnd > exposures$daysToObsEnd] <- exposures$daysToObsEnd[exposures$daysToCohortEnd > exposures$daysToObsEnd]
    #exposures$cohortEndDate <- exposures$cohortStartDate + exposures$daysToCohortEnd
    colnames(exposures)[colnames(exposures) == "daysToCohortEnd"] <- "daysAtRisk"
    colnames(exposures)[colnames(exposures) == "conceptId"] <- "exposureId"
    colnames(exposures)[colnames(exposures) == "subjectId"] <- "personId"
    exposures$eraNumber <- 1
    exposures <- exposures[, c("rowId", "exposureId", "personId", "cohortStartDate", "daysAtRisk", "eraNumber")]
    saveRDS(exposures, file.path(signalInjectionFolder, "exposures.rds"))

    # Create outcomes file:
    ffbase::load.ffdf(dir = file.path(workFolder, "allOutcomes"))
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "LargeScalePopEst")
    negativeControls <- read.csv(pathToCsv)
    negativeControlIds <- negativeControls$conceptId
    negativeControlOutcomes <- outcomes[ffbase::`%in%`(outcomes$outcomeId, negativeControlIds),]
    negativeControlOutcomes <- merge(negativeControlOutcomes, ff::as.ffdf(exposures[, c("rowId", "daysAtRisk")]))

    dedupeAndCount <- function(outcomeId, data) {
        data <- ff::as.ram(data[data$outcomeId == outcomeId, ])
        data <- data[data$daysToEvent >= 0 & data$daysToEvent <= data$daysAtRisk, ]
        y <- aggregate(outcomeId ~ rowId, data, length)
        colnames(y)[colnames(y) == "outcomeId"] <- "y"
        timeToEvent <- aggregate(daysToEvent ~ rowId, data, min)
        colnames(timeToEvent)[colnames(timeToEvent) == "daysToEvent"] <- "timeToEvent"
        result <- merge(y, timeToEvent)
        result$outcomeId <- outcomeId
        return(result)
    }
    outcomes2 <- sapply(negativeControlIds, dedupeAndCount, data = negativeControlOutcomes, simplify = FALSE)
    outcomes2 <- do.call("rbind", outcomes2)
    saveRDS(outcomes2, file.path(signalInjectionFolder, "outcomes.rds"))

    priorOutcomes <- negativeControlOutcomes[negativeControlOutcomes$daysToEvent < 0, c("rowId", "outcomeId")]
    dedupe <- function(outcomeId, data) {
        data <- data[data$outcomeId == outcomeId, ]
        rowIds <- ff::as.ram(ffbase::unique.ff(data$rowId))
        return(data.frame(rowId = rowIds, outcomeId = outcomeId))
    }
    priorOutcomes <- sapply(negativeControlIds, dedupe, data = priorOutcomes, simplify = FALSE)
    priorOutcomes <- do.call("rbind", priorOutcomes)
    saveRDS(priorOutcomes, file.path(signalInjectionFolder, "priorOutcomes.rds"))

    # Clone covariate data:
    covariateData <- FeatureExtraction::loadCovariateData(file.path(workFolder, "allCovariates"))
    covariateDataClone <- list(covariates = ff::clone.ffdf(covariateData$covariates),
                               covariateRef = ff::clone.ffdf(covariateData$covariateRef),
                               metaData = covariateData$metaData)
    class(covariateDataClone) = class(covariateData)
    FeatureExtraction::saveCovariateData(covariateDataClone, file.path(signalInjectionFolder, "covariates"))
}
