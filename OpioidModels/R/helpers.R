# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of OpioidModels package
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


#' Creates the target and outcome cohorts
#'
#' @details
#' This will create the risk prediciton cohorts
#'
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#'
#' @return
#' A summary of the cohort counts
#'
#' @export
createOpioidTables <- function(connectionDetails,
                               cdmDatabaseSchema,
                               cohortDatabaseSchema,
                               cohortTable){

  connection <- DatabaseConnector::connect(connectionDetails)

  #checking whether cohort table exists and creating if not..
  # create the cohort table if it doesnt exist
  existTab <- toupper(cohortTable)%in%toupper(DatabaseConnector::getTableNames(connection, cohortDatabaseSchema))
  if(!existTab){
    sql <- SqlRender::loadRenderTranslateSql("createTable.sql",
                                             packageName = "OpioidModels",
                                             dbms = attr(connection, "dbms"),
                                             target_database_schema = cohortDatabaseSchema,
                                             target_cohort_table = cohortTable)
    DatabaseConnector::executeSql(connection, sql)
  }

  result <- PatientLevelPrediction::createCohort(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                       cohortDatabaseSchema = cohortDatabaseSchema,
                                       cohortTable = cohortTable,
                                       package = 'OpioidModels')


  return(result)
}


#' Validates the opioid use disorder prediction models
#'
#' @details
#' This will run and evaluate a selected opioid use disorder prediction models
#'
#' @param model         The model to apply ('simple','ccae','optum','mdcr','mdcd')
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#' @param outcomeDatabaseSchema The schema holding the outcome table
#' @param outcomeTable         The name of the outcome table
#' @param targetId          The cohort definition id of the target population
#' @param outcomeId         The cohort definition id of the outcome
#' @param oracleTempSchema   The temp schema for oracle
#'
#' @return
#' A list with the performance and plots
#'
#' @export
validateOpioidModels <- function(model='simple',
                                 connectionDetails,
                                 cdmDatabaseSchema,
                                 cohortDatabaseSchema,
                                 cohortTable,
                                 cohortId = 1,
                                 outcomeDatabaseSchema,
                                 outcomeTable,
                                 outcomeId = 2,
                                 oracleTempSchema=NULL){

  if(!model%in%c('simple','ccae','optum','mdcr','mdcd')){
    stop('Incorrect model...')
  }
  if(missing(connectionDetails)){
    stop('Missing connectionDetails')
  }
  if(missing(cdmDatabaseSchema)){
    stop('Missing cdmDatabaseSchema')
  }
  if(missing(cohortDatabaseSchema)){
    stop('Missing cohortDatabaseSchema')
  }
  if(missing(cohortTable)){
    stop('Missing cohortTable')
  }
  if(missing(cohortId)){
    stop('Missing cohortId')
  }
  if(missing(outcomeDatabaseSchema)){
    stop('Missing outcomeDatabaseSchema')
  }
  if(missing(outcomeTable)){
    stop('Missing outcomeTable')
  }
  if(missing(outcomeId)){
    stop('Missing outcomeId')
  }

  writeLines(paste0('Implementing ',model,' opioid risk model...'))

  if(model=='simple'){
    conceptSets <- system.file("extdata", "opioid_concepts.csv", package = "OpioidModels")
    conceptSets <- read.csv(conceptSets)

    modelTable <- system.file("extdata", "opioid_modelTable.csv", package = "OpioidModels")
    modelTable <- read.csv(modelTable)
    modelTable <- modelTable[,c('modelId','modelCovariateId','coefficientValue')]

    covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = T,
                                                                    useConditionOccurrenceLongTerm = T,
                                                                    useConditionGroupEraLongTerm = T,
                                                                    useProcedureOccurrenceShortTerm = T,
                                                                    useObservationShortTerm = T,
                                                                    shortTermStartDays = -30,
                                                                    longTermStartDays = -9999)

    result <- PatientLevelPrediction::evaluateExistingModel(modelTable = modelTable,
                                                            covariateTable = conceptSets[,c('modelCovariateId','covariateId')],
                                                            interceptTable = NULL,
                                                            type = 'score',
                                                            covariateSettings = covariateSettings,
                                                            riskWindowStart = 1,
                                                            riskWindowEnd = 365,
                                                            requireTimeAtRisk = T,
                                                            minTimeAtRisk = 364,
                                                            includeAllOutcomes = T,
                                                            removeSubjectsWithPriorOutcome = T,
                                                            connectionDetails = connectionDetails,
                                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                                            cohortDatabaseSchema = cohortDatabaseSchema,
                                                            cohortTable = cohortTable,
                                                            cohortId = cohortId,
                                                            outcomeDatabaseSchema = outcomeDatabaseSchema,
                                                            outcomeTable = outcomeTable,
                                                            outcomeId = outcomeId,
                                                            calibrationPopulation=NULL)

    inputSetting <- list(connectionDetails=connectionDetails,
                         cdmDatabaseSchema=cdmDatabaseSchema,
                         cohortDatabaseSchema=cohortDatabaseSchema,
                         outcomeDatabaseSchema=outcomeDatabaseSchema,
                         cohortTable=cohortTable,
                         outcomeTable=outcomeTable,
                         cohortId=cohortId,
                         outcomeId=outcomeId,
                         oracleTempSchema=oracleTempSchema)
    result <- list(model=list(model=model),
                   analysisRef ='000000',
                   inputSetting =inputSetting,
                   executionSummary = 'Not available',
                   prediction=result$prediction,
                   performanceEvaluation=result$performance)
    class(result$model) <- 'plpModel'
    attr(result$model, "type")<- 'existing model'
    class(result) <- 'runPlp'
    return(result)

  }else{
    #load model
    plpResult <- PatientLevelPrediction::loadPlpResult(system.file('plp_models',model, package='OpioidModels'))

    # newData
      newData <- PatientLevelPrediction::similarPlpData(plpModel = plpResult$model,
                                                        createCohorts = F,
                                                        newConnectionDetails = connectionDetails,
                                                        newCdmDatabaseSchema = cdmDatabaseSchema,
                                                        newCohortDatabaseSchema = cohortDatabaseSchema,
                                                        newCohortTable = cohortTable,
                                                        newCohortId = cohortId,
                                                        newOutcomeDatabaseSchema = outcomeDatabaseSchema,
                                                        newOutcomeTable = outcomeTable,
                                                        newOutcomeId = outcomeId,
                                                        sample = NULL,
                                                        createPopulation = T)
    #apply model
      results <- PatientLevelPrediction::applyModel(population = newData$population,
                                                   plpData = newData$plpData,
                                                   plpModel = plpResult$model,
                                                   calculatePerformance = T)

  }


 return(results)
}




