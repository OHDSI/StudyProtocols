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

library(PopEstT2Dm)
options('fftempdir' = 's:/fftemp')

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_MDCD_V446.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_mdcd"
exposureCohortSummaryTable <- "mschuemie_depression_exposure_summary_mdcd"
port <- 17001
workFolder <- "R:/PopEstT2Dm_Mdcd"

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_CCAE_V418.dbo"
oracleTempSchema <- NULL
workDatabaseSchema <- "scratch.dbo"
studyCohortTable <- "mschuemie_depression_cohorts_ccae"
exposureCohortSummaryTable <- "mschuemie_t2dm_exposure_summary_ccae"
port <- 17001
workFolder <- "R:/PopEstT2Dm_Ccae"

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

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

generateAllCohortMethodDataObjects(workFolder)

fitAllPsModels(workFolder, fitThreads = 6, cvThreads = 5)

plotAllPsDistributions(workFolder)

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
