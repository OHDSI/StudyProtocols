Treatment Pathways Study Protocol 12 months
===============

This is a study of treatment pathways in hypertension, diabetes, and depression during the first 12 mo after diagnosis.  Detailed information and protocol is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:treatment_pathways_in_chronic_disease_12_mos).

**R Version**

- Open MainAnalysis.R in your R console
- Modify the section of code below

```bash
###########################################################
# Parameters: Please change these to the correct values:  #
###########################################################

folder        = "F:/Documents/OHDSI/StudyProtocols/Study 2 - Treatment Pathways 12mo/R Version" # Folder containing the R and SQL files, use forward slashes
minCellCount  = 1   # the smallest allowable cell count, 1 means all counts are allowed
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
   
   *minCellCount* - all cell counts lower than this value will be removed from the final results table
   
   *cdmSchema* - schema name where your patient-level data in OMOP CDM format resides
   
   *resultsSchema* - schema where you'd like the results tables to be created (requires user to have create/write access)
   
   *sourceName* - short name that will be appeneded to results table name
   
   *dbms* - "sql server", "oracle", "postgresql" or "redshift"
   
 
- Execute the script.
- MainAnalysis.R will render the SQL, translate it to your environment dialect, execute the SQL, and export the resulting summary statistics as .csv files to your target folder.  
- Email the resulting files to study coordinator.

If you would like to run the study directly from SQL without using R, contact the study administrator listed on the [Wiki page](http://www.ohdsi.org/web/wiki/doku.php?id=research:treatment_pathways_in_chronic_disease_12_mos). 
