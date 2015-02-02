Treatment Pathways Study Protocol 12 months
===============

This is a study of treatment pathways in hypertension, diabetes, and depression during the first 12 mo after diagnosis.  Detailed information and protocol is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:treatment_pathways_in_chronic_disease_12_mos).

Execution via R

**R Version**

- Open MainAnalysis.R in your R console
- Modify the parameters near the top of the script
    -	folder        = "C:/Users/mschuemi/Desktop/Treatment patterns" # Folder containing the R files and parameterized SQL script from this repo, make sure to use forward slashes /
    -	minCellCount  = 5   # all cell counts lower than this value will be removed from the final results table
    -	cdmSchema     = "cdm_truven_ccae_6k"   # schema name where your patient-level data in OMOP CDM format resides
    -	resultsSchema = "scratch"  # schema where you'd like the results tables to be created (requires user to have create/write access)
    -	sourceName    = "CCAE_6k"  # short name that will be appeneded to results table name
    -  	dbms          = "postgresql"  	  # Should be "sql server", "oracle", "postgresql" or "redshift"
 
- Execute the script.
	MainAnalysis.r will render the SQL, translate it to your environment dialect (SQL Server, Oracle, PostgresQL), execute the SQL, and export the resulting summary statistics as .csv files.   As written, this script will complete the analysis for all 3 study requests:  hypertension, type 2 diabetes mellitus, and depression.
- 3 CSV files will be generated for each of the 3 studies and placed in the "folder" defined above.  Email the results files to study coordinator.

**SQL Version**

If you would like to run the study directly from SQL without using R, contact the study administrator listed on the Wiki page. - Open the dialect-specific version of the SQL script in your SQL console of choice.
- Perform find/replace on the following parameters:
 
    - cdm_schema  :  replace with schema name of your CDM

    - results_schema  : replace with schema where you want to store temp tables and results tables

    - source_name  :  replace with shortname that'll be in result table name (e.g. CCAE, INPC, Optum)

- Execute SQL (may take a few hours)
- Export the results tables from your resultSchema into .csv files.
- Email the results files to the study coordinator.

Note that the SQL version runs one study at a time, so the above should be repeated to perform all three studies.
