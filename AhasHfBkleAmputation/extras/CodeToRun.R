library(AhasHfBkleAmputation)
options(fftempdir = "r:/FFtemp")

maxCores <- 30
studyFolder <- "r:/AhasHfBkleAmputation"
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv("PDW_SERVER")
port <- Sys.getenv("PDW_PORT")
oracleTempSchema <- NULL
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

# CCAE settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_ccae_v656.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi501_ccae"
databaseName <- "CCAE"
outputFolder <- file.path(studyFolder, "ccae")

# MDCD settings ----------------------------------------------------------------
cdmDatabaseSchema <- "CDM_Truven_MDCD_V635.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi501_mdcd"
databaseName <- "MDCD"
outputFolder <- file.path(studyFolder, "mdcd")

# MDCR settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_mdcr_v657.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi501_mdcr"
databaseName <- "MDCR"
outputFolder <- file.path(studyFolder, "mdcr")

# Optum settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_optum_extended_dod_v654.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "epi501_optum"
databaseName <- "Optum"
outputFolder <- file.path(studyFolder, "optum")


mailSettings <- list(from = Sys.getenv("mailAddress"),
                     to = c(Sys.getenv("mailAddress")),
                     smtp = list(host.name = "smtp.gmail.com", port = 465,
                                 user.name = Sys.getenv("mailAddress"),
                                 passwd = Sys.getenv("mailPassword"), ssl = TRUE),
                     authenticate = TRUE,
                     send = TRUE)

result <- OhdsiRTools::runAndNotify({
  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortDatabaseSchema = cohortDatabaseSchema,
          cohortTable = cohortTable,
          oracleTempSchema = oracleTempSchema,
          outputFolder = outputFolder,
          databaseName = databaseName,
          createCohorts = FALSE,
          runAnalyses = FALSE,
          getPriorExposureData = TRUE,
          runDiagnostics = FALSE,
          prepareResults = TRUE,
          maxCores = maxCores)
}, mailSettings = mailSettings, label = "AhasHfBkleAmputation")


doMetaAnalysis(outputFolders = c(file.path(studyFolder, "ccae"),
                                 file.path(studyFolder, "mdcd"),
                                 file.path(studyFolder, "mdcr"),
                                 file.path(studyFolder, "optum")), 
               maOutputFolder = file.path(studyFolder, "metaAnalysis"),
               maxCores = maxCores)

createTableAndFiguresForReport(outputFolders = c(file.path(studyFolder, "ccae"),
                                                 file.path(studyFolder, "mdcd"),
                                                 file.path(studyFolder, "mdcr"),
                                                 file.path(studyFolder, "optum")),
                               databaseNames = c("CCAE", "MDCD", "MDCR", "Optum"),
                               maOutputFolder = file.path(studyFolder, "metaAnalysis"),
                               reportFolder = file.path(studyFolder, "report"))



outputFolders = c(file.path(studyFolder, "ccae"),
                  file.path(studyFolder, "mdcr"),
                  file.path(studyFolder, "optum"))
databaseNames = c("CCAE", "MDCR", "Optum")
