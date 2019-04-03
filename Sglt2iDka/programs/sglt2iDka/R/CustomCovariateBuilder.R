#' @export
createPriorOutcomesCovariateSettings <- function(outcomeDatabaseSchema = "unknown",
                                                 outcomeTable = "unknown",
                                                 outcomeIds = NA,
                                                 outcomeNames,
                                                 analysisId = NA,
                                                 windowStart = -365,
                                                 windowEnd = -1) {
  covariateSettings <- list(outcomeDatabaseSchema = outcomeDatabaseSchema,
                            outcomeTable = outcomeTable,
                            outcomeIds = outcomeIds,
                            outcomeNames = outcomeNames,
                            analysisId = analysisId,
                            windowStart = windowStart,
                            windowEnd = windowEnd)
  attr(covariateSettings, "fun") <- "sglt2iDka::getDbPriorOutcomesCovariateData"
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
                                           packageName = "sglt2iDka",
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
  covariateRef <- data.frame(covariateId = covariateSettings$outcomeIds * 1000 + covariateSettings$analysisId,  #999,
                             covariateName = paste("Prior outcome:", covariateSettings$outcomeNames),
                             analysisId = covariateSettings$analysisId, # 999,
                             conceptId = 0)
  covariateRef <- ff::as.ffdf(covariateRef)

  # Construct analysis reference:
  analysisRef <- data.frame(analysisId = as.numeric(covariateSettings$analysisId),   #999),
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
setOutcomeDatabaseSchemaAndTable <- function(settings,
                                             outcomeDatabaseSchema,
                                             outcomeTable) {
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


#' @export
createPriorExposureCovariateSettings <- function(exposureDatabaseSchema = "unknown",
                                                 covariateIdPrefix,
                                                 codeListSchema = "unknown",
                                                 codeListTable = "unknown",
                                                 vocabularyDatabaseSchema = "unknown",
                                                 drug) {
  covariateSettings <- list(exposureDatabaseSchema = exposureDatabaseSchema,
                            covariateIdPrefix = covariateIdPrefix,
                            codeListSchema = codeListSchema,
                            codeListTable = codeListTable,
                            vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                            drug = drug)
  attr(covariateSettings, "fun") <- "sglt2iDka::getDbPriorExposureCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' @export
getDbPriorExposureCovariateData <- function(connection,
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
  writeLines("Creating covariates based on prior insulin exposure")
  sql <- SqlRender::loadRenderTranslateSql("getPriorExposureCovariates.sql",
                                           packageName = "sglt2iDka",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           row_id_field = rowIdField,
                                           covariate_id_prefix = covariateSettings$covariateIdPrefix,
                                           code_list_schema = covariateSettings$codeListSchema,
                                           code_list_table = covariateSettings$codeListTable,
                                           cohort_temp_table = cohortTable,
                                           vocabulary_database_schema = covariateSettings$vocabularyDatabaseSchema,
                                           cohort_id = cohortId,
                                           cdm_database_schema = covariateSettings$exposureDatabaseSchema,
                                           drug = covariateSettings$drug)
  covariates <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  covariateRef <- data.frame(covariateId = covariateSettings$covariateIdPrefix + 998,
                             covariateName = paste("Any time prior exposure:", covariateSettings$drug),
                             analysisId = 998,
                             conceptId = 0)
  covariateRef <- ff::as.ffdf(covariateRef)

  # Construct analysis reference:
  analysisRef <- data.frame(analysisId = as.numeric(998),
                            analysisName = "Any time prior exposure",
                            domainId = "Drug",
                            startDay = 0,
                            endDay = 0,
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
setExposureDatabaseSchemaAndIds <- function(settings,
                                            exposureDatabaseSchema,
                                            codeListSchema,
                                            codeListTable,
                                            vocabularyDatabaseSchema) {
  if (class(settings) == "covariateSettings") {
    if (!is.null(settings$exposureDatabaseSchema)) {
      settings$exposureDatabaseSchema <- exposureDatabaseSchema
      settings$codeListSchema <- codeListSchema
      settings$codeListTable <- codeListTable
      settings$vocabularyDatabaseSchema <- vocabularyDatabaseSchema
    }
  } else {
    if (is.list(settings) && length(settings) != 0) {
      for (i in 1:length(settings)) {
        if (is.list(settings[[i]])) {
          settings[[i]] <- setExposureDatabaseSchemaAndIds(settings[[i]], exposureDatabaseSchema, codeListSchema, codeListTable, vocabularyDatabaseSchema)
        }
      }
    }
  }
  return(settings)
}
