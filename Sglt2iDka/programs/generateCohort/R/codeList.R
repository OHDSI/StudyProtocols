codeList <- function(connectionDetails,packageName,target_database_schema,target_table,vocabulary_schema){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "codeList.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           vocabulary_schema = vocabulary_schema)
  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)

}
