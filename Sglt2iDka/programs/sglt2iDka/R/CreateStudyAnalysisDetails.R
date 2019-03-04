#' @export
createEstimateVariants <- function(connectionDetails,
                                   cohortDefinitionSchema,
                                   cohortDefinitionTable,
                                   codeListSchema,
                                   codeListTable,
                                   vocabularyDatabaseSchema,
                                   outputFolder) {
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  sql <- SqlRender::renderSql(sql = "select * from @cohort_definition_schema.@cohort_definition_table",
                              cohort_definition_schema = cohortDefinitionSchema,
                              cohort_definition_table = cohortDefinitionTable)$sql
  cohortDefinitions <- DatabaseConnector::querySql(connection, sql)

  cohortUniverseFile <- file.path(outputFolder, "cohortUniverse.csv")
  write.csv(cohortDefinitions, file = cohortUniverseFile, row.names = FALSE)

  cohortDefinitions <- cohortDefinitions[cohortDefinitions$CENSOR %in% c(90, 0), ]
  drugs <- unique(cohortDefinitions$COHORT_OF_INTEREST[cohortDefinitions$TARGET_COHORT == 1 | cohortDefinitions$COMPARATOR_COHORT == 1])
  cohortDefinitions$excludedCovariateConceptIds <- ""
  for (drug in drugs) {
    sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "getExclusionCovariateConceptIds.sql",
                                             packageName = "sglt2iDka",
                                             dbms = attr(connection, "dbms"),
                                             code_list_schema = codeListSchema,
                                             code_list_table = codeListTable,
                                             vocabulary_database_schema = vocabularyDatabaseSchema,
                                             drug = drug)
    excludedCovariateConceptIds <- DatabaseConnector::querySql(connection, sql)[, 1]
    excludedCovariateConceptIds <- noquote(paste(excludedCovariateConceptIds, collapse = ";"))
    cohortDefinitions$excludedCovariateConceptIds[cohortDefinitions$COHORT_OF_INTEREST == drug] <- excludedCovariateConceptIds
  }
  targetCohorts <- cohortDefinitions[cohortDefinitions$TARGET_COHORT == 1,
                                      c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "T2DM", "CENSOR", "FULL_NAME", "excludedCovariateConceptIds")]
  names(targetCohorts) <- c("targetCohortId", "targetDrugName", "t2dm", "censor", "targetCohortName", "targetExcludedCovariateConceptIds")
  comparatorCohorts <- cohortDefinitions[cohortDefinitions$COMPARATOR_COHORT == 1,
                                         c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "T2DM", "CENSOR", "FULL_NAME", "excludedCovariateConceptIds")]
  names(comparatorCohorts) <- c("comparatorCohortId", "comparatorDrugName", "t2dm", "censor", "comparatorCohortName", "comparatorExcludedCovariateConceptIds")
  outcomeCohorts <- cohortDefinitions[cohortDefinitions$OUTCOME_COHORT == 1, c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST")]
  names(outcomeCohorts) <- c("outcomeCohortId", "outcomeCohortName")
  tcs <- merge(targetCohorts, comparatorCohorts)
  tcs$excludedCovariateConceptIds <- paste(tcs$targetExcludedCovariateConceptIds, tcs$comparatorExcludedCovariateConceptIds, sep = ";")
  tcos <- merge(tcs, outcomeCohorts)
  fullGridTcosAnalyses <- merge(tcos, data.frame(timeAtRisk = c("Intent to Treat", "Per Protocol")))
  tcosAnalyses <- fullGridTcosAnalyses[fullGridTcosAnalyses$targetDrugName != "SGLT2i" | fullGridTcosAnalyses$comparatorDrugName != "Other AHAs", ]

    tcosAnalysesFile <- file.path(outputFolder, "tcoAnalysisVariants.csv")
  write.csv(tcosAnalyses, file = tcosAnalysesFile, row.names = FALSE)
  negativeControlOutcomeCohorts <- cohortDefinitions[cohortDefinitions$NEGATIVE_CONTROL == 1, c(1,2)]
  negativeControlOutcomeCohortsFile <- file.path(outputFolder, "negativeControlOutcomeCohorts.csv")
  write.csv(negativeControlOutcomeCohorts, file = negativeControlOutcomeCohortsFile, row.names = FALSE)
}


