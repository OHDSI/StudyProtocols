#' @title Execute OHDSI Study (FILL IN NAME)
#'
#' @details
#' This function executes OHDSI Study (FILL IN NAME). 
#' This is a study of (GIVE SOME DETAILS).
#' Detailed information and protocol are available on the OHDSI Wiki.
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
#' @param user				The user name used to access the server.
#' @param password		The password for that user
#' @param server			The name of the server
#' @param port				(optional) The port on the server to connect to
#' @param cdmSchema  Schema name where your patient-level data in OMOP CDM format resides
#' @param resultsSchema  (Optional) Schema where you'd like the results tables to be created (requires user to have create/write access)
#' @param file	(Optional) Name of local file to place results; makre sure to use forward slashes (/)
#' @param ...   (FILL IN) Additional properties for this specific study.
#' 
#' @examples \dontrun{
#' # Run study
#' execute(dbms = "postgresql", 
#'         user = "joebruin", 
#'         password = "supersecret", 
#'         server = "myserver", 
#'         cdmSchema = "cdm_schema", 
#'         resultsSchema = "results_schema")
#'
#' # Email result file        
#' email(from = "collaborator@@ohdsi.org", 
#'       dataDescription = "CDM4 Simulated Data") 
#' }
#' 
#' @importFrom DBI dbDisconnect
#' @export
execute <- function(dbms, user, password, server, 
                    port = NULL,
                    cdmSchema, resultsSchema, 
										file = getDefaultStudyFileName(),
                    ...) {        
    # Open DB connection
    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=dbms, 
                                                                    server=server, 
                                                                    user=user, 
                                                                    password=password, 
                                                                    schema=cdmSchema,
                                                                    port = port)    
    conn <- DatabaseConnector::connect(connectionDetails)
        
	result <- 42

    # List of R objects to save
    objectsToSave <- c(
    	"result"
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
getDestinationAddress <- function() { return("nobody@gmail.com") }

# Package must provide a default result file name
#' @keywords internal
getDefaultStudyFileName <- function() { return("OhdsiStudy.rda") }

# Packge must provide default email subject
#' @keywords internal
getDefaultStudyEmailSubject <- function() { return("OHDSI Study Results") }
