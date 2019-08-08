# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of finalWoo
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

#' Execute the Study
#'
#' @details
#' This function executes the finalWoo Study.
#' 
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cdmDatabaseName      Shareable name of the database 
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the target population cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createProtocol       Creates a protocol based on the analyses specification                             
#' @param createCohorts        Create the cohortTable table with the target population and outcome cohorts?
#' @param runAnalyses          Run the model development
#' @param createResultsDoc     Create a document containing the results of each prediction
#' @param createValidationPackage  Create a package for sharing the models 
#' @param analysesToValidate   A vector of analysis ids (e.g., c(1,3,10)) specifying which analysese to export into validation package. Default is NULL and all are exported.
#' @param packageResults       Should results be packaged for later sharing?     
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included 
#'                             in packaged results.
#' @param createShiny          Create a shiny app with the results
#' @param createJournalDocument Do you want to create a template journal document populated with results?
#' @param analysisIdDocument   Which Analysis_id do you want to create the document for?
#' @param verbosity            Sets the level of the verbosity. If the log level is at or higher in priority than the logger threshold, a message will print. The levels are:
#'                                         \itemize{
#'                                         \item{DEBUG}{Highest verbosity showing all debug statements}
#'                                         \item{TRACE}{Showing information about start and end of steps}
#'                                         \item{INFO}{Show informative information (Default)}
#'                                         \item{WARN}{Show warning messages}
#'                                         \item{ERROR}{Show error messages}
#'                                         \item{FATAL}{Be silent except for fatal errors}
#'                                         }                              
#' @param cdmVersion           The version of the common data model                             
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cdmDatabaseName = 'shareable name of the database'
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results", 
#'         createProtocol = T,
#'         createCohorts = T,
#'         runAnalyses = T,
#'         createResultsDoc = T,
#'         createValidationPackage = T,
#'         packageResults = F,
#'         minCellCount = 5,
#'         createShiny = F,
#'         verbosity = "INFO",
#'         cdmVersion = 5)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cdmDatabaseName = 'friendly database name',
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    createProtocol = F,
                    createCohorts = F,
                    runAnalyses = F,
                    createResultsDoc = F,
                    createValidationPackage = F,
                    analysesToValidate = NULL,
                    packageResults = F,
                    minCellCount= 5,
                    createShiny = F,
                    createJournalDocument = F,
                    analysisIdDocument = 1,
                    verbosity = "INFO",
                    cdmVersion = 5) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  
  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "log.txt"))
  
  if(createProtocol){
    createPlpProtocol(outputFolder)
  }
  
  if (createCohorts) {
    ParallelLogger::logInfo("Creating cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
  }
  
  if(runAnalyses){
    ParallelLogger::logInfo("Running predictions")
    predictionAnalysisListFile <- system.file("settings",
                                              "predictionAnalysisList.json",
                                              package = "finalWoo")
    predictionAnalysisList <- PatientLevelPrediction::loadPredictionAnalysisList(predictionAnalysisListFile)
    predictionAnalysisList$connectionDetails = connectionDetails
    predictionAnalysisList$cdmDatabaseSchema = cdmDatabaseSchema
    predictionAnalysisList$cdmDatabaseName = cdmDatabaseName
    predictionAnalysisList$oracleTempSchema = oracleTempSchema
    predictionAnalysisList$cohortDatabaseSchema = cohortDatabaseSchema
    predictionAnalysisList$cohortTable = cohortTable
    predictionAnalysisList$outcomeDatabaseSchema = cohortDatabaseSchema
    predictionAnalysisList$outcomeTable = cohortTable
    predictionAnalysisList$cdmVersion = cdmVersion
    predictionAnalysisList$outputFolder = outputFolder
    predictionAnalysisList$verbosity = verbosity
    
    result <- do.call(PatientLevelPrediction::runPlpAnalyses, predictionAnalysisList)
  }
  
  if (packageResults) {
    ParallelLogger::logInfo("Packaging results")
    packageResults(outputFolder = outputFolder,
                   minCellCount = minCellCount)
  }
  
  if(createResultsDoc){
    createMultiPlpReport(analysisLocation=outputFolder,
                         protocolLocation = file.path(outputFolder,'protocol.docx'),
                         includeModels = F)
  }
  
  if(createValidationPackage){
    predictionAnalysisListFile <- system.file("settings",
                                              "predictionAnalysisList.json",
                                              package = "finalWoo")
    jsonSettings <-  tryCatch({Hydra::loadSpecifications(file=predictionAnalysisListFile)},
                              error=function(cond) {
                                stop('Issue with json file...')
                              })
    pn <- jsonlite::fromJSON(jsonSettings)$packageName
    jsonSettings <- gsub(pn,paste0(pn,'Validation'),jsonSettings)
    jsonSettings <- gsub('PatientLevelPredictionStudy','PatientLevelPredictionValidationStudy',jsonSettings)
    
    
    createValidationPackage(modelFolder = outputFolder, 
                            outputFolder = file.path(outputFolder, paste0(pn,'Validation')),
                            minCellCount = minCellCount,
                            databaseName = cdmDatabaseName,
                            jsonSettings = jsonSettings,
                            analysisIds = analysesToValidate)
  }
  
  if (createShiny) {
    populateShinyApp(resultDirectory = outputFolder,
                     minCellCount = minCellCount,
                     databaseName = cdmDatabaseName)
  }
  
  if(createJournalDocument){
    predictionAnalysisListFile <- system.file("settings",
                                              "predictionAnalysisList.json",
                                              package = "finalWoo")
    jsonSettings <-  tryCatch({Hydra::loadSpecifications(file=predictionAnalysisListFile)},
                              error=function(cond) {
                                stop('Issue with json file...')
                              })
    pn <- jsonlite::fromJSON(jsonSettings)
    createJournalDocument(resultDirectory = outputFolder,
                                      analysisId = analysisIdDocument, 
                                      includeValidation = T,
                                      cohortIds = pn$cohortDefinitions$id,
                                      cohortNames = pn$cohortDefinitions$name)
  }
  
  
  invisible(NULL)
}




