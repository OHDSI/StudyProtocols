# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of KeppraAngioedema
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
#' @param cdmVersion           Version of the CDM. Can be "4" or "5"
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/).
#'
#' @export
createCohorts <- function(connectionDetails,
                          cdmDatabaseSchema,
                          workDatabaseSchema,
                          studyCohortTable = "ohdsi_keppra_angioedema",
                          oracleTempSchema,
                          cdmVersion = 5,
                          outputFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)

  # Create study cohort table structure:
  sql <- "IF OBJECT_ID('@work_database_schema.@study_cohort_table', 'U') IS NOT NULL\n  DROP TABLE @work_database_schema.@study_cohort_table;\n    CREATE TABLE @work_database_schema.@study_cohort_table (cohort_definition_id INT, subject_id BIGINT, cohort_start_date DATE, cohort_end_date DATE);"
  sql <- SqlRender::renderSql(sql,
                              work_database_schema = workDatabaseSchema,
                              study_cohort_table = studyCohortTable)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

  writeLines("- Creating treatment cohort")
  sql <- SqlRender::loadRenderTranslateSql("Treatment.sql",
                                           "KeppraAngioedema",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 1)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating comparator cohort")
  sql <- SqlRender::loadRenderTranslateSql("Comparator.sql",
                                           "KeppraAngioedema",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 2)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating angioedema cohort")
  sql <- SqlRender::loadRenderTranslateSql("Angioedema.sql",
                                           "KeppraAngioedema",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable,
                                           cohort_definition_id = 3)
  DatabaseConnector::executeSql(conn, sql)

  writeLines("- Creating negative control outcome cohort")
  sql <- SqlRender::loadRenderTranslateSql("NegativeControls.sql",
                                           "KeppraAngioedema",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           target_database_schema = workDatabaseSchema,
                                           target_cohort_table = studyCohortTable)
  DatabaseConnector::executeSql(conn, sql)

  # Check number of subjects per cohort:
  sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @work_database_schema.@study_cohort_table GROUP BY cohort_definition_id"
  sql <- SqlRender::renderSql(sql,
                              work_database_schema = workDatabaseSchema,
                              study_cohort_table = studyCohortTable)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  counts <- DatabaseConnector::querySql(conn, sql)
  names(counts) <- SqlRender::snakeCaseToCamelCase(names(counts))
  counts <- addOutcomeNames(counts, "cohortDefinitionId")
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"))
  writeLines("Cohort counts:")
  print(counts)

  RJDBC::dbDisconnect(conn)
  invisible(NULL)
}

#' Add names to a data frame with outcome IDs
#'
#' @param data                  The data frame to add the outcome names to
#' @param outcomeIdColumnName   The name of the column in the data frame that holds the outcome IDs.
#'
#' @export
addOutcomeNames <- function(data, outcomeIdColumnName = "outcomeId") {
    idToName <- data.frame(outcomeId = c(1, 2, 3, 29056, 29735, 73842, 74396, 75344, 75576, 77650, 78786, 78804, 79072, 79903, 80217, 80494, 80665, 80951, 133141, 133228, 133834, 134453, 134461, 134898, 136773, 136937, 137057, 138387, 139099, 140480, 140949, 141663, 141932, 192367, 192606, 192964, 193016, 193326, 194997, 195562, 195588, 195873, 196162, 197032, 197320, 197684, 198075, 198199, 199067, 199876, 200528, 200588, 253796, 256722, 258180, 260134, 261326, 261880, 312437, 313792, 314054, 316993, 317109, 317585, 318800, 319843, 321596, 372409, 373478, 374914, 376103, 376415, 378160, 378424, 378425, 380731, 432436, 432851, 433163, 433440, 433516, 434056, 434926, 435459, 436027, 437409, 437833, 439080, 440328, 440358, 440448, 440814, 441284, 441589, 442013, 443344, 4002650, 4193869, 4205509, 4291005, 4311499, 4324765, 43531027),
                           cohortName = c("Treatment",
                                          "Comparator",
                                          "Angioedema",
                                          "Sialoadenitis", "Candidiasis of mouth", "Enthesopathy of elbow region", "Temporomandibular joint disorder", "Intervertebral disc disorder", "Irritable bowel syndrome", "Aseptic necrosis of bone", "Pleurisy", "Fibrocystic disease of breast", "Inflammatory disorder of breast", "Effusion of joint", "Anal finding", "Arthropathy associated with another disorder", "Malignant neoplasm of thorax", "Candidiasis of urogenital site", "Tinea pedis", "Dental caries", "Atopic dermatitis", "Bursitis", "Tietze's disease", "Non-toxic uninodular goiter", "Rosacea", "Benign neoplasm of endocrine gland", "Paronychia", "Thyrotoxicosis", "Ingrowing nail", "Impetigo", "Infestation by Sarcoptes scabiei var hominis", "Osteomyelitis", "Seborrheic keratosis", "Dysplasia of cervix", "Paraplegia", "Infectious disorder of kidney", "Cystic disease of kidney", "Urge incontinence of urine", "Prostatitis", "Hemorrhoids", "Cystitis", "Leukorrhea", "Inflammatory disease of the uterus", "Hyperplasia of prostate", "Acute renal failure syndrome", "Dysuria", "Condyloma acuminatum", "Pyelonephritis", "Inflammatory disease of female pelvic organs AND/OR tissues", "Prolapse of female genital organs", "Ascites", "Injury of abdomen", "Pneumothorax", "Bronchopneumonia", "Pneumonia due to Gram negative bacteria", "Croup", "Viral pneumonia", "Atelectasis", "Dyspnea", "Paroxysmal tachycardia", "Aortic valve disorder", "Tricuspid valve disorder", "Respiratory arrest", "Aortic aneurysm", "Gastroesophageal reflux disease", "Mitral valve disorder", "Peripheral venous insufficiency", "Sciatica", "Presbyopia", "Tetraplegia", "Retinopathy", "Hypermetropia", "Otorrhea", "Astigmatism", "Blepharitis", "Otitis externa", "Symbolic dysfunction", "Secondary malignant neoplastic disease", "Deficiency of macronutrients", "Dysthymia", "Duodenitis", "Late effects of cerebrovascular disease", "Iridocyclitis", "Staphylococcal infectious disease", "Coxsackie virus disease", "Intracranial injury", "Hypokalemia", "Dyspareunia", "Pneumococcal infectious disease", "Lipoma", "Appendicitis", "Torticollis", "Open-angle glaucoma", "Endocarditis", "Burn", "Barrett's esophagus", "Plantar fasciitis", "Bacterial intestinal infectious disease", "Arthritis of elbow", "Viral hepatitis", "Primary malignant neoplasm of respiratory tract", "Arthropathy of knee joint", "Mononeuropathy of upper limb"))
    names(idToName)[1] <- outcomeIdColumnName
    data <- merge(data, idToName, all.x = TRUE)
  return(data)
}
