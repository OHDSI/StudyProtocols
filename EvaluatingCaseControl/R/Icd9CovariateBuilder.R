# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of EvaluatingCaseControl
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

#' Create settings for covariates representing one or more ICD-9 codes
#'
#' @param covariateDefs  A data frame with three columns: covariateId, covariateName, icd9
#'
#' @param windowStart    Days relative to the index date to start capturing the covariates. Negative numbers indicates
#'                       days prior to index.
#' @param windowEnd      Days relative to the index date to end capturing the covariates. Negative numbers indicates
#'                       days prior to index.
#'
#' @export
createIcd9CovariateSettings <- function(covariateDefs, windowStart = -365, windowEnd = -1) {
  covariateSettings <- list(covariateDefs = covariateDefs,
                            windowStart = windowStart,
                            windowEnd = windowEnd)
  attr(covariateSettings, "fun") <- "EvaluatingCaseControl::getDbIcd9CovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

getDbIcd9CovariateData <- function(connection,
                                   oracleTempSchema = NULL,
                                   cdmDatabaseSchema,
                                   cohortTable = "#cohort_person",
                                   cohortId = -1,
                                   cdmVersion = "5",
                                   rowIdField = "subject_id",
                                   covariateSettings,
                                   aggregated = FALSE) {
  sql <- "CREATE TABLE #covar_defs (concept_id INT, covariate_id INT)"
  sql <- SqlRender::translateSql(sql, targetDialect = attr(connection, "dbms"))$sql
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)

  for (i in 1:nrow(covariateSettings$covariateDefs)) {
    sql <- SqlRender::loadRenderTranslateSql("icd9ToConcepts.sql",
                                             packageName = "EvaluatingCaseControl",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             covariate_id = covariateSettings$covariateDefs$covariateId[i],
                                             icd9 = covariateSettings$covariateDefs$icd9[i],
                                             cdm_database_schema = cdmDatabaseSchema)
    DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  }
  sql <- SqlRender::loadRenderTranslateSql("getIcd9Covariates.sql",
                                           packageName = "EvaluatingCaseControl",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           window_start = covariateSettings$windowStart,
                                           window_end = covariateSettings$windowEnd,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           row_id_field = rowIdField,
                                           cohort_table = cohortTable,
                                           cohort_id = cohortId)
  covariates <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  sql <- "TRUNCATE TABLE #covar_defs; DROP TABLE #covar_defs;"
  sql <- SqlRender::translateSql(sql, targetDialect = attr(connection, "dbms"))$sql
  executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  covariateRef <- unique(covariateSettings$covariateDefs[, c("covariateId","covariateName")])
  covariateRef$covariateId <- as.numeric(covariateRef$covariateId)
  covariateRef$covariateName <- as.factor(covariateRef$covariateName)
  covariateRef$analysisId <- 1
  covariateRef$conceptId <- 0
  covariateRef <- ff::as.ffdf(covariateRef)

  analysisRef <- data.frame(analysisId = 1,
                            analysisName = "ICD9 covariates",
                            domainId = "Condition",
                            startDay = 0,
                            endDay = 0,
                            isBinary = "Y",
                            missingMeansZero = "Y")
  analysisRef <- ff::as.ffdf(analysisRef)

  metaData <- list(call = match.call())
  result <- list(covariates = covariates,
                 covariateRef = covariateRef,
                 analysisRef = analysisRef,
                 metaData = metaData)
  class(result) <- "covariateData"
  return(result)
}
