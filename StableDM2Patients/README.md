Estimating the number of stable diabetes mellitus type II patients
===============

Description: Guidelines for several chronic conditions, like hypertension or depression, still encompass a large amount of uncertainty, often leaving the physician with several choices and not enough tools to decide between them. Our aim is to introduce a data-driven approach that suggests a treatment based on similarity of a new patient to patients that received a beneficial treatments in the past.
In order to assess the utility of our approach, we test it on diabetes mellitus type II (DM) which has relatively good guidelines. Assessing stability of DM patients requires longitudinal information including also outpatient data. As a first step, we estimate the number of patients that are stable on known treatments for diabetes. The query assesses the number of patients that are considered stable on any treatment, by posing several requirements on the amount of information we have on the patient, including total time of observational data, number of visits and the number of relevant lab tests as well as verifying that the patient is on a certain drug above a minimal amount of time.

Before coding the complete study, we are releasing the potential patient identification step to determine if there is enough support on the OHDSI sites for this study to be ported in its entirety.

To execute protocol in `R`

```R
library(devtools)
install_github(c("OHDSI/SqlRender","OHDSI/DatabaseConnector","OHDSI/StudyProtocols/StableDM2Patients"))
library(StableDM2Patients)

# Run study
execute(dbms = "postgresql",      # Change to participant settings
        user = "joebruin",
        password = "supersecret",
        server = "myserver",
        port = "myport",
        resultsSchema = "my_results_schema",
        cdmSchema = "cdm_schema")

# Email results file
email(from = "collaborator@ohdsi.org",         # Change to participant email address
      dataDescription = "Counts for Stable StableDM2Patients initial phase") # Change to participant data description
```

To reload saved results in `R`

```R
# Load (or reload) study results
results <- loadOhdsiStudy(verbose = TRUE)
