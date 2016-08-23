# Copyright 2016 Observational Health Data Sciences and Informatics
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


#' Create the exposure and outcome cohorts
#'
#' @details
#' This function will create the exposure and outcome cohorts following the definitions included in
#' this package.
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
#' @param exposureCohortSummaryTable     The name of the table that will be created in the work database schema.
#'                             This table will hold the summary of the exposure cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_cohorts",
                          exposureCohortSummaryTable = "ohdsi_cohort_summary",
                          oracleTempSchema,
                          workFolder) {
    if (!file.exists(workFolder)) {
        dir.create(workFolder)
    }
    conn <- DatabaseConnector::connect(connectionDetails)

    # Create study cohort table structure:
    sql <- SqlRender::loadRenderTranslateSql("CreateCohortTable.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

    writeLines("- Creating exposure cohorts")
    sql <- SqlRender::loadRenderTranslateSql("ExposureCohorts.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             washout_period = 365)
    DatabaseConnector::executeSql(conn, sql)

    writeLines("- Creating exposure cohort pairs")
    sql <- SqlRender::loadRenderTranslateSql("CreateCohortPairs.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable,
                                             target_cohort_summary_table = exposureCohortSummaryTable)
    DatabaseConnector::executeSql(conn, sql)

    sql <- "SELECT * FROM @target_database_schema.@target_cohort_summary_table"
    sql <- SqlRender::renderSql(sql,target_database_schema = workDatabaseSchema,
                                target_cohort_summary_table = exposureCohortSummaryTable)$sql
    sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
    exposureSummary <- DatabaseConnector::querySql(conn, sql)
    colnames(exposureSummary) <- SqlRender::snakeCaseToCamelCase(colnames(exposureSummary))
    write.csv(exposureSummary, file.path(workFolder, "exposureSummary.csv"), row.names = FALSE)

    writeLines("- Creating negative control cohorts")
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "LargeScalePopEst")
    negativeControls <- read.csv(pathToCsv)
    sql <- SqlRender::loadRenderTranslateSql("NegativeControls.sql",
                                             "LargeScalePopEst",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable,
                                             outcome_ids = negativeControls$conceptId)
    DatabaseConnector::executeSql(conn, sql)

    writeLines("- Creating health outcomes of interest cohorts")
    pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
    outcomes <- read.csv(pathToCsv)
    for (i in 1:nrow(outcomes)) {
        writeLines(paste(" -", outcomes$name[i]))
        sql <- SqlRender::loadRenderTranslateSql(paste0(outcomes$name[i], ".sql"),
                                                 "LargeScalePopEst",
                                                 dbms = connectionDetails$dbms,
                                                 oracleTempSchema = oracleTempSchema,
                                                 cdm_database_schema = cdmDatabaseSchema,
                                                 target_database_schema = workDatabaseSchema,
                                                 target_cohort_table = studyCohortTable,
                                                 target_cohort_id = outcomes$cohortDefinitionId[i])
        DatabaseConnector::executeSql(conn, sql)
    }

    # Check number of subjects per cohort:
    sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @work_database_schema.@study_cohort_table GROUP BY cohort_definition_id"
    sql <- SqlRender::renderSql(sql,
                                work_database_schema = workDatabaseSchema,
                                study_cohort_table = studyCohortTable)$sql
    sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
    counts <- DatabaseConnector::querySql(conn, sql)
    names(counts) <- SqlRender::snakeCaseToCamelCase(names(counts))

    cohortNames <- data.frame()
    cohortNames <- rbind(cohortNames, data.frame(cohortDefinitionId = exposureSummary$tprimeCohortDefinitionId,
                                                 name = exposureSummary$tCohortDefinitionName,
                                                 type = "targetExposure"))
    cohortNames <- rbind(cohortNames, data.frame(cohortDefinitionId = exposureSummary$cprimeCohortDefinitionId,
                                                 name = exposureSummary$cCohortDefinitionName,
                                                 type = "comparatorExposure"))
    cohortNames <- rbind(cohortNames, data.frame(cohortDefinitionId = outcomes$cohortDefinitionId,
                                                 name = outcomes$name,
                                                 type = "outcome"))
    cohortNames <- rbind(cohortNames, data.frame(cohortDefinitionId = negativeControls$conceptId,
                                                 name = negativeControls$name,
                                                 type = "negativeControl"))
    write.csv(cohortNames, file.path(workFolder, "cohortNames.csv"), row.names = FALSE)

    counts <- merge(counts, cohortNames)
    write.csv(counts, file.path(workFolder, "cohortCounts.csv"), row.names = FALSE)
    print(counts)

    RJDBC::dbDisconnect(conn)
}
