OHDSI Keppra and the Risk of Angioedema study
=============================================

This study aims to evaluate angioedema risk in seizure disorder patients exposed to Keppra (levetiracetam) compared with those exposed to phenytoin sodium. A potential link between levetiracetam and angioedema has been recently raised by the Food and Drug Administration in their review of spontaneous reporting data. In this study, we will analyze data from a distributed network using the OHDSI CohortMethod package.

Detailed information is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:angioedema) and [full protocol](https://raw.githubusercontent.com/OHDSI/StudyProtocols/KeppraAngioedema/master/extras/KeppraandAngioedemaRiskStudyProtocolv0.5.docx).

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
	install.packages("stringi")  # Force update to newest version
	
	install.packages("drat")
	drat::addRepo(c("OHDSI","cloudyr")) # Link to OHDSI packages
	install.packages("KeppraAngioedema")
	```
4. Once installed, you can execute the study by modifying and using the following code:

	```r
	library(KeppraAngioedema)

	connectionDetails <- createConnectionDetails(dbms = "postgresql",
												 user = "joe",
												 password = "secret",
												 server = "myserver")

	execute(connectionDetails,
			cdmDatabaseSchema = "cdm_data",
			workDatabaseSchema = "results",
			studyCohortTable = "ohdsi_keppra_angioedema",
			oracleTempSchema = NULL,
			outputFolder = "c:/temp/study_results",
			maxCores = 4)
	```
	
    See [here](https://github.com/OHDSI/StudyProtocols/blob/master/KeppraAngioedema/extras/TestCodeImeds.R) for an example showing how one would run this package in the IMEDS lab.

	* For details on how to configure```createConnectionDetails``` in your environment type this for help:
	```r
	?createConnectionDetails
	```

	* ```cdmDatabaseSchema``` should specify the schema name where your data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.
	
	* ```workDatabaseSchema``` should specify the schema name where intermediate results can be stored. Note that for SQL Server, this should include both the database and schema name, for example 'results.dbo'.
	
	* ```studyCohortTable``` should specify the name of the table that will be created in the work database schema where the exposure and outcomes cohorts will be stored. The default value is 'ohdsi_keppra_angioedema'.

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
* Package manual: [KeppraAngioedema.pdf](https://raw.githubusercontent.com/OHDSI/StudyProtocols/KeppraAngioedema/master/extras/KeppraAngioedema.pdf)
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements


License
=======
The KeppraAngioedema package is licensed under Apache License 2.0

Development
===========
KeppraAngioedema was developed in R Studio.

###Development status

Beta
