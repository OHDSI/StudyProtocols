getCohortConceptExpression <- function(cohortDefinitions){
  lapply(cohortDefinitions$expression$ConceptSets, function(x)
    list(originalConceptId = x$id,
         originalConceptName = x$name,
         conceptTable =do.call(rbind, lapply(x$expression$items, function(y) c(unlist(y$concept), 
                                                                               isExcluded = y$isExcluded, 
                                                                               includeDescendants = y$includeDescendants,
                                                                               includeMapped = y$includeMapped)))))
}

getAllConceptExpression  <- function(json){
  res <- do.call(c,lapply(json$cohortDefinitions, function(x){
    lapply(getCohortConceptExpression(x), function(x) x$conceptTable)}
  ))
  
  names(res) <- unlist(lapply(json$cohortDefinitions, function(x){
    
    if(length(x$expression$ConceptSets)!=0){
      
      paste0(x$id,'_',lapply(getCohortConceptExpression(x), function(x) x$originalConceptId ))}}
  ))
  res
}

getConceptSum  <- function(json){
  do.call(rbind,lapply(json$cohortDefinitions, function(x){
    res <- data.frame(
      originalConceptId = unlist(lapply(x$expression$ConceptSets, function(y) y$id)),
      originalConceptName = unlist(lapply(x$expression$ConceptSets, function(y) y$name))
    )
    if(ncol(res)!=0){
      res$cohortDefinitionId <- x$id
    }
    return(res)
  }))
}

formatConcepts <- function(json){
  
  conceptTableSummary <- getConceptSum(json)
  conceptTableSummary$ref <- paste0(conceptTableSummary$cohortDefinitionId,'_', conceptTableSummary$originalConceptId)
  formattedConceptSets <- getAllConceptExpression(json)
  conceptNames <- names(formattedConceptSets)
  names(formattedConceptSets) <- NULL
  uniqueConceptSets <- unique(formattedConceptSets)
  names(formattedConceptSets) <- conceptNames
  
  uniqueRef <- lapply(lapply(uniqueConceptSets, function(y) unlist(lapply(formattedConceptSets, function(x)
    identical(y,x)))), function(l) names(l)[which(l)])
  
  uniqueConceptSets <- lapply(1:length(uniqueConceptSets), function(i)
    list(conceptId = i, 
         conceptName = unique(conceptTableSummary$originalConceptName[conceptTableSummary$ref%in%uniqueRef[[i]]])[1],
         conceptExpressionTable =uniqueConceptSets[[i]]))
  
  newConceptId <- apply(do.call(cbind, lapply(1:length(uniqueRef), 
                                              function(i) {x <- rep(0,nrow(conceptTableSummary));
                                              x[conceptTableSummary$ref%in%uniqueRef[[i]]] <- i; x}
  )),1, sum)
  conceptTableSummary$newConceptId <- newConceptId
  
  return(list(conceptTableSummary=conceptTableSummary, 
              uniqueConceptSets=uniqueConceptSets))
}