# Copyright 2018 Observational Health Data Sciences and Informatics
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

cohortTable2 <- paste0(cohortTable, "_noCensor")
noCensorFolder <- file.path(outputFolder, "noCensor")

if (!file.exists(noCensorFolder))
  dir.create(noCensorFolder)

pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "AHAsAcutePancreatitis")
tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
cohortIds <- unique(c(tcosOfInterest$targetId, tcosOfInterest$comparatorId))

pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "AHAsAcutePancreatitis")
cohortsToCreate <- read.csv(pathToCsv, stringsAsFactors = FALSE)
cohortsToCreate <- cohortsToCreate[cohortsToCreate$cohortId %in% cohortIds, ]

# Create new cohort table with modified cohorts -----------------------------------------------
connection <- DatabaseConnector::connect(connectionDetails)
sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CreateCohortTable.sql",
                                         packageName = "AHAsAcutePancreatitis",
                                         dbms = attr(connection, "dbms"),
                                         oracleTempSchema = oracleTempSchema,
                                         cohort_database_schema = cohortDatabaseSchema,
                                         cohort_table = cohortTable2)
DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)

# baseUrl = Sys.getenv("baseUrl")
# definitionId <- cohortsToCreate$atlasId[1]
# cohortId <- cohortsToCreate$cohortId[1]
createModifiedCohortDefinition <- function(definitionId,
                                           cohortId,
                                           baseUrl,
                                           connection,
                                           cdmDatabaseSchema,
                                           oracleTempSchema,
                                           cohortDatabaseSchema,
                                           cohortTable2) {
  ### Fetch JSON object ###
  url <- paste(baseUrl, "cohortdefinition", definitionId, sep = "/")
  json <- httr::GET(url)
  json <- httr::content(json)
  name <- json$name
  parsedExpression <- RJSONIO::fromJSON(json$expression)
  
  # Drop censoring criteria
  parsedExpression$CensoringCriteria <- NULL
  
  ### Fetch SQL by posting JSON object ###
  jsonBody <- RJSONIO::toJSON(list(expression = parsedExpression), digits = 23)
  httpheader <- c(Accept = "application/json; charset=UTF-8", `Content-Type` = "application/json")
  url <- paste(baseUrl, "cohortdefinition", "sql", sep = "/")
  cohortSqlJson <- httr::POST(url, body = jsonBody, config = httr::add_headers(httpheader))
  cohortSqlJson <- httr::content(cohortSqlJson)
  sql <- cohortSqlJson$templateSql
  sql <- SqlRender::renderSql(sql = sql,
                              cdm_database_schema = cdmDatabaseSchema,
                              target_database_schema = cohortDatabaseSchema,
                              target_cohort_table = cohortTable2,
                              target_cohort_id = cohortId)$sql
  sql <- SqlRender::translateSql(sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql)
}

for (i in 1:nrow(cohortsToCreate)) {
  writeLines(paste("Creating modified cohort", cohortsToCreate$name[i]))
  createModifiedCohortDefinition(definitionId = cohortsToCreate$atlasId[i],
                                 cohortId =  cohortsToCreate$cohortId[i],
                                 baseUrl = Sys.getenv("baseUrl"),
                                 connection = connection,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 oracleTempSchema = oracleTempSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable2 = cohortTable2)
}
DatabaseConnector::disconnect(connection)

# Get cohort statistics -----------------------------------------------
connection <- DatabaseConnector::connect(connectionDetails)
templateSql <- "SELECT DATEDIFF(DAY, cohort_start_date, cohort_end_date) AS days FROM @cohort_database_schema.@cohort_table WHERE cohort_definition_id = @cohort_id"
results <- data.frame(cohortId = rep(cohortsToCreate$atlasId, 2),
                      cohortName = rep(cohortsToCreate$fullName, 2),
                      type = rep(c("Modified", "Original"), each = nrow(cohortsToCreate)))
                      
for (i in 1:nrow(results)) {
  if (results$type[i] == "Original") {
    table <- cohortTable
  } else {
    table <- cohortTable2
  }
  sql <- SqlRender::renderSql(sql = templateSql,
                              cohort_database_schema = cohortDatabaseSchema,
                              cohort_table = table,
                              cohort_id = results$cohortId[i])$sql
  sql <- SqlRender::translateSql(sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  days <- DatabaseConnector::querySql(connection, sql)
  days <- days$DAYS
  q <- quantile(days, c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1))
  results$count[i] <- length(days)
  results$mean[i] <- mean(days)
  results$sd[i] <- sd(days)
  results$min[i] <- q[1]
  results$p10[i] <- q[2]
  results$p25[i] <- q[3]
  results$median[i] <- q[4]
  results$p50[i] <- q[5]
  results$p90[i] <- q[6]
  results$max[i] <- q[7]
}
DatabaseConnector::disconnect(connection)

write.csv(results, file.path(noCensorFolder, "tarDist.csv"), row.names = FALSE)
