library(AlendronateVsRaloxifene)
options(fftempdir = "s:/FFtemp")

dbms <- "pdw"
user <- NULL
pw <- NULL
server <- "JRDUSAPSCTL01"
port <- 17001
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
cdmDatabaseSchema <- "CDM_Truven_MDCD_V521.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_alendronate_raloxifene_mdcd"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/AlendronateVsRaloxifeneMdcd"

cdmDatabaseSchema <- "cdm_truven_ccae_v519.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_alendronate_raloxifene_ccae"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/AlendronateVsRaloxifeneCcae"

cdmDatabaseSchema <- "cdm_truven_mdcr_v520.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_alendronate_raloxifene_mdcr"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/AlendronateVsRaloxifeneMdcr"

cdmDatabaseSchema <- "cdm_optum_extended_ses_v515.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_alendronate_raloxifene_optum"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/AlendronateVsRaloxifeneOptum"

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

assessFeasibility(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  workDatabaseSchema = workDatabaseSchema,
                  studyCohortTable = studyCohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        workDatabaseSchema = workDatabaseSchema,
        studyCohortTable = studyCohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        createCohorts = FALSE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = 30)

createTableAndFigures(file.path(outputFolder, "export"))

writeReport(file.path(outputFolder, "export"), file.path(outputFolder, "export", "report.docx"))



