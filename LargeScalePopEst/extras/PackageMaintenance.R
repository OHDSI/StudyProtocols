# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of LargeScalePopEst
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
OhdsiRTools::checkUsagePackage("LargeScalePopEst")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual
shell("rm extras//LargeScalePopEst.pdf")
shell("R CMD Rd2pdf ./ --output=extras/LargeScalePopEst.pdf")

# Import outcome definitions
pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)
for (i in 1:nrow(outcomes)) {
  writeLines(paste0("Inserting HOI: ", outcomes$name[i]))
  OhdsiRTools::insertCohortDefinitionInPackage(outcomes$cohortDefinitionId[i], outcomes$name[i])
}

# Create analysis details
createAnalysesDetails("inst/settings/")

# Store environment in which the study was executed
OhdsiRTools::insertEnvironmentSnapshotInPackage("LargeScalePopEst")
