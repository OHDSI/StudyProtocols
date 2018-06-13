# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Package the results for sharing with OHDSI researchers
#'
#' @details
#' This function packages the results.
#'
#' @param connectionDetails   An object of type \code{connectionDetails} as created using the
#'                            \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                            DatabaseConnector package.
#' @param cdmDatabaseSchema   Schema name where your patient-level data in OMOP CDM format resides.
#'                            Note that for SQL Server, this should include both the database and
#'                            schema name, for example 'cdm_data.dbo'.
#' @param outputFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#' @param minCellCount        The minimum number of subjects contributing to a count before it can be included in the results.
#'
#' @export
packageResults <- function(connectionDetails, cdmDatabaseSchema, outputFolder, minCellCount = 5) {
  exportFolder <- file.path(outputFolder, "export")
  if (!file.exists(exportFolder))
    dir.create(exportFolder)
  diagnosticsFolder <- file.path(outputFolder, "diagnostics")
  cmOutputFolder <- file.path(outputFolder, "cmOutput")
  
  createMetaData(connectionDetails, cdmDatabaseSchema, exportFolder)
  
  # Copy MDRR, enforcing minCellCount -----------------------------------------------------------------
  fileName <-  file.path(diagnosticsFolder, "mdrrs.csv")
  mdrrs <- read.csv(fileName)
  mdrrs$totalOutcomes[mdrrs$totalOutcomes < minCellCount] <- paste0("<", minCellCount)
  mdrrs$targetPersons[mdrrs$targetPersons < minCellCount] <- paste0("<", minCellCount)
  mdrrs$comparatorPersons[mdrrs$comparatorPersons < minCellCount] <- paste0("<", minCellCount)
  fileName <-  file.path(exportFolder, "mdrrs.csv")
  write.csv(mdrrs, fileName, row.names = FALSE)
  
  # Copy balance files, dropping person counts --------------------------------------------------------
  files <- list.files(path = diagnosticsFolder, pattern = "^balance.*csv$")
  for (file in files) {
    balance <- read.csv(file.path(diagnosticsFolder, file))
    balance$beforeMatchingSumTreated <- NULL
    balance$beforeMatchingSumComparator <- NULL
    balance$afterMatchingSumTreated <- NULL
    balance$afterMatchingSumComparator <- NULL
    write.csv(balance, file.path(exportFolder, file), row.names = FALSE)
  }
  
  # Copy prepared PS plots to export folder ----------------------------------------------------------
  files <- list.files(path = diagnosticsFolder, pattern = "^preparedPsPlot.*csv$", full.names = TRUE)
  file.copy(from = files, to = exportFolder)
  
  # Copy tables 1 to export folder -------------------------------------------------------------------
  files <- list.files(path = diagnosticsFolder, pattern = "^table1.*csv$", full.names = TRUE)
  file.copy(from = files, to = exportFolder)
  
  # All effect size estimates ------------------------------------------------------------------------
  reference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
  analysisSummary <- CohortMethod::summarizeAnalyses(reference)
  analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
  analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
  analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
  allControlsFile <- file.path(outputFolder, "AllControls.csv")
  allControls <- read.csv(allControlsFile)
  allControls$temp <- allControls$outcomeName
  analysisSummary <- merge(analysisSummary, allControls[, c("targetId", "comparatorId", "outcomeId", "oldOutcomeId", "temp", "targetEffectSize", "trueEffectSize")], all.x = TRUE)
  analysisSummary$outcomeName <- as.character(analysisSummary$outcomeName)
  analysisSummary$temp <- as.character(analysisSummary$temp)
  analysisSummary$outcomeName[!is.na(analysisSummary$temp)] <- analysisSummary$temp[!is.na(analysisSummary$temp)]
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(system.file("settings", "cmAnalysisList.json", package = "AlendronateVsRaloxifene"))
  for (i in 1:length(cmAnalysisList)) {
    analysisSummary$description[analysisSummary$analysisId == cmAnalysisList[[i]]$analysisId] <-  cmAnalysisList[[i]]$description
  }
  analysisSummary$treated[analysisSummary$treated < minCellCount] <- paste0("<", minCellCount)
  analysisSummary$comparator[analysisSummary$comparator < minCellCount] <- paste0("<", minCellCount)
  analysisSummary$eventsTreated[analysisSummary$eventsTreated < minCellCount] <- paste0("<", minCellCount)
  analysisSummary$eventsComparator[analysisSummary$eventsComparator < minCellCount] <- paste0("<", minCellCount)
  write.csv(analysisSummary, file.path(exportFolder, "AllEstimates.csv"), row.names = FALSE)
  
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AlendronateVsRaloxifene")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  tcsOfInterest <- unique(tcosOfInterest[, c("targetId", "comparatorId")])
  for (i in 1:nrow(tcsOfInterest)) {
    targetId <- tcsOfInterest$targetId[i]
    comparatorId <- tcsOfInterest$comparatorId[i]
    targetLabel <- tcosOfInterest$targetName[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId][1]
    comparatorLabel <- tcosOfInterest$comparatorName[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId][1]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    for (analysisId in unique(reference$analysisId)) {
      for (outcomeId in outcomeIds) {
        strataFile <- reference$strataFile[reference$analysisId == analysisId &
                                             reference$targetId == targetId &
                                             reference$comparatorId == comparatorId &
                                             reference$outcomeId == outcomeId]
        if (strataFile == "") {
          strataFile <- reference$studyPopFile[reference$analysisId == analysisId &
                                                 reference$targetId == targetId &
                                                 reference$comparatorId == comparatorId &
                                                 reference$outcomeId == outcomeId]
        }
        population <- readRDS(strataFile)
        fileName <-  file.path(exportFolder, paste0("km_a",analysisId,"_t",targetId,"_c",comparatorId, "_o", outcomeId, ".png"))
        CohortMethod::plotKaplanMeier(population = population,
                                      treatmentLabel = targetLabel,
                                      comparatorLabel = comparatorLabel,
                                      fileName = fileName)
      }
    }
  }
  
  # Attition tables -----------------------------------------------------------------------------------
  files <- list.files(path = diagnosticsFolder, pattern = "^attritionTable.*csv$")
  for (file in files) {
    attritionTable<- read.csv(file.path(diagnosticsFolder, file))
    attritionTable$treatedPersons[attritionTable$treatedPersons < minCellCount] <- paste0("<", minCellCount)
    attritionTable$comparatorPersons[attritionTable$comparatorPersons < minCellCount] <- paste0("<", minCellCount)
    attritionTable$treatedExposures[attritionTable$treatedExposures < minCellCount] <- paste0("<", minCellCount)
    attritionTable$comparatorExposures[attritionTable$comparatorExposures < minCellCount] <- paste0("<", minCellCount)
    write.csv(attritionTable, file.path(exportFolder, file), row.names = FALSE)
  }
  
  # Cohort counts, enforcing minCellCount -------------------------------------------------------------
  fileName <- file.path(outputFolder, "CohortCounts.csv")
  cohortCounts <- read.csv(fileName)
  cohortCounts$cohortCount[cohortCounts$cohortCount < minCellCount] <- paste0("<", minCellCount)
  cohortCounts$personCount[cohortCounts$personCount < minCellCount] <- paste0("<", minCellCount)
  fileName <-  file.path(exportFolder, "CohortCounts.csv")
  write.csv(cohortCounts, fileName, row.names = FALSE)
  
  # Add all to zip file -------------------------------------------------------------------------------
  zipName <- file.path(exportFolder, "StudyResults.zip")
  files <- list.files(exportFolder)
  oldWd <- setwd(exportFolder)
  on.exit(setwd(oldWd))
  zip::zip(zipfile = zipName, files = files, recurse = FALSE) 
  writeLines(paste("\nStudy results are ready for sharing at:", zipName))
}

