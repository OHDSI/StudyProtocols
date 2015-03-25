#' @title Execute OHDSI Study PGxDrugStudy
#'
#' @details
#' This function executes OHDSI Study "Incidence of exposure to drugs for which pre-emptive pharmacogenomic testing is available" (PGxDrugStudy).
#' This is a study to derive data that large healthcare organizations can combine with data on risks of adverse events and cost data to conduct cost-effectiveness / cost-benefit analyses for pre-emptive pharmacogenomics testing.
#' Detailed information and protocol are available on the OHDSI Wiki (http://www.ohdsi.org/web/wiki/doku.php?id=research:pgx_drug_exposure).
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
    
    # Record start time
    start <- Sys.time()
        
    # Count gender
    gender <- invokeSql("CountGender.sql", dbms, conn, "Executing gender count ...")    
    
    # Get frequencies
    frequencies <- invokeSql("GetFrequencies.sql", dbms, conn, "Executing frequency count ...")
    
    # Age by exposure
    ageAtExposure <- invokeSql("AgeAtExposure.sql", dbms, conn, "Executing age by exposure count ...")
    
    # Age by exposure redefinition
    ageAtExposureRedefinition <- invokeSql("AgeAtExposureRedefinition.sql", dbms, conn, "Executing age by exposure redefinition ...")
     
    # Count people
    # TODO: a query for each age range or some way of passing age ranges  needs to be implemented
    # TODO: the chance of null results needs to be accounted for.
    tmp <- invokeSql("CountPerson.sql", dbms, conn, text ="Executing person count ...", 
    								 use.ffdf = TRUE) # Cache to disk in case table is large
    person <- list()
    person$count <- length(tmp[,1])
    person$min <- min(tmp[,1])
    person$median <- median(tmp[,1])
    person$max <- max(tmp[,1])
    rm(tmp) # discard potentially large file
    
    # Execution duration
    executionTime <- Sys.time() - start

    # List of R objects to save
    objectsToSave <- c(
    	"gender",
    	"frequencies",
    	"ageAtExposure",
    	"ageAtExposureRedefinition",
    	"person",
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
getDestinationAddress <- function() { return("codehop.dev@gmail.com") }

# Package must provide a default result file name
#' @keywords internal
getDefaultStudyFileName <- function() { return("PGxStudy.rda") }

# Packge must provide default email subject
#' @keywords internal
getDefaultStudyEmailSubject <- function() { return("OHDSI PGxDrugStudy Results") }
