# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of CiCalibration
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
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param study                For which study should the cohorts be created? Options are "SSRIs" and
#'                             "Dabigatran".
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_ci_calibration",
                          oracleTempSchema,
                          study = "Tata",
                          workFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql("CreateCohortTable.sql",
                                           "CiCalibration",
                                           dbms = connectionDetails$dbms,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable)
  DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "CiCalibration")
  cohortsToCreate <- read.csv(pathToCsv)
  cohortsToCreate <- cohortsToCreate[cohortsToCreate$study == study, ]
  for (i in 1:nrow(cohortsToCreate)) {
    writeLines(paste("Creating cohort:", cohortsToCreate$name[i]))
    sql <- SqlRender::loadRenderTranslateSql(paste0(cohortsToCreate$name[i], ".sql"),
                                             "CiCalibration",
                                             dbms = connectionDetails$dbms,
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             target_database_schema = workDatabaseSchema,
                                             target_cohort_table = studyCohortTable,
                                             target_cohort_id = cohortsToCreate$cohortId[i])
    DatabaseConnector::executeSql(conn, sql)
  }

  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
  negativeControls <- read.csv(pathToCsv)
  negativeControls <- negativeControls[negativeControls$study == study, ]
  if (nrow(negativeControls) == 0) {
      writeLines("- No negative controls to create!")
  } else {
      writeLines("- Creating negative control outcome cohort")
      sql <- SqlRender::loadRenderTranslateSql("NegativeControls.sql",
                                               "CiCalibration",
                                               dbms = connectionDetails$dbms,
                                               oracleTempSchema = oracleTempSchema,
                                               cdm_database_schema = cdmDatabaseSchema,
                                               target_database_schema = workDatabaseSchema,
                                               target_cohort_table = studyCohortTable,
                                               outcome_ids = negativeControls$conceptId)
      DatabaseConnector::executeSql(conn, sql)
  }
  # Check number of subjects per cohort:
  sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @work_database_schema.@study_cohort_table GROUP BY cohort_definition_id"
  sql <- SqlRender::renderSql(sql,
                              work_database_schema = workDatabaseSchema,
                              study_cohort_table = studyCohortTable)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  counts <- DatabaseConnector::querySql(conn, sql)
  RJDBC::dbDisconnect(conn)

  names(counts) <- SqlRender::snakeCaseToCamelCase(names(counts))
  counts <- merge(counts,
                  cohortsToCreate[,
                  c("cohortId", "name")],
                  by.x = "cohortDefinitionId",
                  by.y = "cohortId",
                  all.x = TRUE)
  counts <- merge(counts,
                  negativeControls[,
                  c("conceptId", "name")],
                  by.x = "cohortDefinitionId",
                  by.y = "conceptId",
                  all.x = TRUE)
  counts$cohortName <- as.character(counts$name.x)
  counts$cohortName[is.na(counts$name.x)] <- as.character(counts$name.y[is.na(counts$name.x)])
  counts$name.x <- NULL
  counts$name.y <- NULL
  write.csv(counts, file.path(workFolder,
                              paste0("CohortCounts_", study, ".csv")), row.names = FALSE)
  print(counts)
}


# DatabaseConnector::querySql(conn, 'SELECT max(cohort_start_date) FROM
# scratch.dbo.mschuemie_ci_calibration_cohorts_mdcd WHERE cohort_definition_id = 4')
