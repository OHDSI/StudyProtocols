#' @title Execute OHDSI Study StableDM2Patients
#'
#' @details
#' This function executes OHDSI Study Estimating the number of stable diabetes mellitus type II patients.
#' This is a study of Guidelines for several chronic conditions, like hypertension or depression, still encompass a large amount of uncertainty, often leaving the physician with several choices and not enough tools to decide between them.
#' Our aim is to introduce a data-driven approach that suggests a treatment based on similarity of a new patient to patients that received a beneficial treatments in the past. In order to assess the utility of our approach, we test it on diabetes mellitus type II (DM) which has relatively good guidelines.
#' Assessing stability of DM patients requires longitudinal information including also outpatient data. As a first step, we estimate the number of patients that are stable on known treatments for diabetes.
#' The query assesses the number of patients that are considered stable on any treatment, by posing several requirements on the amount of information we have on the patient, including total time of observational data, number of visits and the number of relevant lab tests as well as verifying that the patient is on a certain drug above a minimal amount of time.
#' Before coding the complete study, we are releasing the potential patient identification step to determine if there is enough support on the OHDSI sites for this study to be ported in its entirety.
#'
#' @return
#' Study results are placed in CSV format files in specified local folder and returned
#' as an R object class \code{OhdsiStudy} when sufficiently small.  The properties of an
#' \code{OhdsiStudy} may differ from study to study.

#' @param dbms              The type of DBMS running on the server. Valid values are
#' \itemize{
#'   \item{"mysql" for MySQL}
#'   \item{"oracle" for Oracle}
#'   \item{"postgresql" for PostgreSQL}
#'   \item{"redshift" for Amazon Redshift}
#'   \item{"sql server" for Microsoft SQL Server}
#' }
#' @param user    			The user name used to access the server.
#' @param password		The password for that user
#' @param server			The name of the server
#' @param port				(optional) The port on the server to connect to
#' @param cdmSchema  Schema name where your patient-level data in OMOP CDM format resides
#' @param studyName  Name of the study
#' @param resultsSchema  (Optional) Schema where you'd like the results tables to be created (requires user to have create/write access)
#' @param file	(Optional) Name of local file to place results; makre sure to use forward slashes (/)
#'
#' @examples \dontrun{
#' # Run study
#' execute(dbms = "postgresql",
#'         user = "joebruin",
#'         password = "supersecret",
#'         server = "myserver",
#'         port ="port"
#'         cdmSchema = "cdm_schema",
#'         studyName = "studyName"
#'         resultsSchema = "results_schema")
#'
#' # Email result file
#' email(from = "collaborator@@ohdsi.org",
#'       dataDescription = "StableDM2Patients results")
#' }
#'
#' @importFrom DBI dbDisconnect
#' @export
execute <- function(dbms, user, password, server, port, cdmSchema, studyName, resultsSchema, file=getDefaultStudyFileName(),
                    ...) {
    # Open DB connection
    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=dbms,
                                                                    server=server,
                                                                    user=user,
                                                                    password=password,
                                                                    schema=cdmSchema,
                                                                    port = port)
    conn <- DatabaseConnector::connect(connectionDetails)
    if (is.null(conn)) {
        stop("Failed to connect to db server.")
    }

    # Record start time
    start <- Sys.time()

    # Place execution code here
    invokeSql("ParameterizedSql.sql",cdmSchema, resultsSchema, studyName, dbms, conn, "Generating estable diabetes mellitus type II patient counts  ...")
    patientCounts <- invokeSqlR("Getcounts.sql",cdmSchema, resultsSchema, studyName, dbms, conn, "Extracting estable diabetes mellitus type II patient counts  ...")

    # Execution duration
    executionTime <- Sys.time() - start

    # List of R objects to save
    objectsToSave <- c(
    	"patientCounts",
        "executionTime"
    	)

    # Save results to disk
    saveOhdsiStudy(list = objectsToSave, file = file)

    # Clean up
    DBI::dbDisconnect(conn)

    # Package and return result if return value is used
    result <- mget(objectsToSave)
    class(result) <- "OhdsiStudy"
    invisible(result)
}

# Package must provide a default gmail address to receive result files
#' @keywords internal
getDestinationAddress <- function() { return("jmbanda@stanford.edu") }

# Package must provide a default result file name
#' @keywords internal
getDefaultStudyFileName <- function() { return("OhdsiStudy.rda") }

# Packge must provide default email subject
#' @keywords internal
getDefaultStudyEmailSubject <- function() { return("OHDSI Study Results") }
