exportTwoPlusNonSGLT2i <- function(connectionDetails,
                                   packageName,
                                   target_database_schema,
                                   target_table_1,
                                   target_table_2,
                                   cdm_database_schema,
                                   dbID,
                                   cohort_table,
                                   code_list,
                                   cohort_universe,
                                   i,
                                   last){

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "exportTwoPlusNonSGLT2i.sql",
                                           packageName = packageName,
                                           dbms = attr(conn, "dbms"),
                                           oracleTempSchema = NULL,
                                           target_database_schema = target_database_schema,
                                           target_table_1 = target_table_1,
                                           target_table_2 = target_table_2,
                                           cdm_database_schema = cdm_database_schema,
                                           dbID = dbID,
                                           cohort_table = cohort_table,
                                           code_list = code_list,
                                           cohort_universe = cohort_universe,
                                           i = i)

  DatabaseConnector::executeSql(conn=conn,sql)

  if(i == last){
    file = paste0(study,"_Results_Two_Plus_Non_SGLT2i_",Sys.Date(),".xlsx")
    if(file.exists(file)){
      file.remove(file)
    }

    #Table 1
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table_1, " ORDER BY DB, COHORT_DEFINITION_ID, PERSON_COUNT DESC")
    renderedSql = SqlRender::renderSql(sql=sql)
    translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                             targetDialect=Sys.getenv("dbms"))
    potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
    xlsx::write.xlsx(potentialRiskFactors,file,sheetName="Summary", append=TRUE)

    #Table 2
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",target_table_2, " ORDER BY DB, COHORT_DEFINITION_ID, PERSON_COUNT DESC, INGREDIENT_CONCEPT_NAME_1, INGREDIENT_CONCEPT_NAME_2")
    renderedSql = SqlRender::renderSql(sql=sql)
    translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                             targetDialect=Sys.getenv("dbms"))
    potentialRiskFactors <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
    xlsx::write.xlsx(potentialRiskFactors,file,sheetName="Details", append=TRUE)
  }

  DatabaseConnector::disconnect(conn)
}
