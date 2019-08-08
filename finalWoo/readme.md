A Package Skeleton for Patientl-Level Prediction Studies
========================================================

A skeleton package, to be used as a starting point when implementing patient-level prediction studies.

Vignette: [Using the package skeleton for patient-level prediction studies](https://raw.githubusercontent.com/OHDSI/StudyProtocolSandbox/master/finalWoo/inst/doc/UsingSkeletonPackage.pdf)

Instructions To Prepare Package Outside Atlas
===================

- Step 1: Change package name, readme and description (replace (finalWoo with the package name)
- Step 2: Change all references of package name [in Main.R lines 101 and 126, CreateCohorts.R lines 27,37 and 42, CreateAllCohorts.R lines 62 and 77, readme.md and in PackageMaintenance.R]
- Step 3: Add inst/settings/CohortToCreate.csv - a csv containing three columns, cohortId, atlasId and name - the cohorts in your local atlas with the atlasId will be downloaded into the package and given the cohortId cohort_definition_id when the user creates the cohorts.
- Step 4: Create prediction analysis detail r code that specifies the models, populations, covariates, Ts and Os used in the study (extras/CreatePredictionAnalysisDetails)
- Step 5: Run package management to extract cohorts (using CohortToCreate.csv) and create json specification (using extras/CreatePredictionAnalysisDetails.R)


Instructions To Build Package
===================

- Build the package by clicking the R studio 'Install and Restart' button in the built tab 

Instructions To Run Package
===================

- Share the package by adding it to the OHDSI/StudyProtocolSandbox github repo and get people to install by running but replace 'finalWoo' with your study name if not using atlas:
```r
  # get the latest PatientLevelPrediction
  install.packages("devtools")
  devtools::install_github("OHDSI/PatientLevelPrediction")
  # check the package
  PatientLevelPrediction::checkPlpInstallation()
  
  # install the network package
  devtools::install_github("OHDSI/StudyProtocolSandbox/finalWoo")
```

- Get users to execute the study by running the code in (extras/CodeToRun.R) but replace 'finalWoo' with your study name:
```r
  library(finalWoo)
  # USER INPUTS
#=======================
# The folder where the study intermediate and result files will be written:
outputFolder <- "./finalWooResults"

# Specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "location with space to save big data")

# Details for connecting to the server:
dbms <- "you dbms"
user <- 'your username'
pw <- 'your password'
server <- 'your server'
port <- 'your port'

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

# Add the database containing the OMOP CDM data
cdmDatabaseSchema <- 'cdm database schema'
# Add a database with read/write access as this is where the cohorts will be generated
cohortDatabaseSchema <- 'work database schema'

oracleTempSchema <- NULL

# table name where the cohorts will be generated
cohortTable <- 'finalWooCohort'
#=======================

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        createProtocol = F,
        createCohorts = T,
        runAnalyses = T,
        createResultsDoc = F,
        packageResults = T,
        createValidationPackage = F,
        minCellCount= 5)
```
- You can then easily transport the trained models into a network validation study package by running:
```r
  
  execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolder,
        createProtocol = F,
        createCohorts = F,
        runAnalyses = F,
        createResultsDoc = F,
        packageResults = F,
        createValidationPackage = T,
        minCellCount= 5)
  

```

- To create the shiny app and view run:
```r
  
populateShinyApp(resultDirectory = outputFolder,
                 minCellCount = 10, 
                 databaseName = 'friendly name'
                 ) 
        
viewShiny('finalWoo')
  

```


# Development status
Under development. Do not use
