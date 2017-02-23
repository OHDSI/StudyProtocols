# Copyright 2016 Observational Health Data Sciences and Informatics
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

createTable1 <- function() {
    denominator <- read.csv("DenominatorByAgeGroup.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByAgeGroup.csv", stringsAsFactors = FALSE)
    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) == 0){
        numeratorInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                         conceptName = rep("drug", nrow(numerator)),
                                         prescriptionCount = rep(0, nrow(numerator)),
                                         personCount = rep(0, nrow(numerator)),
                                         ageGroup = numerator$ageGroup)
    }
    names(numeratorInpatient)[names(numeratorInpatient) == "prescriptionCount"] <- "PrescriptionsInpatient"
    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) == 0){
        numeratorNotInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                            conceptName = rep("drug", nrow(numerator)),
                                            prescriptionCount = rep(0, nrow(numerator)),
                                            personCount = rep(0, nrow(numerator)),
                                            ageGroup = numerator$ageGroup)
    }
    names(numeratorNotInpatient)[names(numeratorNotInpatient) == "prescriptionCount"] <- "PrescriptionsNotInpatient"
    data <- merge(denominator, numeratorInpatient[,c("ageGroup","PrescriptionsInpatient")])
    data <- merge(data, numeratorNotInpatient[,c("ageGroup","PrescriptionsNotInpatient")])
    data <- data[order(data$ageGroup),]
    table1 <- data.frame(Category = data$ageGroup,
                         NoOfChildren = data$persons,
                         NoOrPersonYears = round(data$days / 365.25),
                         PrescriptionsInpatient = data$PrescriptionsInpatient,
                         PrescriptionsNotInpatient = data$PrescriptionsNotInpatient,
                         stringsAsFactors = FALSE)


    denominator <- read.csv("DenominatorByGender.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByGender.csv", stringsAsFactors = FALSE)
    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) == 0){
        numeratorInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                         conceptName = rep("drug", nrow(numerator)),
                                         prescriptionCount = rep(0, nrow(numerator)),
                                         personCount = rep(0, nrow(numerator)),
                                         genderConceptId = numerator$genderConceptId)
    }
    names(numeratorInpatient)[names(numeratorInpatient) == "prescriptionCount"] <- "PrescriptionsInpatient"
    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) == 0){
        numeratorNotInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                            conceptName = rep("drug", nrow(numerator)),
                                            prescriptionCount = rep(0, nrow(numerator)),
                                            personCount = rep(0, nrow(numerator)),
                                            genderConceptId = numerator$genderConceptId)
    }
    names(numeratorNotInpatient)[names(numeratorNotInpatient) == "prescriptionCount"] <- "PrescriptionsNotInpatient"
    data <- merge(denominator, numeratorInpatient[,c("genderConceptId","PrescriptionsInpatient")])
    data <- merge(data, numeratorNotInpatient[,c("genderConceptId","PrescriptionsNotInpatient")])
    data$gender <- "Male"
    data$gender[data$genderConceptId == 8532] <- "Female"
    data <- data[order(data$gender),]
    table1 <- rbind(table1, data.frame(Category = data$gender,
                                       NoOfChildren = data$persons,
                                       NoOrPersonYears = round(data$days / 365.25),
                                       PrescriptionsInpatient = data$PrescriptionsInpatient,
                                       PrescriptionsNotInpatient = data$PrescriptionsNotInpatient,
                                       stringsAsFactors = FALSE))

    denominator <- read.csv("DenominatorByYear.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByYear.csv", stringsAsFactors = FALSE)
    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) == 0){
        numeratorInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                         conceptName = rep("drug", nrow(numerator)),
                                         prescriptionCount = rep(0, nrow(numerator)),
                                         personCount = rep(0, nrow(numerator)),
                                         calendarYear = numerator$calendarYear)
    }
    names(numeratorInpatient)[names(numeratorInpatient) == "prescriptionCount"] <- "PrescriptionsInpatient"
    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) == 0){
        numeratorNotInpatient <- data.frame(conceptId = rep(0, nrow(numerator)),
                                            conceptName = rep("drug", nrow(numerator)),
                                            prescriptionCount = rep(0, nrow(numerator)),
                                            personCount = rep(0, nrow(numerator)),
                                            calendarYear = numerator$calendarYear)
    }
    names(numeratorNotInpatient)[names(numeratorNotInpatient) == "prescriptionCount"] <- "PrescriptionsNotInpatient"
    data <- merge(denominator, numeratorInpatient[,c("calendarYear","PrescriptionsInpatient")])
    data <- merge(data, numeratorNotInpatient[,c("calendarYear","PrescriptionsNotInpatient")])
    data <- data[order(data$calendarYear),]
    table1 <- rbind(table1, data.frame(Category = data$calendarYear,
                                       NoOfChildren = data$persons,
                                       NoOrPersonYears = round(data$days / 365.25),
                                       PrescriptionsInpatient = data$PrescriptionsInpatient,
                                       PrescriptionsNotInpatient = data$PrescriptionsNotInpatient,
                                       stringsAsFactors = FALSE))


    denominator <- read.csv("Denominator.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("Numerator.csv", stringsAsFactors = FALSE)
    data <- denominator
    if (any(numerator$inpatient == 1)) {
        data$PrescriptionsInpatient <- numerator$prescriptionCount[numerator$inpatient == 1]
    } else {
        data$PrescriptionsInpatient <- 0
    }
    if (any(numerator$inpatient == 0)) {
        data$PrescriptionsNotInpatient <- numerator$prescriptionCount[numerator$inpatient == 0]
    } else {
        data$PrescriptionsNotInpatient <- 0
    }
    table1 <- rbind(table1, data.frame(Category = "Total",
                                       NoOfChildren = data$persons,
                                       NoOrPersonYears = round(data$days / 365.25),
                                       PrescriptionsInpatient = data$PrescriptionsInpatient,
                                       PrescriptionsNotInpatient = data$PrescriptionsNotInpatient,
                                       stringsAsFactors = FALSE))
    write.csv(table1, "Table1.csv", row.names = FALSE)
}

