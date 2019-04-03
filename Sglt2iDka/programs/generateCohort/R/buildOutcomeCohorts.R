buildOutcomeCohorts <- function(connectionDetails,packageName,
                                target_database_schema,target_table,target_cohort_id,
                                codeList,cdm_database_schema, gap_days){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "buildOutcomeCohorts.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema=target_database_schema,
                                           target_cohort_table=target_table,
                                           target_cohort_id = target_cohort_id,
                                           codeList = codeList,
                                           cdm_database_schema = cdm_database_schema,
                                           gap_days = gap_days)

  DatabaseConnector::executeSql(conn=conn,sql)

  DatabaseConnector::disconnect(conn)

}
