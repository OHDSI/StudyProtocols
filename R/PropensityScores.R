# Copyright 2065 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
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

#' Fit all propensity models
#'
#' @details
#' This function fits all propensity models, using the cohortMethodData objects constructed using the
#' \code{\link{generateAllCohortMethodDataObjects}} function.
#'
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
fitAllPsModels <- function(workFolder, fitThreads = 1, cvThreads = 4) {
    writeLines("Fitting propensity models")
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    tasks <- list()
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        folderName <- file.path(workFolder, paste0("cmData_t", treatmentId, "_c", comparatorId))
        fileName <- file.path(workFolder, paste0("ps_t", treatmentId, "_c", comparatorId, ".rds"))
        if (!file.exists(fileName)){
            task <- data.frame(folderName = folderName,
                               fileName = fileName,
                               cvThreads = cvThreads,
                               stringsAsFactors = FALSE)
            tasks[[length(tasks) + 1]] <- task
        }
    }

    fitPropensityModel <- function(task) {
        cmData <- CohortMethod::loadCohortMethodData(task$folderName)
        ps <- CohortMethod::createPs(cmData,
                                     control = createControl(noiseLevel = "quiet",
                                                             cvType = "auto",
                                                             tolerance = 2e-07,
                                                             cvRepetitions = 1,
                                                             startingVariance = 0.01,
                                                             threads = task$cvThreads,
                                                             seed = 1))
        saveRDS(ps, task$fileName)
    }
    cluster <- OhdsiRTools::makeCluster(fitThreads)
    OhdsiRTools::clusterRequire(cluster, "CohortMethod")
    dummy <- OhdsiRTools::clusterApply(cluster, tasks, fitPropensityModel)
    OhdsiRTools::stopCluster(cluster)
}

#' Plot all propensity score distributions
#'
#' @details
#' This function plots all propensity score distributions, using the propensity score objects constructed using the
#' \code{\link{fitAllPsModels}} function.
#'
#' @param workFolder           Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#'
#' @export
plotAllPsDistributions <- function(workFolder) {
    writeLines("Plotting propensity score distributions")
    figuresAndTablesFolder <- file.path(workFolder, "figuresAndtables")
    if (!file.exists(figuresAndTablesFolder)) {
        dir.create(figuresAndTablesFolder)
    }
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        psFileName <- file.path(workFolder, paste0("ps_t", treatmentId, "_c", comparatorId, ".rds"))
        ps <- readRDS(psFileName)

        plotFileName <- file.path(figuresAndTablesFolder, paste0("ps_t", treatmentId, "_c", comparatorId, ".png"))
        CohortMethod::plotPs(ps,
                             treatmentLabel = as.character(exposureSummary$tCohortDefinitionName[i]),
                             comparatorLabel = as.character(exposureSummary$cCohortDefinitionName[i]),
                             fileName = plotFileName)

        ps$treatment <- 1 - ps$treatment
        ps$propensityScore <- 1 - ps$propensityScore
        plotFileName <- file.path(figuresAndTablesFolder, paste0("ps_t", comparatorId, "_c", treatmentId, ".png"))
        CohortMethod::plotPs(ps,
                             treatmentLabel = as.character(exposureSummary$cCohortDefinitionName[i]),
                             comparatorLabel = as.character(exposureSummary$tCohortDefinitionName[i]),
                             fileName = plotFileName)
    }
}

computePreferenceScore <- function(data) {
    proportion <- sum(data$treatment)/nrow(data)
    propensityScore <- data$propensityScore
    propensityScore[propensityScore > 0.9999999] <- 0.9999999
    x <- exp(log(propensityScore/(1 - propensityScore)) - log(proportion/(1 - proportion)))
    data$preferenceScore <- x/(x + 1)
    return(data)
}

#' @export
computeEquipoiseMatrix <- function(workFolder) {
    writeLines("Computing equipoise matrix")
    figuresAndTablesFolder <- file.path(workFolder, "figuresAndtables")
    if (!file.exists(figuresAndTablesFolder)) {
        dir.create(figuresAndTablesFolder)
    }
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    matrix1 <- data.frame(cohortId1 = exposureSummary$tprimeCohortDefinitionId,
                         cohortName1 = exposureSummary$tCohortDefinitionName,
                         cohortId2 = exposureSummary$cprimeCohortDefinitionId,
                         cohortName2 = exposureSummary$cCohortDefinitionName,
                         equipoise = 0)
    matrix2 <- data.frame(cohortId1 = exposureSummary$cprimeCohortDefinitionId,
                          cohortName1 = exposureSummary$cCohortDefinitionName,
                          cohortId2 = exposureSummary$tprimeCohortDefinitionId,
                          cohortName2 = exposureSummary$tCohortDefinitionName,
                          equipoise = 0)
    matrix <- rbind(matrix1, matrix2)
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        psFileName <- file.path(workFolder, paste0("ps_t", treatmentId, "_c", comparatorId, ".rds"))
        ps <- readRDS(psFileName)
        ps <- computePreferenceScore(ps)
        equipoise <- mean(ps$preferenceScore >= 0.3 & ps$preferenceScore < 0.7)
        matrix$equipoise[matrix$cohortId1 == treatmentId & matrix$cohortId2 == comparatorId] <- equipoise
        matrix$equipoise[matrix$cohortId2 == treatmentId & matrix$cohortId1 == comparatorId] <- equipoise
    }
    write.csv(matrix, file.path(figuresAndTablesFolder, "Equipoise.csv"), row.names = FALSE)
}
