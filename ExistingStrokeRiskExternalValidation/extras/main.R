#file to run study
options(fftempdir = 'T:/fftemp')
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv('server')
port <- Sys.getenv('port')
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
createCohorts(connectionDetails,
                          cdmDatabaseschema=Sys.getenv('mdcr_cdm'),
                          cohortDatabaseschema='cohortDatabase.dbo',
                          cohortTable='stroke_cohort',
                          targetId=1,
                          outcomeId=2)

table1 <- getTable1(connectionDetails,
                    cdmDatabaseschema=Sys.getenv('mdcr_cdm'),
                    cohortDatabaseschema='cohortDatabase.dbo',
                    cohortTable='stroke_cohort',
                    targetId=1,
                    outcomeId=2)

results <- applyExistingstrokeModels(connectionDetails=connectionDetails,
                                     cdmDatabaseSchema=Sys.getenv('mdcr_cdm'),
                                     cohortDatabaseSchema="cohortDatabase.dbo",
                                     cohortTable="stroke_cohort",
                                     targetId=1,
                                     outcomeId=2)

packageResults(results, table1=NULL, saveFolder=file.path(getwd(),
                                                     'testing_stroke_study'),
               dbName='mdcr')

submitResults(exportFolder=file.path(getwd(),
                                     'testing_stroke_study'),
              dbName='mdcr', key, secret)
