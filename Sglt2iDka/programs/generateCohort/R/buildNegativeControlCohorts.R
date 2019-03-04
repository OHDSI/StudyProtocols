buildNegativeControlCohorts <- function(connectionDetails,packageName,codeList,
                                        target_database_schema,target_table,
                                        cdm_database_schema){
  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "buildNegativeControlCohorts.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema=target_database_schema,
                                           target_cohort_table=target_table,
                                           cdm_database_schema = cdm_database_schema,
                                           codeList = codeList)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)

}
