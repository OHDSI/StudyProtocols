#/******************
#  
#Script to render SQL for TxPath for HTN, T2DM, Depression
#
#Author:  Patrick Ryan
#last revised:  30 November 2014
#  
#******************/

#option to install if already done
install.packages("devtools")
library(devtools)
install_github("ohdsi/SqlRender")
library(SqlRender)


#user:  set these parameters however you'd like

OHDSIDirectory <- "F:/Documents/OHDSI/Studies/"
inputFile <- paste(OHDSIDirectory,"TxPath parameterized.sql",sep="")
minCellCount <- 5
cdmSchema <- "CDM_OPTUM"
resultsSchema <- "SCRATCH"
sourceName <- "Optum"


#don't change anything below this line, it should be consistent across all data partners who choose to run this analysis

studyName = "HTN"
HTNTxList <- '21600381,21601461,21601560,21601664,21601744,21601782'
HTNDxList <- '316866'
HTNExcludeDxList <- '444094'
renderedFile <- paste(OHDSIDirectory, "TxPath rendered ", studyName ,".sql", sep="")
renderSqlFile(inputFile, renderedFile, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName = studyName, sourceName=sourceName, txlist=HTNTxList, dxlist=HTNDxList, excludedxlist=HTNExcludeDxList, smallcellcount = minCellCount)
translatedFile <- paste(OHDSIDirectory, "TxPath translated Oracle ", studyName, ".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "oracle")
translatedFile <- paste(OHDSIDirectory, "TxPath translated Postgres ", studyName,".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "postgresql")



studyName = "T2DM"
T2DMTxList <- '21600712,21500148'
T2DMDxList <- '201820'
T2DMExcludeDxList <- '444094,35506621'
renderedFile <- paste(OHDSIDirectory, "TxPath rendered ", studyName ,".sql", sep="")
renderSqlFile(inputFile, renderedFile, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName = studyName, sourceName=sourceName, txlist=T2DMTxList, dxlist=T2DMDxList, excludedxlist=T2DMExcludeDxList, smallcellcount = minCellCount)
translatedFile <- paste(OHDSIDirectory, "TxPath translated Oracle ", studyName, ".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "oracle")
translatedFile <- paste(OHDSIDirectory, "TxPath translated Postgres ", studyName,".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "postgresql")


studyName = "Depression"
DepTxList <- '21604686, 21500526'
DepDxList <- '440383'
DepExcludeDxList <- '444094,432876,435783'
renderedFile <- paste(OHDSIDirectory, "TxPath rendered ", studyName ,".sql", sep="")
renderSqlFile(inputFile, renderedFile, cdmSchema=cdmSchema, resultsSchema=resultsSchema, studyName = studyName, sourceName=sourceName, txlist=DepTxList, dxlist=DepDxList, excludedxlist=DepExcludeDxList, smallcellcount = minCellCount)
translatedFile <- paste(OHDSIDirectory, "TxPath translated Oracle ", studyName, ".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "oracle")
translatedFile <- paste(OHDSIDirectory, "TxPath translated Postgres ", studyName,".sql",sep="")
translateSqlFile(renderedFile, translatedFile, sourceDialect = "sql server", targetDialect = "postgresql")
