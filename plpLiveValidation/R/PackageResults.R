# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of PredictionNetworkStudySkeleton
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
#' @param outputFolder        Name of local folder to place results; make sure to use forward slashes
#'                            (/)
#' @param minCellCount        The minimum number of subjects contributing to a count before it can be included in the results.
#'
#' @export
packageResults <- function(outputFolder,
                           minCellCount = 5) {
  if(missing(outputFolder)){
    stop('Missing outputFolder...')
  }

  # for each analysis copy the requested files...
  folders <- list.dirs(path = outputFolder, recursive = T, full.names = F)
  folders <- folders[grep('Analysis_', folders)]
  if(length(grep('inst/plp_models', folders))>0){
    folders <- folders[-grep('inst/plp_models', folders)] #in case using package directory
  }
  
  if(length(folders)==0){
    stop('No results to export...')
    }

  #create export subfolder in workFolder
  exportFolder <- file.path(outputFolder, "export")

  for(folder in folders){
    #copy all plots across
    if (!file.exists(file.path(exportFolder,folder))){
      dir.create(file.path(exportFolder,folder), recursive = T)
    }

    # loads analysis results
    if(file.exists(file.path(outputFolder,folder, 'validationResult.rds'))){
      plpResult <- readRDS(file.path(outputFolder,folder, 'validationResult.rds'))

      if(minCellCount==0){
        minCellCount <- NULL
      }
      result <- PatientLevelPrediction::transportPlp(plpResult, save = F,
                                                     n=minCellCount,
                                                     includeEvaluationStatistics=T,
                                                     includeThresholdSummary=T,
                                                     includeDemographicSummary=T,
                                                     includeCalibrationSummary =T,
                                                     includePredictionDistribution=T,
                                                     includeCovariateSummary=T)
      saveRDS(result, file.path(exportFolder,folder, 'validationResult.rds'))

    }
  }


  ### Add all to zip file ###
  zipName <- paste0(outputFolder, '.zip')
  OhdsiSharing::compressFolder(exportFolder, zipName)
  # delete temp folder
  unlink(exportFolder, recursive = T)

  writeLines(paste("\nStudy results are compressed and ready for sharing at:", zipName))
  return(zipName)
}
