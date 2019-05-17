# Copyright 2018 Observational Health Data Sciences and Informatics
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
OhdsiRTools::checkUsagePackage("AHAsAcutePancreatitis")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual -----------------------------------------------------------
shell("rm extras/AHAsAcutePancreatitis")
shell("R CMD Rd2pdf ./ --output=extras/AHAsAcutePancreatitis")

baseUrl <- ""

# Insert cohort definitions from ATLAS into package -----------------------
OhdsiRTools::insertCohortDefinitionSetInPackage(fileName = "ConfigCohortsToCreate.csv",
                                                baseUrl = baseUrl,
                                                insertTableSql = TRUE,
                                                insertCohortCreationR = TRUE,
                                                generateStats = FALSE,
                                                packageName = "AHAsAcutePancreatitis")



# Create exposure cohorts without censoring by modifying cohorts with censoring ----------------
tcos <- read.csv("inst/settings/ConfigTcosOfInterest.csv", stringsAsFactors = FALSE)
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

# add the no censor cohorts
cohorts <- do.call(rbind, newCohorts)

# add censor cohorts
newTcos <- tcos
newTcos$targetId <- 10000 + newTcos$targetId
newTcos$comparatorId <- 10000 + newTcos$comparatorId
newTcos$targetName <- paste0(newTcos$targetName, ", no censoring")
newTcos$comparatorName <- paste0(newTcos$comparatorName, ", no censoring")
newTcos$censorAtSwitch <- FALSE
tcos$censorAtSwitch <- TRUE
tcos <- rbind(tcos, newTcos)

# create no cana entries but the cohorts will be created by a sql script
exposureCohortIds <- unique(c(tcos$targetId, tcos$comparatorId))
newCohorts <- list(cohorts)
for (exposureCohortId in exposureCohortIds) {
  cohort <- cohorts[cohorts$cohortId == exposureCohortId, ]
  noCanaCohort <- cohort
  noCanaCohort$cohortId <- exposureCohortId + 100000
  noCanaCohort$atlasId <- NA
  noCanaCohort$name <- paste0(cohort$name, "NoCana")
  noCanaCohort$fullName <- paste0(cohort$fullName, ", no cana")
  newCohorts[[length(newCohorts) + 1]] <- noCanaCohort
}

cohorts <- do.call(rbind, newCohorts)
write.csv(cohorts, "inst/settings/CohortsToCreate.csv", row.names = FALSE)

# add cana restricted cohorts
newTcos <- tcos
newTcos$targetId <- 100000 + newTcos$targetId
newTcos$comparatorId <- 100000 + newTcos$comparatorId
newTcos$targetName <- paste0(newTcos$targetName, ", no cana")
newTcos$comparatorName <- paste0(newTcos$comparatorName, ", no cana")
newTcos$canaRestricted <- TRUE
tcos$canaRestricted <- FALSE
newTcos[which(newTcos$targetId==106492),]$targetName <- 'Canagliflozin new users'
newTcos[which(newTcos$targetId==106492),]$targetId <- 6492
newTcos[which(newTcos$targetId==116492),]$targetName <- 'Canagliflozin new users, no censoring'
newTcos[which(newTcos$targetId==116492),]$targetId <- 16492
tcos <- rbind(tcos, newTcos)

write.csv(tcos, "inst/settings/TcosOfInterest.csv", row.names = FALSE)

# Create analysis details -------------------------------------------------
source("R/CreateStudyAnalysisDetails.R")
createAnalysesDetails("inst/settings/")

# Store environment in which the study was executed -----------------------
OhdsiRTools::insertEnvironmentSnapshotInPackage("AHAsAcutePancreatitis")

# low population counts were identified by the cohort counts and removed to prevent package failure during execution due to insufficient sample.
removeLowPopulationTcos <- function() {
  tcos <- read.csv("inst/settings/TcosOfInterest.csv", stringsAsFactors = FALSE)
  tcos <- tcos[! tcos$comparatorId %in% c(6519,6517,106517,116517,16517,106519,16519,116519,6518,116518,16518,106518),]
  write.csv(tcos, "inst/settings/TcosOfInterest.csv", row.names = FALSE)  
}


