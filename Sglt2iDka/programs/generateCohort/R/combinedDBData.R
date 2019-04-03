combinedDBData <- function(connectionDetails,packageName,dbID,
                                 target_database_schema,target_table,sourceTable,
                                 i, lastDb){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "combinedDbData.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema=target_database_schema,
                                           target_cohort_table=target_table,
                                           sourceTable=sourceTable,
                                           dbID = dbID,
                                           i = i,
                                           lastDb = lastDb)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)
}
