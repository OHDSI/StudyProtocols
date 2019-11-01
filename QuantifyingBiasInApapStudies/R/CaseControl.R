# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of QuantifyingBiasInApapStudies
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

#' Run CohortMethod package
#'
#' @details
#' Run the CohortMethod package, which implements the comparative cohort design.
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
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
runCaseControl <- function(connectionDetails,
                           cdmDatabaseSchema,
                           cohortDatabaseSchema,
                           cohortTable,
                           oracleTempSchema,
                           outputFolder,
                           maxCores) {
  ccOutputFolder <- file.path(outputFolder, "ccOutput")
  if (!file.exists(ccOutputFolder)) {
    dir.create(ccOutputFolder)
  }
  ccAnalysisListFile <- system.file("settings",
                                    "ccAnalysisList.json",
                                    package = "QuantifyingBiasInApapStudies")
  ccAnalysisList <- CaseControl::loadCcAnalysisList(ccAnalysisListFile)
  tosList <- createTos(outputFolder = outputFolder)
  # Note: using just 1 thread to get exposure data because bulk upload otherwise fails
  results <- CaseControl::runCcAnalyses(connectionDetails = connectionDetails,
                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                        exposureDatabaseSchema = cohortDatabaseSchema,
                                        exposureTable = cohortTable,
                                        outcomeDatabaseSchema = cohortDatabaseSchema,
                                        outcomeTable = cohortTable,
                                        outputFolder = ccOutputFolder,
                                        oracleTempSchema = cohortDatabaseSchema,
                                        ccAnalysisList = ccAnalysisList,
                                        exposureOutcomeNestingCohortList = tosList,
                                        prefetchExposureData = TRUE,
                                        compressCaseDataFiles = TRUE,
                                        getDbCaseDataThreads = min(3, maxCores),
                                        selectControlsThreads = min(5, maxCores),
                                        getDbExposureDataThreads = 1,
                                        createCaseControlDataThreads = min(5, maxCores),
                                        fitCaseControlModelThreads =  min(5, maxCores))
  
  ParallelLogger::logInfo("Summarizing results")
  analysisSummary <- CaseControl::summarizeCcAnalyses(outcomeReference = results, 
                                                      outputFolder = ccOutputFolder)
  analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
  analysisSummary <- addCcAnalysisDescription(analysisSummary, "analysisId", "analysisDescription")
  write.csv(analysisSummary, file.path(outputFolder, "ccAnalysisSummary.csv"), row.names = FALSE)
}

addCcAnalysisDescription <- function(data, IdColumnName = "analysisId", nameColumnName = "analysisDescription") {
  ccAnalysisListFile <- system.file("settings",
                                    "ccAnalysisList.json",
                                    package = "QuantifyingBiasInApapStudies")
  ccAnalysisList <- CaseControl::loadCcAnalysisList(ccAnalysisListFile)
  idToName <- lapply(ccAnalysisList, function(x) data.frame(analysisId = x$analysisId, description = as.character(x$description)))
  idToName <- do.call("rbind", idToName)
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data) , (idCol + 1):(ncol(data) - 1))]
  }
  return(data)
}

