formatFatalDka <- function(connectionDetails,
                                        packageName,
                                        target_database_schema,
                                        target_table,
                                        cohort_universe,
                                        tablePotentialRiskFactors,
                            tableDKAFatal){


  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "formatFatalDka.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           cohort_universe = cohort_universe,
                                           tablePotentialRiskFactors = tablePotentialRiskFactors,
                                           tableDKAFatal = tableDKAFatal)

  DatabaseConnector::executeSql(conn=conn,sql)


  file = paste0(study,"_Results_DKA_Fatal_Formatted_",Sys.Date(),".xlsx")
  if(file.exists(file)){
    file.remove(file)
  }

  #Cohort Attrition List
  sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table, " ORDER BY STAT_ORDER_NUMBER_0, COHORT_OF_INTEREST, DB ")
  renderedSql = SqlRender::renderSql(sql=sql)
  translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                           targetDialect=Sys.getenv("dbms"))
  potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
  xlsx::write.xlsx(potentialRiskFactors,file,sheetName="Fatal DKA", append=TRUE)



  DatabaseConnector::disconnect(conn)
}
