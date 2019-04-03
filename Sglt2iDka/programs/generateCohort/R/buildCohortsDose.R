buildCohortsDose <- function(connectionDetails,packageName,
                         target_database_schema,
                         target_table,
                         codeList,
                         cdm_database_schema,
                         cohort_universe,
                         db_cohorts){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "buildCohortsDose.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema=target_database_schema,
                                           target_table=target_table,
                                           codeList = codeList,
                                           cdm_database_schema = cdm_database_schema,
                                           cohort_universe = cohort_universe,
                                           db_cohorts = db_cohorts)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)
}
