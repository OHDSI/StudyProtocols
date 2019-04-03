exportReviewDKAEvents <- function(connectionDetails,
                                   packageName,
                                   target_database_schema,
                                   target_table,
                                   dbID,
                                   cohort_table,
                                   cohort_universe,
                                   i,
                                   last){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "exportReviewDKAEvents.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           dbID = dbID,
                                           cohort_table = cohort_table,
                                           cohort_universe = cohort_universe,
                                           i = i)

  DatabaseConnector::executeSql(conn=conn,sql)

  if(i == last){
    file = paste0(study,"_Results_Review_DKA_Events_",Sys.Date(),".xlsx")
    if(file.exists(file)){
      file.remove(file)
    }

    #Table 1
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table, " ORDER BY DB, COHORT_DEFINITION_ID, STAT_ORDER_NUMBER")
    renderedSql = SqlRender::renderSql(sql=sql)
    translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                             targetDialect=Sys.getenv("dbms"))
    potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
    xlsx::write.xlsx(potentialRiskFactors,file,sheetName="DKA Events", append=TRUE)

  }

  DatabaseConnector::disconnect(conn)
}
