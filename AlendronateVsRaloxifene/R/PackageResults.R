# Copyright 2017 Observational Health Data Sciences and Informatics
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

    createMetaData(connectionDetails, cdmDatabaseSchema, exportFolder)
    cmOutputFolder <- file.path(outputFolder, "cmOutput")
    outcomeReference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
    analysisSummary <- CohortMethod::summarizeAnalyses(outcomeReference)
    analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
    analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
    analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
    analysisSummary <- addAnalysisDescriptions(analysisSummary)

    cohortMethodDataFolder <- outcomeReference$cohortMethodDataFolder[outcomeReference$analysisId == 1 & outcomeReference$outcomeId == 99323]
    cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)

    ### Write results table ###
    write.csv(analysisSummary, file.path(exportFolder, "MainResults.csv"), row.names = FALSE)

    ### Main attrition table ###
    strataFile <- outcomeReference$strataFile[outcomeReference$analysisId == 1 & outcomeReference$outcomeId == 99323]
    strata <- readRDS(strataFile)
    attrition <- CohortMethod::getAttritionTable(strata)
    write.csv(attrition, file.path(exportFolder, "Attrition.csv"), row.names = FALSE)

    ### Main propensity score plots ###
    psFileName <- outcomeReference$sharedPsFile[outcomeReference$sharedPsFile != ""][1]
    ps <- readRDS(psFileName)
    CohortMethod::plotPs(ps, fileName = file.path(exportFolder, "PsPrefScale.png"))
    CohortMethod::plotPs(ps, scale = "propensity", fileName = file.path(exportFolder, "Ps.png"))
    strataFile <- outcomeReference$strataFile[outcomeReference$analysisId == 1 & outcomeReference$outcomeId == 99323]
    strata <- readRDS(strataFile)
    CohortMethod::plotPs(strata,
                         unfilteredData = ps,
                         fileName = file.path(exportFolder, "PsAfterStratificationPrefScale.png"))
    CohortMethod::plotPs(strata,
                         unfilteredData = ps,
                         scale = "propensity",
                         fileName = file.path(exportFolder, "PsAfterStratification.png"))

    ### Propensity model ###
    psFileName <- outcomeReference$sharedPsFile[outcomeReference$sharedPsFile != ""][1]
    ps <- readRDS(psFileName)
    psModel <- CohortMethod::getPsModel(ps, cohortMethodData)
    write.csv(psModel, file.path(exportFolder, "PsModel.csv"), row.names = FALSE)

    ### Main balance tables ###
    strataFile <- outcomeReference$strataFile[outcomeReference$analysisId == 1 & outcomeReference$outcomeId == 99323]
    strata <- readRDS(strataFile)
    balance <- CohortMethod::computeCovariateBalance(strata, cohortMethodData)
    idx <- balance$beforeMatchingSumTreated < minCellCount
    balance$beforeMatchingSumTreated[idx] <- NA
    balance$beforeMatchingMeanTreated[idx] <- NA
    idx <- balance$beforeMatchingSumComparator < minCellCount
    balance$beforeMatchingSumComparator[idx] <- NA
    balance$beforeMatchingMeanComparator[idx] <- NA
    idx <- balance$afterMatchingSumTreated < minCellCount
    balance$afterMatchingSumTreated[idx] <- NA
    balance$afterMatchingMeanTreated[idx] <- NA
    idx <- balance$afterMatchingSumComparator < minCellCount
    balance$afterMatchingSumComparator[idx] <- NA
    balance$afterMatchingMeanComparator[idx] <- NA
    write.csv(balance, file.path(exportFolder, "Balance.csv"), row.names = FALSE)

    ### Removed (redunant) covariates ###
    if (!is.null(cohortMethodData$metaData$deletedCovariateIds)) {
        idx <- is.na(ffbase::ffmatch(cohortMethodData$covariateRef$covariateId, ff::as.ff(cohortMethodData$metaData$deletedCovariateIds)))
        removedCovars <- ff::as.ram(cohortMethodData$covariateRef[ffbase::ffwhich(idx, idx == FALSE), ])
        write.csv(removedCovars, file.path(exportFolder, "RemovedCovars.csv"), row.names = FALSE)
    }

    ### Main Kaplan Meier plots ###
    strataFile <- outcomeReference$strataFile[outcomeReference$analysisId == 1 & outcomeReference$outcomeId == 99323]
    strata <- readRDS(strataFile)
    CohortMethod::plotKaplanMeier(strata,
                                  fileName = file.path(exportFolder, "KaplanMeier.png"))

    ### Copy cohort counts ###
    counts <- read.csv(file.path(outputFolder, "CohortCounts.csv"))
    write.csv(counts, file.path(exportFolder, "CohortCounts.csv"), row.names = FALSE)
    counts <- read.csv(file.path(outputFolder, "cohortIncStats.csv"))
    write.csv(counts, file.path(exportFolder, "cohortIncStats.csv"), row.names = FALSE)
    counts <- read.csv(file.path(outputFolder, "cohortSummaryStats.csv"))
    write.csv(counts, file.path(exportFolder, "cohortSummaryStats.csv"), row.names = FALSE)

    ### Add all to zip file ###
    zipName <- file.path(exportFolder, "StudyResults.zip")
    OhdsiSharing::compressFolder(exportFolder, zipName)
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
    RJDBC::dbDisconnect(conn)
    lines <- paste(names(cdmSource), cdmSource[1, ], sep = ": ")
    lines <- c(lines, paste("OhdsiRTools version", packageVersion("OhdsiRTools"), sep = ": "))
    lines <- c(lines, paste("SqlRender version", packageVersion("SqlRender"), sep = ": "))
    lines <- c(lines,
               paste("DatabaseConnector version", packageVersion("DatabaseConnector"), sep = ": "))
    lines <- c(lines, paste("Cyclops version", packageVersion("Cyclops"), sep = ": "))
    lines <- c(lines,
               paste("FeatureExtraction version", packageVersion("FeatureExtraction"), sep = ": "))
    lines <- c(lines, paste("CohortMethod version", packageVersion("CohortMethod"), sep = ": "))
    lines <- c(lines, paste("OhdsiSharing version", packageVersion("OhdsiSharing"), sep = ": "))
    lines <- c(lines,
               paste("AlendronateVsRaloxifene version", packageVersion("AlendronateVsRaloxifene"), sep = ": "))
    write(lines, file.path(exportFolder, "MetaData.txt"))
    invisible(NULL)
}

addAnalysisDescriptions <- function(object) {
    cmAnalysisListFile <- system.file("settings", "cmAnalysisList.txt", package = "AlendronateVsRaloxifene")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
    # Add analysis description:
    for (i in 1:length(cmAnalysisList)) {
        object$analysisDescription[object$analysisId == cmAnalysisList[[i]]$analysisId] <- cmAnalysisList[[i]]$description
    }
    # Change order of columns:
    aidCol <- which(colnames(object) == "analysisId")
    if (aidCol < ncol(object) - 1) {
        object <- object[, c(1:aidCol, ncol(object) , (aidCol+1):(ncol(object)-1))]
    }
    return(object)
}
