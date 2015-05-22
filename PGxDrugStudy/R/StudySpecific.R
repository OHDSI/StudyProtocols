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
#'   \item{"pdw" for Microsoft Parallel Data Warehouse (PDW)}
#'   \item{"netezza" for IBM Netezza}
#' }
#' @param user				The user name used to access the server. If the user is not specified for SQL Server,
#' 									  Windows Integrated Security will be used, which requires the SQL Server JDBC drivers
#' 									  to be installed.
#' @param domain	    (optional) The Windows domain for SQL Server only.
#' @param password		The password for that user
#' @param server			The name of the server
#' @param port				(optional) The port on the server to connect to
#' @param cdmSchema  Schema name where your patient-level data in OMOP CDM format resides
#' @param file	(Optional) Name of local file to place results; makre sure to use forward slashes (/)
#' @param ...   (FILL IN) Additional properties for this specific study.
#'
#' @examples \dontrun{
#' # Run study
#' execute(dbms = "postgresql",
#'         user = "joebruin",
#'         password = "supersecret",
#'         server = "myserver",
#'         cdmSchema = "cdm_schema")
#'
#' # Email result file
#' email(from = "collaborator@@ohdsi.org",
#'       dataDescription = "CDM4 Simulated Data")
#' }
#'
#' @importFrom DBI dbDisconnect
#' @export
execute <- function(dbms, user = NULL, domain = NULL, password = NULL, server,
                    port = NULL,
                    cdmSchema,
										file = getDefaultStudyFileName(),
                    ...) {
    # Open DB connection
    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=dbms,
                                                                    server=server,
                                                                    user=user,
    																																domain=domain,
                                                                    password=password,
                                                                    schema=cdmSchema,
                                                                    port = port)
    conn <- DatabaseConnector::connect(connectionDetails)
    if (is.null(conn)) {
    	stop("Failed to connect to db server.")
    }

    # Record start time
    start <- Sys.time()

    # Count gender
    gender0to13 <- invokeSql("CountGender0to13.sql", dbms, conn, "Executing gender count 0 to 13 ...")
    gender14to39 <- invokeSql("CountGender14to39.sql", dbms, conn, "Executing gender count 14 to 39 ...")
    gender40to64 <- invokeSql("CountGender40to64.sql", dbms, conn, "Executing gender count 40 to 64 ...")
    gender65Plus <- invokeSql("CountGender65Plus.sql", dbms, conn, "Executing gender count 65 plus ...")

    # Get frequencies
    frequencies0to13 <- invokeSql("GetFrequencies0to13.sql", dbms, conn, "Executing frequency count 0 to 13 ...")
    frequencies14to39 <- invokeSql("GetFrequencies14to39.sql", dbms, conn, "Executing frequency count 14 to 39 ...")
    frequencies40to64 <- invokeSql("GetFrequencies40to64.sql", dbms, conn, "Executing frequency count 40 to 64 ...")
    frequencies65Plus <- invokeSql("GetFrequencies65Plus.sql", dbms, conn, "Executing frequency count 65+ ...")

    # Age by exposure
    ageAtExposureAllPgx0to13 <- invokeSql("AgeAtExposureAllPgx0to13.sql", dbms, conn, "Executing age by exposure ALL pgx count 0 to 13 ...")
    ageAtExposureAllPgx14to39 <- invokeSql("AgeAtExposureAllPgx14to39.sql", dbms, conn, "Executing age by exposure ALL pgx count 14 to 39 ...")
    ageAtExposureAllPgx40to64 <- invokeSql("AgeAtExposureAllPgx40to64.sql", dbms, conn, "Executing age by exposure ALL pgx count 40 to 64 ...")
    ageAtExposureAllPgx65Plus <- invokeSql("AgeAtExposureAllPgx65Plus.sql", dbms, conn, "Executing age by exposure ALL pgx count 65+ ...")

    ageAtExposureCorePgx0to13 <- invokeSql("AgeAtExposureCorePgx0to13.sql", dbms, conn, "Executing age by exposure CORE pgx count 0 to 13 ...")
    ageAtExposureCorePgx14to39 <- invokeSql("AgeAtExposureCorePgx14to39.sql", dbms, conn, "Executing age by exposure CORE pgx count 14 to 39 ...")
    ageAtExposureCorePgx40to64 <- invokeSql("AgeAtExposureCorePgx40to64.sql", dbms, conn, "Executing age by exposure CORE pgx count 40 to 64 ...")
    ageAtExposureCorePgx65Plus <- invokeSql("AgeAtExposureCorePgx65Plus.sql", dbms, conn, "Executing age by exposure CORE pgx count 65+ ...")

    # Count people
    # TODO: should consider a loop instead of code-duplication
    tmp <- invokeSql("CountPerson0to13.sql", dbms, conn, text ="Executing person count 0 to 13 ...", use.ffdf = TRUE) # Cache to disk in case table is large
    person0to13 <- list()
    person0to13$count <- length(tmp[,1])
    if (length(tmp[,1]) > 0) {
    	person0to13$min <- min(tmp[,1])
    	person0to13$median <- median(tmp[,1])
    	person0to13$max <- max(tmp[,1])
    }
    rm(tmp) # discard potentially large file

    tmp <- invokeSql("CountPerson14to39.sql", dbms, conn, text ="Executing person count 14 to 39 ...", use.ffdf = TRUE) # Cache to disk in case table is large
    person14to39 <- list()
    person14to39$count <- length(tmp[,1])
    if (length(tmp[,1]) > 0) {
    	person14to39$min <- min(tmp[,1])
    	person14to39$median <- median(tmp[,1])
    	person14to39$max <- max(tmp[,1])
    }
    rm(tmp) # discard potentially large file

    tmp <- invokeSql("CountPerson40to64.sql", dbms, conn, text ="Executing person count 40 to 64x ...", use.ffdf = TRUE) # Cache to disk in case table is large
    person40to64 <- list()
    person40to64$count <- length(tmp[,1])
    if (length(tmp[,1]) > 0) {
    	person40to64$min <- min(tmp[,1])
    	person40to64$median <- median(tmp[,1])
    	person40to64$max <- max(tmp[,1])
    }
    rm(tmp) # discard potentially large file

    tmp <- invokeSql("CountPerson65Plus.sql", dbms, conn, text ="Executing person count 65+ ...", use.ffdf = TRUE) # Cache to disk in case table is large
    person65Plus <- list()
    person65Plus$count <- length(tmp[,1])
    if (length(tmp[,1]) > 0) {
    	person65Plus$min <- min(tmp[,1])
    	person65Plus$median <- median(tmp[,1])
    	person65Plus$max <- max(tmp[,1])
    }
    rm(tmp) # discard potentially large file

    # Execution duration
    executionTime <- Sys.time() - start

    # List of R objects to save
    objectsToSave <- c(
    	"gender0to13",
        "gender14to39",
        "gender40to64",
        "gender65Plus",
    	"frequencies0to13",
        "frequencies14to39",
        "frequencies40to64",
        "frequencies65Plus",
    	"ageAtExposureAllPgx0to13",
        "ageAtExposureAllPgx14to39",
        "ageAtExposureAllPgx40to64",
        "ageAtExposureAllPgx65Plus",
    	"ageAtExposureCorePgx0to13",
        "ageAtExposureCorePgx14to39",
        "ageAtExposureCorePgx40to64",
        "ageAtExposureCorePgx65Plus",
    	"person0to13",
        "person14to39",
        "person40to64",
        "person65Plus",
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
