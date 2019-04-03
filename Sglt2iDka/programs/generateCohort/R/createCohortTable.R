createCohortTable <- function(connectionDetails,packageName,
                                 target_database_schema,target_table){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "createCohortTable.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema=target_database_schema,
                                           target_cohort_table=target_table)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)
}
