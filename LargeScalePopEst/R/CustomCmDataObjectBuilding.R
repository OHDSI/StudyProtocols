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

#' Fetch all data on the cohorts for analysis
#'
#' @details
#' This function will create covariates and fetch outcomes and person information from the server.
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
#'
#' @export
fetchAllDataFromServer <- function(connectionDetails,
                                   cdmDatabaseSchema,
                                   workDatabaseSchema,
                                   studyCohortTable = "ohdsi_cohorts",
                                   oracleTempSchema,
                                   workFolder) {
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    exposureIdToConceptId <- rbind(data.frame(exposureId = exposureSummary$tprimeCohortDefinitionId,
                                              conceptId = exposureSummary$tCohortDefinitionId),
                                   data.frame(exposureId = exposureSummary$cprimeCohortDefinitionId,
                                              conceptId = exposureSummary$cCohortDefinitionId))
    exposureIds <- exposureIdToConceptId$exposureId
    exposureConceptIds <- unique(exposureIdToConceptId$conceptId)

    cohortNames <- read.csv(file.path(workFolder, "cohortNames.csv"))
    outcomeIds <- cohortNames$cohortDefinitionId[cohortNames$type == "outcome" | cohortNames$type == "negativeControl"]

    conn <- DatabaseConnector::connect(connectionDetails)

    # Lump persons of interest into one table:
    sql <- SqlRender::loadRenderTranslateSql("UnionExposureCohorts.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable,
                                             exposure_ids = exposureIds)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)
    # Note: removing concept counts because number of drugs is very predictive of drugs vs procedures
    covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
                                                                    useCovariateDemographicsGender = TRUE,
                                                                    useCovariateDemographicsRace = TRUE,
                                                                    useCovariateDemographicsEthnicity = TRUE,
                                                                    useCovariateDemographicsAge = TRUE,
                                                                    useCovariateDemographicsYear = TRUE,
                                                                    useCovariateDemographicsMonth = TRUE,
                                                                    useCovariateConditionOccurrence = TRUE,
                                                                    useCovariateConditionOccurrence365d = TRUE,
                                                                    useCovariateConditionOccurrence30d = TRUE,
                                                                    useCovariateConditionOccurrenceInpt180d = TRUE,
                                                                    useCovariateConditionGroup = TRUE,
                                                                    useCovariateConditionGroupMeddra = TRUE,
                                                                    useCovariateConditionGroupSnomed = TRUE,
                                                                    useCovariateDrugEra = TRUE,
                                                                    useCovariateDrugEra365d = TRUE,
                                                                    useCovariateDrugEra30d = TRUE,
                                                                    useCovariateDrugEraOverlap = TRUE,
                                                                    useCovariateDrugGroup = TRUE,
                                                                    useCovariateProcedureOccurrence = TRUE,
                                                                    useCovariateProcedureOccurrence365d = TRUE,
                                                                    useCovariateProcedureOccurrence30d = TRUE,
                                                                    useCovariateProcedureGroup = TRUE,
                                                                    useCovariateObservation = TRUE,
                                                                    useCovariateObservation365d = TRUE,
                                                                    useCovariateObservation30d = TRUE,
                                                                    useCovariateObservationCount365d = TRUE,
                                                                    useCovariateMeasurement = TRUE,
                                                                    useCovariateMeasurement365d = TRUE,
                                                                    useCovariateMeasurement30d = TRUE,
                                                                    useCovariateMeasurementCount365d = TRUE,
                                                                    useCovariateMeasurementBelow = TRUE,
                                                                    useCovariateMeasurementAbove = TRUE,
                                                                    useCovariateConceptCounts = FALSE,
                                                                    useCovariateRiskScores = TRUE,
                                                                    useCovariateRiskScoresCharlson = TRUE,
                                                                    useCovariateRiskScoresDCSI = TRUE,
                                                                    useCovariateRiskScoresCHADS2 = TRUE,
                                                                    useCovariateRiskScoresCHADS2VASc = TRUE,
                                                                    excludedCovariateConceptIds = 900000010,
                                                                    deleteCovariatesSmallCount = 100)
    # covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
    #                                                                 useCovariateDemographicsGender = TRUE,
    #                                                                 useCovariateDemographicsRace = TRUE,
    #                                                                 useCovariateDemographicsEthnicity = TRUE,
    #                                                                 useCovariateDemographicsAge = TRUE,
    #                                                                 useCovariateDemographicsYear = TRUE,
    #                                                                 useCovariateDemographicsMonth = TRUE,
    #                                                                 deleteCovariatesSmallCount = 100)
    covariates <- FeatureExtraction::getDbCovariateData(connection = conn,
                                                        oracleTempSchema = oracleTempSchema,
                                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                                        cdmVersion = 5,
                                                        cohortTable = "#exposure_cohorts",
                                                        cohortTableIsTemp = TRUE,
                                                        rowIdField = "row_id",
                                                        covariateSettings = covariateSettings,
                                                        normalize = TRUE)
    FeatureExtraction::saveCovariateData(covariates, file.path(workFolder, "allCovariates"))

    writeLines("Retrieving cohorts")
    sql <- SqlRender::loadRenderTranslateSql("GetExposureCohorts.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable)
    cohorts <- DatabaseConnector::querySql.ffdf(conn, sql)
    colnames(cohorts) <- SqlRender::snakeCaseToCamelCase(colnames(cohorts))
    ffbase::save.ffdf(cohorts, dir = file.path(workFolder, "allCohorts"))
    ff::close.ffdf(cohorts)

    writeLines("Retrieving outcomes")
    sql <- SqlRender::loadRenderTranslateSql("GetOutcomes.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             outcome_database_schema = workDatabaseSchema,
                                             outcome_table = studyCohortTable,
                                             outcome_ids = outcomeIds)
    outcomes <- DatabaseConnector::querySql.ffdf(conn, sql)
    colnames(outcomes) <- SqlRender::snakeCaseToCamelCase(colnames(outcomes))
    ffbase::save.ffdf(outcomes, dir = file.path(workFolder, "allOutcomes"))
    ff::close.ffdf(outcomes)

    writeLines("Retrieving filter concepts")
    sql <- SqlRender::loadRenderTranslateSql("GetFilterConcepts.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             exposure_concept_ids = exposureConceptIds)
    filterConcepts <- DatabaseConnector::querySql(conn, sql)
    colnames(filterConcepts) <- SqlRender::snakeCaseToCamelCase(colnames(filterConcepts))
    filterConcepts <- merge(filterConcepts, exposureIdToConceptId, by.x = "exposureConceptId", by.y = "conceptId")
    filterConcepts$exposureConceptId <- NULL
    saveRDS(filterConcepts, file.path(workFolder, "filterConceps.rds"))
}

constructCohortMethodDataObject <- function(targetId,
                                            comparatorId,
                                            targetConceptId,
                                            comparatorConceptId,
                                            workFolder) {
    # Subsetting cohorts
    ffbase::load.ffdf(dir = file.path(workFolder, "allCohorts"))
    ff::open.ffdf(cohorts, readonly = TRUE)
    idx <- cohorts$cohortDefinitionId == targetId | cohorts$cohortDefinitionId == comparatorId
    cohorts <- ff::as.ram(cohorts[ffbase::ffwhich(idx, idx == TRUE), ])
    cohorts$treatment <- 0
    cohorts$treatment[cohorts$cohortDefinitionId == targetId] <- 1
    cohorts$cohortDefinitionId <- NULL
    treatedPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 1]))
    comparatorPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 0]))
    treatedExposures <- length(cohorts$subjectId[cohorts$treatment == 1])
    comparatorExposures <- length(cohorts$subjectId[cohorts$treatment == 0])
    counts <- data.frame(description = "Starting cohorts",
                         treatedPersons = treatedPersons,
                         comparatorPersons = comparatorPersons,
                         treatedExposures = treatedExposures,
                         comparatorExposures = comparatorExposures)
    metaData <- list(targetId = targetId,
                     comparatorId = comparatorId,
                     attrition = counts)
    attr(cohorts, "metaData") <- metaData

    # Subsetting outcomes
    ffbase::load.ffdf(dir = file.path(workFolder, "allOutcomes"))
    ff::open.ffdf(outcomes, readonly = TRUE)
    idx <- !is.na(ffbase::ffmatch(outcomes$rowId, ff::as.ff(cohorts$rowId)))
    if (ffbase::any.ff(idx)){
        outcomes <- ff::as.ram(outcomes[ffbase::ffwhich(idx, idx == TRUE), ])
    } else {
        outcomes <- as.data.frame(outcomes[1, ])
        outcomes <- outcomes[T == F,]
    }
    # Add injected outcomes
    ffbase::load.ffdf(dir = file.path(workFolder, "injectedOutcomes"))
    ff::open.ffdf(injectedOutcomes, readonly = TRUE)
    injectionSummary <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
    injectionSummary <- injectionSummary[injectionSummary$exposureId %in% c(targetConceptId, comparatorConceptId), ]
    idx1 <- ffbase::'%in%'(injectedOutcomes$subjectId, cohorts$subjectId)
    idx2 <- ffbase::'%in%'(injectedOutcomes$cohortDefinitionId, injectionSummary$newOutcomeId)
    idx <- idx1 & idx2
    if (ffbase::any.ff(idx)){
        injectedOutcomes <- ff::as.ram(injectedOutcomes[idx, ])
        colnames(injectedOutcomes)[colnames(injectedOutcomes) == "cohortStartDate"] <- "eventDate"
        colnames(injectedOutcomes)[colnames(injectedOutcomes) == "cohortDefinitionId"] <- "outcomeId"
        injectedOutcomes <- merge(cohorts[, c("rowId", "subjectId", "cohortStartDate")], injectedOutcomes[, c("subjectId", "outcomeId", "eventDate")])
        injectedOutcomes$daysToEvent = injectedOutcomes$eventDate - injectedOutcomes$cohortStartDate
        #any(injectedOutcomes$daysToEvent < 0)
        #min(outcomes$daysToEvent[outcomes$outcomeId == 73008])
        outcomes <- rbind(outcomes, injectedOutcomes[, c("rowId", "outcomeId", "daysToEvent")])
    }
    metaData <- data.frame(outcomeIds = unique(outcomes$outcomeId))
    attr(outcomes, "metaData") <- metaData

    # Subsetting covariates
    covariateData <- FeatureExtraction::loadCovariateData(file.path(workFolder, "allCovariates"))
    idx <- is.na(ffbase::ffmatch(covariateData$covariates$rowId, ff::as.ff(cohorts$rowId)))
    covariates <- covariateData$covariates[ffbase::ffwhich(idx, idx == FALSE), ]

    # Filtering covariates
    filterConcepts <- readRDS(file.path(workFolder, "filterConceps.rds"))
    filterConcepts <- filterConcepts[filterConcepts$exposureId %in% c(targetId, comparatorId),]
    filterConceptIds <- unique(filterConcepts$filterConceptId)
    idx <- is.na(ffbase::ffmatch(covariateData$covariateRef$conceptId, ff::as.ff(filterConceptIds)))
    covariateRef <- covariateData$covariateRef[ffbase::ffwhich(idx, idx == TRUE), ]
    filterCovariateIds <- covariateData$covariateRef$covariateId[ffbase::ffwhich(idx, idx == FALSE), ]
    idx <- is.na(ffbase::ffmatch(covariates$covariateId, filterCovariateIds))
    covariates <- covariates[ffbase::ffwhich(idx, idx == TRUE), ]

    result <- list(cohorts = cohorts,
                   outcomes = outcomes,
                   covariates = covariates,
                   covariateRef = covariateRef,
                   metaData = covariateData$metaData)

    class(result) <- "cohortMethodData"
    return(result)
}

