ExistingStrokeRiskExternalValidation
======================

  Introduction
============
A package for running the OHDSI network study to externally validate 5 existing stroke risk prediction models using the PatientLevelPrediction framework


Features
========
  - Creates target cohort of females newly diagnosed with atrial fibrilation between ages 35-65
  - Creates 4 outcome cohorts of various stroke definitions
  - Implements 5 existing stroke risk prediciton models and validates on data in OMOP CDM for each target and outcome cohort combination
  - Sends summary results 

Technology
==========
  ExistingStrokeRiskExternalValidation is an R package.

System Requirements
===================
  Requires R (version 3.3.0 or higher).

Dependencies
============
  * PatientLevelPrediction
  * PredictionComparison

Getting Started
===============
  1. In R, use the following commands to download and install:

  ```r
install.packages("drat")
drat::addRepo("OHDSI")
install.packages("PatientLevelPrediction")
install.packages("devtools")
devtools::install_github("OHDSI/PredictionComparison")
devtools::install_github("OHDSI/StudyProtocolSandbox/ExistingStrokeRiskExternalValidation")

library('ExistingStrokeRiskExternalValidation')
# Add inputs for the site:
options(fftempdir = 'C:/fftemp')
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv('server')
port <- Sys.getenv('port')

databaseName <- 'database name'
cdmDatabaseSchema <- 'cdmDatabase.dbo'
cohortDatabaseSchema <- 'cohortDatabase.dbo'
outputLocation <- file.path(getwd(),'External Stroke Validation')
cohortTable <- 'stroke_cohort'
getTable1 <- F

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
# Now run the following:
checkPlpInstallation(connectionDetails=connectionDetails,
                     python=F)
                     
# view the models
viewModels()
                     
# NOTE IF THE ABOVE DOESN'T RETURN 1 THEN THERE IS AN ISSUE WITH THE PatientLevelPrediction INSTALL
# OR SETTINGS THAT NEEDS TO BE FIXED BEFORE YOU CONTINUE
              
# Check cohort definitions work for the database:                     
cohorts <- createCohorts(connectionDetails=connectionDetails,
                       cdmDatabaseSchema=cdmDatabaseSchema,
                       cohortDatabaseSchema=cohortDatabaseSchema,
                       cohortTable=cohortTable) 
                       
# If the check passes and you have cohort values submit the cohort counts to the study
# organizor to confirm the cohort definitions run across the network.  
                       
#================================= STEP 2: MAIN STUDY ==================================
#  Once definitons have been checked across sites run:
main(connectionDetails=connectionDetails,
                 databaseName=databaseName,
                 cdmDatabaseSchema=cdmDatabaseSchema,
                 cohortDatabaseSchema=cohortDatabaseSchema,
                 outputLocation=outputLocation,
                 cohortTable=cohortTable)
submitResults(exportFolder=outputLocation,
              dbName=databasename, key, secret)

# where key and secret are provided by request


```

License
=======
  ExistingStrokeRiskExternalValidation is licensed under Apache License 2.0

Development
===========
  ExistingStrokeRiskExternalValidation is being developed in R Studio.

