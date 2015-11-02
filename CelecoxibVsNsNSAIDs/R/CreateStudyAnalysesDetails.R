# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of CelecoxibVsNsNSAIDs
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
#' @param outputFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createAnalysesDetails <- function(connectionDetails, cdmDatabaseSchema, outputFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)

  # Get all NSAIDs:
  sql <- "SELECT concept_id FROM @cdmDatabaseSchema.concept_ancestor INNER JOIN @cdmDatabaseSchema.concept ON descendant_concept_id = concept_id WHERE ancestor_concept_id = 21603933"
  sql <- SqlRender::renderSql(sql, cdmDatabaseSchema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  nsaids <- DatabaseConnector::querySql(conn, sql)
  nsaids <- nsaids$CONCEPT_ID

  RJDBC::dbDisconnect(conn)

  negativeControlIds <- c(22281,
                          72418,
                          72712,
                          73302,
                          74855,
                          76737,
                          77650,
                          78804,
                          79072,
                          80509,
                          81250,
                          81336,
                          133141,
                          133228,
                          133327,
                          133551,
                          134118,
                          134222,
                          134765,
                          136937,
                          137054,
                          139099,
                          140362,
                          140641,
                          141216,
                          141825,
                          192606,
                          193326,
                          193874,
                          194702,
                          194997,
                          195212,
                          195501,
                          197036,
                          198075,
                          199876,
                          201388,
                          253796,
                          261326,
                          261880,
                          315288,
                          317305,
                          317376,
                          317585,
                          317895,
                          319845,
                          373478,
                          373766,
                          374384,
                          376132,
                          376712,
                          378160,
                          378256,
                          378424,
                          379769,
                          380395,
                          380731,
                          381581,
                          432851,
                          433163,
                          433440,
                          434309,
                          434319,
                          434626,
                          434630,
                          435140,
                          436100,
                          436740,
                          437222,
                          437409,
                          437986,
                          438134,
                          438407,
                          438872,
                          439237,
                          439840,
                          440389,
                          440424,
                          440676,
                          440695,
                          440814,
                          441267,
                          441788,
                          442274,
                          443361,
                          443605,
                          443767,
                          444130,
                          444191,
                          4018050,
                          4028970,
                          4029582,
                          4029966,
                          4044391,
                          4047269,
                          4047787,
                          4052648,
                          4083964,
                          4085156,
                          4087647,
                          4092565,
                          4095288,
                          4096666,
                          4112853,
                          4114197,
                          4114222,
                          4129880,
                          4130061,
                          4131595,
                          4131616,
                          4132130,
                          4132546,
                          4140510,
                          4146239,
                          4147672,
                          4153380,
                          4153877,
                          4163232,
                          4164337,
                          4171549,
                          4171915,
                          4172458,
                          4174977,
                          4186392,
                          4195698,
                          4207688,
                          4209011,
                          4215978,
                          4218106,
                          4223947,
                          4224118,
                          4242416,
                          4256228,
                          4262178,
                          4270490,
                          4285569,
                          4286201,
                          4288544,
                          4289933,
                          4295888,
                          4297984,
                          4305304,
                          4307254,
                          4322737,
                          4339088,
                          43020424,
                          45768449)

  # 80180 = Osteoarthritis. Note that all descendant concepts will also be included
  dcos <- CohortMethod::createDrugComparatorOutcomes(targetId = 1,
                                                     comparatorId = 2,
                                                     exclusionConceptIds = nsaids,
                                                     excludedCovariateConceptIds = nsaids,
                                                     indicationConceptIds = 80180,
                                                     outcomeIds = c(10:16, negativeControlIds))
  drugComparatorOutcomesList <- list(dcos)

  covarSettings <- PatientLevelPrediction::createCovariateSettings(useCovariateDemographics = TRUE,
                                                                   useCovariateConditionOccurrence = TRUE,
                                                                   useCovariateConditionOccurrence365d = TRUE,
                                                                   useCovariateConditionOccurrence30d = TRUE,
                                                                   useCovariateConditionOccurrenceInpt180d = TRUE,
                                                                   useCovariateConditionEra = TRUE,
                                                                   useCovariateConditionEraEver = TRUE,
                                                                   useCovariateConditionEraOverlap = TRUE,
                                                                   useCovariateConditionGroup = TRUE,
                                                                   useCovariateDrugExposure = TRUE,
                                                                   useCovariateDrugExposure365d = TRUE,
                                                                   useCovariateDrugExposure30d = TRUE,
                                                                   useCovariateDrugEra = TRUE,
                                                                   useCovariateDrugEra365d = TRUE,
                                                                   useCovariateDrugEra30d = TRUE,
                                                                   useCovariateDrugEraEver = TRUE,
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
                                                                   useCovariateMeasurement365d = TRUE,
                                                                   useCovariateMeasurement30d = TRUE,
                                                                   useCovariateMeasurementCount365d = TRUE,
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
                                                                   deleteCovariatesSmallCount = 100)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutWindow = 183,
                                                                   indicationLookbackWindow = 183,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covarSettings)

  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(riskWindowStart = 0,
                                                                  riskWindowEnd = 30,
                                                                  addExposureDaysToEnd = TRUE,
                                                                  useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratifiedCox = FALSE)

  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "No matching, simple outcome model",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs1)

  createPsArgs <- CohortMethod::createCreatePsArgs()  # Using only defaults

  matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(maxRatio = 100)

  fitOutcomeModelArgs2 <- CohortMethod::createFitOutcomeModelArgs(riskWindowStart = 0,
                                                                  riskWindowEnd = 30,
                                                                  addExposureDaysToEnd = TRUE,
                                                                  useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratifiedCox = TRUE)

  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "Matching plus simple stratified outcome model",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs,
                                                computeCovariateBalance = TRUE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs2)

  fitOutcomeModelArgs3 <- CohortMethod::createFitOutcomeModelArgs(riskWindowStart = 0,
                                                                  riskWindowEnd = 30,
                                                                  addExposureDaysToEnd = TRUE,
                                                                  useCovariates = TRUE,
                                                                  modelType = "cox",
                                                                  stratifiedCox = TRUE)

  cmAnalysis3 <- CohortMethod::createCmAnalysis(analysisId = 3,
                                                description = "Matching plus full outcome model",
                                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                createPs = TRUE,
                                                createPsArgs = createPsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs,
                                                computeCovariateBalance = TRUE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitOutcomeModelArgs3)

  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2, cmAnalysis3)

  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(outputFolder, "cmAnalysisList.txt"))
  CohortMethod::saveDrugComparatorOutcomesList(drugComparatorOutcomesList,
                                               file.path(outputFolder,
                                                         "drugComparatorOutcomesList.txt"))
}
