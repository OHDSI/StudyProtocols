
#' @importFrom SqlRender renderSql
#' @keywords internal
renderStudySpecificSql <- function(studyName, minCellCount, cdmSchema, resultsSchema, sourceName, dbms){
	if (studyName == "HTN12mo"){
		TxList <- '21600381,21601461,21601560,21601664,21601744,21601782'
		DxList <- '316866'
		ExcludeDxList <- '444094'
	} else if (studyName == "DM12mo"){
		TxList <- '21600712,21500148'
		DxList <- '201820'
		ExcludeDxList <- '444094,35506621'
	} else if (studyName == "Dep12mo"){
		TxList <- '21604686, 21500526'
		DxList <- '440383'
		ExcludeDxList <- '444094,432876,435783'
	}
	
	inputFile <- system.file(paste("sql/","sql_server",sep=""), 
													 "TxPath_parameterized.sql", 
													 package="OhdsiStudy2")   
	#   inputFile <- "TxPath_parameterized.sql"
	
	outputFile <- paste("TxPath_autoTranslate_", dbms,"_", studyName, ".sql",sep="")
	
	parameterizedSql <- SqlRender::readSql(inputFile)
	renderedSql <- SqlRender::renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName = studyName, sourceName=sourceName, txlist=TxList, dxlist=DxList, excludedxlist=ExcludeDxList, smallcellcount = minCellCount)$sql
	translatedSql <- SqlRender::translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
	SqlRender::writeSql(translatedSql,outputFile)
	writeLines(paste("Created file '",outputFile,"'",sep=""))
	return(outputFile)
}

#' @importFrom DatabaseConnector querySql
#' @keywords internal
extractAndWriteToFile <- function(connection, tableName, cdmSchema, resultsSchema, sourceName, studyName, dbms){
	parameterizedSql <- "SELECT * FROM @resultsSchema.dbo.@studyName_@sourceName_@tableName"
	renderedSql <- SqlRender::renderSql(parameterizedSql, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName=studyName, sourceName=sourceName, tableName=tableName)$sql
	translatedSql <- SqlRender::translateSql(renderedSql, sourceDialect = "sql server", targetDialect = dbms)$sql
	data <- DatabaseConnector::querySql(connection, translatedSql)
	outputFile <- paste(studyName,"_",sourceName,"_",tableName,".csv",sep='') 
	write.csv(data,file=outputFile)
	writeLines(paste("Created file '",outputFile,"'",sep=""))
}

  
  