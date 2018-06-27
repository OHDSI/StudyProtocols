# @file PaperExecutionCode.R
#
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

library(EvaluatingCaseControl)
options(fftempdir = "r:/fftemp")

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- Sys.getenv("PDW_SERVER")
port <- Sys.getenv("PDW_PORT")
maxCores <- 30

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)


# CCAE settings --------------------------------------------------
cdmDatabaseSchema <- "cdm_truven_ccae_v697.dbo"
oracleTempSchema <- NULL
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemie_case_control_ap_ccae"
outputFolder <- "r:/EvaluatingCaseControl_ccae"

# Optum settings --------------------------------------------------
cdmDatabaseSchema <- "cdm_optum_extended_ses_v694.dbo"
oracleTempSchema <- NULL
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemie_case_control_ap_optum"
outputFolder <- "r:/EvaluatingCaseControl_optum"

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        oracleTempSchema = oracleTempSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        outputFolder = outputFolder,
        createCohorts = TRUE,
        synthesizePositiveControls = TRUE,
        runAnalyses = TRUE,
        createFiguresAndTables = TRUE,
        maxCores = maxCores)
