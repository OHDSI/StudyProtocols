# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
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



#' Create custom covariate settings
#'
#' @param useBmi                 Create a covariate for BMI (prior to cohort start).
#' @param useAlcohol             Create a covariate for alcohol use (prior to cohort start).
#' @param useSmoking             Create a covariate for smoking (prior to cohort start).
#' @param useDiabetesMedication  Create a covariate for diabetes (medication use) (prior to cohort start).
#' @param useRheumatoidArthritis Create a covariate for RA (prior to cohort start).
#' @param useNonRa               Create a covariate for non-RA, chronic back or chronic neck pain (prior to cohort start).
#' @param useFatigue             Create a covariate for fatigue or lack of energy (prior to cohort start).
#' @param useMigraine            Create a covariate for migraine or chronic headache (prior to cohort start).
#'
#' @export
createCustomCovariatesSettings <- function(useBmi = FALSE,
                                           useAlcohol = FALSE,
                                           useSmoking = FALSE,
                                           useDiabetesMedication = FALSE,
                                           useRheumatoidArthritis = FALSE,
                                           useNonRa = FALSE,
                                           useFatigue = FALSE,
                                           useMigraine = FALSE) {
  covariateSettings <- list(useBmi = useBmi,
                            useAlcohol = useAlcohol,
                            useSmoking = useSmoking,
                            useDiabetesMedication = useDiabetesMedication,
                            useRheumatoidArthritis = useRheumatoidArthritis,
                            useNonRa = useNonRa,
                            useFatigue = useFatigue,
                            useMigraine = useMigraine)
  attr(covariateSettings, "fun") <- "QuantifyingBiasInApapStudies::getDbCustomCovariatesData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' Get custom covariate information from the database
#'
#' @description
#' Constructs custom covariates for a cohort.
#'
#' @param covariateSettings   An object of type \code{covariateSettings} as created using the
#'                            \code{\link{createCustomCovariatesSettings}} function.
#'
#' @details
#' This function uses the data in the CDM to construct a large set of covariates for the provided
#' cohort. The cohort is assumed to be in an existing temp table with these fields: 'subject_id',
#' 'cohort_definition_id', 'cohort_start_date'. Optionally, an extra field can be added containing the
#' unique identifier that will be used as rowID in the output. Typically, users don't call this
#' function directly.
#'
#' @param connection          A connection to the server containing the schema as created using the
#'                            \code{connect} function in the \code{DatabaseConnector} package.
#' @param oracleTempSchema    A schema where temp tables can be created in Oracle.
#' @param cdmDatabaseSchema   The name of the database schema that contains the OMOP CDM instance.
#'                            Requires read permissions to this database. On SQL Server, this should
#'                            specifiy both the database and the schema, so for example
#'                            'cdm_instance.dbo'.
#' @param cohortTable         Name of the table holding the cohort for which we want to construct
#'                            covariates. If it is a temp table, the name should have a hash prefix,
#'                            e.g. '#temp_table'. If it is a non-temp table, it should include the
#'                            database schema, e.g. 'cdm_database.cohort'.
#' @param cohortId            For which cohort ID should covariates be constructed? If set to -1,
#'                            covariates will be constructed for all cohorts in the specified cohort
#'                            table.
#' @param cdmVersion          The version of the Common Data Model used. Currently only 
#'                            \code{cdmVersion = "5"} is supported.
#' @param rowIdField          The name of the field in the cohort temp table that is to be used as the
#'                            row_id field in the output table. This can be especially usefull if there
#'                            is more than one period per person.
#' @param aggregated          Should aggregate statistics be computed instead of covariates per
#'                            cohort entry? 
#'
#' @return
#' Returns an object of type \code{covariateData}, containing information on the baseline covariates.
#' Information about multiple outcomes can be captured at once for efficiency reasons. This object is
#' a list with the following components: \describe{ \item{covariates}{An ffdf object listing the
#' baseline covariates per person in the cohorts. This is done using a sparse representation:
#' covariates with a value of 0 are omitted to save space. The covariates object will have three
#' columns: rowId, covariateId, and covariateValue. The rowId is usually equal to the person_id,
#' unless specified otherwise in the rowIdField argument.} \item{covariateRef}{An ffdf object
#' describing the covariates that have been extracted.} \item{metaData}{A list of objects with
#' information on how the covariateData object was constructed.} }
#'
#' @export
getDbCustomCovariatesData <- function(connection,
                                      oracleTempSchema = NULL,
                                      cdmDatabaseSchema,
                                      cohortTable = "#cohort_person",
                                      cohortId = -1,
                                      cdmVersion = "5",
                                      rowIdField = "subject_id",
                                      covariateSettings,
                                      aggregated = FALSE) {
  if (aggregated)
    stop("Aggregation not supported")
  ParallelLogger::logInfo("Creating custom covariates")
  covariates <- data.frame()
  covariateRef <- data.frame()
  analysisRef <- data.frame()
  
  if (covariateSettings$useBmi) {
    analysisId <- 999
    sql <- SqlRender::loadRenderTranslateSql("CreateBmiCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = c(1000, 2000, 3000) + analysisId,
                                     covariateName = c("BMI < 25", "25 <= BMI < 30", "BMI >= 30"),
                                     analysisId = analysisId,
                                     conceptId = 3036277))
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "BMI",
                                    domainId = "Measurement",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useAlcohol) {
    analysisId <- 998
    sql <- SqlRender::loadRenderTranslateSql("CreateAlcoholCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "Regular alcohol drinker",
                                     analysisId = analysisId,
                                     conceptId = 40770351))
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Alcohol",
                                    domainId = "ObserVation",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))    
  }
  if (covariateSettings$useSmoking) {
    analysisId <- 997
    sql <- SqlRender::loadRenderTranslateSql("CreateSmokingCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "Smoker",
                                     analysisId = analysisId,
                                     conceptId = 40766929))    
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Smoking",
                                    domainId = "ObserVation",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useDiabetesMedication) {
    analysisId <- 996
    sql <- SqlRender::loadRenderTranslateSql("CreateDiabetesCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "Diabetes (medication use)",
                                     analysisId = analysisId,
                                     conceptId = 21600712))  
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Diabetes (medication use)",
                                    domainId = "Drug",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useRheumatoidArthritis) {
    analysisId <- 995
    sql <- SqlRender::loadRenderTranslateSql("CreateRaCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "History of rheumatoid arthritis",
                                     analysisId = analysisId,
                                     conceptId = 80809)) 
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Rheumatoid arthritis",
                                    domainId = "Condition",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useNonRa) {
    analysisId <- 994
    sql <- SqlRender::loadRenderTranslateSql("CreateNonRaCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "History of non-rheumatoid arthritis or chronic neck/back/joint pain",
                                     analysisId = analysisId,
                                     conceptId = 4291025))  
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Non-rheumatoid arthritis or chronic neck/back/joint pain",
                                    domainId = "Condition",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useFatigue) {
    analysisId <- 993
    sql <- SqlRender::loadRenderTranslateSql("CreateFatigueCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "History of fatigue or lack of energy",
                                     analysisId = analysisId,
                                     conceptId = 439926))  
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Fatigue",
                                    domainId = "Condition",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))
  }
  if (covariateSettings$useMigraine) {
    analysisId <- 992
    sql <- SqlRender::loadRenderTranslateSql("CreateMigraineCovariate.sql",
                                             packageName = "QuantifyingBiasInApapStudies",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             row_id_field = rowIdField,
                                             cohort_temp_table = cohortTable,
                                             cohort_id = cohortId,
                                             analysis_id = analysisId)
    covariates <- rbind(covariates, DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE))
    covariateRef <- rbind(covariateRef, 
                          data.frame(covariateId = 1000 + analysisId,
                                     covariateName = "History of migraines or frequent headaches",
                                     analysisId = analysisId,
                                     conceptId = 318736))  
    analysisRef <- rbind(analysisRef,
                         data.frame(analysisId = as.numeric(analysisId),
                                    analysisName = "Migraine",
                                    domainId = "Condition",
                                    startDay = NA,
                                    endDay = 0,
                                    isBinary = "Y",
                                    missingMeansZero = "Y"))    
  }
 
  covariates <- ff::as.ffdf(covariates)
  covariateRef <- ff::as.ffdf(covariateRef)
  analysisRef <- ff::as.ffdf(analysisRef)
  metaData <- list(call = match.call())
  result <- list(covariates = covariates,
                 covariateRef = covariateRef,
                 analysisRef = analysisRef,
                 metaData = metaData)
  class(result) <- "covariateData"
  return(result)
}
