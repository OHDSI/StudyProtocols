# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
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

#' Create figures and tables for report
#'
#' @details
#' This function generates tables and figures for the report on the study results.
#'
#' @param outputFolders        Vector of names of local folders where the results were generated; make sure 
#'                             to use forward slashes (/). D
#' @param maOutputFolder       A local folder where the meta-anlysis results will be written.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
doMetaAnalysis <- function(outputFolders, maOutputFolder, maxCores) {
  OhdsiRTools::logInfo("Performing meta-analysis")
  resultsFolder <- file.path(maOutputFolder, "results")
  if (!file.exists(resultsFolder))
    dir.create(resultsFolder, recursive = TRUE)
  shinyDataFolder <- file.path(resultsFolder, "shinyData")
  if (!file.exists(shinyDataFolder))
    dir.create(shinyDataFolder)
  
  loadResults <- function(outputFolder) {
    files <- list.files(file.path(outputFolder, "results"), pattern = "results_.*.csv", full.names = TRUE)
    OhdsiRTools::logInfo("Loading ", files[1], " for meta-analysis")
    return(read.csv(files[1]))  
  }
  allResults <- lapply(outputFolders, loadResults)
  allResults <- do.call(rbind, allResults)
  groups <- split(allResults, paste(allResults$targetId, allResults$comparatorId, allResults$analysisId))
  # Meta-analysis 1: use Hartung-Knapp-Sidik-Jonkman
  OhdsiRTools::logInfo("Meta-analysis using Hartung-Knapp-Sidik-Jonkman")
  cluster <- OhdsiRTools::makeCluster(min(maxCores, 15))
  results <- OhdsiRTools::clusterApply(cluster, groups, computeGroupMetaAnalysis, shinyDataFolder = shinyDataFolder, hksj = TRUE)
  OhdsiRTools::stopCluster(cluster)
  results <- do.call(rbind, results)
  
  fileName <-  file.path(resultsFolder, paste0("results_Meta-analysis_HKSJ.csv"))
  write.csv(results, fileName, row.names = FALSE)
  
  hois <- results[results$type == "Outcome of interest", ]
  fileName <-  file.path(shinyDataFolder, paste0("resultsHois_Meta-analysis_HKSJ.rds"))
  saveRDS(hois, fileName)
  
  ncs <- results[results$type == "Negative control", c("targetId", "comparatorId", "outcomeId", "analysisId", "database", "logRr", "seLogRr")]
  fileName <-  file.path(shinyDataFolder, paste0("resultsNcs_Meta-analysis_HKSJ.rds"))
  saveRDS(ncs, fileName)
  
  # Meta-analysis 1: use DerSimonian-Laird
  OhdsiRTools::logInfo("Meta-analysis using DerSimonian-Laird")
  cluster <- OhdsiRTools::makeCluster(min(maxCores, 15))
  results <- OhdsiRTools::clusterApply(cluster, groups, computeGroupMetaAnalysis, shinyDataFolder = shinyDataFolder, hksj = FALSE)
  OhdsiRTools::stopCluster(cluster)
  results <- do.call(rbind, results)
  
  fileName <-  file.path(resultsFolder, paste0("results_Meta-analysis_DL.csv"))
  write.csv(results, fileName, row.names = FALSE)
  
  hois <- results[results$type == "Outcome of interest", ]
  fileName <-  file.path(shinyDataFolder, paste0("resultsHois_Meta-analysis_DL.rds"))
  saveRDS(hois, fileName)
  
  ncs <- results[results$type == "Negative control", c("targetId", "comparatorId", "outcomeId", "analysisId", "database", "logRr", "seLogRr")]
  fileName <-  file.path(shinyDataFolder, paste0("resultsNcs_Meta-analysis_DL.rds"))
  saveRDS(ncs, fileName)
}

