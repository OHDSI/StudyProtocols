# Copyright 2016 Observational Health Data Sciences and Informatics
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

#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    oracleTempSchema,
                    workDatabaseSchema,
                    studyCohortTable,
                    exposureCohortSummaryTable,
                    workFolder,
                    maxCores,
                    createCohorts = TRUE,
                    fetchAllDataFromServer = TRUE,
                    injectSignals = TRUE,
                    generateAllCohortMethodDataObjects = TRUE,
                    runCohortMethod = TRUE) {
    if (createCohorts) {
        createCohorts(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      oracleTempSchema = oracleTempSchema,
                      workDatabaseSchema = workDatabaseSchema,
                      studyCohortTable = studyCohortTable,
                      exposureCohortSummaryTable = exposureCohortSummaryTable,
                      workFolder = workFolder)

        filterByExposureCohortsSize(workFolder = workFolder)
    }
    if (fetchAllDataFromServer) {
        fetchAllDataFromServer(connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               workDatabaseSchema = workDatabaseSchema,
                               studyCohortTable = studyCohortTable,
                               workFolder = workFolder)
    }
    if (injectSignals) {
        injectSignals(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      workDatabaseSchema = workDatabaseSchema,
                      studyCohortTable = studyCohortTable,
                      oracleTempSchema = oracleTempSchema,
                      workFolder = workFolder,
                      maxCores = maxCores)
    }
    if (generateAllCohortMethodDataObjects) {
        generateAllCohortMethodDataObjects(workFolder)
    }
    if (runCohortMethod) {
        runCohortMethod(workFolder, maxCores = maxCores)
    }
}
