###########################################################
# R script for creating SQL files (and sending the SQL    # 
# commands to the server) for the treatment pattern       #
# studies for these diseases:                             #
# - Hypertension (HTN)                                    #
# - Type 2 Diabetes (T2DM)                                #
# - Depression                                            #
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

folder        = "C:/Users/mschuemi/Desktop/Treatment patterns" # Folder containing the R and SQL files, use forward slashes
minCellCount  = 5
cdmSchema     = "cdm_truven_ccae_6k"
resultsSchema = "scratch"
sourceName    = "CCAE_6k"
dbms          = "postgresql"  	  # Should be "sql server", "oracle", "postgresql" or "redshift"

# If you want to use R to run the SQL and extract the results tables, please create a connectionDetails 
# object. See ?createConnectionDetails for details on how to configure for your DBMS.

connectionDetails <- createConnectionDetails(dbms     = dbms,
                                             user     = "postgres", 
                                             password = "F1r3starter", 
                                             server   = "localhost/ohdsi")

###########################################################
# End of parameters. Make no changes after this           #
###########################################################

setwd(folder)

source("HelperFunctions.R")

# Create the parameterized SQL files:
htnSqlFile <- renderStudySpecificSql("HTN",minCellCount,cdmSchema,resultsSchema,sourceName,dbms)
t2dmSqlFile <- renderStudySpecificSql("T2DM",minCellCount,cdmSchema,resultsSchema,sourceName,dbms)
depSqlFile <- renderStudySpecificSql("Depression",minCellCount,cdmSchema,resultsSchema,sourceName,dbms)

# Execute the SQL:
conn <- connect(connectionDetails)
executeSql(conn,readSql(htnSqlFile))
executeSql(conn,readSql(t2dmSqlFile))
executeSql(conn,readSql(depSqlFile))

# Extract tables to CSV files:
extractAndWriteToFile(conn, "person_count", resultsSchema, sourceName, "HTN", dbms)
extractAndWriteToFile(conn, "person_count_year", resultsSchema, sourceName, "HTN", dbms)
extractAndWriteToFile(conn, "seq_count", resultsSchema, sourceName, "HTN", dbms)
extractAndWriteToFile(conn, "seq_count_year", resultsSchema, sourceName, "HTN", dbms)

extractAndWriteToFile(conn, "person_count", resultsSchema, sourceName, "T2DM", dbms)
extractAndWriteToFile(conn, "person_count_year", resultsSchema, sourceName, "T2DM", dbms)
extractAndWriteToFile(conn, "seq_count", resultsSchema, sourceName, "T2DM", dbms)
extractAndWriteToFile(conn, "seq_count_year", resultsSchema, sourceName, "T2DM", dbms)

extractAndWriteToFile(conn, "person_count", resultsSchema, sourceName, "Depression", dbms)
extractAndWriteToFile(conn, "person_count_year", resultsSchema, sourceName, "Depression", dbms)
extractAndWriteToFile(conn, "seq_count", resultsSchema, sourceName, "Depression", dbms)
extractAndWriteToFile(conn, "seq_count_year", resultsSchema, sourceName, "Depression", dbms)

dbDisconnect(conn)