#' Apply the opioid use disorder prediction models
#'
#' @details
#' This will run a selected opioid use disorder prediction models
#'
#' @param model         The model to apply ('simple','ccae','optum','mdcr','mdcd')
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#' @param targetId          The cohort definition id of the target population
#' @param oracleTempSchema   The temp schema for oracle
#'
#' @return
#' The prediction on the cohort
#'
#' @export
applyOpioidModel <- function(model='simple',
                                 connectionDetails,
                                 cdmDatabaseSchema,
                                 cohortDatabaseSchema,
                                 cohortTable,
                                 cohortId = 1,
                                 oracleTempSchema=NULL){

  if(!model%in%c('simple','ccae','optum','mdcr','mdcd')){
    stop('Incorrect model...')
  }
  if(missing(connectionDetails)){
    stop('Missing connectionDetails')
  }
  if(missing(cdmDatabaseSchema)){
    stop('Missing cdmDatabaseSchema')
  }
  if(missing(cohortDatabaseSchema)){
    stop('Missing cohortDatabaseSchema')
  }
  if(missing(cohortTable)){
    stop('Missing cohortTable')
  }
  if(missing(cohortId)){
    stop('Missing cohortId')
  }

  writeLines(paste0('Applying ',model,' opioid risk model...'))

  if(model=='simple'){
    conceptSets <- system.file("extdata", "opioid_concepts.csv", package = "OpioidModels")
    conceptSets <- read.csv(conceptSets)

    modelTable <- system.file("extdata", "opioid_modelTable.csv", package = "OpioidModels")
    modelTable <- read.csv(modelTable)
    modelTable <- modelTable[,c('modelId','modelCovariateId','coefficientValue')]

    covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = T,
                                                                    useConditionOccurrenceLongTerm = T,
                                                                    useConditionGroupEraLongTerm = T,
                                                                    useProcedureOccurrenceShortTerm = T,
                                                                    useObservationShortTerm = T,
                                                                    shortTermStartDays = -30,
                                                                    longTermStartDays = -9999)

    custCovs <- PatientLevelPrediction::createExistingModelSql(modelTable = modelTable,
                                                   modelNames = 'simple',
                                                   interceptTable = NULL,
                                                   covariateTable = conceptSets[,c('modelCovariateId','covariateId')],
                                                   type='score',
                                                   analysisId = 998,
                                                   covariateSettings = covariateSettings,
                                                   asFunctions=T)
    createExistingmodelsCovariateSettings <- custCovs$createExistingmodelsCovariateSettings
    getExistingmodelsCovariateSettings <- custCovs$getExistingmodelsCovariateSettings
    assign(paste0('getExistingmodelsCovariateSettings'), custCovs$getExistingmodelsCovariateSettings
           ,envir = globalenv())

    plpData <- PatientLevelPrediction::getPlpData(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                       oracleTempSchema = oracleTempSchema,
                                       cohortId = cohortId,
                                       outcomeIds = -999,
                                       cohortDatabaseSchema = cohortDatabaseSchema,
                                       cohortTable = cohortTable,
                                       outcomeDatabaseSchema = cohortDatabaseSchema,
                                       outcomeTable = cohortTable,
                                       washoutPeriod = 0,
                                       firstExposureOnly = F,
                                       sampleSize = NULL,
                                       covariateSettings = createExistingmodelsCovariateSettings())

    result <- ff::as.ram(plpData$covariates)

  }else{
    #load model
    plpResult <- PatientLevelPrediction::loadPlpResult(system.file('plp_models',model, package='OpioidModels'))

    # newData
    plpData <- PatientLevelPrediction::similarPlpData(plpModel = plpResult$model,
                                                      createCohorts = F,
                                                      newConnectionDetails = connectionDetails,
                                                      newCdmDatabaseSchema = cdmDatabaseSchema,
                                                      newCohortDatabaseSchema = cohortDatabaseSchema,
                                                      newCohortTable = cohortTable,
                                                      newCohortId = cohortId,
                                                      newOutcomeDatabaseSchema = cohortDatabaseSchema,
                                                      newOutcomeTable = cohortTable,
                                                      newOutcomeId = -999,
                                                      sample = NULL,
                                                      createPopulation = F)
    #apply model
    result <- PatientLevelPrediction::applyModel(population = plpData$cohorts,
                                                 plpData = plpData,
                                                 plpModel = plpResult$model,
                                                 calculatePerformance = F)

  }


  return(result)
}


flog.warn <- OhdsiRTools::logInfo
