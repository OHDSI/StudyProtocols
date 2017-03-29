# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
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

countCohorts <- function(connectionDetails,
                         cdmDatabaseSchema,
                         workDatabaseSchema,
                         studyCohortTable = "ohdsi_alendronate_raloxifene",
                         oracleTempSchema,
                         outputFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "AlendronateVsRaloxifene")
  cohortsToCreate <- read.csv(pathToCsv)
  sql <- SqlRender::loadRenderTranslateSql("GetCounts.sql",
                                           "AlendronateVsRaloxifene",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           work_database_schema = workDatabaseSchema,
                                           study_cohort_table = studyCohortTable,
                                           cohort_definition_ids = cohortsToCreate$cohortId)
  counts <- DatabaseConnector::querySql(conn, sql)
  colnames(counts) <- SqlRender::snakeCaseToCamelCase(colnames(counts))
  counts <- addCohortNames(counts)
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"), row.names = FALSE)
}