#' Create metadata file
#'
#' @details
#' Creates a file containing metadata about the source data (taken from the cdm_source table) and R
#' package versions.
#'
#' @param connectionDetails   An object of type \code{connectionDetails} as created using the
#'                            \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                            DatabaseConnector package.
#' @param cdmDatabaseSchema   Schema name where your patient-level data in OMOP CDM format resides.
#'                            Note that for SQL Server, this should include both the database and
#'                            schema name, for example 'cdm_data.dbo'.
#' @param exportFolder        The name of the folder where the metadata file should be created.
#'
#' @export
createMetaData <- function(connectionDetails, cdmDatabaseSchema, exportFolder) {
  conn <- DatabaseConnector::connect(connectionDetails)
  sql <- "SELECT * FROM @cdm_database_schema.cdm_source"
  sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  cdmSource <- DatabaseConnector::querySql(conn, sql)
  DatabaseConnector::disconnect(conn)
  lines <- paste(names(cdmSource), cdmSource[1, ], sep = ": ")
  
  snapshot <- OhdsiRTools::takeEnvironmentSnapshot("AlendronateVsRaloxifene")
  lines <- c(lines, "")
  lines <- c(lines, "Package versions:")
  lines <- c(lines, paste(snapshot$package, snapshot$version, sep = ": "))
  write(lines, file.path(exportFolder, "MetaData.txt"))
  invisible(NULL)
}
