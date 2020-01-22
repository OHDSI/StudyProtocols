Opioid Models
============

<img src="https://img.shields.io/badge/Study%20Status-Complete-orange.svg" alt="Study Status: Complete">

- Analytics use case(s): **Patient-Level Prediction**
- Study type: **Clinical Application**
- Tags: **-**
- Study lead: **Jenna Reps**
- Study lead forums tag: **[jreps](https://forums.ohdsi.org/u/jreps)**
- Study start date: **Jan 1, 2018**
- Study end date: **Jan 1, 2020**
- Protocol: **[Protocol](https://github.com/OHDSI/StudyProtocols/OpioidModels/blob/master/documents/Protocol.docx)**
- Publications: ** accepted to PLOS ONE **
- Results explorer: **-**

A package for running the opioid use disorder prediction models on any OMOP CDM


Features
========
  - Users can validate the models on their OMOP CDM data
  - Users can implement the model to predict the risk of 1-year opioid use disorder on any new target cohort

Technology
==========
  OpioidModels is an R package.

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
devtools::install_github("OHDSI/StudyProtocolSandbox/OpioidModels")

library('OpioidModels')
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
outputLocation <- file.path(getwd(),'OpioidModelApplication')
cohortTables <- 'opioid_cohort'

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
# Now run the following:
checkPlpInstallation(connectionDetails=connectionDetails,
                     python=F)
 
#================================= CREATE TABLES ==================================
createOpioidTables(connectionDetails=connectionDetails,
cdmDatabaseSchema=cdmDatabaseSchema,
                 cohortDatabaseSchema=cohortDatabaseSchema,
                 cohortTable = cohortTables)

#================================= VALIDATE MODELS ==================================
val <- validateOpioidModels(model ='simple',
connectionDetails=connectionDetails,
                 cdmDatabaseSchema=cdmDatabaseSchema,
                 cohortDatabaseSchema=cohortDatabaseSchema,
                 cohortTable = cohortTables,
                 cohortId = 1,
                 outcomeDatabaseSchema=cohortDatabaseSchema,
                 outcomeTable = cohortTables,
                 outcomeId = 2)
                 

#================================= APPLY MODELS ==================================
newRisks <- applyOpioidModel(model ='simple',
connectionDetails=connectionDetails,
                 cdmDatabaseSchema=cdmDatabaseSchema,
                 cohortDatabaseSchema=cohortDatabaseSchema,
                 cohortTable = cohortTables,
                 cohortId = 1)

```

License
=======
  ExistingStrokeRiskExternalValidation is licensed under Apache License 2.0

Development
===========
  ExistingStrokeRiskExternalValidation is being developed in R Studio.

