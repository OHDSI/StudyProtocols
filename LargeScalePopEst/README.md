OHDSI Large-Scale Population-Level Evidence Generation study
======================================================================

This study aims to generate population-level evidence on treatments used for major depressive disorder.

Detailed information and protocol is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:largescalepopest).

How to run
==========
1. Make sure that you have Java installed. If you don't have Java already intalled on your computed (on most computers it already is installed), go to java.com to get the latest version. (If you have trouble building with rJava below, be sure on Windows that your Path variable includes the path to jvm.dll (Windows Button --> type "path" --> Edit Environmental Variables --> Edit PATH variable, add to end ;C:/Program Files/Java/jre/bin/server) or wherever it is on your system.)

2. In R, use the following code to install the study package and its dependencies:

	```r
	install.packages("devtools")
	library(devtools)
	install_github("ohdsi/OhdsiRTools") 
	install_github("ohdsi/DatabaseConnector")
	install_github("ohdsi/FeatureExtraction") 
	install_github("ohdsi/CohortMethod", ref = "develop")
	install_github("ohdsi/OhdsiSharing")
	install_github("ohdsi/MethodEvaluation")
	install_github("ohdsi/StudyProtocols/LargeScalePopEst")
	```

3. Once installed, you can execute the study by modifying and using the following code:

	```r
	library(LargeScalePopEst)

	connectionDetails <- createConnectionDetails(dbms = "postgresql",
												 user = "joe",
												 password = "secret",
												 server = "myserver")
	# Optional:											 
    options(fftempdir = "R:/fftemp")

    execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = "cdm_data",
        oracleTempSchema = NULL,
        workDatabaseSchema = "scratch",
        studyCohortTable = "ohdsi_depression_cohorts",
        exposureCohortSummaryTable = "ohdsi_depression_exposure_summary",
        workFolder = "c:/temp/LargeScalePopEst",
        maxCores = 4,
        createCohorts = TRUE,
        fetchAllDataFromServer = TRUE,
        injectSignals = TRUE,
        generateAllCohortMethodDataObjects = TRUE,
        runCohortMethod = TRUE)
        
    
    calibrateEstimatesAndPvalues("c:/temp/LargeScalePopEst")
	```

	* For details on how to configure```createConnectionDetails``` in your environment type this for help:
	```r
	?createConnectionDetails
	```
	
	* ```fftempdir``` can be used to specify a path to a folder on the local file system where temporary files are stored. Be sure to use forward slashes (/). Please make sure at least 100GB of space is available. If fftempdir is not specified, a temp folder will be created in the system temp folder. 

	* ```cdmDatabaseSchema``` should specify the schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.

	* ```oracleTempSchema``` should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.
	
	* ```workDatabaseSchema``` should specify the schema name where intermediate results are stored on the server. You should have create and write priviliges in this schema. Note that for SQL Server, this should include both the database and schema name, for example 'scratch.dbo'.
	
	* ```studyCohortTable``` should specify the name of the table that will be created in the workDatabaseSchema to hold the study-specific cohorts.

	* ```exposureCohortSummaryTable``` should specify the name of the table that will be created in the workDatabaseSchema to hold summary information on the exposure cohorts.
	
    * ```workFolder``` should be the path to a folder on the local file system where intermediate and result files are stored. Be sure to use forward slashes (/). Please make sure at least 250GB of space is available.
    
    * ```maxCores``` specifies the maximum number of cores to be used. Allocating more cores will speed up the process.
    
    * ```createCohorts```, ``` fetchAllDataFromServer```, ```injectSignals```, ```generateAllCohortMethodDataObjects```, ```runCohortMethod``` can be used to run only parts of the analysis. Note that none of the steps can be skipped unless already comleted in a previous run.
    
Getting Involved
================
* Package manual: [LargeScalePopEst.pdf](https://raw.githubusercontent.com/OHDSI/StudyProtocols/LargeScalePopEst/master/extras/LargeScalePopEst.pdf)
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="../../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements


License
=======
The LargeScalePopEst package is licensed under Apache License 2.0

Development
===========
LargeScalePopEst was developed in R Studio.

###Development status

Under active development.

