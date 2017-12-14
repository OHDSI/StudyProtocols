OHDSI Alendronate vs Raloxifene study
=============================================

This study aims to evaluate hip fracture risk in patients exposed to alendronate compared with those exposed to raloxifene.

Detailed information is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:bisphosphonates_and_hip_fracture) and [Full Protocol](https://raw.githubusercontent.com/OHDSI/StudyProtocol/AlendronateVsRaloxifene/master/extras/alendronate_raloxifene_hip_fracture.docx).

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, Amazon RedShift, or Microsoft APS.
- R version 3.2.2 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 100 GB of free disk space

Recommended
===========

- 8 CPU cores or more
- 32 GB of memory or more

How to run
==========
1. Make sure that you have [Java](http://java.com) installed, and on Windows make sure that [RTools](http://cran.r-project.org/bin/windows/Rtools/) is installed. See the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=documentation:r_setup) for help on setting up your R environment

3. In `R`, use the following code to install the study package and its dependencies:
	```r
	library(devtools)
	install_github("ohdsi/SqlRender")
	install_github("ohdsi/DatabaseConnector")
	install_github("ohdsi/OhdsiRTools")
	install_github("ohdsi/OhdsiSharing")
	install_github("ohdsi/FeatureExtraction")
	install_github("ohdsi/CohortMethod")
	install_github("ohdsi/EmpiricalCalibration")
	install_github("ohdsi/StudyProtocols/AlendronateVsRaloxifene")
	```
4. Once installed, you can execute the study by modifying and using the following code:

	```r
	library(AlendronateVsRaloxifene)

	connectionDetails <- createConnectionDetails(dbms = "postgresql",
	                                             user = "joe",
						     password = "secret",
						     server = "myserver")
						     
	# Run this to only perform a feasibility analysis, counting the number of subjects per cohort:
	assessFeasibility(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = "cdm_data",
                  workDatabaseSchema = "results",
                  studyCohortTable = "ohdsi_alendronate_raloxifene",
                  oracleTempSchema = NULL,
                  outputFolder = "c:/temp/study_results")

	# Alternatively, run this to execute the full study:
	execute(connectionDetails = connectionDetails,
		cdmDatabaseSchema = "cdm_data",
		workDatabaseSchema = "results",
		studyCohortTable = "ohdsi_alendronate_raloxifene",
		oracleTempSchema = NULL,
		outputFolder = "c:/temp/study_results",
		createCohorts = TRUE,
		runAnalyses = TRUE,
		packageResults = TRUE,
		maxCores = 30)
	```

	* For details on how to configure```createConnectionDetails``` in your environment type this for help:
	```r
	?createConnectionDetails
	```

	* ```cdmDatabaseSchema``` should specify the schema name where your data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
	
	* ```workDatabaseSchema``` should specify the schema name where intermediate results can be stored. Note that for SQL Server, this should include both the database and schema name, for example 'results.dbo'.
	
	* ```studyCohortTable``` should specify the name of the table that will be created in the work database schema where the exposure and outcomes cohorts will be stored. The default value is 'ohdsi_alendronate_raloxifene'.

	* ```oracleTempSchema``` should be used for Oracle users only to specify a schema where the user has write priviliges for storing temporary tables. This can be the same as the work database schema.
	
	* ```outputFolder``` a location in your local file system where results can be written. Make sure to use forward slashes (/). Do not use a folder on a network drive since this greatly impacts performance. 

	* ```maxCores``` is the number of cores that are available for parallel processing. If more cores are made available this can speed up the analyses. Preferrably, this should be set the number of cores available in the machine.
	
5. Upload the file ```export/studyResult.zip``` in the output folder to the study coordinator:
    ```r
    submitResults("c:/temp/study_results/export", key = "<key>", secret = "<secret>")
    ```
    Where ```key``` and ```secret``` are the credentials provided to you personally by the study coordinator.

6. If you want, you can generate the figures, tables, and report locally using:

    ```r
    createTableAndFigures("c:/temp/study_results/export")
    
    writeReport("c:/temp/study_results/export", "c:/temp/study_results/report.docx")
    ```
    This will create a subfolder called ```tablesAndFigures``` in the ```export``` folder containing several tables and figures, as well as a Word document summarizing the main results of the study/

Getting Involved
================
* Package manual: [AlendronateVsRaloxifene.pdf](https://raw.githubusercontent.com/OHDSI/StudyProtocol/AlendronateVsRaloxifene/master/extras/AlendronateVsRaloxifene.pdf)
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements


License
=======
The AlendronateVsRaloxifene package is licensed under Apache License 2.0

Development
===========
AlendronateVsRaloxifene was developed in R Studio.

### Development status

In production. We're running this study at multiple sites.
