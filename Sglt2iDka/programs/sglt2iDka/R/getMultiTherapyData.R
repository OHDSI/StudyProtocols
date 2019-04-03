#' @export
getMultiTherapyData <- function(connectionDetails,
                                cohortDatabaseSchema,
                                cohortDefinitionTable,
                                cdmDatabaseSchema,
                                cohortTable,
                                codeListTable,
                                oracleTempSchema = NULL,
                                outputFolder) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)

  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "getMultiTherapyCovariates.sql",
                                           packageName = "sglt2iDka",
                                           dbms = connectionDetails$dbms,
                                           oracleTempSchema = oracleTempSchema,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_definition_table = cohortDefinitionTable,
                                           cohort_table = cohortTable,
                                           code_list_table = codeListTable,
                                           cdm_database_schema = cdmDatabaseSchema)
  covariates <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))

  covariateRef <- data.frame(covariateId = c(500001, 500002, 500003),
                             covariateName = c("AHA monotherapy", "AHA dual therapy", "AHA >= triple therapy"),
                             analysisId = c(996, 996, 996),
                             conceptId = NA)
  covariateRef <- ff::as.ffdf(covariateRef)
  DatabaseConnector::disconnect(connection)
  ffbase::save.ffdf(covariates, covariateRef, dir = file.path(outputFolder, "multiTherapyData"))
}
