OHDSI Drug Utilization in Children Protocol
===========================================

This study aims to measure the prevalence of drug use in children in several countries in Asia. We will compute prevalence for all drugs captured in the databases in the pediatric population. The main analysis will focus on drug classes (anatomical and therapeutic) and these prevalences will be stratified by year to evaluate temporal trends. A secondary analysis will report the five top ingredients per anatomical class per country. All analysis will be stratified by age (< 2 years, 2-11 years, and 12-18 years), and by setting (inpatient or ambulatory care).

Detailed information and protocol is available on the [OHDSI Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:drugs_in_peds).

How to run
==========
1. Make sure that you have Java installed. If you don't have Java already intalled on your computed (on most computers it already is installed), go to java.com to get the latest version. (If you have trouble building with rJava below, be sure on Windows that your Path variable includes the path to jvm.dll (Windows Button --> type "path" --> Edit Environmental Variables --> Edit PATH variable, add to end ;C:/Program Files/Java/jre/bin/server) or wherever it is on your system.)

2. In R, use the following code to install the study package and its dependencies:

	```r
	install.packages("devtools")
	library(devtools)
	install_github("ohdsi/SqlRender")
	install_github("ohdsi/DatabaseConnector")
	install_github("ohdsi/OhdsiSharing")
	install_github("ohdsi/StudyProtocols/DrugsInPeds")
	```

3. Once installed, you can execute the study by modifying and using the following code:

	```r
	library(DrugsInPeds)

	connectionDetails <- createConnectionDetails(dbms = "postgresql",
												 user = "joe",
												 password = "secret",
												 server = "myserver")

	execute(connectionDetails,
			cdmDatabaseSchema = "cdm_data",
			oracleTempSchema = NULL,
			cdmVersion = "4")
	```

	* For details on how to configure```createConnectionDetails``` in your environment type this for help:
	```r
	?createConnectionDetails
	```

	* ```cdmDatabaseSchema``` should specify the schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include both the database and schema name, for example 'cdm_data.dbo'.

	* ```oracleTempSchema``` should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.

	* ```cdmVersion``` is the version of the CDM. Can be "4" or "5".

4. Please e-mail the file ```StudyResults.zip.enc``` in the ```DrugsInPeds``` folder to the study coordinator.

Generating figures and tables
=============================

To locally generate the figures and tables described in the protocol, you can run

```r
    createFiguresAndTables(connectionDetails,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           oracleTempSchema = oracleTempSchema,
                           cdmVersion = cdmVersion,
                           folder = "my_folder")
```

where ```my_folder``` is the path to the folder where the results of the ```execute``` command were stored.
