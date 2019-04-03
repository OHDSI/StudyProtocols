# Global settings ---------------------------------------------------------------------
options(fftempdir = "S:/FFtemp")
maxCores <- parallel::detectCores()

mailSettings <- list(from = Sys.getenv("emailAddress"),
                     to = c(Sys.getenv("emailAddress")),
                     smtp = list(host.name = Sys.getenv("emailHost"), port = 25,
                                 user.name = Sys.getenv("emailAddress"),
                                 passwd = Sys.getenv("emailPassword"), ssl = FALSE),
                     authenticate = FALSE,
                     send = TRUE)

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = Sys.getenv("dbms"),
                                                                server = Sys.getenv("server"),
                                                                port = as.numeric(Sys.getenv("port")),
                                                                user = NULL,
                                                                password = NULL)

cohortDefinitionSchema <- "scratch.dbo"
cohortDefinitionTable <- "epi535_cohort_universe"
codeListSchema <- "scratch.dbo"
codeListTable <- "epi535_code_list"
vocabularyDatabaseSchema <- "vocabulary_20171201.dbo"
studyFolder <- "S:/StudyResults/epi_535_4"


# MDCR settings ----------------------------------------------------------------
cdmDatabaseSchema = "cdm_truven_mdcr_v698.dbo"
databaseName <- "MDCR"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi535_cohorts_mdcr"

# CCAE settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_ccae_v697.dbo"
databaseName <- "CCAE"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema = "scratch.dbo"
cohortTable = "epi535_cohorts_ccae"

# MDCD settings ----------------------------------------------------------------
cdmDatabaseSchema = "cdm_truven_mdcd_v699.dbo"
databaseName <- "MDCD"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi535_cohorts_mdcd"

# Optum SES settings -----------------------------------------------------------
cdmDatabaseSchema = "cdm_optum_extended_ses_v694.dbo"
databaseName <- "Optum"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi535_cohorts_optum_ses"


# Database-specific execution---------------------------------------------------
OhdsiRTools::runAndNotify(expression = {
  sglt2iDka::execute(connectionDetails = connectionDetails,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     cohortDatabaseSchema = cohortDatabaseSchema,
                     cohortTable = cohortTable,
                     oracleTempSchema = NULL,
                     outputFolder = outputFolder,
                     codeListSchema = codeListSchema,
                     codeListTable = codeListTable,
                     vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                     databaseName = databaseName,
                     runAnalyses = FALSE,
                     getMultiTherapyData = FALSE,
                     runDiagnostics = TRUE,
                     packageResults = FALSE,
                     runIrSensitivity = FALSE,
                     packageIrSensitivityResults = FALSE,
                     runIrDose = FALSE,
                     packageIrDose = FALSE,
                     maxCores = maxCores,
                     minCellCount = 5)
}, mailSettings = mailSettings, label = paste0("EPI535_", databaseName), stopOnWarning = FALSE)


# execute meta analysis --------------------------------------------------------
OhdsiRTools::runAndNotify(expression = {
  sglt2iDka::doMetaAnalysis(outputFolders = c(file.path(studyFolder, "CCAE"),
                                              file.path(studyFolder, "MDCD"),
                                              file.path(studyFolder, "MDCR"),
                                              file.path(studyFolder, "Optum")),
                            maOutputFolder = file.path(studyFolder, "metaAnalysis"),
                            maxCores = maxCores)
}, mailSettings = mailSettings, label = "EPI535_MetaAnalysis", stopOnWarning = FALSE)


# generate report tables -------------------------------------------------------
OhdsiRTools::runAndNotify(expression = {
  sglt2iDka::createTableAndFiguresForReport(outputFolders = c(file.path(studyFolder, "CCAE"),
                                                              file.path(studyFolder, "MDCD"),
                                                              file.path(studyFolder, "MDCR"),
                                                              file.path(studyFolder, "Optum")),
                                            databaseNames = c("CCAE", "MDCD", "MDCR", "Optum"),
                                            maOutputFolder = file.path(studyFolder, "metaAnalysis"),
                                            reportFolder = file.path(studyFolder, "report2"))
}, mailSettings = mailSettings, label = "EPI535_ReportTables", stopOnWarning = FALSE)
