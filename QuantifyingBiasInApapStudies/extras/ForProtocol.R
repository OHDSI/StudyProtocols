library(DatabaseConnector)

connectionDetails <- createConnectionDetails(dbms = "pdw",
                                             server = Sys.getenv("PDW_SERVER"),
                                             port = Sys.getenv("PDW_PORT"))

cdmDatabaseSchema <- "cdM_cprd_v1017.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_epi_688_cohorts"
oracleTempSchema <- NULL
outputFolder <- "s:/QuantifyingBiasInApapStudies"
maxCores <- parallel::detectCores()

conn <- connect(connectionDetails)

# List all drugs in CPRD containing APAP -----------------------------------------------------------------
sql <- "
SELECT vocabulary_id AS coding_system,
  concept_code AS code,
  concept_name AS description,
  COUNT(*) AS code_frequency
FROM @cdm_database_schema.drug_exposure
INNER JOIN @cdm_database_schema.concept_ancestor
  ON drug_concept_id = descendant_concept_id
INNER JOIN @cdm_database_schema.concept
  ON drug_source_concept_id = concept_id
WHERE ancestor_concept_id = 1125315 -- Acetaminophen
GROUP BY vocabulary_id,
  concept_code,
  concept_name;
"

table <- renderTranslateQuerySql(conn, sql, cdm_database_schema = cdmDatabaseSchema)
write.csv(table, "documents/AppendixA.csv", row.names = FALSE)

# Identify all ingredients in drugs containing APAP -------------------------------------------------------
sql <- "
SELECT concept_id,
  concept_name,
  COUNT_BIG(*) AS concept_frequency
FROM @cdm_database_schema.drug_exposure
INNER JOIN @cdm_database_schema.concept_ancestor apap
  ON drug_concept_id = apap.descendant_concept_id
INNER JOIN @cdm_database_schema.concept_ancestor other_ingredient
  ON drug_concept_id = other_ingredient.descendant_concept_id
INNER JOIN @cdm_database_schema.concept
  ON other_ingredient.ancestor_concept_id = concept_id
WHERE apap.ancestor_concept_id = 1125315 -- Acetaminophen
  AND concept_class_id = 'Ingredient'
GROUP BY concept_id,
  concept_name;
"

table <- renderTranslateQuerySql(conn, sql, cdm_database_schema = cdmDatabaseSchema, snakeCaseToCamelCase = TRUE)
write.csv(table, "documents/IngredientsToExclude.csv", row.names = FALSE)

paste(table$conceptId, collapse = ", ")

# Observed subjects over time -----------------------------------------------------------------------------
sql <- "
SELECT year, 
  COUNT(*) AS persons_observed
FROM (
  SELECT DISTINCT year,
    mid_month
  FROM (
    SELECT YEAR(observation_period_start_date) + CAST((MONTH(observation_period_start_date)-1) AS FLOAT)/12 AS year,
      DATEFROMPARTS(YEAR(observation_period_start_date), MONTH(observation_period_start_date), 15) AS mid_month
    FROM @cdm_database_schema.observation_period

    UNION ALL
    
    SELECT YEAR(observation_period_end_date) + CAST((MONTH(observation_period_end_date)-1) AS FLOAT)/12 AS year,
      DATEFROMPARTS(YEAR(observation_period_end_date), MONTH(observation_period_end_date), 15) AS mid_month
    FROM @cdm_database_schema.observation_period
  ) temp
) months
INNER JOIN @cdm_database_schema.observation_period
  ON mid_month >= observation_period_start_date
    AND mid_month <= observation_period_end_date
GROUP BY year;
"
data <- renderTranslateQuerySql(conn, sql, cdm_database_schema = cdmDatabaseSchema, snakeCaseToCamelCase = TRUE)


library(ggplot2)
require(scales)
maxY <- max(data$personsObserved)
ggplot(data, aes(x = year, y = personsObserved)) +
  geom_rect(xmin = 2008, xmax = 2009, ymin = 0, ymax = maxY*1.2, color = NA, fill = rgb(0.1, 0.1, 0.1, alpha = 0.01)) +
  geom_area(fill = rgb(0, 0, 0.8), alpha = 0.6) +
  geom_vline(xintercept = c(2008, 2009), size = 1) +
  geom_label(x = 2008.5, y = maxY*1.01, label = "2008", hjust = 0.5) +
  # geom_label(x = 2015.5, y = maxY*1.01, label = "Dec 31, 2014", hjust = 0.5) +
  scale_x_continuous("Calendar time") +
  scale_y_continuous("Persons observed", labels = comma)
