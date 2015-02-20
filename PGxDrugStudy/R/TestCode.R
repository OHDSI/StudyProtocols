#' @keywords internal
test <- function() {

    dbms <- "postgresql"
    server <- Sys.getenv("CDM4HOST")
    user <- "ohdsi"
    password <- Sys.getenv("CDM4PASSWORD")
    cdmSchema <- "cdm4_sim"   
    port <- NULL  
    
    result <- execute(dbms, user, password, server, port, cdmSchema)
    
    result
}
   