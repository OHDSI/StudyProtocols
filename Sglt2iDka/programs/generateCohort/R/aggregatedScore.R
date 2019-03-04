aggregatedScore <- function(connectionDetails,
                 packageName,
                 sql,
                 cdm_database_schema,
                 aggregated,
                 temporal,
                 covariate_table,
                 row_id_field,
                 cohort_table,
                 end_day,
                 cohort_definition_id,
                 analysis_id,
                 included_cov_table,
                 analysis_name,
                 domain_id){
  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sql,
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           cdm_database_schema = cdm_database_schema,
                                           aggregated = aggregated,
                                           temporal = temporal,
                                           covariate_table = covariate_table,
                                           row_id_field = row_id_field,
                                           cohort_table = cohort_table,
                                           end_day = end_day,
                                           cohort_definition_id = cohort_definition_id,
                                           analysis_id = analysis_id,
                                           included_cov_table = included_cov_table,
                                           analysis_name = analysis_name,
                                           domain_id = domain_id)

  DatabaseConnector::executeSql(conn=conn,sql)
}
