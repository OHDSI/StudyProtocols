# Use a Linux 64/c1.xlarge instance

library(KeppraAngioedema)

connectionDetails <- createConnectionDetails(
    dbms = "redshift",
    user = Sys.getenv("REDSHIFT_USER"),         # Assumes environmental variables set before running R,
    password = Sys.getenv("REDSHIFT_PASSWORD"), # otherwise fill-in with correct user/password pair.
    server = "omop-datasets.cqlmv7nlakap.us-east-1.redshift.amazonaws.com/truven",
    port = "5439")

execute(connectionDetails,
        cdmDatabaseSchema = "mdcr_v5",
        workDatabaseSchema = "ohdsi",
        studyCohortTable = "ohdsi_keppra_angioedema",
        oracleTempSchema = NULL,
        outputFolder = "~/study_results",
        maxCores = 8)
