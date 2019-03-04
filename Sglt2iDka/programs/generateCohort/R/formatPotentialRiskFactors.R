formatPotentialRiskFactors <- function(connectionDetails,
                                       packageName,
                                       target_database_schema,
                                       target_table,
                                       cohort_universe,
                                       tablePotentialRiskFactors){


  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "formatPotentialRiskFactors.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table = target_table,
                                           cohort_universe = cohort_universe,
                                           tablePotentialRiskFactors = tablePotentialRiskFactors)

  DatabaseConnector::executeSql(conn=conn,sql)


    filePotentialRiskFactors = paste0(study,"_Results_Potential_Risk_Factors_Formated_",Sys.Date(),".xlsx")
    if(file.exists(filePotentialRiskFactors)){
      file.remove(filePotentialRiskFactors)
    }

    #Cohort Attrition List
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table, " ORDER BY DKA DESC, STAT_ORDER_NUMBER_0, COHORT_OF_INTEREST, STAT_ORDER_NUMBER_1_UPDATED, STAT_ORDER_NUMBER_2")
    renderedSql = SqlRender::renderSql(sql=sql)
    translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                             targetDialect=Sys.getenv("dbms"))
    potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
    xlsx::write.xlsx(potentialRiskFactors,filePotentialRiskFactors,sheetName="Potential Risk Factors", append=TRUE)



  DatabaseConnector::disconnect(conn)
}