#' Create the case-control analyses details
#'
#' @details
#' This function creates files specifying the case-control analyses that will be performed.
#'
#' @param workFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#'
#' @export
createCcAnalysesDetails <- function(workFolder) {
  prior <- Cyclops::createPrior("none")
  
  getDbCaseDataArgs1 <- CaseControl::createGetDbCaseDataArgs(useNestingCohort = FALSE, 
                                                             getVisits = FALSE)
  
  
  samplingCriteria <- CaseControl::createSamplingCriteria(controlsPerCase = 4,
                                                          seed = 123)
  
  
  selectControlsArgs1 <- CaseControl::createSelectControlsArgs(firstOutcomeOnly = TRUE,
                                                               washoutPeriod = 365 * 2,
                                                               minAge = 30,
                                                               controlSelectionCriteria = samplingCriteria)
  
  # Excluding one gender (8507 = male) explicitly to avoid redundancy:
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                                                         useDemographicsGender = TRUE,
                                                                         useDemographicsIndexYear = TRUE,
                                                                         excludedCovariateConceptIds = 8507)
  
  customCovariateSettings <- createCustomCovariatesSettings(useBmi = TRUE,
                                                            useAlcohol = TRUE,
                                                            useSmoking = TRUE,
                                                            useDiabetesMedication = TRUE)
  
  covariateSettings1 <- list(defaultCovariateSettings, customCovariateSettings)
  
  getDbExposureDataArgs1 <- CaseControl::createGetDbExposureDataArgs(covariateSettings = covariateSettings1)
  
  createCaseControlDataArgs1 <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                                             riskWindowStart = -999990,
                                                                             riskWindowEnd = 0)
  
  fitCaseControlModelArgs1 <- CaseControl::createFitCaseControlModelArgs(useCovariates = TRUE,
                                                                         excludeCovariateIds = c(1999, 2999, 3999, 1998, 1997, 1996),
                                                                         prior = prior)
  
  ccAnalysis1 <- CaseControl::createCcAnalysis(analysisId = 1,
                                               description = "Sampling, all time prior, adj. for age, sex & year",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs1,
                                               getDbExposureDataArgs = getDbExposureDataArgs1,
                                               createCaseControlDataArgs = createCaseControlDataArgs1,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs1)
  
  fitCaseControlModelArgs2 <- CaseControl::createFitCaseControlModelArgs(useCovariates = TRUE,
                                                                         prior = prior)
  
  ccAnalysis2 <- CaseControl::createCcAnalysis(analysisId = 2,
                                               description = "Sampling, all time prior, adj. for age, sex, year, BMI, alcohol, smoking & diabetes",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs1,
                                               getDbExposureDataArgs = getDbExposureDataArgs1,
                                               createCaseControlDataArgs = createCaseControlDataArgs1,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs2)
  
  createCaseControlDataArgs2 <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                                             riskWindowStart = -999990,
                                                                             riskWindowEnd = -365)
  
  
  ccAnalysis3 <- CaseControl::createCcAnalysis(analysisId = 3,
                                               description = "Sampling, year delay, adj. for age, sex & year",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs1,
                                               getDbExposureDataArgs = getDbExposureDataArgs1,
                                               createCaseControlDataArgs = createCaseControlDataArgs2,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs1)
  
  ccAnalysis4 <- CaseControl::createCcAnalysis(analysisId = 4,
                                               description = "Sampling, year delay, adj. for age, sex, year, BMI, alcohol, smoking & diabetes",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs1,
                                               getDbExposureDataArgs = getDbExposureDataArgs1,
                                               createCaseControlDataArgs = createCaseControlDataArgs2,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs2)
  
  matchingCriteria <- CaseControl::createMatchingCriteria(controlsPerCase = 4,
                                                          matchOnAge = TRUE,
                                                          ageCaliper = 2,
                                                          matchOnGender = TRUE,
                                                          matchOnTimeInCohort = TRUE,
                                                          daysInCohortCaliper = 365,
                                                          matchOnCareSite = TRUE)
  
  selectControlsArgs2 <- CaseControl::createSelectControlsArgs(firstOutcomeOnly = TRUE,
                                                               washoutPeriod = 365 * 2,
                                                               minAge = 30,
                                                               controlSelectionCriteria = matchingCriteria)
  
  getDbExposureDataArgs2 <- CaseControl::createGetDbExposureDataArgs(covariateSettings = customCovariateSettings)
  
  fitCaseControlModelArgs3 <- CaseControl::createFitCaseControlModelArgs(useCovariates = FALSE,
                                                                         prior = prior)
  
  ccAnalysis5 <- CaseControl::createCcAnalysis(analysisId = 5,
                                               description = "Matching, all time prior",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs2,
                                               getDbExposureDataArgs = getDbExposureDataArgs2,
                                               createCaseControlDataArgs = createCaseControlDataArgs1,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs3)
  
  fitCaseControlModelArgs4<- CaseControl::createFitCaseControlModelArgs(useCovariates = TRUE,
                                                                         prior = prior)
  
  ccAnalysis6 <- CaseControl::createCcAnalysis(analysisId = 6,
                                               description = "Matching, all time prior, adj. for BMI, alcohol, smoking & diabetes",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs2,
                                               getDbExposureDataArgs = getDbExposureDataArgs2,
                                               createCaseControlDataArgs = createCaseControlDataArgs1,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs4)
  
  createCaseControlDataArgs2 <- CaseControl::createCreateCaseControlDataArgs(firstExposureOnly = FALSE,
                                                                             riskWindowStart = -999990,
                                                                             riskWindowEnd = -365)
  
  ccAnalysis7 <- CaseControl::createCcAnalysis(analysisId = 7,
                                               description = "Matching, year delay",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs2,
                                               getDbExposureDataArgs = getDbExposureDataArgs2,
                                               createCaseControlDataArgs = createCaseControlDataArgs2,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs3)
  
  ccAnalysis8 <- CaseControl::createCcAnalysis(analysisId = 8,
                                               description = "Matching, year delay, adj. for BMI, alcohol, smoking & diabetes",
                                               getDbCaseDataArgs = getDbCaseDataArgs1,
                                               selectControlsArgs = selectControlsArgs2,
                                               getDbExposureDataArgs = getDbExposureDataArgs2,
                                               createCaseControlDataArgs = createCaseControlDataArgs2,
                                               fitCaseControlModelArgs = fitCaseControlModelArgs4)
  
  ccAnalysisList <- list(ccAnalysis1, ccAnalysis2, ccAnalysis3, ccAnalysis4, ccAnalysis5, ccAnalysis6, ccAnalysis7, ccAnalysis8)
  CaseControl::saveCcAnalysisList(ccAnalysisList, file.path(workFolder, "ccAnalysisList.json"))
}

createTos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TosOfInterest.csv", package = "QuantifyingBiasInApapStudies")
  tosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
  negativeControls <- read.csv(pathToCsv)
  ts <- unique(tosOfInterest$targetId)
  createTo <- function(i) {
    targetId <- ts[i]
    outcomeIds <- as.character(tosOfInterest$outcomeIds[tosOfInterest$targetId == targetId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeIds <- c(outcomeIds, negativeControls$outcomeId[negativeControls$targetId == targetId])
    
    createSingleTo <- function(outcomeId) {
      CaseControl::createExposureOutcomeNestingCohort(exposureId = targetId, outcomeId = outcomeId)
    }
    to <- lapply(outcomeIds, createSingleTo)  
    return(to)
  }
  tosList <- lapply(1:length(ts), createTo)
  tosList <- do.call(c, tosList)
  return(tosList)
}