createTable2 <- function(conn, cdmDatabaseSchema, denominatorType) {
    denominator <- read.csv("Denominator.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByClass.csv", stringsAsFactors = FALSE)
    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) != 0) {
        data <- numeratorInpatient
        data <- data[order(data$conceptName),]
        if (denominatorType == "persons") {
            table2a <- data.frame(Class = data$conceptName,
                                  UserPrevalence = round(data$personCount/(denominator$persons / 1000), digits = 2),
                                  PrescriptionPrevalence = round(data$prescriptionCount/(denominator$persons / 1000), digits = 2))
        } else {
            table2a <- data.frame(Class = data$conceptName,
                                  UserPrevalence = round(data$personCount/(denominator$days / 365.25 / 1000), digits = 2),
                                  PrescriptionPrevalence = round(data$prescriptionCount/(denominator$days / 365.25 / 1000), digits = 2))
        }
        write.csv(table2a, "Table2a.csv", row.names = FALSE)
    }
    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) != 0) {
        data <- numeratorNotInpatient
        data <- data[order(data$conceptName),]
        if (denominatorType == "persons") {
            table2b <- data.frame(Class = data$conceptName,
                                  UserPrevalence = round(data$personCount/(denominator$persons / 1000), digits = 2),
                                  PrescriptionPrevalence = round(data$prescriptionCount/(denominator$days / 365.25 / 1000), digits = 2))
        } else {
            table2b <- data.frame(Class = data$conceptName,
                                  UserPrevalence = round(data$personCount/(denominator$persons / 1000), digits = 2),
                                  PrescriptionPrevalence = round(data$prescriptionCount/(denominator$days / 365.25 / 1000), digits = 2))
        }

        write.csv(table2b, "Table2b.csv", row.names = FALSE)
    }
}

createTable3 <- function(denominatorType, drugsPerClass = 5) {
    denominator <- read.csv("Denominator.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByIngredient.csv", stringsAsFactors = FALSE)

    pathToCsv <- system.file("csv",
                             "CustomClassification.csv",
                             package = "DrugsInPeds")
    classes <- read.csv(pathToCsv, as.is = TRUE)
    names(classes) <- SqlRender::snakeCaseToCamelCase(names(classes))
    classes <- classes[, c("conceptId","classId")]
    numerator <- merge(numerator, classes)

    temp <- list()
    for (inpatient in c(0,1)) {
        for (classId in unique(classes$classId)){
            subset <- numerator[numerator$classId == classId & numerator$inpatient == inpatient,]
            subset <- subset[order(-subset$personCount), ]
            subset <- subset[1:min(drugsPerClass,nrow(subset)), ]
            temp[[length(temp)+1]] <- subset
        }
    }
    numerator <- do.call(rbind, temp)
    numerator <- numerator[order(numerator$classId, -numerator$personCount),]

    data <- numerator[numerator$inpatient == 1,]

    if (denominatorType == "persons") {
        table3a <- data.frame(Class = data$classId,
                              Drug = data$conceptName,
                              UserPrevalence = round(data$personCount/(denominator$persons / 1000), digits = 2))
    } else {
        table3a <- data.frame(Class = data$classId,
                              Drug = data$conceptName,
                              UserPrevalence = round(data$personCount/(denominator$days / 365.25 / 1000), digits = 2))
    }

    data <- numerator[numerator$inpatient == 0,]
    if (denominatorType == "persons") {
        table3b <- data.frame(Class = data$classId,
                              Drug = data$conceptName,
                              UserPrevalence = round(data$personCount/(denominator$persons / 1000), digits = 2))
    } else {
        table3b <- data.frame(Class = data$classId,
                              Drug = data$conceptName,
                              UserPrevalence = round(data$personCount/(denominator$days / 365.25 / 1000), digits = 2))
    }

    write.csv(table3a, "Table3a.csv", row.names = FALSE)
    write.csv(table3b, "Table3b.csv", row.names = FALSE)
}