#' @export
createTcos <- function() {
  tcosAnalyses <- read.csv(system.file("settings", "tcoAnalysisVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  negativeControlOutcomeCohorts <- read.csv(system.file("settings", "negativeControlOutcomeCohorts.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  negativeControlOutcomeCohortIds <- negativeControlOutcomeCohorts$COHORT_DEFINITION_ID
  tcCombinations <- unique(tcosAnalyses[, c("targetCohortId", "comparatorCohortId")])
  tcoList <- list()
  for (i in 1:nrow(tcCombinations)) {
      targetCohortId <- tcCombinations$targetCohortId[i]
      comparatorCohortId <- tcCombinations$comparatorCohortId[i]
      outcomeCohortIds <- unique(tcosAnalyses$outcomeCohortId[tcosAnalyses$targetCohortId == targetCohortId & tcosAnalyses$comparatorCohortId == comparatorCohortId])
      outcomeCohortIds <- c(outcomeCohortIds, negativeControlOutcomeCohortIds)
      excludeCovariateConceptIds <- unique(as.character(tcosAnalyses$excludedCovariateConceptIds[tcosAnalyses$targetCohortId == targetCohortId & tcosAnalyses$comparatorCohortId == comparatorCohortId]))
      excludeCovariateConceptIds <- as.numeric(strsplit(excludeCovariateConceptIds, split = ";")[[1]])
      tcoCombination <- CohortMethod::createDrugComparatorOutcomes(targetId = targetCohortId,
                                                                   comparatorId = comparatorCohortId,
                                                                   outcomeIds = outcomeCohortIds,
                                                                   excludedCovariateConceptIds =  excludeCovariateConceptIds)
      tcoList[[length(tcoList) + 1]] <- tcoCombination
  }
  return(tcoList)
}

#' @export
createAnalysesDetails <- function(outputFolder) {
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                         useDemographicsAgeGroup = TRUE,
                                                                         useDemographicsIndexYear = TRUE,
                                                                         useDemographicsIndexMonth = TRUE,
                                                                         useConditionGroupEraLongTerm = TRUE,
                                                                         useDrugExposureLongTerm = TRUE,
                                                                         useDrugGroupEraLongTerm = TRUE,
                                                                         useDrugEraOverlapping = TRUE,
                                                                         # DrugGroupEraOverlapping = TRUE,
                                                                         useProcedureOccurrenceLongTerm = TRUE,
                                                                         useMeasurementLongTerm = TRUE,
                                                                         useCharlsonIndex = TRUE,
                                                                         useDcsi = TRUE,
                                                                         useChads2 = TRUE,
                                                                         useDistinctConditionCountLongTerm = TRUE,
                                                                         useDistinctIngredientCountLongTerm = TRUE,
                                                                         useDistinctProcedureCountLongTerm = TRUE,
                                                                         useDistinctMeasurementCountLongTerm = TRUE,
                                                                         useDistinctObservationCountLongTerm = TRUE,
                                                                         useVisitCountLongTerm = TRUE,
                                                                         useVisitConceptCountLongTerm = TRUE,
                                                                         addDescendantsToExclude = TRUE)
  priorOutcomesCovariateSettings <- sglt2iDka::createPriorOutcomesCovariateSettings(outcomeDatabaseSchema = "unknown",
                                                                                    outcomeTable = "unknown",
                                                                                    windowStart = -99999,
                                                                                    windowEnd = -1,
                                                                                    outcomeIds = c(200, 201),
                                                                                    outcomeNames = c("DKA IP ER", "DKA IP"),
                                                                                    analysisId = 999) # any time prior
  # priorOutcomes365dCovariateSettings <- sglt2iDka::createPriorOutcomesCovariateSettings(outcomeDatabaseSchema = "unknown",
  #                                                                                       outcomeTable = "unknown",
  #                                                                                       windowStart = -365,
  #                                                                                       windowEnd = -1,
  #                                                                                       outcomeIds = c(200, 201),
  #                                                                                       outcomeNames = c("DKA IP ER", "DKA IP"),
  #                                                                                       analysisId = 997) # 365d prior
  priorInsulinCovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                                   covariateIdPrefix = 1000,
                                                                                   codeListSchema = "unknown",
                                                                                   codeListTable = "unknown",
                                                                                   vocabularyDatabaseSchema = "unknown",
                                                                                   drug = "Insulin")
  priorAHACovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                               covariateIdPrefix = 2000,
                                                                               codeListSchema = "unknown",
                                                                               codeListTable = "unknown",
                                                                               vocabularyDatabaseSchema = "unknown",
                                                                               drug = "AHAs")
  covariateSettings <- list(defaultCovariateSettings,
                            priorOutcomesCovariateSettings,
                            #priorOutcomes365dCovariateSettings, # unecessary to include
                            priorInsulinCovariateSettings,
                            priorAHACovariateSettings)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = "keep all",
                                                                   restrictToCommonPeriod = FALSE,
                                                                   maxCohortSize = 0, # use 5000 for development
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)

  defaultPrior <- Cyclops::createPrior("laplace",
                                       exclude = c(0),
                                       useCrossValidation = TRUE)

  defaultControl <- Cyclops::createControl(cvType = "auto",
                                           startingVariance = 0.01,
                                           noiseLevel = "quiet",
                                           tolerance  = 1e-06,
                                           maxIterations = 2500,
                                           cvRepetitions = 10,
                                           seed = 1234)

  createPsArgs <- CohortMethod::createCreatePsArgs(control = defaultControl,
                                                   prior = defaultPrior,
                                                   errorOnHighCorrelation = FALSE,
                                                   stopOnError = FALSE)

  matchOnPsArgs <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)

  fitOutcomeModelArgs1 <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "cox",
                                                                  stratified = TRUE,
                                                                  prior = defaultPrior,
                                                                  control = defaultControl)

  timeToFirstPostIndexEventITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                firstExposureOnly = FALSE,
                                                                                washoutPeriod = 0,
                                                                                removeDuplicateSubjects = FALSE,
                                                                                minDaysAtRisk = 0,
                                                                                riskWindowStart = 1,
                                                                                addExposureDaysToStart = FALSE,
                                                                                riskWindowEnd = 9999,
                                                                                addExposureDaysToEnd = FALSE,
                                                                                censorAtNewRiskWindow = FALSE)

  timeToFirstPostIndexEventPP <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                               firstExposureOnly = FALSE,
                                                                               washoutPeriod = 0,
                                                                               removeDuplicateSubjects = FALSE,
                                                                               minDaysAtRisk = 0,
                                                                               riskWindowStart = 1,
                                                                               addExposureDaysToStart = FALSE,
                                                                               riskWindowEnd = 0,
                                                                               addExposureDaysToEnd = TRUE,
                                                                               censorAtNewRiskWindow = FALSE)

  a1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                       description = "Time to First Post Index Event Intent to Treat Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)

  a2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                       description = "Time to First Post Index Event Per Protocol Matching",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPP,
                                       createPs = TRUE,
                                       createPsArgs = createPsArgs,
                                       matchOnPs = TRUE,
                                       matchOnPsArgs = matchOnPsArgs,
                                       fitOutcomeModel = TRUE,
                                       fitOutcomeModelArgs = fitOutcomeModelArgs1)

  cmAnalysisList <- list(a1, a2)
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(outputFolder, "cmAnalysisList.json"))
}


