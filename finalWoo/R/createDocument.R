#' Create the exposure and outcome cohorts
#'
#' @details
#' This function will create the exposure and outcome cohorts following the definitions included in
#' this package.
#'
#' @param resultDirectory  The directory containing the results (outputFolder)
#' @param analysisId    An integer specifying the model Analysis_Id used to create the document
#' @param cohortIds A vector of cohort ids
#' @param cohortNames A vector of cohort names
#' @param includeValidation  Whether to look in the validation folder and add any validation results
#'
#' @export
createJournalDocument <- function(resultDirectory,
                                  analysisId = 1, 
                                  cohortIds,
                                  cohortNames,
                                  includeValidation = T){
  
  if(missing(resultDirectory)){
    stop('resultDirectory not input')
  }
  
  if(!includeValidation%in%c(T,F)){
    stop('includeValidation must be TRUE or FALSE')
  }
  
  resLoc <- file.path(resultDirectory, paste0('Analysis_',analysisId),'plpResult')
  if(!dir.exists(resLoc)){
    stop('Results are missing for specified analysisId')
  }
  
  res <- PatientLevelPrediction::loadPlpResult(resLoc)
  
  exVal <- NULL
  if(includeValidation){
    valFile <- dir(file.path(resultDirectory,'Validation'),recursive = T)
    ind <- grep(paste0('Analysis_',analysisId), valFile)
    if(length(ind)>0){
      vois <- valFile[ind]
      databaseNames <- sapply(vois, function(x) strsplit(x,'/')[[1]][1])
    
      results <- list()
      length(results) <- length(vois)
      for(i in 1:length(vois)){
        results[[i]] <- readRDS(file.path(resultDirectory,'Validation',vois[i]))
      }
      
      #remove nulls
      results = results[-which(unlist(lapply(results, function(x) is.null(x$performanceEvaluation))))]
      
      summary <- do.call(rbind, lapply(1:length(results), function(i) summariseVal(results[[i]], 
                                                                                     database=databaseNames[[i]])))
      
      summary$Value <- as.double(as.character(summary$Value ))
      summary <- reshape2::dcast(summary, Database ~ Metric, value.var="Value", fun.aggregate = max)
      
      exVal <- list(summary=summary,
                     validation=results)
      
      class(exVal) <- 'validatePlp'
    
    }
  }
  
  PatientLevelPrediction::createPlpJournalDocument(plpResult = res, 
                                                   plpValidation = exVal, 
                                                   targetName = cohortNames[cohortIds==res$model$cohortId][1], 
                                                   outcomeName = cohortNames[cohortIds==res$model$outcomeId][1], 
                                                   plpData = NULL, 
                                                   table1 = F, connectionDetails = NULL,
                                                   includeTrain = T, 
                                                   includeTest = T, 
                                                   includePredictionPicture = F, 
                                                   includeAttritionPlot = T, 
                                                   outputLocation = file.path(resultDirectory,'plp_document.docx'))
  
  return(file.path(resultDirectory,'plp_document.docx'))
  
}


summariseVal <- function(result, database){
  if(!is.null(result$performanceEvaluation$evaluationStatistics)){
    row.names(result$performanceEvaluation$evaluationStatistics) <- NULL
    result <- as.data.frame(result$performanceEvaluation$evaluationStatistics)
    result$Database <- database
    return(result)
  } else{
    return(NULL)
  }
}