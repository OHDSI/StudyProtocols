createValidationPackage <- function(modelFolder, 
                                    outputFolder,
                                    minCellCount = 5,
                                    databaseName = 'sharable name of development data',
                                    jsonSettings,
                                    analysisIds = NULL){
  
  # json needs to contain the cohort details and packagename
  
  Hydra::hydrate(specifications = jsonSettings, 
                 outputFolder=outputFolder)
  
  transportPlpModels(analysesDir = modelFolder,
                     minCellCount = minCellCount,
                     databaseName = databaseName,
                     outputDir = file.path(outputFolder,"inst/plp_models"),
                     analysisIds = analysisIds)
  
  return(TRUE)
  
}

transportPlpModels <- function(analysesDir,
                               minCellCount = 5,
                               databaseName = 'sharable name of development data',
                               outputDir = "./inst/plp_models",
                               analysisIds = NULL){
  
  files <- dir(analysesDir, recursive = F, full.names = F)
  files <- files[grep('Analysis_', files)]
  
  if(!is.null(analysisIds)){
    #restricting to analysisIds
    files <- files[gsub('Analysis_','',files)%in%analysisIds]
  }
  
  filesIn <- file.path(analysesDir, files , 'plpResult')
  filesOut <- file.path(outputDir, files, 'plpResult')
  
  for(i in 1:length(filesIn)){
    if(file.exists(filesIn[i])){
      plpResult <- PatientLevelPrediction::loadPlpResult(filesIn[i])
      PatientLevelPrediction::transportPlp(plpResult,
                                           modelName= files[i], dataName=databaseName,
                                           outputFolder = filesOut[i],
                                           n=minCellCount,
                                           includeEvaluationStatistics=T,
                                           includeThresholdSummary=T, includeDemographicSummary=T,
                                           includeCalibrationSummary =T, includePredictionDistribution=T,
                                           includeCovariateSummary=T, save=T)
    }
    
  }
}