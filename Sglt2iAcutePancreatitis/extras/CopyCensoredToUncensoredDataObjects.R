# This code generates CohortMethod data objects for cohorts without censoring by modifying objects for cohorts with censoring

cmOutputFolder <- file.path(outputFolder, "cmOutput")

connection <- DatabaseConnector::connect(connectionDetails)
tcos <- read.csv("inst/settings/TcosOfInterest.csv", stringsAsFactors = FALSE)
tcosWithCensoring <- tcos[tcos$censorAtSwitch, ]
for (i in 1:nrow(tcosWithCensoring)) {
  targetId <- tcosWithCensoring$targetId[i]
  comparatorId <- tcosWithCensoring$comparatorId[i]
  newTargetId <- 10000 + targetId
  newComparatorId <- 10000 + comparatorId
  
  # Copy cohortMethodData object -------------------------------------------------------------------
  sourceFileName <- file.path(cmOutputFolder, sprintf("CmData_l1_t%s_c%s", targetId, comparatorId))
  cmData <- CohortMethod::loadCohortMethodData(sourceFileName)
  sql <- "SELECT subject_id, 
    cohort_start_date, 
    DATEDIFF(DAY, cohort_start_date, cohort_end_date) AS days_to_cohort_end,
    CASE WHEN cohort_definition_id = @target_id THEN 1 ELSE 0 END AS treatment
  FROM @cohort_database_schema.@cohort_table 
  WHERE cohort_definition_id IN (@target_id, @comparator_id)"
  sql <- SqlRender::renderSql(sql = sql,
                              cohort_database_schema = cohortDatabaseSchema,
                              cohort_table = cohortTable,
                              target_id = newTargetId,
                              comparator_id = newComparatorId)$sql
  sql <- SqlRender::translateSql(sql = sql, targetDialect = connectionDetails$dbms, oracleTempSchema = oracleTempSchema)$sql
  newCohorts <- DatabaseConnector::querySql(connection, sql)
  colnames(newCohorts) <- SqlRender::snakeCaseToCamelCase(colnames(newCohorts))
  cmData$cohorts$daysToCohortEnd <- NULL
  cmData$cohorts <- merge(cmData$cohorts, newCohorts, all.x = TRUE)
  if (any(is.na(cmData$cohorts$daysToCohortEnd)))
    stop("Cohort mismatch")
  targetFileName <- file.path(cmOutputFolder, sprintf("CmData_l1_t%s_c%s", newTargetId, newComparatorId))
  CohortMethod::saveCohortMethodData(cmData, targetFileName)
  writeLines(paste("Created object", targetFileName))
  
  # Copy shared PS object --------------------------------------------------------------------------
  sourceFileName <- file.path(cmOutputFolder, sprintf("Ps_l1_p1_t%s_c%s.rds", targetId, comparatorId))
  ps <- readRDS(sourceFileName)
  targetFileName <- file.path(cmOutputFolder, sprintf("Ps_l1_p1_t%s_c%s.rds", newTargetId, newComparatorId))
  saveRDS(ps, targetFileName)
  writeLines(paste("Created object", targetFileName))
}

DatabaseConnector::disconnect(connection)


