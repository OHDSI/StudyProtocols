The Women of OHDSI Overview
========================================================

OHDSI's mission is to improve health by empowering a community to collaboratively generate the evidence that promotes better health decisions and better care. As a community, we strive promote openness and inclusivity by creating an environment where all voices are heard.

The Women of OHDSI group aims to provide a forum for women within the OHDSI community to come together and discuss challenges they face as women working in science, technology, engineering and mathematics (STEM). We aim to facilitate discussions where women can share their perspectives, raise concerns, propose ideas on how the OHDSI community can support women in STEM, and ultimately inspire women to become leaders within the community and their respective fields. This research investigation is intended to foster collaboration across the OHDSI community about an important clinical question. 

Executive Summary of Study
========================================================

Mammography screening can lead to early detection of cancer but has negative impacts such as causing patients anxiety. Being more informed, such as quantifying your personal risk, can reduce anxiety.  We wish to develop a risk prediction model could be developed to predict future risk of breast cancer at the point in time a patient has a mammography.  This would be implemented at the same time a patient has a screen to not only enable them to know whether they have current breast cancer but to also tell them their 3-year risk.

The objective of this study is to develop and validate patient-level prediction models for patients in 2 target cohort(s) (Target 1: Patients with first mammography in 2 years and no prior neoplasm and Target 2: Patients with first mammography in 2 years and no prior breast cancer) to predict 1 outcome(s) (Outcome: At least two occurrence of Breast cancer in the Time at Risk (TAR Settings: Risk Window Start:  1 day after index, , Risk Window End:  1095 days after index).

The prediction will be implemented using one algorithm (a Lasso Logistic Regression).

Study Milestones
========================================================
- **August 09, 2019:** Study Protocol Published
- **August 09 - Sep 05, 2019:** Call for Sites to Run & Send Results
- **Sep 16, 2019:** Results Presentation at 2019 US OHDSI Symposium
- **September onward:** Manuscript preparations

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

- To create the shiny app locally and view run:
```r
  
populateShinyApp(resultDirectory = outputFolder,
                 minCellCount = 10, 
                 databaseName = 'friendly name'
                 ) 
        
viewShiny('finalWoo')
  

```
