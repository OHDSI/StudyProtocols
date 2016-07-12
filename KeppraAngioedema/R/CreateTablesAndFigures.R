# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of KeppraAngioedema
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


#' Create tables and figures
#'
#' @details
#' Creates tables and figures for viewing and interpreting the results. Requires that the
#' \code{\link{execute}} function has completed first.
#'
#' @param exportFolder   The path to the export folder containing the results.
#'
#' @export
createTableAndFigures <- function(exportFolder) {
  analysisSummary <- read.csv(file.path(exportFolder, "MainResults.csv"))

  tablesAndFiguresFolder <- file.path(exportFolder, "tablesAndFigures")
  if (!file.exists(tablesAndFiguresFolder))
    dir.create(tablesAndFiguresFolder)

  negControlCohortIds <- unique(analysisSummary$outcomeId[analysisSummary$outcomeId != 3])
  # Calibrate p-values and draw calibration plots:
  for (analysisId in unique(analysisSummary$analysisId)) {
    negControlSubset <- analysisSummary[analysisSummary$analysisId == analysisId & analysisSummary$outcomeId %in%
      negControlCohortIds, ]
    negControlSubset <- negControlSubset[!is.na(negControlSubset$logRr) & negControlSubset$logRr !=
      0, ]
    if (nrow(negControlSubset) > 10) {
      null <- EmpiricalCalibration::fitMcmcNull(negControlSubset$logRr, negControlSubset$seLogRr)
      subset <- analysisSummary[analysisSummary$analysisId == analysisId, ]
      calibratedP <- EmpiricalCalibration::calibrateP(null, subset$logRr, subset$seLogRr)
      subset$calibratedP <- calibratedP$p
      subset$calibratedP_lb95ci <- calibratedP$lb95ci
      subset$calibratedP_ub95ci <- calibratedP$ub95ci
      mcmc <- attr(null, "mcmc")
      subset$null_mean <- mean(mcmc$chain[, 1])
      subset$null_sd <- 1/sqrt(mean(mcmc$chain[, 2]))
      analysisSummary$calibratedP[analysisSummary$analysisId == analysisId] <- subset$calibratedP
      analysisSummary$calibratedP_lb95ci[analysisSummary$analysisId == analysisId] <- subset$calibratedP_lb95ci
      analysisSummary$calibratedP_ub95ci[analysisSummary$analysisId == analysisId] <- subset$calibratedP_ub95ci
      analysisSummary$null_mean[analysisSummary$analysisId == analysisId] <- subset$null_mean
      analysisSummary$null_sd[analysisSummary$analysisId == analysisId] <- subset$null_sd
      EmpiricalCalibration::plotCalibration(negControlSubset$logRr,
                                            negControlSubset$seLogRr,
                                            fileName = file.path(tablesAndFiguresFolder,
                                                                 paste0("Cal_a", analysisId, ".png")))
      EmpiricalCalibration::plotCalibrationEffect(negControlSubset$logRr,
                                                  negControlSubset$seLogRr,
                                                  fileName = file.path(tablesAndFiguresFolder,
                                                                       paste0("CalEffectNoHoi_a", analysisId, ".png")))
      hoi <- analysisSummary[analysisSummary$analysisId == analysisId & !(analysisSummary$outcomeId %in%
        negControlCohortIds), ]
      EmpiricalCalibration::plotCalibrationEffect(negControlSubset$logRr,
                                                  negControlSubset$seLogRr,
                                                  hoi$logRr,
                                                  hoi$seLogRr,
                                                  fileName = file.path(tablesAndFiguresFolder,
                                                                       paste0("CalEffect_a", analysisId, ".png")))
      EmpiricalCalibration::plotCalibrationEffect(negControlSubset$logRr,
                                                  negControlSubset$seLogRr,
                                                  hoi$logRr,
                                                  hoi$seLogRr,
                                                  showCis = TRUE,
                                                  fileName = file.path(tablesAndFiguresFolder,
                                                                       paste0("CalEffectCi_a", analysisId, ".png")))
    }
  }
  write.csv(analysisSummary, file.path(tablesAndFiguresFolder,
                                       "EmpiricalCalibration.csv"), row.names = FALSE)

  # Balance plots:
  balance <- read.csv(file.path(exportFolder, "Balance1On1Matching.csv"))
  CohortMethod::plotCovariateBalanceScatterPlot(balance,
                                                fileName = file.path(tablesAndFiguresFolder,
                                                                              "BalanceScatterPlot1On1Matching.png"))
  CohortMethod::plotCovariateBalanceOfTopVariables(balance,
                                                   fileName = file.path(tablesAndFiguresFolder,
                                                                                 "BalanceTopVariables1On1Matching.png"))

  balance <- read.csv(file.path(exportFolder, "BalanceVarRatioMatching.csv"))
  CohortMethod::plotCovariateBalanceScatterPlot(balance,
                                                fileName = file.path(tablesAndFiguresFolder,
                                                                              "BalanceScatterPlotVarRatioMatching.png"))
  CohortMethod::plotCovariateBalanceOfTopVariables(balance,
                                                   fileName = file.path(tablesAndFiguresFolder,
                                                                                 "BalanceTopVariablesVarRatioMatching.png"))

  ### Population characteristics table
  balance <- read.csv(file.path(exportFolder, "BalanceVarRatioMatching.csv"))

  ## Age
  age <- balance[grep("Age group:", balance$covariateName), ]
  age <- data.frame(group = age$covariateName,
                    countTreated = age$beforeMatchingSumTreated,
                    countComparator = age$beforeMatchingsumComparator,
                    fractionTreated = age$beforeMatchingMeanTreated,
                    fractionComparator = age$beforeMatchingMeanComparator)

  # Add removed age group (if any):
  removedCovars <- read.csv(file.path(exportFolder, "RemovedCovars.csv"))
  removedAgeGroup <- removedCovars[grep("Age group:", removedCovars$covariateName), ]
  if (nrow(removedAgeGroup) == 1) {
      totalTreated <- age$countTreated[1] / age$fractionTreated[1]
      missingFractionTreated <- 1 - sum(age$fractionTreated)
      missingFractionComparator <- 1 - sum(age$fractionComparator)
      removedAgeGroup <- data.frame(group = removedAgeGroup$covariateName,
                                    countTreated = round(missingFractionTreated * totalTreated),
                                    countComparator = round(missingFractionComparator * totalTreated),
                                    fractionTreated = missingFractionTreated,
                                    fractionComparator = missingFractionComparator)
      age <- rbind(age, removedAgeGroup)
  }
  age$start <- gsub("Age group: ", "", gsub("-.*$", "", age$group))
  age$start <- as.integer(age$start)
  age <- age[order(age$start), ]
  age$start <- NULL

  ## Gender
  gender <- balance[grep("Gender", balance$covariateName), ]
  gender <- data.frame(group = gender$covariateName,
                       countTreated = gender$beforeMatchingSumTreated,
                       countComparator = gender$beforeMatchingsumComparator,
                       fractionTreated = gender$beforeMatchingMeanTreated,
                       fractionComparator = gender$beforeMatchingMeanComparator)
  # Add removed gender (if any):
  removedGender <- removedCovars[grep("Gender", removedCovars$covariateName), ]
  if (nrow(removedGender) == 1) {
      totalTreated <- gender$countTreated[1] / gender$fractionTreated[1]
      missingFractionTreated <- 1 - sum(gender$fractionTreated)
      missingFractionComparator <- 1 - sum(gender$fractionComparator)
      removedGender <- data.frame(group = removedGender$covariateName,
                                    countTreated = round(missingFractionTreated * totalTreated),
                                    countComparator = round(missingFractionComparator * totalTreated),
                                    fractionTreated = missingFractionTreated,
                                    fractionComparator = missingFractionComparator)
      gender <- rbind(gender, removedGender)
  }
  gender$group <- gsub("Gender = ", "", gender$group)

  ## Calendar year
  year <- balance[grep("Index year", balance$covariateName), ]
  year <- data.frame(group = year$covariateName,
                       countTreated = year$beforeMatchingSumTreated,
                       countComparator = year$beforeMatchingsumComparator,
                       fractionTreated = year$beforeMatchingMeanTreated,
                       fractionComparator = year$beforeMatchingMeanComparator)
  # Add removed year (if any):
  removedYear <- removedCovars[grep("Index year", removedCovars$covariateName), ]
  if (nrow(removedYear) == 1) {
      totalTreated <- year$countTreated[1] / year$fractionTreated[1]
      missingFractionTreated <- 1 - sum(year$fractionTreated)
      missingFractionComparator <- 1 - sum(year$fractionComparator)
      removedYear <- data.frame(group = removedYear$covariateName,
                                  countTreated = round(missingFractionTreated * totalTreated),
                                  countComparator = round(missingFractionComparator * totalTreated),
                                  fractionTreated = missingFractionTreated,
                                  fractionComparator = missingFractionComparator)
      year <- rbind(year, removedYear)
  }
  year$group <- gsub("Index year: ", "", year$group)
  year <- year[order(year$group), ]

  table <- rbind(age, gender, year)
  write.csv(table, file.path(tablesAndFiguresFolder, "PopChar.csv"), row.names = FALSE)

  ### Attrition diagrams
  attrition <- read.csv(file.path(exportFolder, "Attrition1On1Matching.csv"))
  object <- list()
  attr(object, "metaData") <- list(attrition = attrition)
  CohortMethod::drawAttritionDiagram(object, fileName = file.path(tablesAndFiguresFolder, "Attr1On1Matching.png"))

  attrition <- read.csv(file.path(exportFolder, "AttritionVarRatioMatching.csv"))
  object <- list()
  attr(object, "metaData") <- list(attrition = attrition)
  CohortMethod::drawAttritionDiagram(object, fileName = file.path(tablesAndFiguresFolder, "AttrVarRatioMatching.png"))

}
