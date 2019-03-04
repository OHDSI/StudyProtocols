################################################################################
# CONFIG
################################################################################
options(java.parameters = "- Xmx1024m")
library(generateCohort)

################################################################################
# VARIABLES
################################################################################
configFile <- "extras/config.csv"
connectionDetails <- getConnectionDetails(configFile)
study = "EPI535"

################################################################################
# DATABASES
################################################################################
datasources <- createDatabaseList()

################################################################################
# RUN
################################################################################
execute(connectionDetails = connectionDetails,
        study = study,
        datasources = datasources,
        createCodeList = FALSE,
        createUniverse = FALSE,
        createCohortTables = FALSE, #This drops all cohort data
        buildTheCohorts = FALSE,
        buildOutcomeCohorts = FALSE,
        buildNegativeControlCohorts = FALSE,
        buildTheCohortsDose = FALSE,
        combinedDbData = FALSE,
        exportResults = FALSE,
        exportPotentialRiskFactors = FALSE,
        exportPotentialRiskFactorsScores = FALSE,
        exportMeanAge = FALSE,
        exportTwoPlusNonSGLT2i = FALSE,
        exportReviewDKAEvents = FALSE,
        exportInitislSGLT2iDosage = FALSE,
        exportDKAFatal = FALSE,
        exportRelevantLabs = FALSE,
        formatPotentialRiskFactors = FALSE,
        formatPaticipantsTxInfo = FALSE,
        formatFatalDka = TRUE)


