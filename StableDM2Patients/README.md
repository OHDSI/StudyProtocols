Estimating the number of stable diabetes mellitus type II patients
===============

Description: Guidelines for several chronic conditions, like hypertension or depression, still encompass a large amount of uncertainty, often leaving the physician with several choices and not enough tools to decide between them. Our aim is to introduce a data-driven approach that suggests a treatment based on similarity of a new patient to patients that received a beneficial treatments in the past.
In order to assess the utility of our approach, we test it on diabetes mellitus type II (DM) which has relatively good guidelines. Assessing stability of DM patients requires longitudinal information including also outpatient data. As a first step, we estimate the number of patients that are stable on known treatments for diabetes. The query assesses the number of patients that are considered stable on any treatment, by posing several requirements on the amount of information we have on the patient, including total time of observational data, number of visits and the number of relevant lab tests as well as verifying that the patient is on a certain drug above a minimal amount of time.

Before coding the complete study, we are releasing the potential patient identification step to determine if there is enough support on the OHDSI sites for this study to be ported in its entirety. 

- Open MainAnalysis.R in your R console
- Modify the section of code below

```bash
###########################################################
# Parameters: Please change these to the correct values:  #
###########################################################

folder        = "/OHDSI/StudyProtocols/Study Stable Diabetes Mellitus Type II Patients/R Version" # Folder containing the R and SQL files, use forward slashes
cdmSchema     = "cdm_schema"
resultsSchema = "results_schema"
sourceName    = "source_name"
dbms          = "sql server"  	  # Should be "sql server", "oracle", "postgresql" or "redshift"

# If you want to use R to run the SQL and extract the results tables, please create a connectionDetails 
# object. See ?createConnectionDetails for details on how to configure for your DBMS.

user <- NULL
pw <- NULL
server <- "server_name"
port <- NULL 
```

   *folder* - folder containing the R files and parameterized SQL script from this repo, make sure to use forward slashes (/)
   
   *cdmSchema* - schema name where your patient-level data in OMOP CDM format resides
   
   *resultsSchema* - schema where you'd like the results tables to be created (requires user to have create/write access)
   
   *sourceName* - short name that will be appeneded to results table name
   
   *dbms* - "sql server", "oracle", "postgresql" or "redshift"
   
 
- Execute the script.
- MainAnalysis.R will render the SQL, translate it to your environment dialect, execute the SQL, and export the resulting summary statistics as .csv files to your target folder.  
- Email the resulting files to study coordinator.
