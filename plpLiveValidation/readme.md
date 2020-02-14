Development and validation of a prognostic model predicting symptomatic hemorrhagic transformation in acute ischemic stroke at scale in the OHDSI network
=======================================================

<img src="https://img.shields.io/badge/Study%20Status-Complete-orange.svg" alt="Study Status: Complete">

- Analytics use case(s): **Patient-Level Prediction**
- Study type: **Clinical Application**
- Tags: **-**
- Study lead: **Qiong Wang**
- Study lead forums tag: **[[qiongwang]](https://forums.ohdsi.org/u/qiongwang/)**
- Study start date: **October 12, 2018**
- Study end date: **June 1, 2019**
- Protocol: **[Protocol](https://github.com/OHDSI/StudyProtocols/tree/master/plpLiveValidation/documents/Qiong PLP-protocol-V5.docx)**
- Publications: **[Development and validation of a prognostic model predicting symptomatic hemorrhagic transformation in acute ischemic stroke at scale in the OHDSI network](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0226718)**
- Results explorer: **[plpLive18Study](https://data.ohdsi.org/plpLive18Study/)**

Hemorrhagic transformation (HT) after cerebral infarction is a complex and multifactorial phenomenon in the acute stage of ischemic stroke, and often results in a poor prognosis. Thus, identifying risk factors and making an early prediction of HT in acute cerebral infarction contributes not only to the selections of therapeutic regimen but also, more importantly, to the improvement of prognosis of acute cerebral infarction. The purpose of this study was to develop and validate a model to predict a patient’s risk of HT within 30 days of initial ischemic stroke.

 Executive Summary
============
  At the 2018 OHDSI US Symposium, the OHDSI Community embarked on a novel challenge: could we run a full patient-level prediction study in a single day? The day started with symposium attendees submitting their clinical questions. The audience voted on which question they wanted to answer. The rest of the day (less than 6 hours of working time) was spent on defining the study question, building cohort definitions for the target and comparator groups, generating a study protocol and study code, performing clinical validation of the cohorts, internally validating a prediction model and externally validating the model across other OHDSI network sites. The exercise culminated in a final presentation of results at the closing session of the symposium. A video of this presentation can be found here: https://youtu.be/NJ-Ov_RsH2U.
  
  Following the 2018 OHDSI US Symposium, a small team of researchers assembled a publication team to move the Live PLP exercise into a formal journal publication. The GitHub repository here is intended to provide a public record of all of the design choices specified in this analysis. Anyone with an OMOP v5+ compliant database may download this study, run on their data set and produce results.
    
  Responsible Parties
============
  Lead Author: Qiong Wang


  Introduction
============
  This package validates two models developed to predict conversion to hemorrhagic stroke within 30 days after ischemic stroke 

Features
========
  - Applies two models 
  - These are the final models that were initially developed during the OHDSI 2018 symposium

Technology
==========
  plpLiveValidation is an R package.

System Requirements
===================
  Requires R (version 3.3.0 or higher).

Dependencies
============
  * PatientLevelPrediction

Getting Started
===============
  1. In R, use the following commands to run the study:

  ```r
  # If not building locally uncomment and run:
#install.packages("devtools")
#devtools::install_github("OHDSI/StudyProtocols/plpLiveValidation")

library(plpLiveValidation)

# add details of your database setting:
databaseName <- 'add a shareable name for the database used to develop the models'

# add the cdm database schema with the data
cdmDatabaseSchema <- 'your cdm database schema'

# add the work database schema this requires read/write privileges 
cohortDatabaseSchema <- 'your work database schema'

# if using oracle please set the location of your temp schema
oracleTempSchema <- NULL

# the name of the table that will be created in cohortDatabaseSchema to hold the cohorts
cohortTable <- 'plpLiveValidationCohortTable'

# the location to save the prediction models results to:
outputFolder <- getwd()

# add connection details:
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

# Now run the study
plpLiveValidation::execute(connectionDetails = connectionDetails,
                 databaseName = databaseName,
                 cdmDatabaseSchema = cdmDatabaseSchema,
                 cohortDatabaseSchema = cohortDatabaseSchema,
                 oracleTempSchema = oracleTempSchema,
                 cohortTable = cohortTable,
                 outputFolder = outputFolder,
                 createCohorts = T,
                 runValidation = T,
                 packageResults = T,
                 minCellCount = 5,
                 sampleSize = NULL)
                 
# add code to submit results to study admin here


```

License
=======
  PredictionNetworkStudySkeleton is licensed under Apache License 2.0

Development
===========
  PredictionNetworkStudySkeleton is being developed in R Studio.
