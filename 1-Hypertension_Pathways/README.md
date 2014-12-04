Hypertension Pathway Protocol
===============

Protocol is available on OHDSI wiki at:  http://www.ohdsi.org/web/wiki/doku.php?id=research:treatment_pathways_in_hypertension.

The SQL code in this directory was rendered using the Treatment Pathway R script available in the Treatment_Pathways folder within this StudyProtocols github repository.

You have two options to execute this analysis:

1)  Working within R
- Open MainAnalysis.r, within Treatment_Pathways subfolder.
- Modify the parameters near the top of the script
	folder        = "C:/Users/mschuemi/Desktop/Treatment patterns" # Folder containing the R and SQL files
	minCellCount  = 5   # all cell counts lower than this value will be removed from the final results table
	cdmSchema     = "cdm_truven_ccae_6k"   # schema name where your patient-level data in OMOP CDM format resides
	resultsSchema = "scratch"  # schema where you'd like the results tables to be created (requires user to have create/write access)
	sourceName    = "CCAE_6k"  # short name that will be appeneded to results table name
	dbms          = "postgresql"  	  # Should be "sql server", "oracle", "postgresql" or "redshift"
 
- Execute the script.
	MainAnalysis.r will render the SQL, translate it to your environment dialect (SQL Server, Oracle, PostgresQL), execute the SQL, and export the resulting summary statistics as .csv files.   As written, this script will complete the analysis for all 3 study requests:  hypertension, type 2 diabetes mellitus, and depression.
- Email the results files to study coordinator.


2) Use the SQL code 
- Open the dialect-specific version of the SQL in your SQL developer console.
- Find/replace the default values for th following parameters:
 
-- cdm_schema  :  replace with schema name of your CDM

-- results_schema  : replace with schema where you want to store temp tables and results tables

-- source_name  :  replace with shortname that'll be in result table name (e.g. CCAE, INPC, Optum)

- Export the 4 results tables from your resultSchema into .csv files.
- Email the results files to the study coordinator.
