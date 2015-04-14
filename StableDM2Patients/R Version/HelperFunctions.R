renderStudySql <- function(cdmSchema, resultsSchema, studyName, dbms){
  inputFile <- "T2DM counts parameterized.sql"
  outputFile <- paste("T2DM counts autoTranslate ", dbms, ".sql",sep="")
  parameterizedSql <- readSql(inputFile)
  renderedSql <- renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName=studyName )$sql
  translatedSql <- translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
  writeSql(translatedSql,outputFile)
  writeLines(paste("Created file '",outputFile,"'",sep=""))
  return(outputFile)
}
  
extractAndWriteToFile <- function(connection, tableName, resultsSchema, studyName, dbms){
    parameterizedSql <- "SELECT * FROM @resultsSchema.dbo.@studyName_@tableName"
    renderedSql <- renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName=studyName , tableName=tableName)$sql
    translatedSql <- translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
    data <- querySql(connection, translatedSql)
    outputFile <- paste(studyName,"_",sourceName,"_",tableName,".csv",sep='') 
    write.csv(data,file=outputFile)
    writeLines(paste("Created file '",outputFile,"'",sep=""))
}
