# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
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

#' Create the analyses details
#'
#' @details
#' This function creates files specifying the analyses that will be performed.
#'
#' @param connectionDetails   An object of type \code{connectionDetails} as created using the
#'                            \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                            DatabaseConnector package.
#' @param cdmDatabaseSchema   Schema name where your patient-level data in OMOP CDM format resides.
#'                            Note that for SQL Server, this should include both the database and
#'                            schema name, for example 'cdm_data.dbo'.
#' @param workFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createAnalysesDetails <- function(connectionDetails, cdmDatabaseSchema, workFolder) {

  # Verbatim from ATLAS (except for explicit package refs,add. outcomes, and no balance)-----------------

  targetCohortId <- 99321
  comparatorCohortId <- 99322
  outcomeList <- c(99323, 100791, 100792, 100793, 100794, 100795)

  # Default Prior & Control settings ----
  defaultPrior <- Cyclops::createPrior("laplace",
                                       exclude = c(0),
                                       useCrossValidation = TRUE)

  defaultControl <- Cyclops::createControl(cvType = "auto",
                                           startingVariance = 0.01,
                                           noiseLevel = "quiet",
                                           tolerance  = 2e-07,
                                           cvRepetitions = 10,
                                           threads = 1,
                                           seed = 123)



  # Get all Sisyphus challenge: drugs to exclude Concept IDs for exclusion ----
  sql <- paste("select distinct I.concept_id FROM
               (
               select concept_id from @cdm_database_schema.CONCEPT where concept_id in (1557272,44506794,21604148,1513103)and invalid_reason is null
               UNION  select c.concept_id
               from @cdm_database_schema.CONCEPT c
               join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
               and ca.ancestor_concept_id in (1557272,44506794,21604148,1513103)
               and c.invalid_reason is null

               ) I
               ")
  sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  connection <- DatabaseConnector::connect(connectionDetails)
  excludedConcepts <- DatabaseConnector::querySql(connection, sql)
  excludedConcepts <- excludedConcepts$CONCEPT_ID

  # Get all  Concept IDs for inclusion ----

  includedConcepts <- c()


  # Get all  Concept IDs for exclusion in the outcome model ----

  omExcludedConcepts <- c()

  # Get all  Concept IDs for inclusion exclusion in the outcome model ----

  omIncludedConcepts <- c()


  # Get all Sisyphus challenge:  negative controls for alendronate and raloxifenee Concept IDs for empirical calibration ----
  sql <- paste("select distinct I.concept_id FROM
               (
               select concept_id from @cdm_database_schema.CONCEPT where concept_id in (4305080,45765647,4217633,198809,4133026,440083,376981,4207240,4312008,4080321,4145825,4081007,314054,137829,440448,261880,4281109,4193166,4224118,378425,256722,442013,197028,314658,374384,4189855,4134586,140057,4304484,440704,4104204,312723,4080664,193016,441267,432590,375801,443767,436641,4225726,4023319,433694,22350,4157036,4101350,4029295,196456,4007453,4295370,4055361,4263367,4195003,4163735,432868,195562,444429,4038835,4214376,438134,4124693,436375,4120621,433752,4080305,192964,4208784,4074815,139099,4092885,200588,4152163,437409,436659,75576,4004352,380397,4209145,197676,4199395,4103995,4175297,316084,4308125,4177067,439045,435785,440389,4271024,440631,4129886,4130375,40304526,4038838,198802,442274,372914,43531000,43531638,43531639,440087,313792,4106574,317309,441838,4304010,134870,44783617,4324261,4114158,198199,133547,4256228,73754,80809,4286201,435783,319826,196236,4021907,433967,4329707,437779,4279309,4077081,432436,4227653,4344040,4280071,4207615,138387,381839,4234533,43021132,4119796,4002659,379801,201254,4281232,4032424,195862,4082798,443605,312935,40457757,197036,4193875,439981)and invalid_reason is null

               ) I
               ")
  sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  # connection <- connect(connectionDetails)
  negativeControlConcepts <- DatabaseConnector::querySql(connection, sql)
  negativeControlConcepts <- negativeControlConcepts$CONCEPT_ID


  # Create drug comparator and outcome arguments by combining target + comparitor + outcome + negative controls ----
  dcos <- CohortMethod::createDrugComparatorOutcomes(targetId = targetCohortId,
                                                     comparatorId = comparatorCohortId,
                                                     excludedCovariateConceptIds = excludedConcepts,
                                                     includedCovariateConceptIds = includedConcepts,
                                                     outcomeIds = c(outcomeList, negativeControlConcepts))

  drugComparatorOutcomesList <- list(dcos)



  # Define which types of covariates must be constructed ----
  covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
                                                                  useCovariateDemographicsGender = TRUE,
                                                                  useCovariateDemographicsRace = FALSE,
                                                                  useCovariateDemographicsEthnicity = FALSE,
                                                                  useCovariateDemographicsAge = TRUE,
                                                                  useCovariateDemographicsYear = TRUE,
                                                                  useCovariateDemographicsMonth = TRUE,
                                                                  useCovariateConditionOccurrence = TRUE,
                                                                  useCovariateConditionOccurrenceLongTerm = TRUE,
                                                                  useCovariateConditionOccurrenceShortTerm = TRUE,
                                                                  useCovariateConditionOccurrenceInptMediumTerm = FALSE,
                                                                  useCovariateConditionEra = FALSE,
                                                                  useCovariateConditionEraEver = FALSE,
                                                                  useCovariateConditionEraOverlap = FALSE,
                                                                  useCovariateConditionGroup = TRUE,
                                                                  useCovariateConditionGroupMeddra = FALSE,
                                                                  useCovariateConditionGroupSnomed = TRUE,
                                                                  useCovariateDrugExposure = FALSE,
                                                                  useCovariateDrugExposureLongTerm = FALSE,
                                                                  useCovariateDrugExposureShortTerm = FALSE,
                                                                  useCovariateDrugEra = TRUE,
                                                                  useCovariateDrugEraLongTerm = TRUE,
                                                                  useCovariateDrugEraShortTerm = FALSE,
                                                                  useCovariateDrugEraOverlap = FALSE,
                                                                  useCovariateDrugEraEver = FALSE,
                                                                  useCovariateDrugGroup = TRUE,
                                                                  useCovariateProcedureOccurrence = TRUE,
                                                                  useCovariateProcedureOccurrenceLongTerm = TRUE,
                                                                  useCovariateProcedureOccurrenceShortTerm = FALSE,
                                                                  useCovariateProcedureGroup = FALSE,
                                                                  useCovariateObservation = FALSE,
                                                                  useCovariateObservationLongTerm = FALSE,
                                                                  useCovariateObservationShortTerm = FALSE,
                                                                  useCovariateObservationCountLongTerm = FALSE,
                                                                  useCovariateMeasurement = TRUE,
                                                                  useCovariateMeasurementLongTerm = TRUE,
                                                                  useCovariateMeasurementShortTerm = FALSE,
                                                                  useCovariateMeasurementCountLongTerm = TRUE,
                                                                  useCovariateMeasurementBelow = FALSE,
                                                                  useCovariateMeasurementAbove = FALSE,
                                                                  useCovariateConceptCounts = TRUE,
                                                                  useCovariateRiskScores = TRUE,
                                                                  useCovariateRiskScoresCharlson = TRUE,
                                                                  useCovariateRiskScoresDCSI = FALSE,
                                                                  useCovariateRiskScoresCHADS2 = FALSE,
                                                                  useCovariateRiskScoresCHADS2VASc = FALSE,
                                                                  useCovariateInteractionYear = FALSE,
                                                                  useCovariateInteractionMonth = FALSE,
                                                                  deleteCovariatesSmallCount = 100,
                                                                  addDescendantsToExclude = TRUE)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 365,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = TRUE,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)

  createStudyPopArgs1 <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                       firstExposureOnly = FALSE,
                                                                       washoutPeriod = 365,
                                                                       removeDuplicateSubjects = TRUE,
                                                                       minDaysAtRisk = 0,
                                                                       riskWindowStart = 90,
                                                                       addExposureDaysToStart = FALSE,
                                                                       riskWindowEnd = 9999,
                                                                       addExposureDaysToEnd = FALSE)

  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = TRUE,
                                                                  includeCovariateIds = omIncludedConcepts,
                                                                  excludeCovariateIds = omExcludedConcepts,
                                                                  prior = defaultPrior,
                                                                  control = defaultControl)

  createPsArgs1 <- CohortMethod::createCreatePsArgs(control = defaultControl) # Using only defaults
  trimByPsArgs1 <- CohortMethod::createTrimByPsArgs() # Using only defaults
  trimByPsToEquipoiseArgs1 <- CohortMethod::createTrimByPsToEquipoiseArgs(bounds = c(0.1, 0.9))
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs() # Using only defaults
  stratifyByPsArgs1 <- CohortMethod::createStratifyByPsArgs(numberOfStrata = 5)

  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "Main analysis: ITT",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs1,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs1,
                                                trimByPs = FALSE,
                                                trimByPsArgs = trimByPsArgs1,
                                                trimByPsToEquipoise = TRUE,
                                                trimByPsToEquipoiseArgs = trimByPsToEquipoiseArgs1,
                                                matchOnPs = FALSE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs1,
                                                computeCovariateBalance = FALSE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs1)

  createStudyPopArgs2 <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                       firstExposureOnly = FALSE,
                                                                       washoutPeriod = 365,
                                                                       removeDuplicateSubjects = TRUE,
                                                                       minDaysAtRisk = 0,
                                                                       riskWindowStart = 90,
                                                                       addExposureDaysToStart = FALSE,
                                                                       riskWindowEnd = 0,
                                                                       addExposureDaysToEnd = TRUE)

  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "Sensitivity analysis: Per-protocol",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createStudyPopArgs = createStudyPopArgs2,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs1,
                                                trimByPs = FALSE,
                                                trimByPsArgs = trimByPsArgs1,
                                                trimByPsToEquipoise = TRUE,
                                                trimByPsToEquipoiseArgs = trimByPsToEquipoiseArgs1,
                                                matchOnPs = FALSE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                stratifyByPs = TRUE,
                                                stratifyByPsArgs = stratifyByPsArgs1,
                                                computeCovariateBalance = FALSE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs1)

  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2)

  # Save settings to package ------------------------------------------------
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.txt"))
  CohortMethod::saveDrugComparatorOutcomesList(drugComparatorOutcomesList, file.path(workFolder, "drugComparatorOutcomesList.txt"))
}