createFigure1 <- function(denominatorType) {
    denominator <- read.csv("DenominatorByAgeGroup.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByAgeGroupByClass.csv", stringsAsFactors = FALSE)

    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) != 0){
        data <- merge(denominator, numeratorInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
        ggplot2::ggplot(data, ggplot2::aes(x = ageGroup, y = Prevalence)) +
            ggplot2::geom_bar(stat = "identity") +
            ggplot2::facet_grid(.~ conceptName) +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.x = ggplot2::element_text(angle=-90))
        ggplot2::ggsave("Figure1a.png", width = 9, height = 9, dpi= 200)
    }

    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) != 0){
        data <- merge(denominator, numeratorNotInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
        ggplot2::ggplot(data, ggplot2::aes(x = ageGroup, y = Prevalence)) +
            ggplot2::geom_bar(stat = "identity") +
            ggplot2::facet_grid(.~ conceptName) +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.x = ggplot2::element_text(angle=-90))
        ggplot2::ggsave("Figure1b.png", width = 9, height = 9, dpi= 200)
    }
}

createFigure2 <- function(denominatorType) {
    denominator <- read.csv("DenominatorByGender.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByGenderByClass.csv", stringsAsFactors = FALSE)

    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) != 0){
        data <- merge(denominator, numeratorInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$Gender <- "Male"
        data$Gender[data$genderConceptId == 8532] <- "Female"
        ggplot2::ggplot(data, ggplot2::aes(x = Gender, y = Prevalence)) +
            ggplot2::geom_bar(stat = "identity") +
            ggplot2::facet_grid(.~ conceptName) +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.x = ggplot2::element_text(angle=-90))
        ggplot2::ggsave("Figure2a.png", width = 9, height = 9, dpi= 200)
    }
    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) != 0){
        data <- merge(denominator, numeratorNotInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$Gender <- "Male"
        data$Gender[data$genderConceptId == 8532] <- "Female"
        ggplot2::ggplot(data, ggplot2::aes(x = Gender, y = Prevalence)) +
            ggplot2::geom_bar(stat = "identity") +
            ggplot2::facet_grid(.~ conceptName) +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.x = ggplot2::element_text(angle=-90))
        ggplot2::ggsave("Figure2b.png", width = 9, height = 9, dpi= 200)
    }
}

createFigure3 <- function(denominatorType) {
    denominator <- read.csv("DenominatorByAgeGroupByYear.csv", stringsAsFactors = FALSE)
    numerator <- read.csv("NumeratorByAgeGroupByYearByClass.csv", stringsAsFactors = FALSE)

    numeratorInpatient <- numerator[numerator$inpatient == 1,]
    if (nrow(numeratorInpatient) != 0){
        data <- merge(denominator, numeratorInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
        ggplot2::ggplot(data, ggplot2::aes(x = calendarYear, y = Prevalence)) +
            ggplot2::geom_line() +
            ggplot2::facet_grid(conceptName ~ ageGroup, scales = "free") +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.y = ggplot2::element_text(angle=0))
        ggplot2::ggsave("Figure3a.png", width = 10, height = 8, dpi= 200)
    }

    numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
    if (nrow(numeratorNotInpatient) != 0){
        data <- merge(denominator, numeratorNotInpatient)
        if (denominatorType == "persons") {
            data$Prevalence <- data$personCount/(data$persons / 1000)
        } else {
            data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
        }
        data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
        ggplot2::ggplot(data, ggplot2::aes(x = calendarYear, y = Prevalence)) +
            ggplot2::geom_line() +
            ggplot2::facet_grid(conceptName ~ ageGroup, scales = "free") +
            ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                           strip.text.y = ggplot2::element_text(angle=0))
        ggplot2::ggsave("Figure3b.png", width = 10, height = 8, dpi= 200)
    }
}

#' @title Create figures and tables for the paper
#'
#' @details
#' This function creates the figures and tables specified in the protocol, based on the data files generated using the \code{\link{execute}} function.
#'
#' Note that this function requires access to a CDM database to query the vocabulary.
#'
#' @return
#' Creates CSV and PNG files in the specified folder.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the \code{\link[DatabaseConnector]{createConnectionDetails}}
#' function in the DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides. Note that for SQL Server, this should include
#' both the database and schema name, for example 'cdm_data.dbo'.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write priviliges for storing temporary tables.
#' @param cdmVersion           Version of the CDM. Can be "4" or "5"
#' @param folder	           (Optional) Name of local file to place results; make sure to use forward slashes (/)
#'
#' @export
createFiguresAndTables <- function(connectionDetails,
                                   cdmDatabaseSchema,
                                   oracleTempSchema = cdmDatabaseSchema,
                                   cdmVersion,
                                   folder){
    # Study parameters:
    denominatorType <- "persons" # denominatorType can be "persons" or "person time"

    writeLines("Creating tables and figures")
    setwd(folder)
    conn <- DatabaseConnector::connect(connectionDetails)
    createTable1()
    createTable2(conn = conn,
                 cdmDatabaseSchema = cdmDatabaseSchema,
                 denominatorType = denominatorType)
    createTable3(denominatorType = denominatorType)
    createFigure1(denominatorType = denominatorType)
    createFigure2(denominatorType = denominatorType)
    createFigure3(denominatorType = denominatorType)
    DBI::dbDisconnect(conn)
    writeLines("Done")
}