ggsave("documents/cprdTime.png", width = 11, height = 3)

disconnect(conn)

# Evaluate cohort definitions ----------------------------------------
cohortsToCreate <- read.csv("inst/settings/CohortsToCreate.csv")
for (i in 1:nrow(cohortsToCreate)) {
  jsonFileName <- file.path("inst","cohorts", paste0(cohortsToCreate$name[i], ".json"))
  sqlFileName <- file.path("inst","sql", "sql_server", paste0(cohortsToCreate$name[i], ".sql"))
  outputFile <- file.path("documents", paste0("SourceCodeCheck_", cohortsToCreate$name[i], ".html"))
  cohortJson <- readChar(jsonFileName, file.info(jsonFileName)$size)
  cohortSql <- readChar(sqlFileName, file.info(sqlFileName)$size)
  MethodEvaluation::checkCohortSourceCodes(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           cohortJson = cohortJson,
                                           cohortSql = cohortSql,
                                           outputFile = outputFile)
}

orphans <- MethodEvaluation::findOrphanSourceCodes(connectionDetails = connectionDetails,
                                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                                   oracleTempSchema = oracleTempSchema,
                                                   conceptName = "Acetaminophen",
                                                   conceptSynonyms = c("Paracetamol"))
View(orphans)
# Note: potential orphans found, but these turned out to be legacy STCM entries

# Inspect cohorts ---------------------------------------------
CdmTools::launchCohortExplorer(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               cohortTable = cohortTable,
                               cohortDefinitionId = 1)

CdmTools::launchCohortExplorer(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               cohortTable = cohortTable,
                               cohortDefinitionId = 2)

# Power calculations case-control study ----------------------------------
createCohorts(connectionDetails,
              cdmDatabaseSchema,
              cohortDatabaseSchema,
              cohortTable,
              oracleTempSchema,
              outputFolder)

runCaseControl(connectionDetails,
               cdmDatabaseSchema,
               cohortDatabaseSchema,
               cohortTable,
               oracleTempSchema,
               outputFolder,
               maxCores)

ccOutputFolder <- file.path(outputFolder, "ccOutput")
omReference <- readRDS(file.path(ccOutputFolder, "outcomeModelReference.rds"))

outcomeId <- 11666
analysisId <- 1

computeMdrr <- function(outcomeId, analysisId) {
  studyPopFile <- omReference$caseControlDataFile[omReference$outcomeId == outcomeId & omReference$analysisId == analysisId]
  studyPop <- readRDS(file.path(ccOutputFolder, studyPopFile))
  mdrr <- CaseControl::computeMdrr(studyPop)
  mdrr$analysisId <- analysisId
  mdrr$outcomeId <- outcomeId
  return(mdrr)
}
computeMdrrForAnalysis <- function(analysisId) {
  mdrrs <- lapply(unique(omReference$outcomeId), computeMdrr, analysisId = analysisId)
  return(do.call(rbind, mdrrs))
}

mdrrs <- lapply(unique(omReference$analysisId), computeMdrrForAnalysis)
mdrrs <- do.call(rbind, mdrrs)
mdrrs <- QuantifyingBiasInApapStudies:::addCohortNames(mdrrs, IdColumnName = "outcomeId", nameColumnName = "outcomeName")
pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
negativeControls <- read.csv(pathToCsv)
mdrrs$negativeControl <- "No" 
mdrrs$negativeControl[mdrrs$outcomeId %in% negativeControls$outcomeId] <- "Yes" 

mdrrs <- mdrrs[order(mdrrs$analysisId, mdrrs$outcomeId), ]
write.csv(mdrrs, file.path("documents", "AppendixB.csv"), row.names = FALSE)

min(mdrrs$exposedControls, na.rm = TRUE)
max(mdrrs$exposedControls, na.rm = TRUE)

