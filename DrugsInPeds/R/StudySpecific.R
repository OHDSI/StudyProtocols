# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of DrugsInPeds
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

loadHelperTables <- function(conn, oracleTempSchema){
    writeLines("Loading helper tables")
    pathToCsv <- system.file("csv",
                             "AgeGroups.csv",
                             package = "DrugsInPeds")
    ageGroups <- read.csv(pathToCsv, as.is = TRUE)
    DatabaseConnector::insertTable(conn, table = "#age_group", data = ageGroups, dropTableIfExists = TRUE, createTable = TRUE, tempTable = TRUE, oracleTempSchema = oracleTempSchema)

    pathToCsv <- system.file("csv",
                             "Years.csv",
                             package = "DrugsInPeds")
    years <- read.csv(pathToCsv, as.is = TRUE)
    DatabaseConnector::insertTable(conn, table = "#calendar_year", data = years, dropTableIfExists = TRUE, createTable = TRUE, tempTable = TRUE, oracleTempSchema = oracleTempSchema)

    sql <- SqlRender::loadRenderTranslateSql("CreateYearPeriods.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)
}

findPopulationWithData <- function(conn,
                                   oracleTempSchema,
                                   cdmDatabaseSchema,
                                   studyStartDate,
                                   studyEndDate,
                                   minDaysPerPerson) {
    writeLines(paste("Finding persons with at least", minDaysPerPerson, "days of observation in the period", studyStartDate, "to", studyEndDate))
    sql <- SqlRender::loadRenderTranslateSql("FindPopulationWithData.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             study_start_date = studyStartDate,
                                             study_end_date = studyEndDate,
                                             min_days_per_person = minDaysPerPerson)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)
}

saveDenominator <- function(conn,
                            oracleTempSchema,
                            cdmDatabaseSchema,
                            studyStartDate,
                            studyEndDate,
                            splitByAgeGroup,
                            splitByYear,
                            splitByGender,
                            fileName) {
    line <- "Getting denominator"
    if (splitByAgeGroup) {
        line <- paste(line, "by age group")
    }
    if (splitByYear) {
        line <- paste(line, "by year")
    }
    if (splitByGender) {
        line <- paste(line, "by gender")
    }
    writeLines(line)
    sql <- SqlRender::loadRenderTranslateSql("GetDenominator.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             study_start_date = studyStartDate,
                                             study_end_date = studyEndDate,
                                             split_by_age_group = splitByAgeGroup,
                                             split_by_year = splitByYear,
                                             split_by_gender = splitByGender)
    denominator <- DatabaseConnector::querySql(conn, sql)
    names(denominator) <- SqlRender::snakeCaseToCamelCase(names(denominator))
    write.csv(denominator, file = fileName, row.names = FALSE)
}

