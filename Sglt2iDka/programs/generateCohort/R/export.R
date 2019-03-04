export <- function(connectionDetails, packageName, codeList, cohortUniverse,
                   target_database_schema,
                   cohortAttrition,
                   datasources){
  tableCodeList <- codeList
  tableCohortUniverse <- cohortUniverse

  conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)

  writeLines("### Code List & Cohort Descriptions")

   file = paste0(study,"_Results_",Sys.Date(),".xlsx")
   if(file.exists(file)){
     file.remove(file)
   }

   #Concept Set
   sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",tableCodeList, " ORDER BY CODE_LIST_NAME, CODE_LIST_DESCRIPTION, CONCEPT_NAME")
   renderedSql = SqlRender::renderSql(sql=sql)
   translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                            targetDialect=Sys.getenv("dbms"))
   conceptSet <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
   xlsx::write.xlsx(conceptSet,file,sheetName="Code List", append=TRUE)

   #Ingredient List
   sql <- paste0("SELECT DISTINCT cl.* FROM ",Sys.getenv("writeTo"),".",tableCodeList, " cl JOIN ", Sys.getenv("vocabulary"),".CONCEPT c	ON c.CONCEPT_ID = cl.CONCEPT_ID AND CONCEPT_CLASS_ID = 'Ingredient' ORDER BY cl.CODE_LIST_NAME, cl.CONCEPT_NAME")
   renderedSql = SqlRender::renderSql(sql=sql)
   translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                            targetDialect=Sys.getenv("dbms"))
   conceptSet <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
   xlsx::write.xlsx(conceptSet,file,sheetName="Code List (Ingredients Only)", append=TRUE)

   #Cohort List
   sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",tableCohortUniverse, " ORDER BY COHORT_DEFINITION_ID")
   renderedSql = SqlRender::renderSql(sql=sql)
   translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                            targetDialect=Sys.getenv("dbms"))
   cohorts <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
   xlsx::write.xlsx(cohorts,file,sheetName="Cohorts", append=TRUE)

  ### Cohort Attrition ##################################################################

  #writeLines("### Cohort Attrition")

  fileCohortAttrition = paste0(study,"_Results_Cohort_Attrition_",Sys.Date(),".xlsx")
  if(file.exists(fileCohortAttrition)){
    file.remove(fileCohortAttrition)
  }

  # Cohorts for Attrition List
  sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",tableCohortUniverse, " WHERE EXPOSURE_COHORT = 1 AND FU_STRAT_ITT_PP0DAY = 1 ORDER BY COHORT_DEFINITION_ID")
  renderedSql = SqlRender::renderSql(sql=sql)
  translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                           targetDialect=Sys.getenv("dbms"))
  cohorts <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)

  for(z in 1:length(datasources)){

    writeLines("##################################################################")
    print(paste0(datasources[[z]]$db.name))
    writeLines("##################################################################")

    for(i in 1:nrow(cohorts)){
      print(paste0('I: ',i, ' COHORT_DEF_ID:  ',cohorts$COHORT_DEFINITION_ID[i], ' FULL_NAME: ', cohorts$FULL_NAME[i]))

      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "exportCohortAttrition.sql",
                                               packageName = packageName,
                                               dbms = attr(conn, "dbms"),
                                               oracleTempSchema = NULL,
                                               i = i,
                                               z = z,
                                               cdm_database_schema = datasources[[z]]$schema,
                                               db.name = datasources[[z]]$db.name,
                                               cohortID = cohorts$COHORT_DEFINITION_ID[i],
                                               target_database_schema = target_database_schema,
                                               target_table = cohortAttrition,
                                               t2dm = cohorts$T2DM[i],
                                               drugOfInterest = cohorts$COHORT_OF_INTEREST[i])

      DatabaseConnector::executeSql(conn=conn,sql)
    }
  }

  #Cohort Attrition List
  sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",cohortAttrition, " ORDER BY DB, COHORT_ID")
  renderedSql = SqlRender::renderSql(sql=sql)
  translatedSql <- SqlRender::translateSql(renderedSql$sql,
                                           targetDialect=Sys.getenv("dbms"))
  cohortAttrition <- DatabaseConnector::querySql(conn=conn,translatedSql$sql)
  xlsx::write.xlsx(cohortAttrition,fileCohortAttrition,sheetName="Cohort Attrition", append=TRUE)

  DatabaseConnector::disconnect(conn)
}
