.testCode <- function() {
    library(CelecoxibPredictiveModels)
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
    studyCohortTable <- "ohdsi_celecoxib_prediction"
    oracleTempSchema <- NULL
    cdmVersion <- "5"
    outputFolder <- "S:/temp/CelecoxibPredictiveModels_newplp"

    execute(connectionDetails,
            cdmDatabaseSchema = cdmDatabaseSchema,
            workDatabaseSchema = workDatabaseSchema,
            studyCohortTable = studyCohortTable,
            outputFolder = outputFolder)
}
