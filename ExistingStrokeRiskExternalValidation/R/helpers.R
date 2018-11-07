# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of Existing Stroke Risk External Valiation study
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


#' Create and summarise the target and outcome cohorts
#'
#' @details
#' This will create the risk prediciton cohorts and then count the table sizes
#'
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#' @param targetId          The cohort definition id of the target population
#' @param outcomeIds         The cohort definition ids of the outcomes
#'
#' @return
#' A summary of the cohort counts
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                          cohortTable,
                          targetId,
                          outcomeIds){

  cohortDetails <- NULL
  if(!missing(outcomeIds)){
    if(length(unique(outcomeIds))!=4){
      stop('Need to enter four outcome ids')
    }
    if(length(targetId)!=1){
      stop('Need to enter one target id')
    }

    cohortDetails <- data.frame(cohortName=c('Females newly diagnosed with atrial fibrilation aged 65 to 95',
                                       'Stroke definition 1 Broad stroke Inpatient',
                                       'Stroke definition 2 Broad stroke',
                                       'Stroke definition 3 Haemorrhagic stroke',
                                       'Stroke definition 4 Ischaemic stroke'),
                          cohortId = c(targetId, outcomeIds))

    }

  connection <- DatabaseConnector::connect(connectionDetails)

  #checking whether cohort table exists and creating if not..
  # create the cohort table if it doesnt exist
  existTab <- toupper(cohortTable)%in%toupper(DatabaseConnector::getTableNames(connection, cohortDatabaseSchema))
  if(!existTab){
    sql <- SqlRender::loadRenderTranslateSql("createTable.sql",
                                             packageName = "ExistingStrokeRiskExternalValidation",
                                             dbms = attr(connection, "dbms"),
                                             target_database_schema = cohortDatabaseSchema,
                                             target_cohort_table = cohortTable)
    DatabaseConnector::executeSql(connection, sql)
  }

  if(is.null(cohortDetails)){
  result <- PatientLevelPrediction::createCohort(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                       cohortDatabaseSchema = cohortDatabaseSchema,
                                       cohortTable = cohortTable,
                                       package = 'ExistingStrokeRiskExternalValidation')
  } else {
    result <- PatientLevelPrediction::createCohort(cohortDetails = cohortDetails,
                                                   connectionDetails = connectionDetails,
                                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                                   cohortDatabaseSchema = cohortDatabaseSchema,
                                                   cohortTable = cohortTable,
                                                   package = 'ExistingStrokeRiskExternalValidation')
  }

  print(result)

  return(result)
}

#' Creates the target population and outcome summary characteristics
#'
#' @details
#' This will create the patient characteristic table
#'
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#' @param targetId          The cohort definition id of the target population
#' @param outcomeId         The cohort definition id of the outcome
#' @param tempCohortTable   The name of the temporary table used to hold the cohort
#'
#' @return
#' A dataframe with the characteristics
#'
#' @export
getTable1 <- function(connectionDetails,
                      cdmDatabaseSchema,
                      cohortDatabaseSchema,
                      cohortTable,
                      targetId,
                      outcomeId,
                      tempCohortTable='#temp_cohort'){

  covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T)

  plpData <- PatientLevelPrediction::getPlpData(connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortId = targetId, outcomeIds = outcomeId,
                                     cohortDatabaseSchema = cohortDatabaseSchema,
                                     outcomeDatabaseSchema = cohortDatabaseSchema,
                                     cohortTable = cohortTable,
                                     outcomeTable = cohortTable,
                                     covariateSettings=covariateSettings)

  population <- PatientLevelPrediction::createStudyPopulation(plpData = plpData,
                                                              outcomeId = outcomeId,
                                                              binary = T,
                                                              includeAllOutcomes = T,
                                                              requireTimeAtRisk = T,
                                                              minTimeAtRisk = 364,
                                                              riskWindowStart = 1,
                                                              riskWindowEnd = 365,
                                                              removeSubjectsWithPriorOutcome = T)

  table1 <- PatientLevelPrediction::getPlpTable(cdmDatabaseSchema = cdmDatabaseSchema,
                                                longTermStartDays = -9999,
                                                population=population,
                                                connectionDetails=connectionDetails,
                                                cohortTable=tempCohortTable)

  return(table1)
}