#' @export
createIrSensitivityVariants <- function(connectionDetails,
                                        cohortDefinitionSchema,
                                        cohortDefinitionTable,
                                        outputFolder) {
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  sql <- SqlRender::renderSql(sql = "select * from @cohort_definition_schema.@cohort_definition_table",
                              cohort_definition_schema = cohortDefinitionSchema,
                              cohort_definition_table = cohortDefinitionTable)$sql
  cohortDefinitions <- DatabaseConnector::querySql(connection, sql)
  cohortDefinitions <- cohortDefinitions[cohortDefinitions$CENSOR %in% c(60, 120, 0) & cohortDefinitions$NEGATIVE_CONTROL == 0, ]
  targetCohorts <- cohortDefinitions[cohortDefinitions$TARGET_COHORT == 1,
                                     c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "T2DM", "CENSOR", "FULL_NAME")]
  names(targetCohorts) <- c("targetCohortId", "targetDrugName", "t2dm", "censor", "targetCohortName")
  comparatorCohorts <- cohortDefinitions[cohortDefinitions$COMPARATOR_COHORT == 1,
                                         c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "T2DM", "CENSOR", "FULL_NAME")]
  names(comparatorCohorts) <- c("comparatorCohortId", "comparatorDrugName", "t2dm", "censor", "comparatorCohortName")
  outcomeCohorts <- cohortDefinitions[cohortDefinitions$OUTCOME_COHORT == 1, c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST")]
  names(outcomeCohorts) <- c("outcomeCohortId", "outcomeCohortName")
  tcs <- merge(targetCohorts, comparatorCohorts)
  tcos <- merge(tcs, outcomeCohorts)
  tcos <- tcos[tcos$targetDrugName != "SGLT2i" | tcos$comparatorDrugName != "Other AHAs", ]
  tcosFile <- file.path(outputFolder, "tcoIrSensitivityVariants.csv")
  write.csv(tcos, file = tcosFile, row.names = FALSE)
}

