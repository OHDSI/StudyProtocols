source("DataPulls.R")
source("PlotsAndTables.R")

shinySettings <- list(dataFolder = "S:/StudyResults/UkaTkaSafetyFull/shinyDataAll", blind = FALSE)
# shinySettings <- list(dataFolder = "S:/StudyResults/UkaTkaSafetyFull_old_pos_control_synth/shinyDataAll", blind = FALSE)
dataFolder <- shinySettings$dataFolder
blind <- shinySettings$blind
connection <- NULL
positiveControlOutcome <- NULL

splittableTables <- c("covariate_balance", "preference_score_dist", "kaplan_meier_dist")

files <- list.files(dataFolder, pattern = ".rds")

# Remove data already in global environment:
tableNames <- gsub("(_t[0-9]+_c[0-9]+)|(_)[^_]*\\.rds", "", files)
camelCaseNames <- SqlRender::snakeCaseToCamelCase(tableNames)
camelCaseNames <- unique(camelCaseNames)
camelCaseNames <- camelCaseNames[!(camelCaseNames %in% SqlRender::snakeCaseToCamelCase(splittableTables))]
rm(list = camelCaseNames)

relabel <- function(var, oldLabel, newLabel) {
  levels(var)[levels(var) == oldLabel] <- newLabel
  return(var)
}

# Load data from data folder:
loadFile <- function(file) {
  # file = files[3]
  tableName <- gsub("(_t[0-9]+_c[0-9]+)*\\.rds", "", file) 
  # tableName <- gsub("(_t[0-9]+_c[0-9]+)|(_)[^_]*\\.rds", "", file) 
  camelCaseName <- SqlRender::snakeCaseToCamelCase(tableName)
  if (!(tableName %in% splittableTables)) {
    newData <- readRDS(file.path(dataFolder, file))
    colnames(newData) <- SqlRender::snakeCaseToCamelCase(colnames(newData))
    if (exists(camelCaseName, envir = .GlobalEnv)) {
      existingData <- get(camelCaseName, envir = .GlobalEnv)
      newData <- rbind(existingData, newData)
    }
    if (!is.null(newData$databaseId)) {
      newData$databaseId <- relabel(newData$databaseId, "thin", "THIN")
      newData$databaseId <- relabel(newData$databaseId, "pmtx", "PharMetrics")
    }
    assign(camelCaseName, newData, envir = .GlobalEnv)
  }
  invisible(NULL)
}
lapply(files, loadFile)

tcos <- unique(cohortMethodResult[, c("targetId", "comparatorId", "outcomeId")])
tcos <- tcos[tcos$outcomeId %in% outcomeOfInterest$outcomeId, ]

dbInfoHtml <- readChar("DataSources.html", file.info("DataSources.html")$size)
outcomesInfoHtml <- readChar("Outcomes.html", file.info("Outcomes.html")$size)
targetCohortsInfoHtml <- readChar("TargetCohorts.html", file.info("TargetCohorts.html")$size)
comparatorCohortsInfoHtml <- readChar("ComparatorCohorts.html", file.info("ComparatorCohorts.html")$size)
analysesInfoHtml <- readChar("Analyses.html", file.info("Analyses.html")$size)



# exposures rename
exposureOfInterest$exposureName <- relabel(exposureOfInterest$exposureName, "[OD4] Patients with unicompartmental knee replacement without limitation on hip-spine-foot pathology", "Unicompartmental knee replacement without hip-spine-foot pathology restriction")
exposureOfInterest$exposureName <- relabel(exposureOfInterest$exposureName, "[OD4] Patients with unicompartmental knee replacement", "Unicompartmental knee replacement")
exposureOfInterest$exposureName <- relabel(exposureOfInterest$exposureName, "[OD4] Patients with total knee replacement without limitation on hip-spine-foot pathology", "Total knee replacement without hip-spine-foot pathology restriction")
exposureOfInterest$exposureName <- relabel(exposureOfInterest$exposureName, "[OD4] Patients with total knee replacement", "Total knee replacement")
exposureOfInterest$order <- match(exposureOfInterest$exposureName, c("Unicompartmental knee replacement",
                                                                     "Total knee replacement",
                                                                     "Unicompartmental knee replacement without hip-spine-foot pathology restriction",
                                                                     "Total knee replacement without hip-spine-foot pathology restriction"))