#' Applies the five existing stroke prediction models
#'
#' @details
#' This will run and evaluate five existing stroke risk prediction models
#'
#' @param connectioDetails The connections details for connecting to the CDM
#' @param cdmDatabaseSchema  The schema holding the CDM data
#' @param cohortDatabaseSchema The schema holding the cohort table
#' @param cohortTable         The name of the cohort table
#' @param targetId          The cohort definition id of the target population
#' @param outcomeId         The cohort definition id of the outcome
#'
#' @return
#' A list with the performance and plots
#'
#' @export
applyExistingstrokeModels <- function(connectionDetails,
                                      cdmDatabaseSchema,
                                      cohortDatabaseSchema,
                                      cohortTable,
                                      targetId,
                                      outcomeId){

  writeLines('Implementing Astria stroke risk model...')
  astria <- PredictionComparison::atriaStrokeModel(connectionDetails, cdmDatabaseSchema,
                                       cohortDatabaseSchema = cohortDatabaseSchema,
                                       outcomeDatabaseSchema = cohortDatabaseSchema,
                                       cohortTable = cohortTable,
                                       outcomeTable = cohortTable,
                                       cohortId = targetId, outcomeId = outcomeId,
                                       removePriorOutcome=T,
                                       riskWindowStart = 1,
                                       riskWindowEnd = 365,
                                       requireTimeAtRisk = T,
                                       minTimeAtRisk = 364, includeAllOutcomes = T)

  writeLines('Implementing Qstroke stroke risk model...')
  qstroke <- PredictionComparison::qstrokeModel(connectionDetails, cdmDatabaseSchema,
                                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                                 outcomeDatabaseSchema = cohortDatabaseSchema,
                                                 cohortTable = cohortTable,
                                                 outcomeTable = cohortTable,
                                                 cohortId = targetId, outcomeId = outcomeId,
                                                 removePriorOutcome=T,
                                                riskWindowStart = 1,
                                                riskWindowEnd = 365,
                                                requireTimeAtRisk = T,
                                                minTimeAtRisk = 364, includeAllOutcomes = T)

  writeLines('Implementing Framington stroke risk model...')
  framington <- PredictionComparison::framinghamModel(connectionDetails, cdmDatabaseSchema,
                                              cohortDatabaseSchema = cohortDatabaseSchema,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              cohortTable = cohortTable,
                                              outcomeTable = cohortTable,
                                              cohortId = targetId, outcomeId = outcomeId,
                                              removePriorOutcome=T,
                                              riskWindowStart = 1,
                                              riskWindowEnd = 365,
                                              requireTimeAtRisk = T,
                                              minTimeAtRisk = 364, includeAllOutcomes = T)

  writeLines('Implementing chads2 stroke risk model...')
  chads2 <- PredictionComparison::chads2Model(connectionDetails, cdmDatabaseSchema,
                                              cohortDatabaseSchema = cohortDatabaseSchema,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              cohortTable = cohortTable,
                                              outcomeTable = cohortTable,
                                              cohortId = targetId, outcomeId = outcomeId,
                                              removePriorOutcome=T,
                                              riskWindowStart = 1,
                                              riskWindowEnd = 365,
                                              requireTimeAtRisk = T,
                                              minTimeAtRisk = 364, includeAllOutcomes = T)

  writeLines('Implementing chads2vas stroke risk model...')
  chads2vas <- PredictionComparison::chads2vasModel(connectionDetails, cdmDatabaseSchema,
                                              cohortDatabaseSchema = cohortDatabaseSchema,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              cohortTable = cohortTable,
                                              outcomeTable = cohortTable,
                                              cohortId = targetId, outcomeId = outcomeId,
                                              removePriorOutcome=T,
                                              riskWindowStart = 1,
                                              riskWindowEnd = 365,
                                              requireTimeAtRisk = T,
                                              minTimeAtRisk = 364, includeAllOutcomes = T)

# format the results... [TODO...]
  results <- list(astria=astria,
                  qstroke=qstroke,
                  framington=framington,
                  chads2=chads2,
                  chads2vas=chads2vas)

 return(results)
}

#' Submit the study results to the study coordinating center
#'
#' @details
#' This will upload the file \code{StudyResults.zip} to the study coordinating center using Amazon S3.
#' This requires an active internet connection.
#'
#' @param exportFolder   The path to the folder containing the \code{StudyResults.zip} file.
#' @param dbName         Database name used in the zipName
#' @param key            The key string as provided by the study coordinator
#' @param secret         The secret string as provided by the study coordinator
#'
#' @return
#' TRUE if the upload was successful.
#'
#' @export
submitResults <- function(exportFolder,dbName, key, secret) {
  zipName <- file.path(exportFolder, paste0(dbName,"-StudyResults.zip"))
  folderName <- file.path(exportFolder, paste0(dbName,"-StudyResults"))
  if (!dir.exists(folderName)) {
    dir.create(folderName, recursive = T)
  }

  # move all zipped files into folder
  files <- list.files(exportFolder)
  files <- files[grep('.zip', files)]
  for(file in files){
    file.copy(file.path(exportFolder,file), file.path(folderName), recursive=TRUE)
  }

  if(file.exists(file.path(exportFolder, 'predictionDetails.txt'))){
    file.copy(file.path(exportFolder, 'predictionDetails.txt'), file.path(folderName), recursive=TRUE)
  }

  # compress complete folder
  OhdsiSharing::compressFolder(folderName, zipName)
  # delete temp folder
  unlink(folderName, recursive = T)

  if (!file.exists(zipName)) {
    stop(paste("Cannot find file", zipName))
  }
  PatientLevelPrediction::submitResults(exportFolder = file.path(exportFolder, paste0(dbName,"-StudyResults.zip")),
                                        key =  key, secret = secret)


}


#' View the coefficients of the models in this study and the concept ids used to define them
#'
#'
#' @details
#' This will print the models and return a data.frame with the models
#'
#'
#' @return
#' A data.frame of the models
#'
#' @export
viewModels <- function(){
  conceptSets <- system.file("extdata", "existingStrokeModels_concepts.csv", package = "PredictionComparison")
  conceptSets <- read.csv(conceptSets)

  existingBleedModels <- system.file("extdata", "existingStrokeModels_modelTable.csv", package = "PredictionComparison")
  existingBleedModels <- read.csv(existingBleedModels)

  modelNames <- system.file("extdata", "existingStrokeModels_models.csv", package = "PredictionComparison")
  modelNames <- read.csv(modelNames)


  models <- merge(modelNames,merge(existingBleedModels[,c('modelId','modelCovariateId','Name','Time','coefficientValue')],
                                   conceptSets[,c('modelCovariateId','ConceptId','AnalysisId')]))
  models <- models[,c('name','Name','Time','coefficientValue','ConceptId','AnalysisId')]
  colnames(models)[1:2] <- c('Model','Covariate')
  models[,1] <- as.character(models[,1])
  models[,2] <- as.character(models[,2])
  models <- rbind(models, c('Chads2','FeatureExtraction covariate','',0,0,0))
  models <- rbind(models, c('Chads2Vas','FeatureExtraction covariate','',0,0,0))

  View(models)
  return(models)
}