computeGroupMetaAnalysis <- function(group, shinyDataFolder, hksj) {
  # group <- groups[[2]]
  analysisId <- group$analysisId[1]
  targetId <- group$targetId[1]
  comparatorId <- group$comparatorId[1]
  OhdsiRTools::logTrace("Performing meta-analysis for target ", targetId, ", comparator ", comparatorId, ", analysis", analysisId)
  outcomeGroups <- split(group, group$outcomeId)
  outcomeGroupResults <- lapply(outcomeGroups, computeSingleMetaAnalysis, hksj = hksj)
  groupResults <- do.call(rbind, outcomeGroupResults)
  negControlSubset <- groupResults[groupResults$type == "Negative control", ]
  validNcs <- sum(!is.na(negControlSubset$seLogRr))
  if (validNcs >= 5) {
    if (hksj) {
      fileName <-  file.path(shinyDataFolder, paste0("null_a",analysisId,"_t",targetId,"_c",comparatorId,"_Meta-analysis_HKJS.rds"))
    } else {
      fileName <-  file.path(shinyDataFolder, paste0("null_a",analysisId,"_t",targetId,"_c",comparatorId,"_Meta-analysis_DL.rds"))
    }
    null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
    saveRDS(null, fileName)
    
    calibratedP <- EmpiricalCalibration::calibrateP(null = null,
                                                    logRr = groupResults$logRr,
                                                    seLogRr = groupResults$seLogRr)
    groupResults$calP <- calibratedP$p
    groupResults$calP_lb95ci <- calibratedP$lb95ci
    groupResults$calP_ub95ci <- calibratedP$ub95ci
  } else {
    groupResults$calP <- NA
    groupResults$calP_lb95ci <- NA
    groupResults$calP_ub95ci <- NA
  }
  return(groupResults)
}

computeSingleMetaAnalysis <- function(outcomeGroup, hksj) {
  # outcomeGroup <- outcomeGroups[[1]]
  maRow <- outcomeGroup[1, ]
  outcomeGroup <- outcomeGroup[!is.na(outcomeGroup$seLogRr), ]
  if (nrow(outcomeGroup) == 0) {
    maRow$treated <- 0
    maRow$comparator <- 0
    maRow$treatedDays <- 0
    maRow$comparatorDays <- 0
    maRow$eventsTreated <- 0
    maRow$eventsComparator <- 0
    maRow$rr <- NA
    maRow$ci95lb <- NA
    maRow$ci95ub <- NA
    maRow$p <- NA
    maRow$logRr <- NA
    maRow$seLogRr <- NA
    maRow$i2 <- NA
  } else if (nrow(outcomeGroup) == 1) {
    maRow <- outcomeGroup[1, ]
    maRow$i2 <- 0
  } else {
    maRow$treated <- sum(outcomeGroup$treated)
    maRow$comparator <- sum(outcomeGroup$comparator)
    maRow$treatedDays <- sum(outcomeGroup$treatedDays)
    maRow$comparatorDays <- sum(outcomeGroup$comparatorDays)
    maRow$eventsTreated <- sum(outcomeGroup$eventsTreated)
    maRow$eventsComparator <- sum(outcomeGroup$eventsComparator)
    meta <- meta::metagen(outcomeGroup$logRr, outcomeGroup$seLogRr, sm = "RR", hakn = hksj)
    s <- summary(meta)
    maRow$i2 <- s$I2$TE
    if (maRow$i2 < .40) {
      rnd <- s$random  
      maRow$rr <- exp(rnd$TE)
      maRow$ci95lb <- exp(rnd$lower)
      maRow$ci95ub <- exp(rnd$upper)
      maRow$p <- rnd$p
      maRow$logRr <- rnd$TE
      maRow$seLogRr <- rnd$seTE
    } else {
      maRow$rr <- NA
      maRow$ci95lb <- NA
      maRow$ci95ub <- NA
      maRow$p <- NA
      maRow$logRr <- NA
      maRow$seLogRr <- NA
    }
  }
  if (is.na(maRow$logRr)) {
    maRow$mdrr <- NA
  } else {
    alpha <- 0.05
    power <- 0.8
    z1MinAlpha <- qnorm(1 - alpha/2)
    zBeta <- -qnorm(1 - power)
    pA <- maRow$treated / (maRow$treated + maRow$comparator)
    pB <- 1 - pA
    totalEvents <- maRow$eventsTreated + maRow$eventsComparator
    maRow$mdrr <- exp(sqrt((zBeta + z1MinAlpha)^2/(totalEvents * pA * pB)))
  }
  if (hksj) {
    maRow$database <- "Meta-analysis (HKSJ)"
  } else {
    maRow$database <- "Meta-analysis (DL)"
  }
  return(maRow)
}
