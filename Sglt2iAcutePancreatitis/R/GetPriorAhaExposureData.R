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

#' Get data on prior exposure to AHAs.
#'
#' @details
#' Downloads data on prior exposure to anti-hyperglycemic agents for the cohorts of interest.
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
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
getPriorAhaExposureData <- function(connectionDetails,
                                    cdmDatabaseSchema,
                                    cohortDatabaseSchema,
                                    cohortTable = "cohort",
                                    oracleTempSchema,
                                    outputFolder) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  
  conn <- DatabaseConnector::connect(connectionDetails)
  
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AHAsAcutePancreatitis")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  sql <- SqlRender::loadRenderTranslateSql("PriorAhaExposureCovariates.sql",
                                           "AHAsAcutePancreatitis",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable,
                                           cohort_ids = unique(c(tcosOfInterest$targetId, 
                                                                 tcosOfInterest$comparatorId)))
  covariates <- DatabaseConnector::querySql.ffdf(conn, sql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))

  sql <- SqlRender::loadRenderTranslateSql("PriorAhaExposureCovariateRef.sql",
                                           "AHAsAcutePancreatitis",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema)
  covariateRef <- DatabaseConnector::querySql.ffdf(conn, sql)
  colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
  
  DatabaseConnector::disconnect(conn)
  
  ffbase::save.ffdf(covariates, covariateRef, dir = file.path(outputFolder, "priorAhaExposures"))
}