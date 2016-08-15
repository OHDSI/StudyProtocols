# @file PackageMaintenance
#
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

# Format and check code:
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("DrugsInPeds")
OhdsiRTools::updateCopyrightYearFolder()


# Create manual :
shell("rm extras/DrugsInPeds.pdf")
shell("R CMD Rd2pdf ./ --output=extras/DrugsInPeds.pdf")


# Create custom drug classification:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",
                                                                server = "RNDUSRDHIT06.jnj.com")
conn <- DatabaseConnector::connect(connectionDetails)
DatabaseConnector::executeSql(conn, "USE [OMOP_Vocabulary_20160311]")
sql <- SqlRender::readSql("extras/BuildCustomDrugClassification.sql")
DatabaseConnector::executeSql(conn, sql)
classification <- DatabaseConnector::querySql(conn, "SELECT * FROM #my_drug_classification ORDER BY class_id, concept_name")
write.csv(classification, "inst/csv/CustomClassification.csv", row.names = FALSE)
RJDBC::dbDisconnect(conn)



