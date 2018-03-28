# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
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

# Format and check code ---------------------------------------------------
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("AhasHfBkleAmputation")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual -----------------------------------------------------------
shell("rm extras/AhasHfBkleAmputation.pdf")
shell("R CMD Rd2pdf ./ --output=extras/AhasHfBkleAmputation.pdf")

# Insert cohort definitions from ATLAS into package -----------------------
OhdsiRTools::insertCohortDefinitionSetInPackage(fileName = "CohortsToCreateWithCensoring.csv",
                                                baseUrl = Sys.getenv("baseUrl"),
                                                insertTableSql = TRUE,
                                                insertCohortCreationR = TRUE,
                                                generateStats = FALSE,
                                                packageName = "AhasHfBkleAmputation")

# Hack: get names and excluded concepts for comparisons from ATLAS ----------
tcos <- read.csv("inst/settings/TcosOfInterestWithCensoring.csv", stringsAsFactors = FALSE)
cohorts <- read.csv("inst/settings/CohortsToCreateWithCensoring.csv", stringsAsFactors = FALSE)
tcos <- merge(tcos, data.frame(targetId = cohorts$cohortId,
                               targetName = cohorts$fullName))
tcos <- merge(tcos, data.frame(comparatorId = cohorts$cohortId,
                               comparatorName = cohorts$fullName))
getPrimaryConcepts <- function(fileName) {
  json <- readChar(fileName, file.info(fileName)$size)
  x <- RJSONIO::fromJSON(json)
  id <- x$PrimaryCriteria$CriteriaList[[1]]$DrugExposure$CodesetId
  for (i in 1:length(x$ConceptSets))
    if (x$ConceptSets[[i]]$id == id) {
      conceptIds <- c()
      for (item in x$ConceptSets[[i]]$expression$items)
        conceptIds <- c(conceptIds, item$concept$CONCEPT_ID)
      return(conceptIds)
    }
  stop("No primary concept found")
}
for (i in 1:nrow(tcos)) {
  targetName <- paste0("inst/cohorts/", cohorts$name[cohorts$cohortId == tcos$targetId[i]], ".json")
  comparatorName <- paste0("inst/cohorts/", cohorts$name[cohorts$cohortId == tcos$comparatorId[i]], ".json")
  excludeIds <- c()
  excludeIds <- c(excludeIds, getPrimaryConcepts(targetName))
  excludeIds <- c(excludeIds, getPrimaryConcepts(comparatorName))
  tcos$excludedCovariateConceptIds[i] <- paste(excludeIds, collapse = ";")
}
write.csv(tcos, "inst/settings/TcosOfInterestWithCensoring.csv", row.names = FALSE)

# Create exposure cohorts without censoring by modifying cohorts with censoring ----------------
baseUrl <- Sys.getenv("baseUrl")
tcos <- read.csv("inst/settings/TcosOfInterestWithCensoring.csv", stringsAsFactors = FALSE)
cohorts <- read.csv("inst/settings/CohortsToCreateWithCensoring.csv", stringsAsFactors = FALSE)
exposureCohortIds <- unique(c(tcos$targetId, tcos$comparatorId))
newCohorts <- list(cohorts)
for (exposureCohortId in exposureCohortIds) {
  cohort <- cohorts[cohorts$cohortId == exposureCohortId, ]
  writeLines(paste("Dropping censoring criteria for", cohort$fullName))
  cohortDef <- RJSONIO::fromJSON(file.path("inst", "cohorts", paste0(cohort$name, ".json")))

  cohort$cohortId <- exposureCohortId + 10000
  cohort$atlasId <- NA
  cohort$name <- paste0(cohort$name, "NoCensor")
  cohort$fullName <- paste0(cohort$fullName, ", no censoring")
  newCohorts[[length(newCohorts) + 1]] <- cohort 
  
  # Drop censoring criteria
  cohortDef$CensoringCriteria <- NULL
  fileConn <- file(file.path("inst/cohorts", paste(cohort$name, "json", sep = ".")))
  writeLines(RJSONIO::toJSON(cohortDef), fileConn)
  close(fileConn)
  jsonBody <- RJSONIO::toJSON(list(expression = cohortDef), digits = 23)
  httpheader <- c(Accept = "application/json; charset=UTF-8", `Content-Type` = "application/json")
  url <- paste(baseUrl, "cohortdefinition", "sql", sep = "/")
  cohortSqlJson <- httr::POST(url, body = jsonBody, config = httr::add_headers(httpheader))
  cohortSqlJson <- httr::content(cohortSqlJson)
  sql <- cohortSqlJson$templateSql
  fileConn <- file(file.path("inst/sql/sql_server", paste(cohort$name, "sql", sep = ".")))
  writeLines(sql, fileConn)
  close(fileConn)
}
cohorts <- do.call(rbind, newCohorts)
write.csv(cohorts, "inst/settings/CohortsToCreate.csv", row.names = FALSE)
newTcos <- tcos
newTcos$targetId <- 10000 + newTcos$targetId
newTcos$comparatorId <- 10000 + newTcos$comparatorId
newTcos$targetName <- paste0(newTcos$targetName, ", no censoring")
newTcos$comparatorName <- paste0(newTcos$comparatorName, ", no censoring")
newTcos$censorAtSwitch <- FALSE
tcos$censorAtSwitch <- TRUE
tcos <- rbind(tcos, newTcos)
write.csv(tcos, "inst/settings/TcosOfInterest.csv", row.names = FALSE)

# Create analysis details -------------------------------------------------
source("R/CreateStudyAnalysisDetails.R")
createAnalysesDetails("inst/settings/")

# Store environment in which the study was executed -----------------------
OhdsiRTools::insertEnvironmentSnapshotInPackage("AhasHfBkleAmputation")

