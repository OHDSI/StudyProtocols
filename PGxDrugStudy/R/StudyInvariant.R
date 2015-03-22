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
		assign("metadata", metadata, envir = parent.frame()) # place in same environment as named objects
		list <- c(list, "metadata")
	}
	
	save(list = list,
			 file = file,
			 envir = parent.frame(1),
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
									subject = getDefaultStudyEmailSubject(),
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
