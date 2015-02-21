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
#' @param folder   The name of the local folder to place results;  make sure to use forward slashes (/)
#' @param ...   (FILL IN) Additional properties for this specific study.
#' 
#' @importFrom DBI dbDisconnect
#' @export
execute <- function(dbms, user, password, server, 
                    port = NULL,
                    cdmSchema, resultsSchema, 
										file = getDefaultStudyFileName(),
                    folder = getwd(),
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
    save(list = objectsToSave, file = file)
            
    # Clean up
    DBI::dbDisconnect(conn)    

    # Package and return result if return value is used	
    result <- mget(objectsToSave)
    class(result) <- "OhdsiStudy"
    invisible(result)
}

#' @export
saveOhsdiStudy <- function(list = stop("Must provide object list to save"),
													 file = getDefaultStudyFileName(),
													 compress = "xz",
													 includeMetadata = TRUE) {
	
	
	if (includeMetadata) {
		metadata <- list()
		
		metadata$r.version <- R.Version()$version.string		
		info <- Sys.info()
		metadata$sysname <- info[["sysname"]]
		metadata$login <- info[["login"]]
		metadata$user <- info[["user"]]
		metadata$nodename <- info[["nodename"]]
		list <- c(list, "metadata")
	}
	
	save(list = list,
			 file = file,
			 compress = compress)
}

#' @export
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


#' @keywords internal
getDestinationAddress <- function() { return("nobody@gmail.com") }

#' @keywords internal
getDefaultStudyFileName <- function() { return("PGxStudy.rda") }

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
#' @param sourceName Short name that was be appeneded to results table name
#' @param folder   The name of the local folder to place results;  make sure to use forward slashes (/)
#' @param compress Use GZip compression on transmitted files
#'
#' @export
email <- function(from,
									to = getDestinationAddress(),
									subject = "OHDSI Skeleton Study Results",
									dataDescription,									
									folder = getwd(),
									compress = TRUE) {
	
	if (missing(from)) stop("Must provide return address")
	if (missing(dataDescription)) stop("Must provide a data description")
	
	suffix <- c("_person_cnt.csv", "_seq_cnt.csv", "_summary.csv")
	prefix <- c("Dep12mo_", "HTN12mo_", "DM12mo_")
	
	files <- unlist(lapply(prefix, paste, 
												 paste(sourceName, suffix, sep =""), 
												 sep =""))
	absolutePaths <- paste(folder, files, sep="/")
	
	if (compress) {
		
		sapply(absolutePaths, function(name) {
			newName = paste(name, ".gz", sep="")
			tmp <- read.csv(file = name)			
			newFile <- gzfile(newName, "w")
			write.csv(tmp, newFile)
			writeLines(paste("Compressed to file '",newName,"'",sep=""))	
			close(newFile)
		})
		absolutePaths <- paste(absolutePaths, ".gz", sep="")		
	}
	
	result <- mailR::send.mail(from = from,
														 to = to,
														 subject = subject,
														 body = paste("\n", dataDescription, "\n",
														 						 sep = ""),
														 smtp = list(host.name = "aspmx.l.google.com",
														 						port = 25),
														 attach.files = absolutePaths,						
														 authenticate = FALSE,
														 send = TRUE)
	if (result$isSendPartial()) {
		stop("Error in sending email")
	} else {
		writeLines("Emailed the following files:\n")
		writeLines(paste(absolutePaths, collapse="\n"))
		writeLines(paste("\nto:", to))
	}
}