#' @export
createIrSensitivityTcos <- function() {
  tcos <- read.csv(system.file("settings", "tcoIrSensitivityVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  tcCombinations <- unique(tcos[, c("targetCohortId", "comparatorCohortId")])
  tcoList <- list()
  for (i in 1:nrow(tcCombinations)) {
    targetCohortId <- tcCombinations$targetCohortId[i]
    comparatorCohortId <- tcCombinations$comparatorCohortId[i]
    outcomeCohortIds <- unique(tcos$outcomeCohortId[tcos$targetCohortId == targetCohortId & tcos$comparatorCohortId == comparatorCohortId])
    tcoCombination <- CohortMethod::createDrugComparatorOutcomes(targetId = targetCohortId,
                                                                 comparatorId = comparatorCohortId,
                                                                 outcomeIds = outcomeCohortIds)
    tcoList[[length(tcoList) + 1]] <- tcoCombination
  }
  return(tcoList)
}


#' @export
createIrSensitivityAnalysesDetails <- function(outputFolder) {
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                         useDemographicsAgeGroup = TRUE)
  priorOutcomesCovariateSettings <- sglt2iDka::createPriorOutcomesCovariateSettings(outcomeDatabaseSchema = "unknown",
                                                                                    outcomeTable = "unknown",
                                                                                    windowStart = -99999,
                                                                                    windowEnd = -1,
                                                                                    outcomeIds = c(200, 201),
                                                                                    outcomeNames = c("DKA IP ER", "DKA IP"),
                                                                                    analysisId = 999) # any time prior
  priorInsulinCovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                                   covariateIdPrefix = 1000,
                                                                                   codeListSchema = "unknown",
                                                                                   codeListTable = "unknown",
                                                                                   vocabularyDatabaseSchema = "unknown",
                                                                                   drug = "Insulin")
  priorAHACovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                               covariateIdPrefix = 2000,
                                                                               codeListSchema = "unknown",
                                                                               codeListTable = "unknown",
                                                                               vocabularyDatabaseSchema = "unknown",
                                                                               drug = "AHAs")
  covariateSettings <- list(defaultCovariateSettings, priorOutcomesCovariateSettings, priorInsulinCovariateSettings, priorAHACovariateSettings)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = "keep all",
                                                                   restrictToCommonPeriod = FALSE,
                                                                   maxCohortSize = 0,
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)

  timeToFirstPostIndexEventPP <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                               firstExposureOnly = FALSE,
                                                                               washoutPeriod = 0,
                                                                               removeDuplicateSubjects = FALSE,
                                                                               minDaysAtRisk = 0,
                                                                               riskWindowStart = 1,
                                                                               addExposureDaysToStart = FALSE,
                                                                               riskWindowEnd = 0,
                                                                               addExposureDaysToEnd = TRUE,
                                                                               censorAtNewRiskWindow = FALSE)

  a1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                       description = "Time to First Post Index Event IR Sensitivity",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventPP)

  cmAnalysisList <- list(a1)
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(outputFolder, "cmIrSensitivityAnalysisList.json"))
}


