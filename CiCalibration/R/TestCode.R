.testCode <- function() {
  # library(CelecoxibVsNsNSAIDs)
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
  studyCohortTable <- "ohdsi_celecoxib_vs_nsnsaids"
  oracleTempSchema <- NULL
  cdmVersion <- "5"
  outputFolder <- "S:/temp/CelecoxibVsNsNSAIDs_MDCD"


  cdmDatabaseSchema <- "cdm_truven_ccae_v5.dbo"
  workDatabaseSchema <- "scratch.dbo"
  studyCohortTable <- "ohdsi_celecoxib_vs_nsnsaids_ccae"
  oracleTempSchema <- NULL
  cdmVersion <- "5"
  outputFolder <- "S:/temp/CelecoxibVsNsNSAIDs_CCAE"

  cdmDatabaseSchema <- "cdm_truven_mdcr_v5.dbo"
  workDatabaseSchema <- "scratch.dbo"
  studyCohortTable <- "ohdsi_celecoxib_vs_nsnsaids_mdcr"
  oracleTempSchema <- NULL
  cdmVersion <- "5"
  outputFolder <- "S:/temp/CelecoxibVsNsNSAIDs_MDCR"

  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          workDatabaseSchema = workDatabaseSchema,
          studyCohortTable = studyCohortTable,
          oracleTempSchema = oracleTempSchema,
          cdmVersion = cdmVersion,
          outputFolder = outputFolder)

}