exposureOfInterest <- exposureOfInterest[order(exposureOfInterest$order), ]

# outcomes rename
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Post operative infection events", "Post-operative infection")
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Venous thromboembolism events", "Venous thromboembolism")
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Mortality", "Mortality")
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Readmission after knee arthroplasty", "Readmission")
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Persons with knee arthroplasty revision", "Revision")
outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Opioid use after arthroplasty", "Opioid use")
outcomeOfInterest$order <- match(outcomeOfInterest$outcomeName, c("Venous thromboembolism",
                                                                  "Post-operative infection",
                                                                  "Readmission",
                                                                  "Mortality",
                                                                  "Opioid use",
                                                                  "Revision"))
outcomeOfInterest <- outcomeOfInterest[order(outcomeOfInterest$order), ]

# analyses rename
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "1. PS matching variable ratio No trim TAR 60d", "10:1 variable ratio matching, 60 day time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "2. PS matching variable ratio No trim TAR 1yr", "10:1 variable ratio matching, 1 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "3. PS matching variable ratio No trim TAR 5yr", "10:1 variable ratio matching, 5 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "4. PS matching variable ratio Trim 5% TAR 60d", "10:1 variable ratio matching 5% trim, 60 day time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "5. PS matching 1-1 ratio No trim TAR 60d", "1:1 ratio matching, 60 day time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "6. PS matching variable ratio Trim 5% TAR 5yr", "10:1 variable ratio matching 5% trim, 5 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "7. PS matching 1-1 ratio No trim TAR 5yr", "1:1 ratio matching, 5 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "8. PS matching variable ratio No trim TAR 91d-1yr", "10:1 variable ratio matching, 91 days to 1 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "9. PS matching variable ratio No trim TAR 91d-5yr", "10:1 variable ratio matching, 91 days to 5 years time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "10. PS matching variable ratio Trim 5% TAR 91d-1yr", "10:1 variable ratio matching 5% trim, 91 days to 1 year time-at-risk")
cohortMethodAnalysis$description <- relabel(cohortMethodAnalysis$description, "11. PS matching 1-1 ratio No trim TAR 91d-1yr" , "1:1 ratio matching, 91 days to 1 year time-at-risk")

dropRows <- (cohortMethodResult$databaseId %in% c("CCAE", "MDCR", "PharMetrics") & cohortMethodResult$outcomeId == 8210) | # drop mortality from CCAE, MDCR, PharMetrics
  (cohortMethodResult$databaseId %in% c("THIN", "PharMetrics") & cohortMethodResult$outcomeId == 8211) | # drop readmission from THIN and PharMetrics
  (cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId %in% c(6:11)) |
  (cohortMethodResult$outcomeId == 8212 & cohortMethodResult$analysisId %in% c(1, 4, 5, 8:11)) | # drop complications analyses (5yr trim, 5yr 1:1, 91d-1yr TARs, 91d-5yr TARs)
  (cohortMethodResult$outcomeId == 8233 & cohortMethodResult$analysisId %in% c(1:7)) # drop opioids analyses (60d TAR, 1yr TAR, 5yr TAR)
cohortMethodResult <- cohortMethodResult[!dropRows, ]

badCalibration <- (cohortMethodResult$databaseId %in% c("THIN") & cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId %in% c(1,4,5)) # THIN 60d complications for removing calibrated results
cohortMethodResult[badCalibration, c("calibratedP", "calibratedRr", "calibratedCi95Lb", "calibratedCi95Ub", "calibratedLogRr","calibratedSeLogRr")] <- NA

primary <- (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId == 1) |
           (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8212) & cohortMethodResult$analysisId == 3) |
           (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8233) & cohortMethodResult$analysisId == 8)

cohortMethodResult$analysisType[primary] <- "Primary"
cohortMethodResult$analysisType[!primary] <- "Sensitivity"
