# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of CiCalibration
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
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param study                For which study should the cohorts be created? Options are "SSRIs" and "Dabigatran".
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
injectSignals <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_ci_calibration",
                          oracleTempSchema,
                          study,
                          workFolder,
                          maxCores = 4) {
    signalInjectionFolder <- file.path(workFolder, "signalInjection")
    if (!file.exists(signalInjectionFolder))
        dir.create(signalInjectionFolder)
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
    negativeControls <- read.csv(pathToCsv)
    negativeControls <- negativeControls[negativeControls$study == study, ]

    if (study == "Tata") {
        modelType <- "poisson"
        firstOutcomeOnly <- FALSE
        removePeopleWithPriorOutcomes <- FALSE
        firstExposureOnly <- FALSE
        riskWindowEnd <- 30

        pathToHoi <- system.file("settings", "sccsHypothesisOfInterest.txt", package = "CiCalibration")
        hypothesesOfInterest <- SelfControlledCaseSeries::loadExposureOutcomeList(pathToHoi)
        exposureOutcomePairs <- data.frame(exposureId = hypothesesOfInterest[[1]]$exposureId,
                                           outcomeId = negativeControls$conceptId)
    } else if (study == "Southworth") {
        modelType <- "survival"
        firstOutcomeOnly <- TRUE
        removePeopleWithPriorOutcomes <- TRUE
        firstExposureOnly <- TRUE
        riskWindowEnd <- 0

        pathToHoi <- system.file("settings", "cmHypothesisOfInterestSouthworth.txt", package = "CiCalibration")
        hypothesesOfInterest <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)
        exposureOutcomePairs <- data.frame(exposureId = hypothesesOfInterest[[1]]$targetId,
                                           outcomeId = negativeControls$conceptId)
    } else if (study == "Graham") {
        modelType <- "survival"
        firstOutcomeOnly <- TRUE
        removePeopleWithPriorOutcomes <- TRUE
        firstExposureOnly <- TRUE
        riskWindowEnd <- 0

        pathToHoi <- system.file("settings", "cmHypothesisOfInterestGraham.txt", package = "CiCalibration")
        hypothesesOfInterest <- CohortMethod::loadDrugComparatorOutcomesList(pathToHoi)
        exposureOutcomePairs <- data.frame(exposureId = hypothesesOfInterest[[1]]$targetId,
                                           outcomeId = negativeControls$conceptId)
    }
    covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
                                                                    useCovariateDemographicsGender = TRUE,
                                                                    useCovariateDemographicsRace = TRUE,
                                                                    useCovariateDemographicsEthnicity = TRUE,
                                                                    useCovariateDemographicsAge = TRUE,
                                                                    useCovariateDemographicsYear = TRUE,
                                                                    useCovariateDemographicsMonth = TRUE,
                                                                    useCovariateConditionOccurrence = TRUE,
                                                                    useCovariateConditionOccurrenceLongTerm = TRUE,
                                                                    useCovariateConditionOccurrenceShortTerm = TRUE,
                                                                    useCovariateConditionOccurrenceInptMediumTerm = TRUE,
                                                                    useCovariateConditionEra = TRUE,
                                                                    useCovariateConditionEraEver = TRUE,
                                                                    useCovariateConditionEraOverlap = TRUE,
                                                                    useCovariateConditionGroup = TRUE,
                                                                    useCovariateConditionGroupMeddra = TRUE,
                                                                    useCovariateConditionGroupSnomed = TRUE,
                                                                    useCovariateDrugExposure = TRUE,
                                                                    useCovariateDrugExposureLongTerm = TRUE,
                                                                    useCovariateDrugExposureShortTerm = TRUE,
                                                                    useCovariateDrugEra = TRUE,
                                                                    useCovariateDrugEraLongTerm = TRUE,
                                                                    useCovariateDrugEraShortTerm = TRUE,
                                                                    useCovariateDrugEraOverlap = TRUE,
                                                                    useCovariateDrugEraEver = TRUE,
                                                                    useCovariateDrugGroup = TRUE,
                                                                    useCovariateProcedureOccurrence = TRUE,
                                                                    useCovariateProcedureOccurrenceLongTerm = TRUE,
                                                                    useCovariateProcedureOccurrenceShortTerm = TRUE,
                                                                    useCovariateProcedureGroup = TRUE,
                                                                    useCovariateObservation = TRUE,
                                                                    useCovariateObservationLongTerm = TRUE,
                                                                    useCovariateObservationShortTerm = TRUE,
                                                                    useCovariateObservationCountLongTerm = TRUE,
                                                                    useCovariateMeasurement = TRUE,
                                                                    useCovariateMeasurementLongTerm = TRUE,
                                                                    useCovariateMeasurementShortTerm = TRUE,
                                                                    useCovariateMeasurementCountLongTerm = TRUE,
                                                                    useCovariateMeasurementBelow = TRUE,
                                                                    useCovariateMeasurementAbove = TRUE,
                                                                    useCovariateConceptCounts = TRUE,
                                                                    useCovariateRiskScores = TRUE,
                                                                    useCovariateRiskScoresCharlson = TRUE,
                                                                    useCovariateRiskScoresDCSI = TRUE,
                                                                    useCovariateRiskScoresCHADS2 = TRUE,
                                                                    useCovariateRiskScoresCHADS2VASc = TRUE,
                                                                    useCovariateInteractionYear = FALSE,
                                                                    useCovariateInteractionMonth = FALSE,
                                                                    excludedCovariateConceptIds = c(),
                                                                    includedCovariateConceptIds = c(),
                                                                    deleteCovariatesSmallCount = 100,
                                                                    longTermDays = 180,
                                                                    mediumTermDays = 180,
                                                                    shortTermDays = 30)

    summ <- MethodEvaluation::injectSignals(connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            oracleTempSchema = cdmDatabaseSchema,
                                            exposureDatabaseSchema = workDatabaseSchema,
                                            exposureTable = studyCohortTable,
                                            outcomeDatabaseSchema = workDatabaseSchema,
                                            outcomeTable = studyCohortTable,
                                            outputDatabaseSchema = workDatabaseSchema,
                                            outputTable = studyCohortTable,
                                            createOutputTable = FALSE,
                                            exposureOutcomePairs = exposureOutcomePairs,
                                            modelType = modelType,
                                            buildOutcomeModel = TRUE,
                                            buildModelPerExposure = FALSE,
                                            covariateSettings = covariateSettings,
                                            minOutcomeCountForModel = 100,
                                            minOutcomeCountForInjection = 25,
                                            prior = Cyclops::createPrior("laplace", exclude = 0, useCrossValidation = TRUE),
                                            control = Cyclops::createControl(cvType = "auto",
                                                                             startingVariance = 0.01,
                                                                             tolerance = 2e-07,
                                                                             cvRepetitions = 1,
                                                                             noiseLevel = "silent",
                                                                             threads = min(10, maxCores)),
                                            firstExposureOnly = firstExposureOnly,
                                            washoutPeriod = 180,
                                            riskWindowStart = 0,
                                            riskWindowEnd = riskWindowEnd,
                                            addExposureDaysToEnd = TRUE,
                                            firstOutcomeOnly = firstOutcomeOnly,
                                            removePeopleWithPriorOutcomes = removePeopleWithPriorOutcomes,
                                            maxSubjectsForModel = 250000,
                                            effectSizes = c(1.5, 2, 4),
                                            precision = 0.01,
                                            outputIdOffset = 10000,
                                            workFolder = signalInjectionFolder,
                                            cdmVersion = "5",
                                            modelThreads = max(1, round(maxCores/8)),
                                            generationThreads = min(6, maxCores))
    write.csv(summ, file.path(workFolder, paste0("SignalInjectionSummary_", study, ".csv")), row.names = FALSE)
}
