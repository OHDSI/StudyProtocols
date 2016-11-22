# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of CiCalibration
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

# Format and check code
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("CiCalibration")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual and vignette
shell("CiCalibration.pdf")
shell("R CMD Rd2pdf ./ --output=extras/CiCalibration.pdf")

# Insert cohort definitions into package
pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "CiCalibration")
cohortsToCreate <- read.csv(pathToCsv)
for (i in 1:nrow(cohortsToCreate)) {
    writeLines(paste("Inserting cohort:", cohortsToCreate$name[i]))
    OhdsiRTools::insertCirceDefinitionInPackage(cohortsToCreate$atlasId[i], cohortsToCreate$name[i])
}


# Create analysis details
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = "JRDUSAPSCTL01",
                                                                user = NULL,
                                                                password = NULL,
                                                                port = 17001)
cdmDatabaseSchema <- "cdm_truven_ccae_v483.dbo"
createAnalysesDetails(connectionDetails, cdmDatabaseSchema, "inst/settings/")

