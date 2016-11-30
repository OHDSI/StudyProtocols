# Copyright 2016 Observational Health Data Sciences and Informatics
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

    # Southworh study -----------------------------------------------------

    covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE, useCovariateDemographicsGender = TRUE)

    getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(excludeDrugsFromCovariates = FALSE,
                                                                     covariateSettings = covariateSettings)

    createStudyPopArgsSouthworth <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                                   minDaysAtRisk = 1,
                                                                                   riskWindowStart = 0,
                                                                                   addExposureDaysToStart = FALSE,
                                                                                   riskWindowEnd = 0,
                                                                                   addExposureDaysToEnd = TRUE)

    fitOutcomeModelArgsSouthworth <- CohortMethod::createFitOutcomeModelArgs(modelType = "poisson",
                                                                             useCovariates = FALSE,
                                                                             stratified = FALSE)

    cmAnalysisSouthworth <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                           description = "Southworth replication",
                                                           getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                           createStudyPopArgs = createStudyPopArgsSouthworth,
                                                           fitOutcomeModel = TRUE,
                                                           fitOutcomeModelArgs = fitOutcomeModelArgsSouthworth)

    cmAnalysisListSouthworth <- list(cmAnalysisSouthworth)

    CohortMethod::saveCmAnalysisList(cmAnalysisListSouthworth, file.path(workFolder, "cmAnalysisListSouthworth.txt"))

    dco <- CohortMethod::createDrugComparatorOutcomes(targetId = 1,
                                                      comparatorId = 2,
                                                      outcomeIds = 3)
    dcos <- list(dco)
    CohortMethod::saveDrugComparatorOutcomesList(dcos, file.path(workFolder, "cmHypothesisOfInterestSouthworth.txt"))

    # Graham study ------------------------------------------------------

    # Get drugs and descendants to exclude from covariates:
    conn <- DatabaseConnector::connect(connectionDetails)
    sql <- "SELECT concept_id FROM @cdmDatabaseSchema.concept_ancestor INNER JOIN @cdmDatabaseSchema.concept ON descendant_concept_id = concept_id WHERE ancestor_concept_id IN (1310149, 40228152)"
    sql <- SqlRender::renderSql(sql, cdmDatabaseSchema = cdmDatabaseSchema)$sql
    sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
    excludeConceptIds <- DatabaseConnector::querySql(conn, sql)
    excludeConceptIds <- excludeConceptIds$CONCEPT_ID
    RJDBC::dbDisconnect(conn)

    covarSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
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
                                                                useCovariateConditionEra = TRUE,
                                                                useCovariateConditionEraEver = TRUE,
                                                                useCovariateConditionEraOverlap = TRUE,
                                                                useCovariateConditionGroup = TRUE,
                                                                useCovariateConditionGroupMeddra = TRUE,
                                                                useCovariateConditionGroupSnomed = TRUE,
                                                                useCovariateDrugExposure = TRUE,
                                                                useCovariateDrugExposure365d = TRUE,
                                                                useCovariateDrugExposure30d = TRUE,
                                                                useCovariateDrugEra = TRUE,
                                                                useCovariateDrugEra365d = TRUE,
                                                                useCovariateDrugEra30d = TRUE,
                                                                useCovariateDrugEraOverlap = TRUE,
                                                                useCovariateDrugEraEver = TRUE,
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
                                                                useCovariateConceptCounts = TRUE,
                                                                useCovariateRiskScores = TRUE,
                                                                useCovariateRiskScoresCharlson = TRUE,
                                                                useCovariateRiskScoresDCSI = TRUE,
                                                                useCovariateRiskScoresCHADS2 = TRUE,
                                                                useCovariateRiskScoresCHADS2VASc = TRUE,
                                                                useCovariateInteractionYear = FALSE,
                                                                useCovariateInteractionMonth = FALSE,
                                                                excludedCovariateConceptIds = excludeConceptIds,
                                                                deleteCovariatesSmallCount = 100)

    getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(excludeDrugsFromCovariates = FALSE,
                                                                     covariateSettings = covarSettings)

    createStudyPopArgsGraham <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                              minDaysAtRisk = 1,
                                                                              riskWindowStart = 1,
                                                                              addExposureDaysToStart = FALSE,
                                                                              riskWindowEnd = 0,
                                                                              addExposureDaysToEnd = TRUE)

    createPsArgs <- CohortMethod::createCreatePsArgs()

    matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(caliper = 0.25,
                                                       caliperScale = "standardized",
                                                       maxRatio = 1)

    fitOutcomeModelArgsGraham <- CohortMethod::createFitOutcomeModelArgs(modelType = "cox",
                                                                         stratified = FALSE,
                                                                         useCovariates = FALSE)

    cmAnalysisGraham <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                       description = "Graham replication",
                                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                                       createStudyPopArgs = createStudyPopArgsGraham,
                                                       createPs = TRUE,
                                                       createPsArgs = createPsArgs,
                                                       matchOnPs = TRUE,
                                                       matchOnPsArgs = matchOnPsArgs,
                                                       fitOutcomeModel = TRUE,
                                                       fitOutcomeModelArgs = fitOutcomeModelArgsGraham)


    cmAnalysisListGraham <- list(cmAnalysisGraham)

    CohortMethod::saveCmAnalysisList(cmAnalysisListGraham, file.path(workFolder, "cmAnalysisListGraham.txt"))

    dco <- CohortMethod::createDrugComparatorOutcomes(targetId = 4,
                                                      comparatorId = 5,
                                                      outcomeIds = 6)
    dcos <- list(dco)
    CohortMethod::saveDrugComparatorOutcomesList(dcos, file.path(workFolder, "cmHypothesisOfInterestGraham.txt"))

    # Tata study Case Control --------------------------------------------------------------

    getDbCaseDataArgs <- CaseControl::createGetDbCaseDataArgs(getVisits = FALSE,
                                                              useNestingCohort = FALSE,
                                                              studyStartDate = "19900101",
                                                              studyEndDate = "20031101")

    selectControlsArgs <- CaseControl::createSelectControlsArgs(firstOutcomeOnly = TRUE,
                                                                washoutPeriod = 180,
                                                                controlsPerCase = 6,
                                                                matchOnAge = TRUE,
                                                                ageCaliper = 1,
                                                                matchOnGender = TRUE,
                                                                matchOnCareSite = TRUE)

    getDbExposureDataArgs <- CaseControl::createGetDbExposureDataArgs()

    createCaseControlDataArgs <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                                              riskWindowStart = -30,
                                                                              riskWindowEnd = 0)

    fitCaseControlModelArgs <- CaseControl::createFitCaseControlModelArgs()

    ccAnalysis <- CaseControl::createCcAnalysis(analysisId = 1,
                                                description = "Tata case-control replication",
                                                getDbCaseDataArgs = getDbCaseDataArgs,
                                                selectControlsArgs = selectControlsArgs,
                                                getDbExposureDataArgs = getDbExposureDataArgs,
                                                createCaseControlDataArgs = createCaseControlDataArgs,
                                                fitCaseControlModelArgs = fitCaseControlModelArgs)

    ccAnalysisList <- list(ccAnalysis)

    CaseControl::saveCcAnalysisList(ccAnalysisList, file.path(workFolder, "ccAnalysisList.txt"))

    eon <- CaseControl::createExposureOutcomeNestingCohort(exposureId = 11,
                                                           outcomeId = 14)

    eons <- list(eon)
    CaseControl::saveExposureOutcomeNestingCohortList(eons, file.path(workFolder, "ccHypothesisOfInterest.txt"))

    # Tata study SCCS ---------------------------------------------------------

    getDbSccsDataArgs <- SelfControlledCaseSeries::createGetDbSccsDataArgs(studyStartDate = "19900101",
                                                                           studyEndDate = "20031101",
                                                                           exposureIds = c("exposureId", 5, 6))

    covarExposureOfInt <- SelfControlledCaseSeries::createCovariateSettings(label = "Exposure of interest",
                                                                            includeCovariateIds = "exposureId",
                                                                            start = 0,
                                                                            end = 0,
                                                                            addExposedDaysToEnd = TRUE)

    covarNsaids <- SelfControlledCaseSeries::createCovariateSettings(label = "NSAIDs",
                                                                     includeCovariateIds = 5,
                                                                     start = 0,
                                                                     end = 0,
                                                                     addExposedDaysToEnd = TRUE)

    covarTcas <- SelfControlledCaseSeries::createCovariateSettings(label = "TCAs",
                                                                   includeCovariateIds = 6,
                                                                   start = 0,
                                                                   end = 0,
                                                                   addExposedDaysToEnd = TRUE)

    covarPreExposure <- SelfControlledCaseSeries::createCovariateSettings(label = "Pre-exposure",
                                                                          includeCovariateIds = "exposureId",
                                                                          start = -30,
                                                                          end = -1)

    ageSettings <- SelfControlledCaseSeries::createAgeSettings(includeAge = TRUE,
                                                               ageKnots = 5,
                                                               minAge = 18)

    createSccsEraDataArgs <- SelfControlledCaseSeries::createCreateSccsEraDataArgs(naivePeriod = 180,
                                                                                   firstOutcomeOnly = FALSE,
                                                                                   covariateSettings = list(covarExposureOfInt,
                                                                                                            covarNsaids,
                                                                                                            covarTcas,
                                                                                                            covarPreExposure),
                                                                                   ageSettings = ageSettings)

    fitSccsModelArgs <- SelfControlledCaseSeries::createFitSccsModelArgs()

    sccsAnalysis <- SelfControlledCaseSeries::createSccsAnalysis(analysisId = 1,
                                                                 description = "Tata SCCS replication",
                                                                 getDbSccsDataArgs = getDbSccsDataArgs,
                                                                 createSccsEraDataArgs = createSccsEraDataArgs,
                                                                 fitSccsModelArgs = fitSccsModelArgs)

    sccsAnalysisList <- list(sccsAnalysis)

    SelfControlledCaseSeries::saveSccsAnalysisList(sccsAnalysisList,
                                                   file.path(workFolder, "sccsAnalysisList.txt"))

    eo <- SelfControlledCaseSeries::createExposureOutcome(exposureId = 11,
                                                          outcomeId = 14)
    eos <- list(eo)
    SelfControlledCaseSeries::saveExposureOutcomeList(eos, file.path(workFolder, "sccsHypothesisOfInterest.txt"))
}

