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
        
    # Count gender
    gender <- invokeSql("CountGender.sql", dbms, conn, "Executing gender count ...")    
    
    # Count race
    race <- invokeSql("CountRace.sql", dbms, conn, "Executing race count ...")
    
    # Get frequencies
    frequencies <- invokeSql("GetFrequencies.sql", dbms, conn, "Executing frequency count ...")
    
    # Age by exposure
    ageAtExposure <- invokeSql("AgeAtExposure.sql", dbms, conn, "Executing age by exposure count ...")
    
    # Age by exposure redefinition
   	ageAtExposureRedefinition <- invokeSql("AgeAtExposureRedefinition.sql", dbms, conn, "Executing age by exposure redefinition ...")
     
    # Count people
    tmp <- invokeSql("CountPerson.sql", dbms, conn, text ="Executing person count ...", 
    								 use.ffdf = TRUE) # Cache to disk in case table is large
    person <- list()
    person$count <- length(tmp[,1])
    person$min <- min(tmp[,1])
    person$median <- median(tmp[,1])
    person$max <- max(tmp[,1])
    rm(tmp) # discard potentially large file

    # List of R objects to save
    objectsToSave <- c(
    	"gender",
    	"race",
    	"frequencies",
    	"ageAtExposure",
    	"ageAtExposureRedefinition",
    	"person"
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

#' @keywords internal
getDestinationAddress <- function() { return("msuchard@gmail.com") }

#' @keywords internal
getDefaultStudyFileName <- function() { return("PGxStudy.rda") }

#' @title Load OHSDI study
#' 
#' @details
#' This function loads an OHDSI study results from disk file. 
#' 
#' @param file	(Optional) Name of local file to place results; makre sure to use forward slashes (/)
#' @param verbose Logical: print R object names that are loaded
#' 
#' @return
#' A list of class type \code{OhsiStudy} that contains all saved study objects
#' 
#' @export 
loadOhdsiStudy <- function(file = getDefaultStudyFileName(),													 
													 verbose = FALSE) {
	# Return list of results
	tmp <- new.env()
	load(file, envir = tmp, verbose = verbose)
	result <- mget(ls(tmp), envir = tmp)
	class(result) <- "OhdsiStudy"
	return (result)	
}

#' @title Save OHDSI study
#'
#' @details
#' This function saves an OHDSI study to disk file.  All objects are written using \code{\link{save}}
#' format and can be read back from file at a later time by using the function \code{\link{loadOhdsiStudy}}.
#' 
#' @param list	A list of R objects to save to disk file.
#' @param file	(Optional) Name of local file to place results; makre sure to use forward slashes (/)
#' @param compress Logical or character string specifying the use of compression. See \code{\link{save}}
#' @param includeMetadata Logical: include metadata about user and system in saved file 
#' 
#' @export
saveOhdsiStudy <- function(list,
													 file = getDefaultStudyFileName(),
													 compress = "xz",
													 includeMetadata = TRUE) {
	
	if (missing(list)) {
		stop("Must provide object list to save")
	}
	
	if (includeMetadata) {
		metadata <- list()
		
		metadata$r.version <- R.Version()$version.string		
		info <- Sys.info()
		metadata$sysname <- info[["sysname"]]
		metadata$user <- info[["user"]]
		metadata$nodename <- info[["nodename"]]
		metadata$time <- Sys.time()
		list <- c(list, "metadata")
	}
	
	save(list = list,
			 file = file,
			 compress = compress)
}

#' @keywords internal
invokeSql <- function(fileName, dbms, conn, text, use.ffdf = FALSE)  {
	
	parameterizedSql <- SqlRender::readSql(system.file(paste("sql/","sql_server",sep=""), 
																									 fileName, 
																									 package="PGxDrugStudy"))        
	renderedSql <- SqlRender::renderSql(parameterizedSql)$sql    
	translatedSql <- SqlRender::translateSql(renderedSql, 
																				 sourceDialect = "sql server", 
																				 targetDialect = dbms)$sql
	writeLines(text)
	if (use.ffdf) { 
		return (DatabaseConnector::dbGetQuery.ffdf(conn, translatedSql))
	} else {
		return (DBI::dbGetQuery(conn, translatedSql))
	}
}

#' @title Email results
#' 
#' @details
#' This function emails the result CSV files to the study coordinator.
#' 
#' @return 
#' A list of files that were emailed.
#' 
#' @param from     Return email address
#' @param to			Delivery email address (must be a gmail.com acccount)
#' @param subject  Subject line of email
#' @param dataDescription A short description of the database
#' @param file	(Optional) Name of local file with results; makee sure to use forward slashes (/)
#'
#' @export
email <- function(from,
									to = getDestinationAddress(),
									subject = "OHDSI PGxDrugStudy Results",
									dataDescription,	
									file = getDefaultStudyFileName()) {
	
	if (missing(from)) stop("Must provide return address")
	if (missing(dataDescription)) stop("Must provide a data description")
	
	if(!file.exists(file)) stop(paste(c("No results file named '",file,"' exists"),sep=""))
	
	result <- mailR::send.mail(from = from,
														 to = to,
														 subject = subject,
														 body = paste("\n", dataDescription, "\n",
														 						 sep = ""),
														 smtp = list(host.name = "aspmx.l.google.com",
														 						port = 25),
														 attach.files = file,						
														 authenticate = FALSE,
														 send = TRUE)
	if (result$isSendPartial()) {
		stop("Error in sending email")
	} else {
		writeLines(c(
			"Emailed the following file:",
			paste("\t", file, sep = ""),
			paste("to:", to)
		))
	}
}
