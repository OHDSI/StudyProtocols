###########################################################
# R script for creating SQL files (and sending the SQL    # 
# commands to the server) for T2DM Patient counts         #
#                                                         #
# Requires: R and Java 1.6 or higher                      #
###########################################################

# Install necessary packages if needed
install.packages("devtools")
library(devtools)
install_github("ohdsi/SqlRender")
install_github("ohdsi/DatabaseConnector")

# Load libraries
library(SqlRender)
library(DatabaseConnector)

###########################################################
# Parameters: Please change these to the correct values:  #
###########################################################

folder        = "/Documents/study/R Version" # Folder containing the R and SQL files, use forward slashes
cdmSchema     = "cdm_schema"
resultsSchema = "results_schema"
sourceName    = "source_name"
studyName     = "T2DMCounts"
dbms          = "sql server"  	  # Should be "sql server", "oracle", "postgresql" or "redshift"

# If you want to use R to run the SQL and extract the results tables, please create a connectionDetails 
# object. See ?createConnectionDetails for details on how to configure for your DBMS.



user <- NULL
pw <- NULL
server <- "server_name"
port <- NULL

connectionDetails <- createConnectionDetails(dbms=dbms, 
                                              server=server, 
                                              user=user, 
                                              password=pw, 
                                              schema=cdmSchema,
                                              port=port)


###########################################################
# End of parameters. Make no changes after this           #
###########################################################

setwd(folder)

source("HelperFunctions.R")

# Create the parameterized SQL files:
SqlFile <- renderStudySql(cdmSchema,resultsSchema,studyName, dbms)

# Execute the SQL:
conn <- connect(connectionDetails)
executeSql(conn,readSql(SqlFile))

# Extract tables to CSV files:
extractAndWriteToFile(conn, "_patients_t2dm_final_counts", resultsSchema, studyName, dbms)

dbDisconnect(conn)
