formatParticipantsAndTxInfo <- function(connectionDetails,
                                       packageName,
                                       target_database_schema,
                                       target_table,
                                       cohort_universe,
                                       tablePotentialRiskFactors,
                                       tableMeanAge){


  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "formatParticipantsAndTxInfo.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           cohort_universe = cohort_universe,
                                           tablePotentialRiskFactors = tablePotentialRiskFactors,
                                           tableMeanAge = tableMeanAge)

  DatabaseConnector::executeSql(conn=conn,sql)


  file = paste0(study,"_Results_Participants_And_TX_Info_Formated_",Sys.Date(),".xlsx")
  if(file.exists(file)){
    file.remove(file)
  }

  #Cohort Attrition List
  sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table, " ORDER BY COHORT_TYPE DESC,COHORT_OF_INTEREST,DB ")
  renderedSql = SqlRender::renderSql(sql=sql)
  translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                           targetDialect=Sys.getenv("dbms"))
  potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
  xlsx::write.xlsx(potentialRiskFactors,file,sheetName="Potential Risk Factors", append=TRUE)



  DatabaseConnector::disconnect(conn)
}
