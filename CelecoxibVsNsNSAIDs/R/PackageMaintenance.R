# Copyright 2015 Observational Health Data Sciences and Informatics
#
# This file is part of CelecoxibVsNsNSAIDs
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

.formatAndCheckCode <- function() {
  OhdsiRTools::formatRFolder()
  OhdsiRTools::checkUsagePackage("CelecoxibVsNsNSAIDs")
  OhdsiRTools::ohdsiLintrFolder()
}

.createManualAndVignettes <- function() {
  shell("rm extras/CelecoxibVsNsNSAIDs.pdf")
  shell("R CMD Rd2pdf ./ --output=extras/CelecoxibVsNsNSAIDs.pdf")
}

.insertCohortDefinitions <- function() {
    OhdsiRTools::insertCirceDefinitionInPackage(293, "Treatment")
    OhdsiRTools::insertCirceDefinitionInPackage(484, "Comparator")
    OhdsiRTools::insertCirceDefinitionInPackage(280, "MyocardialInfarction")
    OhdsiRTools::insertCirceDefinitionInPackage(289, "MiAndIschemicDeath")
    OhdsiRTools::insertCirceDefinitionInPackage(288, "GiHemorrhage")
    OhdsiRTools::insertCirceDefinitionInPackage(282, "Angioedema")
    OhdsiRTools::insertCirceDefinitionInPackage(417, "AcuteRenalFailure")
    OhdsiRTools::insertCirceDefinitionInPackage(416, "DrugInducedLiverInjury")
    OhdsiRTools::insertCirceDefinitionInPackage(418, "HeartFailure")
}