#' @export
createIrDoseVariants <- function(connectionDetails,
                                 cohortDefinitionSchema,
                                 cohortDoseDefinitionTable,
                                 cohortDefinitionTable,
                                 outputFolder) {
  cohortDefinitionSchema <- "scratch.dbo"
  cohortDoseDefinitionTable <- "epi535_cohort_universe_dose"
  cohortDefinitionTable <- "epi535_cohort_universe"
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  sql <- SqlRender::renderSql(sql = "select * from @cohort_definition_schema.@cohort_definition_table",
                              cohort_definition_schema = cohortDefinitionSchema,
                              cohort_definition_table = cohortDoseDefinitionTable)$sql
  cohortDefinitions <- DatabaseConnector::querySql(connection, sql)
  cohortUniverseDoseFile <- file.path(outputFolder, "cohortUniverseDose.csv")
  write.csv(cohortDefinitions, file = cohortUniverseDoseFile, row.names = FALSE)
  targetCohorts <- cohortDefinitions[1:9, c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "FULL_NAME")] # create as few CM data objects as possible that obtain data on all dose cohorts
  names(targetCohorts) <- c("targetCohortId", "targetDrugName", "targetCohortName")
  comparatorCohorts <- cohortDefinitions[10:18, c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST", "FULL_NAME")]
  names(comparatorCohorts) <- c("comparatorCohortId", "comparatorDrugName", "comparatorCohortName")
  tcs <- cbind(targetCohorts, comparatorCohorts)
  sql <- SqlRender::renderSql(sql = "select * from @cohort_definition_schema.@cohort_definition_table",
                              cohort_definition_schema = cohortDefinitionSchema,
                              cohort_definition_table = cohortDefinitionTable)$sql
  outcomeCohorts <- DatabaseConnector::querySql(connection, sql)
  outcomeCohorts <- outcomeCohorts[outcomeCohorts$OUTCOME_COHORT == 1, c("COHORT_DEFINITION_ID", "COHORT_OF_INTEREST")]
  names(outcomeCohorts) <- c("outcomeCohortId", "outcomeCohortName")
  tcos <- merge(tcs, outcomeCohorts)
  tcosFile <- file.path(outputFolder, "tcoIrDoseVariants.csv")
  write.csv(tcos, file = tcosFile, row.names = FALSE)
}

