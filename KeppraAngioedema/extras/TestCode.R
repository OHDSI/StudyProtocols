library(KeppraAngioedema)
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
cdmDatabaseSchema <- "cdm_truven_mdcd_v5.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaMdcd"

cdmDatabaseSchema <- "cdm_truven_ccae_v5.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_ccae"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaCcae"

cdmDatabaseSchema <- "cdm_truven_mdcr_v5.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_mdcr"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaMdcr"

cdmDatabaseSchema <- "cdm_optum_v5.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_optum"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaOptum"

# CPRD?

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        workDatabaseSchema = workDatabaseSchema,
        studyCohortTable = studyCohortTable,
        oracleTempSchema = oracleTempSchema,
        cdmVersion = cdmVersion,
        outputFolder = outputFolder,
        createCohorts = FALSE,
        runAnalyses = FALSE,
        maxCores = 32)

createTableAndFigures(file.path(outputFolder, "export"))


submitResults(file.path(outputFolder, "export"),
              key = Sys.getenv("keyAngioedema"),
              secret = Sys.getenv("secretAngioedema"))

### Test on Oracle ###

dbms <- "oracle"
user <- "system"
pw <- "OHDSI"
server <- "xe"
port <- NULL
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
cdmDatabaseSchema <- "cdm_truven_ccae_6k_V5"
workDatabaseSchema <- "scratch"
studyCohortTable <- "ohdsi_keppra_angioedema"
oracleTempSchema <- "scratch"
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaOracle"

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        workDatabaseSchema = workDatabaseSchema,
        studyCohortTable = studyCohortTable,
        oracleTempSchema = oracleTempSchema,
        cdmVersion = cdmVersion,
        outputFolder = outputFolder,
        createCohorts = TRUE,
        maxCores = 30)

om <- readRDS(file.path(outputFolder, "cmOutput", "Analysis_3", "om_t1_c2_o3.rds"))
summary(om)
