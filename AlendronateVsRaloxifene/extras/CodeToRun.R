remove.packages("AlendronateVsRaloxifene")
setwd("c:/Users/Administrator/Dropbox/")
library(devtools)
install("AlendronateVsRaloxifene")

library(AlendronateVsRaloxifene)

# Optional: specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "e:/FFtemp")

# Maximum number of cores to be used:
maxCores <- 32

# The folder where the study intermediate and result files will be written:
outputFolder <- "e:/temp/study"

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",
                                                                server = "localhost",
                                                                user = "joe",
                                                                password = "secret")

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "NHIS_CDM_Sample.dbo"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "NHIS_CDM_RESULT_v2_2_0.dbo"
cohortTable <- "AlendronateVsRaloxifene"

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        createCohorts = TRUE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        runDiagnostics = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

prepareForEvidenceExplorer(studyFolder = "e:/SkeletonStudy")

launchEvidenceExplorer(studyFolder = "e:/SkeletonStudy", blind = FALSE, launch.browser = FALSE)
