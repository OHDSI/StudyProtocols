# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
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

#' Execute OHDSI Large-Scale Population-Level Evidence Generation study
#'
#' @details
#' This function executes the OHDSI Large-Scale Population-Level Evidence Generation study.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param workDatabaseSchema   Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param studyCohortTable     The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param exposureCohortSummaryTable   The name of the table that will be created in the work database schema.
#'                             This table will hold summary data on the  exposure cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param workFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param createCohorts        Create the studyCohortTable and exposureCohortSummaryTable tables with the exposure and outcome cohorts?
#' @param fetchAllDataFromServer          Fetch all relevant data from the server?
#' @param injectSignals       Inject signals to create synthetic controls?
#' @param generateAllCohortMethodDataObjects  Create the cohortMethodData objects from the fetched data and injected signals?
#' @param runCohortMethod      Run the CohortMethod package to produce the outcome models.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    oracleTempSchema,
                    workDatabaseSchema,
                    studyCohortTable,
                    exposureCohortSummaryTable,
                    workFolder,
                    maxCores,
                    createCohorts = TRUE,
                    fetchAllDataFromServer = TRUE,
                    injectSignals = TRUE,
                    generateAllCohortMethodDataObjects = TRUE,
                    runCohortMethod = TRUE) {
    if (createCohorts) {
        createCohorts(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      oracleTempSchema = oracleTempSchema,
                      workDatabaseSchema = workDatabaseSchema,
                      studyCohortTable = studyCohortTable,
                      exposureCohortSummaryTable = exposureCohortSummaryTable,
                      workFolder = workFolder)

        filterByExposureCohortsSize(workFolder = workFolder)
    }
    if (fetchAllDataFromServer) {
        fetchAllDataFromServer(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               workDatabaseSchema = workDatabaseSchema,
                               studyCohortTable = studyCohortTable,
                               workFolder = workFolder)
    }
    if (injectSignals) {
        injectSignals(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      workDatabaseSchema = workDatabaseSchema,
                      studyCohortTable = studyCohortTable,
                      oracleTempSchema = oracleTempSchema,
                      workFolder = workFolder,
                      maxCores = maxCores)
    }
    if (generateAllCohortMethodDataObjects) {
        generateAllCohortMethodDataObjects(workFolder)
    }
    if (runCohortMethod) {
        runCohortMethod(workFolder, maxCores = maxCores)
    }
}
