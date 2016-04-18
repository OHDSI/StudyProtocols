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

#' @title Execute OHDSI Celecoxib predictive modelsstudy
#'
#' @details
#' This function executes the OHDSI Celecoxib predictive models study.
#'
#' @return
#' TODO
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
#' @examples \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         workDatabaseSchema = "results",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results",
#'         cdmVersion = "5")
#'
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    workDatabaseSchema = cdmDatabaseSchema,
                    studyCohortTable = "ohdsi_celecoxib_prediction",
                    oracleTempSchema = NULL,
                    gap=1,
                    cdmVersion = 5,
                    outputFolder,
                    createCohorts = TRUE,
                    createPredictiveModels = TRUE,
                    packageResultsForSharing = TRUE,
                    updateProgress=NULL) {

    if (cdmVersion == 4) {
        stop("CDM version 4 not supported")
    }

    if (!file.exists(outputFolder))
        dir.create(outputFolder)

    if (createCohorts) {
        writeLines("Creating exposure and outcome cohorts")
        if (is.function(updateProgress)) {
            updateProgress(detail = "\n Creating exposure and outcome cohorts...")
        }
        createCohorts(connectionDetails,
                      cdmDatabaseSchema,
                      workDatabaseSchema,
                      studyCohortTable,
                      oracleTempSchema,
                      cdmVersion,
                      outputFolder)
    }

    if (createPredictiveModels) {
        writeLines("Creating predictive models")
        createPredictiveModels(connectionDetails,
                               cdmDatabaseSchema,
                               workDatabaseSchema,
                               studyCohortTable,
                               oracleTempSchema,
                               gap,
                               cdmVersion,
                               outputFolder,
                               updateProgress=updateProgress)
    }

    if (packageResultsForSharing) {
        writeLines("Packaging results")
        packageResults(outputFolder)
    }
}

