# Copyright 2018 Observational Health Data Sciences and Informatics
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


#' Create settings for adding prior outcomes as covariates
#'
#' @param outcomeDatabaseSchema  The name of the database schema that is the location
#'                               where the data used to define the outcome cohorts is
#'                               available.
#' @param outcomeTable           The tablename that contains the outcome cohorts.
#' @param outcomeIds             A vector of cohort_definition_ids used to define outcomes
#' @param outcomeNames           A vector of names of the outcomes, to be used to create
#'                               covariate names.
#' @param windowStart            Start day of the window where covariates are captured,
#'                               relative to the index date (0 = index date).
#' @param windowEnd              End day of the window where covariates are captured,
#'                               relative to the index date (0 = index date).
#'
#' @return
#' A covariateSettings object.
#'
#' @export
createPriorOutcomesCovariateSettings <- function(outcomeDatabaseSchema = "unknown",
                                                 outcomeTable = "unknown",
                                                 outcomeIds,
                                                 outcomeNames,
                                                 windowStart = -365,
                                                 windowEnd = -1) {
  covariateSettings <- list(outcomeDatabaseSchema = outcomeDatabaseSchema,
                            outcomeTable = outcomeTable,
                            outcomeIds = outcomeIds,
                            outcomeNames = outcomeNames,
                            windowStart = windowStart,
                            windowEnd = windowEnd)
  attr(covariateSettings, "fun") <- "AHAsAcutePancreatitis::getDbPriorOutcomesCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' @export
getDbPriorOutcomesCovariateData <- function(connection,
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
  writeLines("Creating covariates based on prior outcomes")
  sql <- SqlRender::loadRenderTranslateSql("getPriorOutcomeCovariates.sql",
                                           packageName = "AHAsAcutePancreatitis",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           window_start = covariateSettings$windowStart,
                                           window_end = covariateSettings$windowEnd,
                                           row_id_field = rowIdField,
                                           cohort_temp_table = cohortTable,
                                           cohort_id = cohortId,
                                           outcome_database_schema = covariateSettings$outcomeDatabaseSchema,
                                           outcome_table = covariateSettings$outcomeTable,
                                           outcome_ids = covariateSettings$outcomeIds)
  covariates <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  covariateRef <- data.frame(covariateId = covariateSettings$outcomeIds * 1000 + 999,
                             covariateName = paste("Prior outcome:", covariateSettings$outcomeNames),
                             analysisId = 999,
                             conceptId = 0)
  covariateRef <- ff::as.ffdf(covariateRef)
  
  # Construct analysis reference:
  analysisRef <- data.frame(analysisId = as.numeric(1),
                            analysisName = "Prior outcome",
                            domainId = "Cohort",
                            startDay = as.numeric(covariateSettings$windowStart),
                            endDay = as.numeric(covariateSettings$windowEnd),
                            isBinary = "Y",
                            missingMeansZero = "Y")
  analysisRef <- ff::as.ffdf(analysisRef)
  # Construct analysis reference:
  metaData <- list(sql = sql, call = match.call())
  result <- list(covariates = covariates,
                 covariateRef = covariateRef,
                 analysisRef = analysisRef,
                 metaData = metaData)
  class(result) <- "covariateData"
  return(result)
}

#' @export
setOutcomeDatabaseSchemaAndTable <-function(settings, outcomeDatabaseSchema, outcomeTable) {
  if (class(settings) == "covariateSettings") {
    if (!is.null(settings$outcomeDatabaseSchema)) {
      settings$outcomeDatabaseSchema <- outcomeDatabaseSchema
      settings$outcomeTable <- outcomeTable
    }
  } else {
    if (is.list(settings) && length(settings) != 0) {
      for (i in 1:length(settings)) {
        if (is.list(settings[[i]])) {
          settings[[i]] <- setOutcomeDatabaseSchemaAndTable(settings[[i]], outcomeDatabaseSchema, outcomeTable)
        }
      }
    }
  }
  return(settings)
}