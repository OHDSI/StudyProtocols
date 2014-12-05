renderStudySpecificSql <- function(studyName, minCellCount, cdmSchema, resultsSchema, sourceName, dbms){
  if (studyName == "HTN"){
    TxList <- '21600381,21601461,21601560,21601664,21601744,21601782'
    DxList <- '316866'
    ExcludeDxList <- '444094'
  } else if (studyName == "T2DM"){
    TxList <- '21600712,21500148'
    DxList <- '201820'
    ExcludeDxList <- '444094,35506621'
  } else if (studyName == "Depression"){
    TxList <- '21604686, 21500526'
    DxList <- '440383'
    ExcludeDxList <- '444094,432876,435783'
  }
  
  inputFile <- "TxPath parameterized.sql"
  outputFile <- paste("TxPath autoTranslate ", dbms," ", studyName, ".sql",sep="")
  
  parameterizedSql <- readSql(inputFile)
  renderedSql <- renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName = studyName, sourceName=sourceName, txlist=TxList, dxlist=DxList, excludedxlist=ExcludeDxList, smallcellcount = minCellCount)$sql
  translatedSql <- translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
  writeSql(translatedSql,outputFile)
  writeLines(paste("Created file '",outputFile,"'",sep=""))
  return(outputFile)
  }
  
  extractAndWriteToFile <- function(connection, tableName, resultsSchema, sourceName, studyName, dbms){
    parameterizedSql <- "SELECT * FROM @resultsSchema.dbo.TxPath_@sourceName_@studyName_@tableName"
    renderedSql <- renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName=studyName, sourceName=sourceName, tableName=tableName)$sql
    translatedSql <- translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
    data <- querySql(connection, translatedSql)
    outputFile <- paste("TxPath_",sourceName,"_",studyName,"_",tableName,".csv") 
    write.csv(data,file=outputFile)
    writeLines(paste("Created file '",outputFile,"'",sep=""))
  }
  
  
  