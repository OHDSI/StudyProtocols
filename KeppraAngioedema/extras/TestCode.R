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
cdmDatabaseSchema <- "CDM_Truven_MDCD_V446.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaMdcd"

cdmDatabaseSchema <- "cdm_truven_ccae_v441.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_ccae"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaCcae"

cdmDatabaseSchema <- "cdm_truven_mdcr_v445.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_mdcr"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaMdcr"

cdmDatabaseSchema <- "cdm_optum_extended_ses_v458.dbo"
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "ohdsi_keppra_angioedema_optum"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/KeppraAngioedemaOptum"

# cdmDatabaseSchema <- "cdm_cprd_v5.dbo"
# workDatabaseSchema <- "scratch.dbo"
# studyCohortTable <- "ohdsi_keppra_angioedema_cprd"
# oracleTempSchema <- NULL
# cdmVersion <- "5"
# outputFolder <- "S:/temp/KeppraAngioedemaCprd"

# dbms <- "redshift"
# user <- "martijn"
# pw <- Sys.getenv("pwPharmetrics")
# server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/pplus"
# cdmDatabaseSchema <- "cdmv5"
# workDatabaseSchema <- "scratch"
# oracleTempSchema <- NULL
# studyCohortTable <- "ohdsi_test_cohorts"
# outputFolder <- "S:/temp/KeppraAngioedemaPplus"
# port <- 5439
# cdmVersion <- "5"


connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        workDatabaseSchema = workDatabaseSchema,
        studyCohortTable = studyCohortTable,
        oracleTempSchema = oracleTempSchema,
        cdmVersion = cdmVersion,
        outputFolder = outputFolder,
        createCohorts = FALSE,
        runAnalyses = TRUE,
        maxCores = 20)

packageResults(connectionDetails = connectionDetails,
               cdmDatabaseSchema = cdmDatabaseSchema,
               outputFolder = outputFolder,
               minCellCount = 5)

createTableAndFigures(file.path(outputFolder, "export"))

writeReport(file.path(outputFolder, "export"), file.path(outputFolder, "Report.docx"))

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


library(CohortMethod)
cmData <- loadCohortMethodData(file.path(outputFolder, "cmOutput", "CmData_l1_t1_c2"))
str(cmData$cohorts$treatment)
str(cmData$covariateRef$covariateName)
as.Date(cmData$cohorts$cohortStartDate)
ff::as.ff(cmData$cohorts$cohortStartDate)

as.Date(c("2001-13-13"))