# Power calculations cohort study -----------------------------------------
createCohorts(connectionDetails,
              cdmDatabaseSchema,
              cohortDatabaseSchema,
              cohortTable,
              oracleTempSchema,
              outputFolder)

runCohortMethod(connectionDetails,
                cdmDatabaseSchema,
                cohortDatabaseSchema,
                cohortTable,
                oracleTempSchema,
                outputFolder,
                maxCores)

cmOutputFolder <- file.path(outputFolder, "cmOutput")
omReference <- readRDS(file.path(cmOutputFolder, "outcomeModelReference.rds"))
outcomeId <- 11666
analysisId <- 1

computeMdrr <- function(outcomeId, analysisId) {
  studyPopFile <- omReference$studyPopFile[omReference$outcomeId == outcomeId & omReference$analysisId == analysisId]
  studyPop <- readRDS(file.path(cmOutputFolder, studyPopFile))
  mdrr <- CohortMethod::computeMdrr(studyPop)
  mdrr$analysisId <- analysisId
  mdrr$outcomeId <- outcomeId
  return(mdrr)
}
computeMdrrForAnalysis <- function(analysisId) {
  mdrrs <- lapply(unique(omReference$outcomeId), computeMdrr, analysisId = analysisId)
  return(do.call(rbind, mdrrs))
}

mdrrs <- lapply(unique(omReference$analysisId), computeMdrrForAnalysis)
mdrrs <- do.call(rbind, mdrrs)
mdrrs <- QuantifyingBiasInApapStudies:::addCohortNames(mdrrs, IdColumnName = "outcomeId", nameColumnName = "outcomeName")
mdrrs <- mdrrs[order(mdrrs$analysisId, mdrrs$outcomeId), ]
pathToCsv <- system.file("settings", "NegativeControls.csv", package = "QuantifyingBiasInApapStudies")
negativeControls <- read.csv(pathToCsv)
mdrrs$negativeControl <- "No"
mdrrs$negativeControl[mdrrs$o %in% negativeControls$outcomeId] <- "Yes"
write.csv(mdrrs, file.path("documents", "AppendixC.csv"), row.names = FALSE)

# Get code lists for cohort definitions -----------------------------------------------
pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "QuantifyingBiasInApapStudies")
cohortsToCreate <- read.csv(pathToCsv)
codeListsFolder <- file.path("documents", "codeLists")
if (!file.exists(codeListsFolder)) {
  dir.create(codeListsFolder)
}
getCodeLists <- function(i) {
  writeLines(paste("Getting codelists for cohort:", cohortsToCreate$name[i])) 
  conceptSets <- ROhdsiWebApi::getConceptSetsAndConceptsFromCohort(Sys.getenv("baseUrl"), cohortsToCreate$atlasId[i]) 
  for (j in 1:length(conceptSets)) {
    conceptSets[[1]]$name
    conceptIds <- conceptSets[[1]]$includedConceptsDf$CONCEPT_ID
    DatabaseConnector::insertTable(connection = conn, 
                                   tableName = "#concepts", 
                                   data = data.frame(concept_id = conceptIds), 
                                   dropTableIfExists = TRUE, 
                                   createTable = TRUE, 
                                   tempTable = TRUE, 
                                   oracleTempSchema = oracleTempSchema, 
                                   progressBar = TRUE)
                                   
    sql <- "
    SELECT DISTINCT condition_concept_id AS concept_id,
      concept_code AS source_code,
      vocabulary_id,
      concept_name AS description
    FROM @cdm_database_schema.condition_occurrence
    INNER JOIN #concepts c
      ON condition_concept_id = c.concept_id
    INNER JOIN @cdm_database_schema.concept source_code
      ON condition_source_concept_id = source_code.concept_id;
    "
    codeList <- DatabaseConnector::renderTranslateQuerySql(conn, sql, cdm_database_schema = cdmDatabaseSchema, snakeCaseToCamelCase = TRUE)
    fileName <- file.path(codeListsFolder, paste(conceptSets[[1]]$name, "csv", sep = "."))
    write.csv(codeList, fileName, row.names = FALSE)
    writeLines(paste("- Saved code list",fileName)) 
  }
}
lapply(1:nrow(cohortsToCreate), getCodeLists)