#' @export
createIrDoseTcos <- function() {
  tcos <- read.csv(system.file("settings", "tcoIrDoseVariants.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  tcCombinations <- unique(tcos[, c("targetCohortId", "comparatorCohortId")])
  tcoList <- list()
  for (i in 1:nrow(tcCombinations)) {
    targetCohortId <- tcCombinations$targetCohortId[i]
    comparatorCohortId <- tcCombinations$comparatorCohortId[i]
    outcomeCohortIds <- unique(tcos$outcomeCohortId[tcos$targetCohortId == targetCohortId & tcos$comparatorCohortId == comparatorCohortId])
    tcoCombination <- CohortMethod::createDrugComparatorOutcomes(targetId = targetCohortId,
                                                                 comparatorId = comparatorCohortId,
                                                                 outcomeIds = outcomeCohortIds)
    tcoList[[length(tcoList) + 1]] <- tcoCombination
  }
  return(tcoList)
}

#' @export
createIrDoseAnalysesDetails <- function(outputFolder) {
  defaultCovariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                         useDemographicsAgeGroup = TRUE)
  priorOutcomesCovariateSettings <- sglt2iDka::createPriorOutcomesCovariateSettings(outcomeDatabaseSchema = "unknown",
                                                                                    outcomeTable = "unknown",
                                                                                    windowStart = -99999,
                                                                                    windowEnd = -1,
                                                                                    outcomeIds = c(200, 201),
                                                                                    outcomeNames = c("DKA IP ER", "DKA IP"),
                                                                                    analysisId = 999) # any time prior
  priorInsulinCovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                                   covariateIdPrefix = 1000,
                                                                                   codeListSchema = "unknown",
                                                                                   codeListTable = "unknown",
                                                                                   vocabularyDatabaseSchema = "unknown",
                                                                                   drug = "Insulin")
  priorAHACovariateSettings <- sglt2iDka::createPriorExposureCovariateSettings(exposureDatabaseSchema = "unknown",
                                                                               covariateIdPrefix = 2000,
                                                                               codeListSchema = "unknown",
                                                                               codeListTable = "unknown",
                                                                               vocabularyDatabaseSchema = "unknown",
                                                                               drug = "AHAs")
  covariateSettings <- list(defaultCovariateSettings, priorOutcomesCovariateSettings, priorInsulinCovariateSettings, priorAHACovariateSettings)

  getDbCmDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(washoutPeriod = 0,
                                                                   firstExposureOnly = FALSE,
                                                                   removeDuplicateSubjects = "keep all",
                                                                   restrictToCommonPeriod = FALSE,
                                                                   maxCohortSize = 0,
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covariateSettings)

  timeToFirstPostIndexEventITT <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = FALSE,
                                                                                firstExposureOnly = FALSE,
                                                                                washoutPeriod = 0,
                                                                                removeDuplicateSubjects = FALSE,
                                                                                minDaysAtRisk = 0,
                                                                                riskWindowStart = 1,
                                                                                addExposureDaysToStart = FALSE,
                                                                                riskWindowEnd = 9999,
                                                                                addExposureDaysToEnd = FALSE,
                                                                                censorAtNewRiskWindow = FALSE)

  a1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                       description = "Time to First Post Index Event IR dose ITT",
                                       getDbCohortMethodDataArgs = getDbCmDataArgs,
                                       createStudyPopArgs = timeToFirstPostIndexEventITT)

  cmAnalysisList <- list(a1)
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(outputFolder, "cmIrDoseAnalysisList.json"))
}

#' @export
addCohortNames <- function(data,
                           dose = FALSE,
                           IdColumnName = "cohortDefinitionId",
                           nameColumnName = "cohortName") {
  if (dose) {
    cohortsToCreate <- read.csv(system.file("settings", "cohortUniverse.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
    cohortsToCreateDose <- read.csv(system.file("settings", "cohortUniverseDose.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
    cohortsToCreateDose <- cohortsToCreateDose[, -c(13,14)]
    cohortsToCreate <- rbind(cohortsToCreate, cohortsToCreateDose)
  } else {
    cohortsToCreate <- read.csv(system.file("settings", "cohortUniverse.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  }
  cohortsToCreate$FULL_NAME[is.na(cohortsToCreate$FULL_NAME)] <- cohortsToCreate$COHORT_OF_INTEREST[is.na(cohortsToCreate$FULL_NAME)]
  cohortsToCreate <- cohortsToCreate[, c("COHORT_DEFINITION_ID", "FULL_NAME")]
  names(cohortsToCreate) <- c("cohortId", "name")
  idToName <- cohortsToCreate
  idToName <- idToName[order(idToName$cohortId), ]
  idToName <- idToName[!duplicated(idToName$cohortId), ]
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data) , (idCol+1):(ncol(data)-1))]
  }
  return(data)
}
