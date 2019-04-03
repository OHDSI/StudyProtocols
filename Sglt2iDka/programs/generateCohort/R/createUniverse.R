createUniverse <- function(connectionDetails,packageName,target_database_schema,target_table,target_table_dose,codeList){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "createUniverse.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           target_table_dose = target_table_dose,
                                           codeList = codeList)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)

}
