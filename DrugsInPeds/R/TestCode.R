testCode <- function() {
    #library(DrugsInPeds);setwd('s:/temp')
    password <- NULL
    user <- NULL
    oracleTempSchema <- NULL

    dbms <- "sql server"
    server <- "RNDUSRDHIT07.jnj.com"
    cdmDatabaseSchema <- "cdm4_sim.dbo"
    port <- NULL
    cdmVersion <- "4"

    dbms <- "sql server"
    server <- "RNDUSRDHIT02.jnj.com"
    cdmDatabaseSchema <- "cdm_jmdc.dbo"
    port <- NULL
    cdmVersion <- "4"

    dbms <- "pdw"
    server <- "JRDUSAPSCTL01"
    cdmDatabaseSchema <- "cdm_jmdc_v5.dbo"
    port <- 17001
    cdmVersion <- "5"


    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                    server = server,
                                                                    user = user,
                                                                    password = password,
                                                                    port = port)

    execute(connectionDetails,
            cdmDatabaseSchema = cdmDatabaseSchema,
            oracleTempSchema = oracleTempSchema,
            cdmVersion = cdmVersion)


    createFiguresAndTables(connectionDetails,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           oracleTempSchema = oracleTempSchema,
                           cdmVersion = cdmVersion,
                           folder = "s:/temp/DrugsInPeds")
    #OhdsiSharing::generateKeyPair("s:/temp/public.key","s:/temp/private.key")

    #OhdsiSharing::decryptAndDecompressFolder("s:/temp/DrugsInPeds/StudyResults.zip.enc","s:/temp/test","s:/temp/private.key")
}
