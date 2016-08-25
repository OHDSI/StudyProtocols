# Copyright 2016 Observational Health Data Sciences and Informatics
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
    outcomeModelReference <- readRDS(file.path(workFolder, "cmOutput", "outcomeModelReference.rds"))
    for (i in 1:nrow(exposureSummary)) {
        treatmentId <- exposureSummary$tprimeCohortDefinitionId[i]
        comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
        psFileName <- outcomeModelReference$sharedPsFile[outcomeModelReference$targetId == treatmentId & outcomeModelReference$comparatorId == comparatorId & outcomeModelReference$analysisId == 2][1]
        if (file.exists(psFileName)){
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
