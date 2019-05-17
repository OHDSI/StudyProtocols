library(AHAsAcutePancreatitis)
options(fftempdir = "D:/FFtemp")

maxCores <- parallel::detectCores()-1
studyFolder <- "D:/Studies/EPI534"
dbms <- ""
server <- ""
port <- ""
oracleTempSchema <- NULL
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                port = port)

# MDCR settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_mdcr_v698.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "EPI534_MDCR"
databaseName <- "MDCR"
outputFolder <- file.path(studyFolder, "mdcr")

# CCAE settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_ccae_v697.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "EPI534_CCAE"
databaseName <- "CCAE"
outputFolder <- file.path(studyFolder, "ccae")

# Optum settings ----------------------------------------------------------------
cdmDatabaseSchema <- "cdm_optum_extended_ses_v694.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "EPI534_OPTUM"
databaseName <- "Optum"
outputFolder <- file.path(studyFolder, "optum")

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseName = databaseName,
        createCohorts = FALSE,
        runAnalyses = FALSE,
        getPriorExposureData = FALSE,
        runDiagnostics = FALSE,
        prepareResults = FALSE,
        maxCores = maxCores)

# run queries to create our additional cohorts here...

# cana restricted cohorts - the protocol calls for comparator cohorts to exclude cana exposed people
sql <- SqlRender::loadRenderTranslateSql("CreateCanaRestrictedCohorts.sql",
                                         "AHAsAcutePancreatitis",
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         cohortDatabaseSchema = cohortDatabaseSchema,
                                         cohortTable = cohortTable)

connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(connection, sql)

# metformin add-on therapy - the protocol calls for a sensitivity analysis with required prior metformin
sql <- SqlRender::loadRenderTranslateSql("ManuallyCreateMetforminAddOnCohorts.sql",
                                         "AHAsAcutePancreatitis",
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         cohortDatabaseSchema = cohortDatabaseSchema,
                                         cohortTable = cohortTable)

connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(connection, sql)
#
# # required prior ap - the protocol calls for a sensitivity analysis with required prior AP
sql <- SqlRender::loadRenderTranslateSql("ManuallyCreatePriorAPCohorts.sql",
                                         "AHAsAcutePancreatitis",
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         cohortDatabaseSchema = cohortDatabaseSchema,
                                         cohortTable = cohortTable)

connection <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(connection, sql)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseName = databaseName,
        createCohorts = F,
        runAnalyses = F,
        getPriorExposureData = F,
        runDiagnostics = F,
        prepareResults = T,
        maxCores = 1)

AHAsAcutePancreatitis::createTableAndFiguresForReport(outputFolders = c(file.path(studyFolder, "ccae"),
                                                 file.path(studyFolder, "mdcr"),
                                                 file.path(studyFolder, "optum")),
                               databaseNames = c("CCAE", "MDCR", "Optum"),
                               maOutputFolder = file.path(studyFolder, "metaAnalysis"),
                               reportFolder = file.path(studyFolder, "report"))
