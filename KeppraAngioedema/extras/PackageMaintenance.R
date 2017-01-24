# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of KeppraAngioedema
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

# Format and check code:
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("KeppraAngioedema")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual and vignettes:
shell("rm extras/KeppraAngioedema.pdf")
shell("R CMD Rd2pdf ./ --output=extras/KeppraAngioedema.pdf")

# Insert cohort definitions from Circe into package:
OhdsiRTools::insertCirceDefinitionInPackage(2189, "Treatment")
OhdsiRTools::insertCirceDefinitionInPackage(2191, "Comparator")
OhdsiRTools::insertCirceDefinitionInPackage(2193, "Angioedema")

# Create analysis details
createAnalysesDetails("inst/settings/")

# Get negative control names and exclusion concept IDs
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- "JRDUSAPSCTL01"
port <- 17001
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
sql <- "SELECT concept_id, concept_name FROM cdm_truven_mdcd.dbo.concept WHERE concept_id IN (75344, 312437, 4324765, 318800, 197684, 437409, 434056, 261880, 380731, 433516, 437833, 319843, 195562, 195588, 432851, 378425, 433440, 43531027, 139099, 79903, 435459, 197320, 433163, 4002650, 197032, 141932, 372409, 137057, 80665, 200588, 316993, 80951, 134453, 133228, 133834, 80217, 442013, 313792, 75576, 314054, 195873, 198199, 134898, 140480, 200528, 193016, 321596, 29735, 138387, 4193869, 73842, 193326, 4205509, 78804, 141663, 376103, 4311499, 136773, 4291005, 440358, 134461, 192367, 261326, 74396, 78786, 374914, 260134, 196162, 253796, 133141, 136937, 192964, 194997, 440328, 258180, 441284, 440448, 80494, 199876, 376415, 317585, 441589, 140949, 432436, 256722, 378160, 373478, 436027, 443344, 192606, 434926, 439080, 29056, 199067, 77650, 440814, 198075, 79072, 317109, 378424) ORDER BY concept_id"
connection <- DatabaseConnector::connect(connectionDetails)
ncNames <- querySql(connection, sql)
dbDisconnect(connection)

writeLines(paste(ncNames$CONCEPT_ID, collapse = ", "))
writeLines(paste0("\"", paste(ncNames$CONCEPT_NAME, collapse = "\", \""), "\""))


sql <- "SELECT descendant_concept_id FROM cdm_truven_mdcd.dbo.concept_ancestor WHERE ancestor_concept_id IN (711584, 740910) ORDER BY descendant_concept_id"
connection <- DatabaseConnector::connect(connectionDetails)
excludeIds <- querySql(connection, sql)
dbDisconnect(connection)

writeLines(paste(excludeIds$DESCENDANT_CONCEPT_ID, collapse = ", "))

# Store environment in which the study was executed
OhdsiRTools::insertEnvironmentSnapshotInPackage("KeppraAngioedema")



