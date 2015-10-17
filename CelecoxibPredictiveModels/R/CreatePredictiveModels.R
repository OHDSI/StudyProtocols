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
                                   cdmVersion = 5,
                                   outputFolder) {

    outcomeIds <- 10:16
    minOutcomeCount <- 25

    plpDataFile <- file.path(outputFolder, "plpData")
    if (file.exists(plpDataFile)) {
        plpData <- PatientLevelPrediction::loadPlpData(plpDataFile)
    } else {
        writeLines("- Extracting cohorts/covariates/outcomes")
        conn <- DatabaseConnector::connect(connectionDetails)
        sql <- "SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = 1118084"
        sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql
        sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
        celecoxibDrugs <- DatabaseConnector::querySql(conn, sql)
        celecoxibDrugs <- celecoxibDrugs[,1]
        RJDBC::dbDisconnect(conn)

        covariateSettings <- PatientLevelPrediction::createCovariateSettings(useCovariateDemographics = TRUE,
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
                                                        cohortIds = 1,
                                                        useCohortEndDate = FALSE,
                                                        windowPersistence = 365,
                                                        covariateSettings = covariateSettings,
                                                        outcomeDatabaseSchema = workDatabaseSchema,
                                                        outcomeTable = studyCohortTable,
                                                        outcomeIds = outcomeIds,
                                                        cdmVersion = cdmVersion)


        PatientLevelPrediction::savePlpData(plpData, plpDataFile)
    }

    trainPlpDataFile <- file.path(outputFolder, "trainPlptData")
    testPlpDataFile <- file.path(outputFolder, "testPlpData")
    if (file.exists(trainPlpDataFile) &&
        file.exists(testPlpDataFile)) {
        trainPlpData <- PatientLevelPrediction::loadPlpData(trainPlpDataFile)
    } else {
        writeLines("Creating train-test split")
        parts <- PatientLevelPrediction::splitData(plpData, c(0.75, 0.25))

        PatientLevelPrediction::savePlpData(parts[[1]], trainPlpDataFile)
        PatientLevelPrediction::savePlpData(parts[[2]], testPlpDataFile)

        trainPlpData <- parts[[1]]
        testPlpData <- parts[[2]]

        sumTrainPlpData <- summary(trainPlpData)
        sumTestPlpData <- summary(testPlpData)

        write.csv(c(summary(trainPlpData)$subjectCount, summary(trainPlpData)$windowCount), file.path(outputFolder, "trainCohortSize.csv"), row.names = FALSE)
        write.csv(addOutcomeNames(summary(trainPlpData)$outcomeCounts), file.path(outputFolder, "trainOutcomeCounts.csv"), row.names = FALSE)
        write.csv(c(summary(testPlpData)$subjectCount, summary(testPlpData)$windowCount), file.path(outputFolder, "testCohortSize.csv"), row.names = FALSE)
        write.csv(addOutcomeNames(summary(trainPlpData)$outcomeCounts), file.path(outputFolder, "testOutcomeCounts.csv"), row.names = FALSE)
    }
    counts <- summary(trainPlpData)$outcomeCounts
    for (outcomeId in outcomeIds){
        writeLines(paste(outcomeId))
        modelFile <- file.path(outputFolder, paste("model_o",outcomeId, ".rds", sep = ""))
        if (counts$eventCount[counts$outcomeId == outcomeId] > minOutcomeCount &&
            !file.exists(modelFile)){
            writeLines(paste("- Fitting model for outcome", outcomeId))
            control = Cyclops::createControl(noiseLevel = "quiet",
                                             cvType = "auto",
                                             startingVariance = 0.1,
                                             threads = 10)


            model <- PatientLevelPrediction::fitPredictiveModel(trainPlpData,
                                                                outcomeId = outcomeId,
                                                                modelType = "logistic",
                                                                control = control)
            saveRDS(model, modelFile)
        }
    }
}
