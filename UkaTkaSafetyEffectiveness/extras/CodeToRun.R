library(UkaTkaSafetyFull)
options(fftempdir = "S:/FFTemp")
maxCores <- parallel::detectCores()
studyFolder <- "S:/StudyResults/UkaTkaSafetyFull"

# server connection:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = Sys.getenv("server"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("port"))

mailSettings <- list(from = Sys.getenv("emailAddress"),
                     to = c(Sys.getenv("emailAddress")),
                     smtp = list(host.name = Sys.getenv("emailHost"), port = 25,
                                 user.name = Sys.getenv("emailAddress"),
                                 passwd = Sys.getenv("emailPassword"), ssl = FALSE),
                     authenticate = FALSE,
                     send = TRUE)

# MDCR settings ----------------------------------------------------------------
databaseId <- "MDCR"
databaseName <- "MDCR"
databaseDescription <- "MDCR"
cdmDatabaseSchema = ""
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- ""

# MDCD settings ----------------------------------------------------------------
databaseId <- "MDCD"
databaseName <- "MDCD"
databaseDescription <- "MDCD"
cdmDatabaseSchema = ""
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- ""

# CCAE settings ----------------------------------------------------------------
databaseId <- "CCAE"
databaseName <- "CCAE"
databaseDescription <- "CCAE"
cdmDatabaseSchema <- ""
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema = "scratch.dbo"
cohortTable = "uka_tka_safety_ccae"

# Optum DOD settings -----------------------------------------------------------
databaseId <- "Optum"
databaseName <- "Optum"
databaseDescription <- "Optum DOD"
cdmDatabaseSchema = ""
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "uka_tka_safety_optum"

# THIN settings ----------------------------------------------------------------
databaseId <- "thin"
databaseName <- "thin"
databaseDescription <- "thin"
cdmDatabaseSchema = ""
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- ""
cohortTable <- ""

# Pharmetrics settings ---------------------------------------------------------
databaseId <- "pmtx"
databaseName <- "pmtx"
databaseDescription <- "pmtx"
cdmDatabaseSchema = ""
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- ""
cohortTable <- ""

# Run --------------------------------------------------------------------------
OhdsiRTools::runAndNotify(expression = {
  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortDatabaseSchema = cohortDatabaseSchema,
          cohortTable = cohortTable,
          oracleTempSchema = NULL,
          outputFolder = outputFolder,
          databaseId = databaseId,
          databaseName = databaseName,
          databaseDescription = databaseDescription,
          createCohorts = FALSE,
          synthesizePositiveControls = FALSE,
          runAnalyses = FALSE,
          runDiagnostics = FALSE,
          packageResults = FALSE,
          maxCores = maxCores)
}, mailSettings = mailSettings, label = paste0("Uka Tka ", databaseId), stopOnWarning = FALSE)

resultsZipFile <- file.path(outputFolder, "exportFull", paste0("Results", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)

# meta-analysis ----------------------------------------------------------------
doMetaAnalysis(outputFolders = c(file.path(studyFolder, "CCAE"),
                                 file.path(studyFolder, "MDCR"),
                                 file.path(studyFolder, "Optum"),
                                 file.path(studyFolder, "thin"),
                                 file.path(studyFolder, "pmtx")), 
               maOutputFolder = file.path(studyFolder, "MetaAnalysis"),
               maxCores = maxCores)
# prepare meta analysis results for shiny --------------------------------------

# compile results for Shiny here -----------------------------------------------
compileShinyData(studyFolder = studyFolder,
                 databases = c("CCAE", "MDCR", "Optum", "thin", "pmtx"))

fullShinyDataFolder <- file.path(studyFolder, "shinyDataAll")
launchEvidenceExplorer(dataFolder = fullShinyDataFolder, blind = FALSE, launch.browser = FALSE)

# Plots and tables for manuscript ----------------------------------------------
createPlotsAndTables(studyFolder = studyFolder,
                     createTable1 = TRUE,
                     createHrTable = TRUE,
                     createForestPlot = TRUE,
                     createKmPlot = TRUE,
                     createDiagnosticsPlot = TRUE)
