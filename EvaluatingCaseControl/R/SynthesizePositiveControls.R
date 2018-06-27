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

#' Synthesize positive controls
#'
#' @details
#' This function will synthesize positve controls based on the negative controls. The simulated outcomes
#' will be added to the cohort table.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
synthesizePositiveControls <- function(connectionDetails,
                                       cdmDatabaseSchema,
                                       cohortDatabaseSchema,
                                       cohortTable = "cohort",
                                       oracleTempSchema,
                                       outputFolder,
                                       maxCores = 1) {
  synthesisFolder <- file.path(outputFolder, "positiveControlSynthesisAp")
  synthesisSummaryFile <- file.path(outputFolder, "SynthesisSummaryAp.csv")
  outcomeId <- 2
  riskWindowEnd <- 30
  outputIdOffset <- 10000
  allControlsFile <- file.path(outputFolder, "AllControls.csv")

  synthesize <- function(synthesisFolder,
                         synthesisSummaryFile,
                         outcomeId,
                         riskWindowEnd,
                         outputIdOffset,
                         allControlsFile) {
    if (!file.exists(synthesisFolder))
      dir.create(synthesisFolder)


    if (!file.exists(synthesisSummaryFile)) {
      pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
      negativeControls <- read.csv(pathToCsv)
      negativeControls <- negativeControls[negativeControls$outcomeId == outcomeId, ]
      exposureOutcomePairs <- data.frame(exposureId = negativeControls$targetId,
                                         outcomeId = negativeControls$outcomeId)
      exposureOutcomePairs <- unique(exposureOutcomePairs)
      prior = Cyclops::createPrior("laplace", exclude = 0, useCrossValidation = TRUE)
      control = Cyclops::createControl(cvType = "auto",
                                       startingVariance = 0.01,
                                       noiseLevel = "quiet",
                                       cvRepetitions = 1,
                                       threads = min(c(10, maxCores)))
      covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                                                      useDemographicsGender = TRUE,
                                                                      useDemographicsIndexYear = TRUE,
                                                                      useDemographicsIndexMonth = TRUE,
                                                                      useConditionGroupEraLongTerm = TRUE,
                                                                      useDrugGroupEraLongTerm = TRUE,
                                                                      useProcedureOccurrenceLongTerm = TRUE,
                                                                      useMeasurementLongTerm = TRUE,
                                                                      useObservationLongTerm = TRUE,
                                                                      useCharlsonIndex = TRUE,
                                                                      useDcsi = TRUE,
                                                                      useChads2Vasc = TRUE,
                                                                      longTermStartDays = 365,
                                                                      endDays = 0)
      result <- MethodEvaluation::injectSignals(connectionDetails,
                                                cdmDatabaseSchema = cdmDatabaseSchema,
                                                oracleTempSchema = oracleTempSchema,
                                                exposureDatabaseSchema = cohortDatabaseSchema,
                                                exposureTable = cohortTable,
                                                outcomeDatabaseSchema = cohortDatabaseSchema,
                                                outcomeTable = cohortTable,
                                                outputDatabaseSchema = cohortDatabaseSchema,
                                                outputTable = cohortTable,
                                                createOutputTable = FALSE,
                                                outputIdOffset = outputIdOffset,
                                                exposureOutcomePairs = exposureOutcomePairs,
                                                firstExposureOnly = FALSE,
                                                firstOutcomeOnly = TRUE,
                                                removePeopleWithPriorOutcomes = TRUE,
                                                modelType = "survival",
                                                washoutPeriod = 365,
                                                riskWindowStart = 0,
                                                riskWindowEnd = riskWindowEnd,
                                                addExposureDaysToEnd = TRUE,
                                                effectSizes = c(1.5, 2, 4),
                                                precision = 0.01,
                                                prior = prior,
                                                control = control,
                                                maxSubjectsForModel = 250000,
                                                minOutcomeCountForModel = 50,
                                                minOutcomeCountForInjection = 25,
                                                workFolder = synthesisFolder,
                                                modelThreads = max(1, round(maxCores/8)),
                                                generationThreads = min(6, maxCores),
                                                covariateSettings = covariateSettings)
      write.csv(result, synthesisSummaryFile, row.names = FALSE)
    }
    OhdsiRTools::logTrace("Merging positive with negative controls ")
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
    negativeControls <- read.csv(pathToCsv)
    negativeControls <- negativeControls[negativeControls$outcomeId == outcomeId, ]

    synthesisSummary <- read.csv(synthesisSummaryFile)
    synthesisSummary$targetId <- synthesisSummary$exposureId
    synthesisSummary <- merge(synthesisSummary, negativeControls)
    synthesisSummary <- synthesisSummary[synthesisSummary$trueEffectSize != 0, ]
    synthesisSummary$outcomeName <- paste0(synthesisSummary$outcomeName, ", RR=", synthesisSummary$targetEffectSize)
    synthesisSummary$oldOutcomeId <- synthesisSummary$outcomeId
    synthesisSummary$outcomeId <- synthesisSummary$newOutcomeId
    negativeControls$targetEffectSize <- 1
    negativeControls$trueEffectSize <- 1
    negativeControls$trueEffectSizeFirstExposure <- 1
    negativeControls$oldOutcomeId <- negativeControls$outcomeId
    allControls <- rbind(negativeControls, synthesisSummary[, names(negativeControls)])
    # allControls <- negativeControls
    write.csv(allControls, allControlsFile, row.names = FALSE)
  }
  OhdsiRTools::logInfo("Synhtesizing positive controls for Chou replication")
  synthesize(synthesisFolder = file.path(outputFolder, "positiveControlSynthesisAp"),
             synthesisSummaryFile = file.path(outputFolder, "SynthesisSummaryAp.csv"),
             outcomeId = 2,
             riskWindowEnd = 30,
             outputIdOffset = 10000,
             allControlsFile = file.path(outputFolder, "AllControlsAp.csv"))

  OhdsiRTools::logInfo("Synhtesizing positive controls for Crockett replication")
  synthesize(synthesisFolder = file.path(outputFolder, "positiveControlSynthesisIbd"),
             synthesisSummaryFile = file.path(outputFolder, "SynthesisSummaryIbd.csv"),
             outcomeId = 3,
             riskWindowEnd = 365,
             outputIdOffset = 11000,
             allControlsFile = file.path(outputFolder, "AllControlsIbd.csv"))
}
