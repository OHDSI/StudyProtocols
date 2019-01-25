# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of EvaluatingCaseControl
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

# Format and check code ----
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("EvaluatingCaseControl")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual and vignette ----
shell("EvaluatingCaseControl.pdf")
shell("R CMD Rd2pdf ./ --output=extras/EvaluatingCaseControl.pdf")

# Insert cohort definitions into package ----
OhdsiRTools::insertCohortDefinitionSetInPackage(fileName = "CohortsToCreate.csv",
                                                baseUrl = Sys.getenv("baseUrl"),
                                                insertTableSql = TRUE,
                                                insertCohortCreationR = TRUE,
                                                generateStats = FALSE,
                                                packageName = "EvaluatingCaseControl")

# Create analysis details ----
source("R/CaseControl.R")
createCaseControlAnalysesDetails("inst/settings/")
source("R/CohortMethod.R")
createCohortMethodAnalysesDetails("inst/settings/")
source("R/Sccs.R")
createSccsAnalysesDetails("inst/settings/")

# Store environment in which the study was executed ----
OhdsiRTools::insertEnvironmentSnapshotInPackage("EvaluatingCaseControl")



# Get CohortMethod negative controls from MethodEvaluation package
# x <- readRDS(system.file("ohdsiNegativeControls.rds", package = "MethodEvaluation"))
# x <- x[x$outcomeName %in% c("Inflammatory Bowel Disease", "Acute pancreatitis"), ]
# x$outcomeId[x$outcomeName == "Inflammatory Bowel Disease"] <- 3
# x$outcomeId[x$outcomeName == "Acute pancreatitis"] <- 2
# pathToCsv <- system.file("settings", "NegativeControls.csv", package = "EvaluatingCaseControl")
# allControls <- read.csv(pathToCsv)
# min(x$targetId %in% allControls$targetId)
# min(x$comparatorId %in% allControls$targetId)
# write.csv(x, "inst/settings/NegativeControlsForCm.csv", row.names = FALSE)
