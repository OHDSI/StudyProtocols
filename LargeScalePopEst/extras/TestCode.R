# @file TestCode.R
#
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

library(LargeScalePopEst)
options('fftempdir' = 'R:/fftemp')
#options('fftempdir' = 'S:/fftemp')

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_MDCD_V464.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_mdcd"
exposureCohortSummaryTable <- "mschuemie_depression_exposure_summary_mdcd"
port <- 17001
workFolder <- "R:/PopEstDepression_Mdcd"
#workFolder <- "S:/PopEstDepression_Mdcd"
maxCores <- 15

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_CCAE_V466.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_ccae"
exposureCohortSummaryTable <- "mschuemie_t2dm_exposure_summary_ccae"
port <- 17001
workFolder <- "R:/PopEstDepression_Ccae"
maxCores <- 30

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_MDCR_V467.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_mdcr"
exposureCohortSummaryTable <- "mschuemie_t2dm_exposure_summary_mdcr"
port <- 17001
workFolder <- "r:/PopEstDepression_Mdcr"
maxCores <- 20

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "cdm_optum_extended_ses_v469.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_optum"
exposureCohortSummaryTable <- "mschuemie_t2dm_exposure_summary_optum"
port <- 17001
workFolder <- "r:/PopEstDepression_Optum"
maxCores <- 20

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        oracleTempSchema = oracleTempSchema,
        workDatabaseSchema = workDatabaseSchema,
        studyCohortTable = studyCohortTable,
        exposureCohortSummaryTable = exposureCohortSummaryTable,
        workFolder = workFolder,
        maxCores = maxCores,
        createCohorts = FALSE,
        fetchAllDataFromServer = FALSE,
        injectSignals = FALSE,
        generateAllCohortMethodDataObjects = TRUE,
        runCohortMethod = TRUE)

analysePsDistributions(workFolder)

plotControlDistributions(workFolder)

calibrateEstimatesAndPvalues(workFolder)

createCohorts(connectionDetails = connectionDetails,
              cdmDatabaseSchema = cdmDatabaseSchema,
              oracleTempSchema = oracleTempSchema,
              workDatabaseSchema = workDatabaseSchema,
              studyCohortTable = studyCohortTable,
              exposureCohortSummaryTable = exposureCohortSummaryTable,
              workFolder = workFolder)

filterByExposureCohortsSize(workFolder = workFolder)

fetchAllDataFromServer(connectionDetails = connectionDetails,
                       cdmDatabaseSchema = cdmDatabaseSchema,
                       oracleTempSchema = oracleTempSchema,
                       workDatabaseSchema = workDatabaseSchema,
                       studyCohortTable = studyCohortTable,
                       workFolder = workFolder)

injectSignals(connectionDetails = connectionDetails,
              cdmDatabaseSchema = cdmDatabaseSchema,
              workDatabaseSchema = workDatabaseSchema,
              studyCohortTable = studyCohortTable,
              oracleTempSchema = oracleTempSchema,
              workFolder = workFolder,
              maxCores = maxCores)

generateAllCohortMethodDataObjects(workFolder)

runCohortMethod(workFolder, maxCores = maxCores)

analysePsDistributions(workFolder)

CohortMethod::plotPs(ps)


eq <- read.csv(file.path(figuresAndTablesFolder, "Equipoise.csv"), stringsAsFactors = FALSE)
names <- unique(c(eq$cohortName1, eq$cohortName2))
names <- names[order(names)]
m <- combn(names, 2)
m <- data.frame(cohortName1 = m[1, ],
                cohortName2 = m[2, ])
m <- merge(m, eq[, c("cohortName1", "cohortName2", "equipoise")], all.x = TRUE)


m$equipoise[is.na(m$equipoise)] <- 0
m <- m[order(m$cohortName1, m$cohortName2), ]
d1 <- 1-m$equipoise
attr(d1, "Size") <- length(names)
attr(d1, "Labels") <- names
attr(d1, "Diag") <- FALSE
attr(d1, "Upper") <- TRUE
attr(d1, "method") <- "binary"
class(d1) <- "dist"

hc <- hclust(d1)
png("s:/temp/dendo.png")
plot(hc)
dev.off()
