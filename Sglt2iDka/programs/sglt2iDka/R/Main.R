#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    codeListSchema,
                    codeListTable,
                    vocabularyDatabaseSchema,
                    databaseName,
                    runAnalyses = FALSE,
                    getMultiTherapyData = FALSE,
                    runDiagnostics = FALSE,
                    packageResults = FALSE,
                    runIrSensitivity = FALSE,
                    packageIrSensitivityResults = FALSE,
                    runIrDose = FALSE,
                    packageIrDose = FALSE,
                    maxCores = 4,
                    minCellCount= 5) {

  start <- Sys.time()

  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)

  OhdsiRTools::addDefaultFileLogger(file.path(outputFolder, "log.txt"))

  if (runAnalyses) {
    OhdsiRTools::logInfo("Running analyses")
    cmOutputFolder <- file.path(outputFolder, "cmOutput")
    if (!file.exists(cmOutputFolder))
      dir.create(cmOutputFolder)

    # analysis Settings
    cmAnalysisListFile <- system.file("settings", "cmAnalysisList.json", package = "sglt2iDka")
    cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
    cmAnalysisList <- sglt2iDka::setOutcomeDatabaseSchemaAndTable(settings = cmAnalysisList,
                                                                  outcomeDatabaseSchema = cohortDatabaseSchema,
                                                                  outcomeTable = cohortTable)
    cmAnalysisList <- sglt2iDka::setExposureDatabaseSchemaAndIds(settings = cmAnalysisList,
                                                                 exposureDatabaseSchema = cdmDatabaseSchema,
                                                                 codeListSchema = codeListSchema,
                                                                 codeListTable = codeListTable,
                                                                 vocabularyDatabaseSchema = vocabularyDatabaseSchema)

    # tcos
    tcoList <- sglt2iDka::createTcos() # 62 TCs * 45 main and NC outcomes * 2 analyses = 5580 estimates
    results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           exposureDatabaseSchema = cohortDatabaseSchema,
                                           exposureTable = cohortTable,
                                           outcomeDatabaseSchema = cohortDatabaseSchema,
                                           outcomeTable = cohortTable,
                                           outputFolder = cmOutputFolder,
                                           oracleTempSchema = oracleTempSchema,
                                           cmAnalysisList = cmAnalysisList,
                                           drugComparatorOutcomesList = tcoList,
                                           getDbCohortMethodDataThreads = min(3, maxCores),
                                           createStudyPopThreads = min(3, maxCores),
                                           createPsThreads = max(1, round(maxCores/10)),
                                           psCvThreads = min(10, maxCores),
                                           computeCovarBalThreads = min(3, maxCores),
                                           trimMatchStratifyThreads = min(10, maxCores),
                                           fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                           outcomeCvThreads = min(4, maxCores),
                                           refitPsForEveryOutcome = FALSE)
  }

  if (getMultiTherapyData) {
    OhdsiRTools::logInfo("Getting multi-therapy data from server")
    sglt2iDka::getMultiTherapyData(connectionDetails = connectionDetails,
                                   cohortDatabaseSchema = cohortDatabaseSchema,
                                   cohortDefinitionTable = cohortDefinitionTable,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   cohortTable = cohortTable,
                                   codeListTable = codeListTable,
                                   oracleTempSchema = oracleTempSchema,
                                   outputFolder = outputFolder)
  }


  if (runDiagnostics) {
    OhdsiRTools::logInfo("Running diagnostics")
    sglt2iDka::generateDiagnostics(outputFolder = outputFolder,
                                   databaseName = databaseName)
    sglt2iDka::hrHeterogeneity(outputFolder = outputFolder,
                               databaseName = databaseName,
                               primaryOnly = FALSE)
  }

  if (packageResults) {
    OhdsiRTools::logInfo("Packaging results")
    sglt2iDka::prepareResultsForAnalysis(outputFolder = outputFolder,
                                         databaseName = databaseName,
                                         maxCores = maxCores)
  }

  if (runIrSensitivity) {
    OhdsiRTools::logInfo("Running IR sensitivity analysis")
    cmIrSensitivityFolder <- file.path(outputFolder, "cmIrSensitivityOutput")
    if (!file.exists(cmIrSensitivityFolder))
      dir.create(cmIrSensitivityFolder)

    # analysis settings
    cmIrSensitivityListFile <- system.file("settings", "cmIrSensitivityAnalysisList.json", package = "sglt2iDka")
    cmIrSensitivityList <- CohortMethod::loadCmAnalysisList(cmIrSensitivityListFile)
    cmIrSensitivityList <- sglt2iDka::setOutcomeDatabaseSchemaAndTable(settings = cmIrSensitivityList,
                                                                       outcomeDatabaseSchema = cohortDatabaseSchema,
                                                                       outcomeTable = cohortTable)
    cmIrSensitivityList <- sglt2iDka::setExposureDatabaseSchemaAndIds(settings = cmIrSensitivityList,
                                                                      exposureDatabaseSchema = cdmDatabaseSchema,
                                                                      codeListSchema = codeListSchema,
                                                                      codeListTable = codeListTable,
                                                                      vocabularyDatabaseSchema = vocabularyDatabaseSchema)

    # tcos
    tcoIrSensitivityList <- sglt2iDka::createIrSensitivityTcos()
    results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           exposureDatabaseSchema = cohortDatabaseSchema,
                                           exposureTable = cohortTable,
                                           outcomeDatabaseSchema = cohortDatabaseSchema,
                                           outcomeTable = cohortTable,
                                           outputFolder = cmIrSensitivityFolder,
                                           oracleTempSchema = oracleTempSchema,
                                           cmAnalysisList = cmIrSensitivityList,
                                           drugComparatorOutcomesList = tcoIrSensitivityList,
                                           getDbCohortMethodDataThreads = min(3, maxCores),
                                           createStudyPopThreads = min(3, maxCores))
  }

  if (packageIrSensitivityResults) {
    OhdsiRTools::logInfo("Packaging IR sensitivity results")
    sglt2iDka::prepareIrSensitivityResultsForAnalysis(outputFolder = outputFolder,
                                                      databaseName = databaseName,
                                                      maxCores = maxCores)
  }

  if (runIrDose) {
    OhdsiRTools::logInfo("Running IR dose analysis")
    cmIrDoseFolder <- file.path(outputFolder, "cmIrDoseOutput")
    if (!file.exists(cmIrDoseFolder))
      dir.create(cmIrDoseFolder)

    cohortDoseTable <- paste(cohortTable, "dose", sep = "_")

    # analysis settings
    cmIrDoseListFile <- system.file("settings", "cmIrDoseAnalysisList.json", package = "sglt2iDka")
    cmIrDoseList <- CohortMethod::loadCmAnalysisList(cmIrDoseListFile)
    cmIrDoseList <- sglt2iDka::setOutcomeDatabaseSchemaAndTable(settings = cmIrDoseList,
                                                                outcomeDatabaseSchema = cohortDatabaseSchema,
                                                                outcomeTable = cohortTable)
    cmIrDoseList <- sglt2iDka::setExposureDatabaseSchemaAndIds(settings = cmIrDoseList,
                                                               exposureDatabaseSchema = cdmDatabaseSchema,
                                                               codeListSchema = codeListSchema,
                                                               codeListTable = codeListTable,
                                                               vocabularyDatabaseSchema = vocabularyDatabaseSchema)

    # tcos
    tcoIrDoseList <- sglt2iDka::createIrDoseTcos()
    results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           exposureDatabaseSchema = cohortDatabaseSchema,
                                           exposureTable = cohortDoseTable,
                                           outcomeDatabaseSchema = cohortDatabaseSchema,
                                           outcomeTable = cohortTable,
                                           outputFolder = cmIrDoseFolder,
                                           oracleTempSchema = oracleTempSchema,
                                           cmAnalysisList = cmIrDoseList,
                                           drugComparatorOutcomesList = tcoIrDoseList,
                                           getDbCohortMethodDataThreads = min(3, maxCores),
                                           createStudyPopThreads = min(3, maxCores))
  }

  if (packageIrDose) {
    OhdsiRTools::logInfo("Packaging IR dose results")
    sglt2iDka::prepareIrDoseResultsForAnalysis(outputFolder = outputFolder,
                                               databaseName = databaseName,
                                               maxCores = maxCores)
  }

  delta <- Sys.time() - start
  writeLines(paste("Completed analyses in", signif(delta, 3), attr(delta, "units")))
  invisible(NULL)
}
