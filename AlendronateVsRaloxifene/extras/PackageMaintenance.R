# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
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
OhdsiRTools::checkUsagePackage("AlendronateVsRaloxifene")
OhdsiRTools::updateCopyrightYearFolder()


# Create manual and vignettes ---------------------------------------------
shell("rm extras/AlendronateVsRaloxifene.pdf")
shell("R CMD Rd2pdf ./ --output=extras/AlendronateVsRaloxifene.pdf")


# Insert cohort definitions from ATLAS into package -----------------------
OhdsiRTools::insertCohortDefinitionSetInPackage(fileName = "CohortsToCreate.csv",
                                                baseUrl = "http://api.ohdsi.org/WebAPI",
                                                insertTableSql = TRUE,
                                                insertCohortCreationR = TRUE,
                                                generateStats = TRUE,
                                                packageName = "AlendronateVsRaloxifene")

# Create analysis details -------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = "JRDUSAPSCTL01",
                                                                user = NULL,
                                                                password = NULL,
                                                                port = 17001)
cdmDatabaseSchema <- "CDM_Truven_MDCD_V521.dbo"
createAnalysesDetails(connectionDetails, cdmDatabaseSchema, "inst/settings/")


# Store environment in which the study was executed -----------------------
OhdsiRTools::insertEnvironmentSnapshotInPackage("AlendronateVsRaloxifene")