#' Construct all cohortMethodData object
#'
#' @details
#' This function constructs all cohortMethodData objects using the data
#' fetched earlier using the \code{\link{fetchAllDataFromServer}} function.
#'
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
generateAllCohortMethodDataObjects <- function(workFolder) {
    writeLines("Constructing cohortMethodData objects")
    start <- Sys.time()
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    pb <- txtProgressBar(style = 3)
    for (i in 1:nrow(exposureSummary)) {
        targetId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        targetConceptId <- exposureSummary$tCohortDefinitionId[i]
        comparatorConceptId <- exposureSummary$cCohortDefinitionId[i]
        folderName <- file.path(workFolder, "cmOutput", paste0("CmData_l1_t", targetId, "_c", comparatorId))
        if (!file.exists(folderName)) {
            cmData <- constructCohortMethodDataObject(targetId = targetId,
                                                      comparatorId = comparatorId,
                                                      targetConceptId = targetConceptId,
                                                      comparatorConceptId = comparatorConceptId,
                                                      workFolder = workFolder)
            CohortMethod::saveCohortMethodData(cmData, folderName)
        }
        setTxtProgressBar(pb, i/nrow(exposureSummary))
    }
    close(pb)
    delta <- Sys.time() - start
    writeLines(paste("Generating all CohortMethodData objects took", signif(delta, 3), attr(delta, "units")))
}
