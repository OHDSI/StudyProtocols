# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of CelecoxibPredictiveModels
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

#' Compute evaluation metrics for the predictive models
#'
#' @details
#' This function computes the AUC and plots the ROC and calibration plots per predictive model.
#'
#' @param outputFolder	       Name of local folder to place results; make sure to use forward slashes (/)
#'
#' @export
evaluatePredictiveModels <- function(outputFolder) {

    outcomeIds <- 10:16
    minOutcomeCount <- 25

    testPlpDataFile <- file.path(outputFolder, "testPlpData")
    testPlpData <- PatientLevelPrediction::loadPlpData(testPlpDataFile)

    counts <- summary(testPlpData)$outcomeCounts
    for (outcomeId in outcomeIds){
        modelFile <- file.path(outputFolder, paste("model_o",outcomeId, ".rds", sep = ""))
        if (counts$eventCount[counts$outcomeId == outcomeId] > minOutcomeCount && file.exists(modelFile)){
            writeLines(paste("- Evaluating model for outcome", outcomeId))
            model <- readRDS(modelFile)

            predictionsFile <- file.path(outputFolder, paste("predictions_o",outcomeId, ".rds", sep = ""))
            if (file.exists(predictionsFile)){
                predictions <- readRDS(predictionsFile)
            } else {
                predictions <- PatientLevelPrediction::predictProbabilities(model, testPlpData)
                saveRDS(predictions, predictionsFile)
            }

            detailsFile <- file.path(outputFolder, paste("details_o",outcomeId, ".csv", sep = ""))
            if (!file.exists(detailsFile)){
                details <- PatientLevelPrediction::getModelDetails(model, testPlpData)
                write.csv(details, detailsFile, row.names = FALSE)
            }

            aucFile <- file.path(outputFolder, paste("auc_o",outcomeId, ".csv", sep = ""))
            if (!file.exists(aucFile)){
                auc <- PatientLevelPrediction::computeAuc(predictions, testPlpData, confidenceInterval = TRUE)
                write.csv(auc, aucFile, row.names = FALSE)
            }

            rocFile <- file.path(outputFolder, paste("roc_o",outcomeId, ".png", sep = ""))
            if (!file.exists(rocFile)){
                PatientLevelPrediction::plotRoc(predictions, testPlpData, fileName = rocFile)
            }

            calibrationFile <- file.path(outputFolder, paste("calibration_o",outcomeId, ".png", sep = ""))
            if (!file.exists(calibrationFile)){
                PatientLevelPrediction::plotCalibration(predictions, testPlpData, numberOfStrata = 10, fileName = calibrationFile)
            }
        }
    }
}