saveNumerator <- function(conn,
                          oracleTempSchema,
                          cdmDatabaseSchema,
                          studyStartDate,
                          studyEndDate,
                          splitByAgeGroup,
                          splitByYear,
                          splitByGender,
                          splitByDrugLevel,
                          cdmVersion,
                          fileName) {
    line <- "Getting numerator"
    if (splitByAgeGroup) {
        line <- paste(line, "by age group")
    }
    if (splitByYear) {
        line <- paste(line, "by year")
    }
    if (splitByGender) {
        line <- paste(line, "by gender")
    }
    if (splitByDrugLevel != "none"){
        line <- paste(line, "at drug level", splitByDrugLevel)
    }
    writeLines(line)
    sql <- SqlRender::loadRenderTranslateSql("BuildNumerator.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             study_start_date = studyStartDate,
                                             study_end_date = studyEndDate,
                                             split_by_age_group = splitByAgeGroup,
                                             split_by_year = splitByYear,
                                             split_by_gender = splitByGender,
                                             split_by_drug_level = splitByDrugLevel,
                                             cdm_version = cdmVersion)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

    sql <- SqlRender::loadRenderTranslateSql("GetNumerator.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema)

    numerator <- DatabaseConnector::querySql(conn, sql)

    sql <- SqlRender::loadRenderTranslateSql("DropNumerator.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema)

    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

    names(numerator) <- SqlRender::snakeCaseToCamelCase(names(numerator))
    write.csv(numerator, file = fileName, row.names = FALSE)
}

dropHelperTables <- function(conn, oracleTempSchema){
    writeLines("Dropping helper tables")
    sql <- SqlRender::loadRenderTranslateSql("DropHelperTables.sql",
                                             "DrugsInPeds",
                                             attr(conn,"dbms"),
                                             oracleTempSchema = oracleTempSchema)
    DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)
}

saveMetaData <- function(fileName){
    info <- Sys.info()
    metaData <- data.frame(rVersion = R.Version()$version.string,
                           sysname = info[["sysname"]],
                           user = info[["user"]],
                           nodename = info[["nodename"]],
                           time = Sys.time())
    write.csv(metaData, file = fileName, row.names = FALSE)
}

compressAndEncrypt <- function(file){
    pathToPublicKey <- system.file("key",
                             "public.key",
                             package = "DrugsInPeds")
    OhdsiSharing::compressAndEncryptFolder("./", file, pathToPublicKey)
}

#' @title Execute OHDSI Drug Utilization in Children
#'
#' @details
#' This function executes the OHDSI Drug Utilization in Children Study.
#'
#' @return
#' Study results are placed in CSV format files in specified local folder. The CSV files are then compressed and encrypted into
#' a single file called StudyResults.zip.enc.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the \code{\link[DatabaseConnector]{createConnectionDetails}}
#' function in the DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include
#' both the database and schema name, for example 'cdm_data.dbo'.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.
#' @param cdmVersion           Version of the CDM. Can be "4" or "5"
#' @param folder	           (Optional) Name of local file to place results; make sure to use forward slashes (/)
#'
#' @examples \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cdmVersion = "4")
#'
#' email(from = "collaborator@@ohdsi.org",
#'       dataDescription = "CDM4 Simulated Data")
#'
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    oracleTempSchema,
                    cdmVersion = 4,
                    folder = getDefaultStudyFolder(),
                    file = getDefaultStudyFileName()) {
    if (!file.exists(folder)){
        dir.create(folder)
    }
    previousFolder <- setwd(folder)
	on.exit(setwd(previousFolder))

    studyStartDate <- "20090101"
    studyEndDate <- "20131231"
    minDaysPerPerson <- 180

    conn <- DatabaseConnector::connect(connectionDetails)
    if (is.null(conn)) {
        stop("Failed to connect to db server.")
    }
    start <- Sys.time()

    loadHelperTables(conn, oracleTempSchema)

    findPopulationWithData(conn,
                           oracleTempSchema,
                           cdmDatabaseSchema,
                           studyStartDate,
                           studyEndDate,
                           minDaysPerPerson)

    saveDenominator(conn,
                    oracleTempSchema,
                    cdmDatabaseSchema,
                    studyStartDate,
                    studyEndDate,
                    splitByAgeGroup = FALSE,
                    splitByYear = FALSE,
                    splitByGender = FALSE,
                    "Denominator.csv")

    saveDenominator(conn,
                    oracleTempSchema,
                    cdmDatabaseSchema,
                    studyStartDate,
                    studyEndDate,
                    splitByAgeGroup = TRUE,
                    splitByYear = FALSE,
                    splitByGender = FALSE,
                    "DenominatorByAgeGroup.csv")

    saveDenominator(conn,
                    oracleTempSchema,
                    cdmDatabaseSchema,
                    studyStartDate,
                    studyEndDate,
                    splitByAgeGroup = FALSE,
                    splitByYear = TRUE,
                    splitByGender = FALSE,
                    "DenominatorByYear.csv")

    saveDenominator(conn,
                    oracleTempSchema,
                    cdmDatabaseSchema,
                    studyStartDate,
                    studyEndDate,
                    splitByAgeGroup = FALSE,
                    splitByYear = FALSE,
                    splitByGender = TRUE,
                    "DenominatorByGender.csv")

    saveDenominator(conn,
                    oracleTempSchema,
                    cdmDatabaseSchema,
                    "20000101",
                    "20141231",
                    splitByAgeGroup = TRUE,
                    splitByYear = TRUE,
                    splitByGender = FALSE,
                    "DenominatorByAgeGroupByYear.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = FALSE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "none",
                  cdmVersion = cdmVersion,
                  "Numerator.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = TRUE,
                  splitByYear = FALSE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "none",
                  cdmVersion = cdmVersion,
                  "NumeratorByAgeGroup.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = TRUE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "none",
                  cdmVersion = cdmVersion,
                  "NumeratorByYear.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = FALSE,
                  splitByGender = TRUE,
                  splitByDrugLevel = "none",
                  cdmVersion = cdmVersion,
                  "NumeratorByGender.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = FALSE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "atc3",
                  cdmVersion = cdmVersion,
                  "NumeratorByAtc3.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = FALSE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "ingredient",
                  cdmVersion = cdmVersion,
                  "NumeratorByIngredient.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = TRUE,
                  splitByYear = FALSE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "atc1",
                  cdmVersion = cdmVersion,
                  "NumeratorByAgeGroupByAtc1.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  studyStartDate,
                  studyEndDate,
                  splitByAgeGroup = FALSE,
                  splitByYear = FALSE,
                  splitByGender = TRUE,
                  splitByDrugLevel = "atc1",
                  cdmVersion = cdmVersion,
                  "NumeratorByGenderByAtc1.csv")

    saveNumerator(conn,
                  oracleTempSchema,
                  cdmDatabaseSchema,
                  "20000101",
                  "20141231",
                  splitByAgeGroup = TRUE,
                  splitByYear = TRUE,
                  splitByGender = FALSE,
                  splitByDrugLevel = "atc1",
                  cdmVersion = cdmVersion,
                  "NumeratorByAgeGroupByYearByAtc1.csv")

    dropHelperTables(conn, oracleTempSchema)

    DBI::dbDisconnect(conn)

    saveMetaData("MetaData.csv")

    compressAndEncrypt(file)

    # Report time
    delta <- Sys.time() - start
    writeLines(paste("Analysis took", signif(delta, 3), attr(delta, "units")))
}

# Package must provide a default gmail address to receive result files
#' @export
getDestinationAddress <- function() { return("schuemie@ohdsi.org") }

# Package must provide a default result folder name
#' @export
getDefaultStudyFolder <- function() { return("DrugsInPeds") }

# Package must provide a default result file name
#' @export
getDefaultStudyFileName <- function() { return("StudyResults.zip.enc") }

# Packge must provide default email subject
#' @export
getDefaultStudyEmailSubject <- function() { return("OHDSI Drug Utilization in Children study results") }
