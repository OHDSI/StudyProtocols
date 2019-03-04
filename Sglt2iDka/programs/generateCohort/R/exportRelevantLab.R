exportRelevantLabs <- function(connectionDetails,
                                       packageName,
                                       target_database_schema,
                                       target_table,
                                       cdm_database_schema,
                                       dbID,
                                       cohort_table,
                                       code_list,
                                       cohort_universe,
                                       i,
                                       last){


  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "exportRelevantLabs.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           cdm_database_schema = cdm_database_schema,
                                           dbID = dbID,
                                           cohort_table = cohort_table,
                                           code_list = code_list,
                                           cohort_universe = cohort_universe,
                                           i = i)

  DatabaseConnector::executeSql(conn=conn,sql)

  if(i == last){
    filePotentialRiskFactors = paste0(study,"_Results_Relevant_Labs_",Sys.Date(),".xlsx")
    if(file.exists(filePotentialRiskFactors)){
      file.remove(filePotentialRiskFactors)
    }

    #Cohort Attrition List
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table, " ORDER BY DB, COHORT_DEFINITION_ID")
    renderedSql = SqlRender::renderSql(sql=sql)
    translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                             targetDialect=Sys.getenv("dbms"))
    potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
    xlsx::write.xlsx(potentialRiskFactors,filePotentialRiskFactors,sheetName="Relevant Labs", append=TRUE)
  }

  DatabaseConnector::disconnect(conn)
}
