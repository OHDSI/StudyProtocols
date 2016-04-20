# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of CelecoxibPredictiveModels
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

#' Create the exposure and outcome cohorts
#'
#' @details
#' This function creates the predictive outcomes for the different outcomes.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the \code{\link[DatabaseConnector]{createConnectionDetails}}
#' function in the DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include
#' both the database and schema name, for example 'cdm_data.dbo'.
#' @param workDatabaseSchema   Schema name where intermediate data can be stored. You will need to have write priviliges in this schema. Note that
#' for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
#' @param studyCohortTable     The name of the table that will be created in the work database schema. This table will hold the exposure and outcome
#' cohorts used in this study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.
#' @param cdmVersion           Version of the CDM. Can be "4" or "5"
#' @param outputFolder	       Name of local folder to place results; make sure to use forward slashes (/)
#'
#' @export
createPredictiveModels <- function(connectionDetails,
                                   cdmDatabaseSchema,
                                   workDatabaseSchema,
                                   studyCohortTable = "ohdsi_celecoxib_prediction",
                                   oracleTempSchema,
                                   gap=1,
                                   cdmVersion = 5,
                                   outputFolder,
                                   updateProgress=NULL) {

    outcomeIds <- 10:16
    minOutcomeCount <- 25

    database <- strsplit(cdmDatabaseSchema, '\\.')[[1]][1]
    plpDataFile <- file.path(outputFolder, paste("plpData", toupper(database), sep='_'))
    if (file.exists(plpDataFile)) {
        if (is.function(updateProgress)) {
            updateProgress(detail = "\n Data extracted...")
        }
        warning('Loaded existing plpData - change outputFolder if you want new data')
        plpData <- PatientLevelPrediction::loadPlpData(plpDataFile)
    } else {
        if (is.function(updateProgress)) {
            updateProgress(detail = "\n Extracting data...")
        }
        writeLines("- Extracting cohorts/covariates/outcomes")
        conn <- DatabaseConnector::connect(connectionDetails)
        sql <- "SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = 1118084"
        sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql
        sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
        celecoxibDrugs <- DatabaseConnector::querySql(conn, sql)
        celecoxibDrugs <- celecoxibDrugs[,1]
        RJDBC::dbDisconnect(conn)

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
                                                                             excludedCovariateConceptIds = celecoxibDrugs,
                                                                             includedCovariateConceptIds = c(),
                                                                             deleteCovariatesSmallCount = 100)




        plpData <- PatientLevelPrediction::getDbPlpData(connectionDetails,
                                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                                        cohortDatabaseSchema = workDatabaseSchema,
                                                        cohortTable = studyCohortTable,
                                                        cohortId = 1,
                                                        washoutPeriod = 365,
                                                        studyStartDate = "",
                                                        studyEndDate = "",
                                                        covariateSettings = covariateSettings,
                                                        outcomeDatabaseSchema = workDatabaseSchema,
                                                        outcomeTable = studyCohortTable,
                                                        outcomeIds = outcomeIds,
                                                        cdmVersion = cdmVersion)


        PatientLevelPrediction::savePlpData(plpData, plpDataFile)

    }

    for (outcomeId in outcomeIds){
        if (is.function(updateProgress)) {
            updateProgress(detail = paste0("\n Creating model for outcome: ", outcomeId)  )
        }
        writeLines(paste0('Creating models for outcome: ', outcomeId))

        if(file.exists(file.path(outputFolder,'modelInfo.txt'))){
            # check modelInfo+performance to find if already done
            models <- read.table(file.path(outputFolder,'modelInfo.txt'), header=T)

            done <- sum(models[,'cohortId']==1 &
                            models[,'outcomeId']==outcomeId &
                            models[,'database'] == strsplit(cdmDatabaseSchema, '\\.')[[1]][1]  )>0
        } else{done<-F}
        if (!done){

            writeLines(paste("-creating study population for outcome", outcomeId))
            population <- PatientLevelPrediction::createStudyPopulation(plpData,
                                                                        outcomeId=outcomeId,
                                                                        binary=T,
                                                                        firstExposureOnly=T,
                                                                        washoutPeriod =365,
                                                                        removeSubjectsWithPriorOutcome = TRUE, priorOutcomeLookback = 365,
                                                                        requireTimeAtRisk = T, minTimeAtRisk = 0, riskWindowStart = gap,
                                                                        addExposureDaysToStart = FALSE, riskWindowEnd = 365+gap,
                                                                        addExposureDaysToEnd = F, silent = F)

            if(!is.null(population)){
            writeLines(paste("- Training model for outcome", outcomeId))

            modelSet <- PatientLevelPrediction::logisticRegressionModel(variance=0.01)
            model <- tryCatch({
                PatientLevelPrediction::developModel(population, plpData,
                                                     featureSettings = NULL,
                                                     modelSettings=modelSet,
                                                     testSplit = "person",
                                                     testFraction = 0.3, nfold = 3,
                                                     indexes = NULL,
                                                     dirPath = outputFolder,
                                                     silent = F)},
                error = function(err) {
                    # error handler picks up where error was generated
                    print(paste("MY_ERROR:  ",err))
                    return(NULL)
                }
            )

            } else {
                warning(paste0('Populatation for outcome ',outcomeId, ' NULL - model skipped'))
            }

        } else {writeLines('Model already exists')}
    }
}
