# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of UkaTkaSafetyFull
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
createPlotsAndTables <- function(studyFolder,
                                 createTable1,
                                 createHrTable,
                                 createForestPlot,
                                 createKmPlot,
                                 createDiagnosticsPlot) {
  
  source("inst/shiny/EvidenceExplorer/DataPulls.R")
  source("inst/shiny/EvidenceExplorer/PlotsAndTables.R")
  dataFolder <- file.path(studyFolder, "shinyDataAll")
  reportFolder <- file.path(studyFolder, "report")
  if (!file.exists(reportFolder)) {
    dir.create(reportFolder)
  }
  splittableTables <- c("covariate_balance", "preference_score_dist", "kaplan_meier_dist")
  connection <- NULL
  files <- list.files(dataFolder, pattern = ".rds")
  
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
      assign(camelCaseName, newData, envir = .GlobalEnv)
    }
    invisible(NULL)
  }
  lapply(files, loadFile)
  
  relabel <- function(var, oldLabel, newLabel) {
    levels(var)[levels(var) == oldLabel] <- newLabel
    return(var)
  }
  
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
  outcomeOfInterest$outcomeName <- relabel(outcomeOfInterest$outcomeName, "[OD4] Post operative infection events","Post-operative infection")
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
  
  dropRows <- (cohortMethodResult$databaseId %in% c("CCAE", "MDCR", "pmtx") & cohortMethodResult$outcomeId == 8210) | # drop mortality from CCAE, MDCR, PharMetrics
    (cohortMethodResult$databaseId %in% c("thin", "pmtx") & cohortMethodResult$outcomeId == 8211) | # drop readmission from THIN and PharMetrics
    (cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId %in% c(6:11)) |
    (cohortMethodResult$outcomeId == 8212 & cohortMethodResult$analysisId %in% c(1, 4, 5, 8:11)) | # drop complications analyses (5yr trim, 5yr 1:1, 91d-1yr TARs, 91d-5yr TARs)
    (cohortMethodResult$outcomeId == 8233 & cohortMethodResult$analysisId %in% c(1:7)) # drop opioids analyses (60d TAR, 1yr TAR, 5yr TAR)
  cohortMethodResult <- cohortMethodResult[!dropRows, ]
  
  badCalibration <- (cohortMethodResult$databaseId %in% c("thin") & cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId %in% c(1,4,5)) # thin 60d complications for removing calibrated results
  cohortMethodResult[badCalibration, c("calibratedP", "calibratedRr", "calibratedCi95Lb", "calibratedCi95Ub", "calibratedLogRr","calibratedSeLogRr")] <- NA
  
  if (createTable1) {
    covariateOrder <- c(
      "",
      "Characteristic",
      "Age group",
      "    40-44",
      "    45-49",
      "    50-54",
      "    55-59",
      "    60-64",
      "    65-69",
      "    70-74",
      "    75-79",
      "    80-84",
      "    85-89",
      "    90-94",
      "Gender: female",
      "Medical history: General",
      "    Acute respiratory disease",
      "    Attention deficit hyperactivity disorder",
      "    Chronic liver disease",
      "    Chronic obstructive lung disease",
      "    Crohn's disease",
      "    Dementia",
      "    Depressive disorder",
      "    Diabetes mellitus",
      "    Gastroesophageal reflux disease",
      "    Gastrointestinal hemorrhage",
      "    Human immunodeficiency virus infection",
      "    Hyperlipidemia",
      "    Hypertensive disorder",
      "    Lesion of liver",
      "    Obesity",
      "    Osteoarthritis",
      "    Pneumonia",
      "    Psoriasis",
      "    Renal impairment",
      "    Schizophrenia",
      "    Ulcerative colitis",
      "    Urinary tract infectious disease",
      "    Viral hepatitis C",
      "    Visual system disorder",
      "Medical history: Cardiovascular disease",
      "    Atrial fibrillation",
      "    Cerebrovascular disease",
      "    Coronary arteriosclerosis",
      "    Heart disease",
      "    Heart failure",
      "    Ischemic heart disease",
      "    Peripheral vascular disease",
      "    Pulmonary embolism",
      "    Venous thrombosis",
      "Medical history: Neoplasms",
      "    Hematologic neoplasm",
      "    Malignant lymphoma",
      "    Malignant neoplasm of anorectum",
      "    Malignant neoplastic disease",
      "    Malignant tumor of breast",
      "    Malignant tumor of colon",
      "    Malignant tumor of lung",
      "    Malignant tumor of urinary bladder",
      "    Primary malignant neoplasm of prostate",
      "Medication use",
      "    Agents acting on the renin-angiotensin system",
      "    Antibacterials for systemic use",
      "    Antidepressants",
      "    Antiepileptics",
      "    Antiinflammatory and antirheumatic products",
      "    Antineoplastic agents",
      "    Antipsoriatics",
      "    Antithrombotic agents",
      "    Beta blocking agents",
      "    Calcium channel blockers",
      "    Diuretics",
      "    Drugs for acid related disorders",
      "    Drugs for obstructive airway diseases",
      "    Drugs used in diabetes",
      "    Immunosuppressants",
      "    Lipid modifying agents",
      "    Opioids",
      "    Psycholeptics",
      "    Psychostimulants, agents used for adhd and nootropics")
    
    paperCovariateOrder <- c(
      "",
      "Characteristic",
      "Age group",
      "    40-44",
      "    45-49",
      "    50-54",
      "    55-59",
      "    60-64",
      "    65-69",
      "    70-74",
      "    75-79",
      "    80-84",
      "    85-89",
      "    90-94",
      "Gender: female",
      "Medical history: General",
      "    Atrial fibrillation",
      "    Chronic obstructive lung disease",
      "    Depressive disorder",
      "    Diabetes mellitus",
      "    Hyperlipidemia",
      "    Hypertensive disorder",
      "    Obesity",
      "    Osteoarthritis",
      "    Renal impairment",
      "    Peripheral vascular disease",
      "    Pulmonary embolism",
      "    Venous thrombosis",
      "Medication use",
      "    Antibacterials for systemic use",
      "    Antidepressants",
      "    Antiinflammatory and antirheumatic products",
      "    Antithrombotic agents",
      "    Opioids")
    
    tcoas <- unique(cohortMethodResult[c("analysisId", "targetId", "comparatorId", "outcomeId")])
    tcoas <- tcoas[tcoas$outcomeId %in% outcomeOfInterest$outcomeId, ]
    tcoas <- tcoas[order(tcoas$targetId, tcoas$analysisId, tcoas$outcomeId), ]
    tcoas <- aggregate(outcomeId ~ analysisId + targetId + comparatorId, tcoas, head, 1)
    
    for (i in 1) { # 1:nrow(tcoas)) { # i=1
      targetId <- tcoas$targetId[i]
      comparatorId <- tcoas$comparatorId[i]
      analysisId <- tcoas$analysisId[i]
      outcomeId <- tcoas$outcomeId[i]
      matching <- c("before_matching", "after_matching", "before_and_after_matching")
      for (j in 1:length(matching)) { # j=1
        table1List <- list()
        for (databaseId in database$databaseId) { # databaseId="CCAE"
          balance <- getCovariateBalance2(connection = connection,
                                          dataFolder = dataFolder,
                                          targetId = targetId,
                                          comparatorId = comparatorId,
                                          databaseId = databaseId,
                                          analysisId = analysisId,
                                          outcomeId = outcomeId)
          table1 <- prepareTable1(balance = balance,
                                  beforeLabel = "Before matching",
                                  afterLabel = "After matching",
                                  targetLabel = "UKR",
                                  comparatorLabel = "TKR",
                                  percentDigits = 1,
                                  stdDiffDigits = 2,
                                  output = "latex",
                                  pathToCsv = file.path("inst", "shiny", "EvidenceExplorer", "Table1Specs.csv"))
          colnames(table1) <- c("covariate", 
                                paste0("bmUkr", databaseId), paste0("bmTkr", databaseId), paste0("bmSdm", databaseId),
                                paste0("amUkr", databaseId), paste0("amTkr", databaseId), paste0("amSdm", databaseId))
          if (matching[j] == matching[1]) {
            table1 <- table1[, c("covariate", paste0("bmUkr", databaseId), paste0("bmTkr", databaseId), paste0("bmSdm", databaseId))]
          }
          if (matching[j] == matching[2]) {
            table1 <- table1[, c("covariate", paste0("amUkr", databaseId), paste0("amTkr", databaseId), paste0("amSdm", databaseId))]  
          }
          if (matching[j] == matching[3]) {
            table1 <- table1
          }
          table1List[[length(table1List) + 1]] <- table1
        }
        table1 <- merge(table1List[[1]], table1List[[2]], by = "covariate", all = TRUE)
        table1 <- merge(table1, table1List[[3]], by = "covariate", all = TRUE)
        table1 <- merge(table1, table1List[[4]], by = "covariate", all = TRUE)
        table1 <- merge(table1, table1List[[5]], by = "covariate", all = TRUE)
        
        table1Full <- table1[match(covariateOrder, table1$covariate), ]
        table1FullFileName <- file.path(reportFolder, paste0("table1_", matching[j],"_full_t", targetId, "_c", comparatorId, ".csv"))
        write.csv(table1Full, table1FullFileName, row.names = FALSE, na = "")
        
        table1Reduced <- table1[match(paperCovariateOrder, table1$covariate), ]
        table1ReducedFileName <- file.path(reportFolder, paste0("table1_", matching[j], "_reduced_t", targetId, "_c", comparatorId, ".csv"))
        write.csv(table1Reduced, table1ReducedFileName, row.names = FALSE, na = "")
      }
    }
  }
  
  if (createHrTable) {
    tcoads <- unique(cohortMethodResult[c("analysisId", "targetId", "comparatorId", "outcomeId", "databaseId")])
    tcoads <- tcoads[tcoads$outcomeId %in% unique(outcomeOfInterest$outcomeId), ]
    tcoads <- tcoads[order(tcoads$targetId, tcoads$outcomeId, tcoads$databaseId, tcoads$analysisId), ]
    hrTable <- data.frame()
    for (i in 1:nrow(tcoads)) { # i=56
      outcomeId <- tcoads$outcomeId[i]
      databaseId <- tcoads$databaseId[i]
      targetId <- tcoads$targetId[i]
      comparatorId <- tcoads$comparatorId[i]
      analysisId <- tcoads$analysisId[i]
      mainResults <- getMainResults(connection = connection,
                                    targetIds = targetId,
                                    comparatorIds = comparatorId,
                                    outcomeIds = outcomeId,
                                    databaseIds = databaseId,
                                    analysisIds = analysisId)
      hrs <- prepareMainResultsTable(mainResults = mainResults, analyses = cohortMethodAnalysis)
      irs <- preparePowerTable(mainResults = mainResults, analyses = cohortMethodAnalysis)
      targetIr <- sprintf("%s (%s)", irs$targetOutcomes, irs$targetIr)
      comparatorIr <- sprintf("%s (%s)", irs$comparatorOutcomes, irs$comparatorIr)
      hrs$`UKR IR` <- targetIr
      hrs$`TKR IR` <- comparatorIr
      hrs$outcomeId <- outcomeId
      hrs$databaseId <- databaseId
      hrs$targetId <- targetId
      hrs$comparatorId <- comparatorId
      hrs$analysisId <- analysisId
      hrs <- merge(outcomeOfInterest[, c("outcomeId", "outcomeName")], hrs)
      hrs <- hrs[, c("analysisId",
                     "targetId",
                     "comparatorId",
                     "outcomeId",
                     "outcomeName", 
                     "databaseId",
                     "Analysis",
                     "UKR IR",
                     "TKR IR",
                     "HR (95% CI)",
                     "P",
                     "Cal. HR (95% CI)",
                     "Cal. p")]
      hrTable <- rbind(hrTable, hrs)
    }
    hrTable$Analysis <- as.character(hrTable$Analysis)
    hrTable$Analysis[hrTable$targetId == 8260] <- paste(hrTable$Analysis[hrTable$targetId == 8260], "without prior spine-hip-foot pathology restriction", sep = "; ")
    primary <- (hrTable$targetId == 8257 & hrTable$outcomeId %in% c(8208, 8209, 8210, 8211) & hrTable$analysisId == 1) |
               (hrTable$targetId == 8257 & hrTable$outcomeId %in% c(8212) & hrTable$analysisId == 3) |
               (hrTable$targetId == 8257 & hrTable$outcomeId %in% c(8233) & hrTable$analysisId == 8)
    hrTable$AnalysisName[primary] <- "Primary"
    hrTable$AnalysisName[!primary] <- "Sensitivity"
    hrTable <- hrTable[, c("analysisId",
                           "targetId",
                           "comparatorId",
                           "outcomeId",
                           "outcomeName",
                           "databaseId",
                           "AnalysisName",
                           "Analysis",
                           "UKR IR",
                           "TKR IR",
                           "HR (95% CI)",
                           "P",               
                           "Cal. HR (95% CI)",
                           "Cal. p")]
    hrTable$outcomeIdOrder <- match(hrTable$outcomeId, c(8209, 8208, 8211, 8210, 8233, 8212))
    hrTable <- hrTable[order(hrTable$outcomeIdOrder, hrTable$databaseId, hrTable$targetId, hrTable$AnalysisName, hrTable$analysisId), ]
    
    hrsTableAllFileName <- file.path(reportFolder, "hrs_table_primary_and_sensitivity.csv")
    write.csv(hrTable[, -c(1:4, 15)], hrsTableAllFileName, row.names = FALSE)
    
    hrsTablePrimaryFileName <- file.path(reportFolder, "hrs_table_primary.csv")
    write.csv(hrTable[hrTable$AnalysisName == "Primary", -c(1:4, 15)], hrsTablePrimaryFileName, row.names = FALSE)
  }

  if (createForestPlot) {
    primary <- (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8208, 8209, 8210, 8211) & cohortMethodResult$analysisId == 1) |
               (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8212) & cohortMethodResult$analysisId == 3) |
               (cohortMethodResult$targetId == 8257 & cohortMethodResult$outcomeId %in% c(8233) & cohortMethodResult$analysisId == 8)
    plotData <- cohortMethodResult[primary, ]
    plotData <- merge(plotData, outcomeOfInterest[, c("outcomeId", "outcomeName")])
    levels(plotData$outcomeName)[levels(plotData$outcomeName) == "Venous thromboembolism"] <- "VTE"
    levels(plotData$outcomeName)[levels(plotData$outcomeName) == "Post-operative infection"] <- "Infection"
    plotData$TAR[plotData$analysisId == 1] <- "60 days"
    plotData$TAR[plotData$analysisId == 3] <- "5 years"
    plotData$TAR[plotData$analysisId == 8] <- "91 days - 1 year"
    ccae <- generateForestPlot(plotData = plotData, databaseId = "CCAE", dropMortality = TRUE)
    optum <- generateForestPlot(plotData = plotData, databaseId = "Optum")
    mdcr <- generateForestPlot(plotData = plotData, databaseId = "MDCR", dropMortality = TRUE)
    thin <- generateForestPlot(plotData = plotData, databaseId = "thin", dropMortality = TRUE, dropReadmission = TRUE, dropInfection = TRUE, dropVTE = TRUE)
    pmtx <- generateForestPlot(plotData = plotData, databaseId = "pmtx", dropMortality = TRUE, dropReadmission = TRUE, favorsLabel = TRUE, addLegend = TRUE)
    row1 <- grid::textGrob("CCAE", rot = 90, gp = grid::gpar(fontsize = 18))
    row2 <- grid::textGrob("Optum", rot = 90, gp = grid::gpar(fontsize = 18))
    row3 <- grid::textGrob("MDCR", rot = 90, gp = grid::gpar(fontsize = 18))
    row4 <- grid::textGrob("THIN", rot = 90, gp = grid::gpar(fontsize = 18))
    row5 <- grid::textGrob("PharMetrics", rot = 90, gp = grid::gpar(fontsize = 18))
    plot <- gridExtra::grid.arrange(row1, ccae,
                                    row2, optum,
                                    row3, mdcr,
                                    row4, thin,
                                    row5, pmtx,
                                    nrow = 5,
                                    heights = grid::unit(c(5, 6, 5, 3, 6), rep("cm", 5)),
                                    widths =  grid::unit(c(2, 11), rep("cm", 2)))
    plotFile <- file.path(reportFolder, "hr_calibrated_forest_plot_primary.png")
    ggplot2::ggsave(filename = plotFile, plot = plot, height = 26, width = 16, units = "cm")
  }
  
  if (createKmPlot) {
    refKm <- data.frame(outcomeId = c(8233, 8212), 
                        analysisId = c(8, 3), 
                        yLim = c(0.5, 0.9),
                        useYLabel = c(TRUE, FALSE),
                        timeOffset = c(TRUE, FALSE))
    refKm <- merge(refKm, database)
    refKm$order <- match(refKm$databaseId, c("CCAE", 
                                             "Optum",
                                             "MDCR",
                                             "thin",
                                             "pmtx"))
    refKm <- refKm[order(refKm$order), ]
    refKm$legendLabel <- c(rep(TRUE, 2), rep(FALSE, 8))
    kmPlotList <- list()
    for (i in 1:nrow(refKm)) { # i=1
      outcomeId <- refKm$outcomeId[i]
      databaseId <- refKm$databaseId[i]
      analysisId <- refKm$analysisId[i]
      yLim <- refKm$yLim[i]
      legendLabel <- refKm$legendLabel[i]
      useYLabel <- refKm$useYLabel[i]
      timeOffset <- refKm$useYLabel[i]
      kmData <- getKaplanMeier2(connection = connection,
                                dataFolder = dataFolder,
                                targetId = 8257,
                                comparatorId = 8256,
                                outcomeId = outcomeId,
                                databaseId = databaseId,
                                analysisId = analysisId)
      kmPlotList[[length(kmPlotList) + 1]] <- plotKaplanMeier2(kaplanMeier = kmData,
                                                               targetName = "UKR",
                                                               comparatorName = "TKR",
                                                               legendLabel = legendLabel,
                                                               yLimLower = yLim,
                                                               useYLabel = useYLabel,
                                                               timeOffset = timeOffset)
    }
    col0 <- grid::textGrob("")
    col1 <- grid::textGrob("Opioid use", gp = grid::gpar(fontsize = 25))
    col2 <- grid::textGrob("Revision", gp = grid::gpar(fontsize = 25))
    row1 <- grid::textGrob("CCAE", rot = 90, gp = grid::gpar(fontsize = 35))
    row2 <- grid::textGrob("Optum", rot = 90, gp = grid::gpar(fontsize = 35))
    row3 <- grid::textGrob("MDCR", rot = 90, gp = grid::gpar(fontsize = 35))
    row4 <- grid::textGrob("THIN", rot = 90, gp = grid::gpar(fontsize = 35))
    row5 <- grid::textGrob("PharMetrics", rot = 90, gp = grid::gpar(fontsize = 35))
    plot <- gridExtra::grid.arrange(col0, col1, col2, 
                                    row1, kmPlotList[[1]], kmPlotList[[2]],
                                    row2, kmPlotList[[3]], kmPlotList[[4]],
                                    row3, kmPlotList[[5]], kmPlotList[[6]],
                                    row4, kmPlotList[[7]], kmPlotList[[8]],
                                    row5, kmPlotList[[9]], kmPlotList[[10]],
                                    nrow = 6,
                                    heights = grid::unit(c(2, 14, 11, 11, 11, 11), rep("cm", 6)),
                                    widths = grid::unit(c(2, 18, 18), rep("cm", 2)))
    plotFile <- file.path(reportFolder, "km_plots_long_term_primary.png")
    ggplot2::ggsave(filename = plotFile, plot = plot, height = 60, width = 38, units = "cm")
  }
  
  if (createDiagnosticsPlot) {
    tcoads <- unique(cohortMethodResult[c("analysisId", "targetId", "comparatorId", "outcomeId", "databaseId")])
    refPsBal <- tcoads[tcoads$analysisId == 2 & tcoads$targetId == 8257 & tcoads$comparatorId == 8256 & tcoads$outcomeId == 8208, ]
    refPsBal$order <- match(refPsBal$databaseId, c("CCAE", 
                                                   "Optum",
                                                   "MDCR",
                                                   "thin",
                                                   "pmtx"))
    refPsBal <- refPsBal[order(refPsBal$order), ]
    psPlotList <- list()
    balancePlotList <- list()
    for (i in 1:nrow(refPsBal)) { # i=1
      databaseId <- refPsBal$databaseId[i]
      analysisId <- refPsBal$analysisId[i]
      targetId <- refPsBal$targetId[i]
      comparatorId <- refPsBal$comparatorId[i]
      outcomeId <- refPsBal$outcomeId[i]
      ps <- getPs2(connection = connection,
                   dataFolder = dataFolder,
                   targetIds = 8257,
                   comparatorIds = 8256,
                   databaseId = databaseId)
      psPlotList[[length(psPlotList) + 1]] <- plotPs2(ps = ps,
                                                      targetName = "UKR",
                                                      comparatorName = "TKR")
      balance <- getCovariateBalance2(connection = connection,
                                      dataFolder = dataFolder,
                                      targetId = targetId,
                                      comparatorId = comparatorId,
                                      databaseId = databaseId,
                                      analysisId = analysisId,
                                      outcomeId = outcomeId)
      balancePlotList[[length(balancePlotList) + 1]] <- plotCovariateBalanceScatterPlot2(balance = balance, 
                                                                                         beforeLabel = "Before matching", 
                                                                                         afterLabel = "After matching")
    }
    nullPlotList <- list()
    refNull <- data.frame(analysisId = c(1, 8, 3),
                          targetId = rep(8257, 3),
                          comparatorId = rep(8256, 3))
    refNull <- merge(refNull, database)
    refNull$order <- match(refNull$databaseId, c("CCAE", 
                                                 "Optum",
                                                 "MDCR",
                                                 "thin",
                                                 "pmtx"))
    refNull <- refNull[order(refNull$order), ]
    for (i in 1:nrow(refNull)) { # i=1
      targetId <- refNull$targetId[i]
      comparatorId <- refNull$comparatorId[i]
      analysisId <- refNull$analysisId[i]
      databaseId <- refNull$databaseId[i]
      controlResults <- getControlResults(connection = connection,
                                          targetId = targetId,
                                          comparatorId = comparatorId,
                                          analysisId = analysisId,
                                          databaseId = databaseId)
      negativeControlResults <- controlResults[controlResults$effectSize == 1,]
      nullPlotList[[length(nullPlotList) + 1]] <- plotLargeScatter2(d = negativeControlResults, xLabel = "Hazard ratio")
    }  
    col0 <- grid::textGrob("")
    col1 <- grid::textGrob("Preference score distribution", gp = grid::gpar(fontsize = 40))
    col2 <- grid::textGrob("Covariate balance", gp = grid::gpar(fontsize = 40))
    col3 <- grid::textGrob("Empirical null, 60 days", gp = grid::gpar(fontsize = 40))
    col4 <- grid::textGrob("Empirical null, 1 year", gp = grid::gpar(fontsize = 40))
    col5 <- grid::textGrob("Empirical null, 5 years", gp = grid::gpar(fontsize = 40))
    row1 <- grid::textGrob("CCAE", rot = 90, gp = grid::gpar(fontsize = 40))
    row2 <- grid::textGrob("Optum", rot = 90, gp = grid::gpar(fontsize = 40))
    row3 <- grid::textGrob("MDCR", rot = 90, gp = grid::gpar(fontsize = 40))
    row4 <- grid::textGrob("THIN", rot = 90, gp = grid::gpar(fontsize = 40))
    row5 <- grid::textGrob("PharMetrics", rot = 90, gp = grid::gpar(fontsize = 40))
    plot <- gridExtra::grid.arrange(col0, col1, col2, col3, col4, col5,
                                    row1, psPlotList[[1]], balancePlotList[[1]], nullPlotList[[1]], nullPlotList[[2]], nullPlotList[[3]],
                                    row2, psPlotList[[2]], balancePlotList[[2]], nullPlotList[[4]], nullPlotList[[5]], nullPlotList[[6]], 
                                    row3, psPlotList[[3]], balancePlotList[[3]], nullPlotList[[7]], nullPlotList[[8]], nullPlotList[[9]], 
                                    row4, psPlotList[[4]], balancePlotList[[4]], nullPlotList[[10]], nullPlotList[[11]], nullPlotList[[12]], 
                                    row5, psPlotList[[5]], balancePlotList[[5]], nullPlotList[[13]], nullPlotList[[14]], nullPlotList[[15]], 
                                    nrow = 6,
                                    heights = c(50, rep(500, 5)),
                                    widths = c(50, rep(500, 5)))
    plotFile <- file.path(reportFolder, "diagnostics_primary.png")
    ggplot2::ggsave(filename = plotFile, plot = plot, height = 35, width = 45)
  }
}

generateForestPlot <- function(plotData,
                               databaseId,
                               favorsLabel = FALSE,
                               dropMortality = FALSE,
                               dropReadmission = FALSE,
                               dropInfection = FALSE,
                               dropVTE = FALSE,
                               addLegend = FALSE) {
  results <- plotData[plotData$databaseId == databaseId, ]
  data <- data.frame(outcome = results$outcomeName,
                     logRr = results$calibratedLogRr,
                     logLb = results$calibratedLogRr + qnorm(0.025) * results$calibratedSeLogRr,
                     logUb = results$calibratedLogRr + qnorm(0.975) * results$calibratedSeLogRr,
                     database = results$databaseId,
                     TAR = as.factor(results$TAR))
  
  data$order <- match(data$TAR, c("60 days", "91 days - 1 year", "5 years"))
  data <- data[order(data$order), ]
  
  breaks <- c(0.25, 0.5, 1, 2, 4)
  if (favorsLabel) {
    labels <- c(0.25, paste("0.5\nFavours", "UKR"), 1, paste("2\nFavours", "TKR"), 4)
  } else {
    labels <- c(0.25, 0.5, 1, 2, 4)
  }
  limits <- c("Revision", 
              "Opioid use",
              "Mortality",
              "Readmission",
              "Infection",
              "VTE")
  if (dropMortality) {
    limits <- limits[! limits %in% "Mortality"]
  }
  if (dropReadmission) {
    limits <- limits[! limits %in% "Readmission"]
  }
  if (dropInfection) {
    limits <- limits[! limits %in% "Infection"]
  }
  if (dropVTE) {
    limits <- limits[! limits %in% "VTE"]
  }
  if (addLegend) {
    legendPosition <- "bottom"
  } else {
    legendPosition <- "none"
  }
  plot <- ggplot2::ggplot(data,
                          ggplot2::aes(x = exp(logRr),
                                       y = outcome,
                                       xmin = exp(logLb),
                                       xmax = exp(logUb),
                                       colour = TAR),
                          environment = environment()) +
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.1) +
    ggplot2::geom_vline(xintercept = 1, colour = "#000000", lty = 1, size = 1) +
    ggplot2::geom_errorbarh(height = 0, size = 2, alpha = 0.7) +
    ggplot2::geom_point(shape = 16, size = 4.4, alpha = 0.7) +
    ggplot2::scale_colour_manual(breaks = data$TAR,
                                 values=c(rgb(0, 0.8, 0), rgb(0, 0, 0.8), rgb(0.8, 0, 0))) + 
    ggplot2::labs(color = 'Time-at-risk') +
    ggplot2::coord_cartesian(xlim = c(0.25, 4)) +
    ggplot2::scale_x_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = labels) +
    ggplot2::scale_y_discrete(limits = limits) +
    ggplot2::theme(text = ggplot2::element_text(size = 12),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_rect(fill = "#FAFAFA",colour = NA),
                   panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                   axis.ticks = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank(),
                   axis.title.x = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_text(size = 12),
                   axis.text.x = ggplot2::element_text(size = 12),
                   legend.position = legendPosition)
  return(plot)
}

getKaplanMeier2 <- function(connection,
                            dataFolder,
                            targetId,
                            comparatorId,
                            outcomeId,
                            databaseId,
                            analysisId) {
  file <- sprintf("kaplan_meier_dist_t%s_c%s.rds", targetId, comparatorId)
  km <- readRDS(file.path(dataFolder, file))
  colnames(km) <- SqlRender::snakeCaseToCamelCase(colnames(km))
  km <- km[km$outcomeId == outcomeId &
             km$analysisId == analysisId &
             km$databaseId == databaseId, ]
  return(km)
}

plotKaplanMeier2 <- function(kaplanMeier,
                             targetName,
                             comparatorName,
                             legendLabel,
                             yLimLower,
                             useYLabel,
                             timeOffset) {
  if (timeOffset) {
    survTimeOffset <- 91
    xAxisOffset <- 50
  } else {
    survTimeOffset <- 0
    xAxisOffset <- 0
  }
  data <- rbind(data.frame(time = kaplanMeier$time + survTimeOffset,
                           s = kaplanMeier$targetSurvival,
                           lower = kaplanMeier$targetSurvivalLb,
                           upper = kaplanMeier$targetSurvivalUb,
                           strata = paste0(" ", targetName, "    ")),
                data.frame(time = kaplanMeier$time + survTimeOffset,
                           s = kaplanMeier$comparatorSurvival,
                           lower = kaplanMeier$comparatorSurvivalLb,
                           upper = kaplanMeier$comparatorSurvivalUb,
                           strata = paste0(" ", comparatorName)))
  if (timeOffset) {
    xlims <- c(survTimeOffset, max(data$time))
  } else {
    xlims <- c(-max(data$time)/40, max(data$time))
  }
  xBreaks <- kaplanMeier$time[!is.na(kaplanMeier$targetAtRisk)] + xAxisOffset
  xLabel <- "Days since surgery"
  ylims <- c(yLimLower, 1)
  if (useYLabel) {
    yLabel <- "Survival probability"
  } else {
    yLabel <- NULL
  }
  if (legendLabel) {
    legendPosition <- "top"
  } else {
    legendPosition <- "none"
  }
  theme1 <- ggplot2::element_text(colour = "#000000", size = 20)
  theme2 <- ggplot2::element_text(colour = "#000000", size = 20)
  
  plot <- ggplot2::ggplot(data, ggplot2::aes(x = time,
                                             y = s,
                                             color = strata,
                                             fill = strata,
                                             ymin = lower,
                                             ymax = upper)) +
    ggplot2::geom_ribbon(color = rgb(0, 0, 0, alpha = 0)) +
    ggplot2::geom_step(size = 1) +
    ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.8),
                                           rgb(0, 0, 0.8, alpha = 0.8))) +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.3),
                                          rgb(0, 0, 0.8, alpha = 0.3))) +
    ggplot2::scale_x_continuous(xLabel, limits = xlims, breaks = xBreaks) +
    ggplot2::scale_y_continuous(yLabel, limits = ylims) +
    ggplot2::theme(legend.title = ggplot2::element_blank(),
                   legend.position = legendPosition,
                   legend.text = ggplot2::element_text(size = 20),
                   legend.key.size = ggplot2::unit(2, "lines"),
                   plot.title = ggplot2::element_text(hjust = 0.5),
                   text = theme1) +
    ggplot2::theme(axis.title.y = ggplot2::element_text(vjust = -10, size = 20))
  
  targetAtRisk <- kaplanMeier$targetAtRisk[!is.na(kaplanMeier$targetAtRisk)]
  comparatorAtRisk <- kaplanMeier$comparatorAtRisk[!is.na(kaplanMeier$comparatorAtRisk)]
  labels <- data.frame(x = c(0, xBreaks, xBreaks),
                       y = as.factor(c("Number at risk",
                                       rep(targetName, length(xBreaks)),
                                       rep(comparatorName, length(xBreaks)))),
                       label = c("",
                                 formatC(targetAtRisk, big.mark = ",", mode = "integer"),
                                 formatC(comparatorAtRisk, big.mark = ",", mode = "integer")))
  labels$y <- factor(labels$y, levels = c(comparatorName, targetName, "Number at risk"))
  dataTable <- ggplot2::ggplot(labels, ggplot2::aes(x = x, y = y, label = label)) + 
    ggplot2::geom_text(size = 4.5, vjust = 0.5) + 
    ggplot2::scale_x_continuous(xLabel,
                                limits = xlims,
                                breaks = xBreaks) + 
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   legend.position = "none",
                   panel.border = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_text(color = "white"),
                   axis.title.x = ggplot2::element_text(color = "white"),
                   axis.title.y = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_line(color = "white"),
                   text = theme2)
  plots <- list(plot, dataTable)
  grobs <- widths <- list()
  for (i in 1:length(plots)) {
    grobs[[i]] <- ggplot2::ggplotGrob(plots[[i]])
    widths[[i]] <- grobs[[i]]$widths[2:5]
  }
  maxwidth <- do.call(grid::unit.pmax, widths)
  for (i in 1:length(grobs)) {
    grobs[[i]]$widths[2:5] <- as.list(maxwidth)
  }
  plot <- gridExtra::grid.arrange(grobs[[1]], grobs[[2]], heights = c(400, 200))
  return(plot)
}

getPs2 <- function(connection,
                   dataFolder,
                   targetIds,
                   comparatorIds,
                   databaseId) {
  file <- sprintf("preference_score_dist_t%s_c%s.rds", targetIds, comparatorIds)
  ps <- readRDS(file.path(dataFolder, file))
  colnames(ps) <- SqlRender::snakeCaseToCamelCase(colnames(ps))
  ps <- ps[ps$databaseId == databaseId, ]
  return(ps)
}

plotPs2 <- function(ps,
                    targetName,
                    comparatorName,
                    legendLabel = TRUE) {
  if (legendLabel) {
    legendPosition <- "top"
  } else {
    legendPosition <- "none"
  }
  ps <- rbind(data.frame(x = ps$preferenceScore, y = ps$targetDensity, group = targetName),
              data.frame(x = ps$preferenceScore, y = ps$comparatorDensity, group = comparatorName))
  ps$group <- factor(ps$group, levels = c(as.character(targetName), as.character(comparatorName)))
  theme <- ggplot2::element_text(colour = "#000000", size = 25, margin = ggplot2::margin(0, 0.5, 0, 0.1, "cm"))
  plot <- ggplot2::ggplot(ps,
                          ggplot2::aes(x = x, y = y, color = group, group = group, fill = group)) +
    ggplot2::geom_density(stat = "identity") +
    ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5),
                                          rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5),
                                           rgb(0, 0, 0.8, alpha = 0.5))) +
    ggplot2::scale_x_continuous("Preference score", limits = c(0, 1)) +
    ggplot2::scale_y_continuous("Density") +
    ggplot2::theme(legend.title = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   legend.position = legendPosition,
                   legend.text = theme,
                   axis.text = theme,
                   axis.title = theme)
  return(plot)
}

getCovariateBalance2 <- function(connection,
                                 dataFolder,
                                 targetId,
                                 comparatorId,
                                 databaseId,
                                 analysisId,
                                 outcomeId = NULL) {
  # file <- sprintf("covariate_balance_t%s_c%s_%s.rds", targetId, comparatorId, databaseId)
  file <- sprintf("covariate_balance_t%s_c%s.rds", targetId, comparatorId)
  balance <- readRDS(file.path(dataFolder, file))
  colnames(balance) <- SqlRender::snakeCaseToCamelCase(colnames(balance))
  # balance <- balance[balance$analysisId == analysisId & balance$outcomeId == outcomeId, ]
  balance <- balance[balance$analysisId == analysisId & balance$outcomeId == outcomeId & balance$databaseId == databaseId, ]
  balance <- merge(balance, covariate[covariate$databaseId == databaseId, c("covariateId", "covariateAnalysisId", "covariateName")])
  balance <- balance[ c("covariateId",
                        "covariateName",
                        "covariateAnalysisId", 
                        "targetMeanBefore", 
                        "comparatorMeanBefore", 
                        "stdDiffBefore", 
                        "targetMeanAfter", 
                        "comparatorMeanAfter",
                        "stdDiffAfter")]
  colnames(balance) <- c("covariateId",
                         "covariateName",
                         "analysisId",
                         "beforeMatchingMeanTreated",
                         "beforeMatchingMeanComparator",
                         "beforeMatchingStdDiff",
                         "afterMatchingMeanTreated",
                         "afterMatchingMeanComparator",
                         "afterMatchingStdDiff")
  balance$absBeforeMatchingStdDiff <- abs(balance$beforeMatchingStdDiff)
  balance$absAfterMatchingStdDiff <- abs(balance$afterMatchingStdDiff)
  return(balance)
}

plotCovariateBalanceScatterPlot2 <- function(balance, 
                                             beforeLabel = "Before stratification",
                                             afterLabel = "After stratification") {
  limits <- c(min(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff),
                  na.rm = TRUE),
              max(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff),
                  na.rm = TRUE))
  theme <- ggplot2::element_text(colour = "#000000", size = 25)
  plot <- ggplot2::ggplot(balance, ggplot2::aes(x = absBeforeMatchingStdDiff, y = absAfterMatchingStdDiff)) +
    ggplot2::geom_point(color = rgb(0, 0, 0.8, alpha = 0.3), shape = 16, size = 4) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", size = 1.5, colour = rgb(0.8, 0, 0)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_vline(xintercept = 0) +
    ggplot2::scale_x_continuous(beforeLabel, limits = limits) +
    ggplot2::scale_y_continuous(afterLabel, limits = limits) +
    ggplot2::theme(text = theme)
  
  return(plot)
}

plotLargeScatter2 <- function(d,
                              xLabel) {
  d$Significant <- d$ci95Lb > 1 | d$ci95Ub < 1
  
  oneRow <- data.frame(nLabel = paste0(formatC(nrow(d), big.mark = ","), " estimates"),
                       meanLabel = paste0(formatC(100 *
                                                    mean(!d$Significant, na.rm = TRUE), digits = 1, format = "f"), "% of CIs includes 1"))
  
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- ggplot2::element_text(colour = "#000000", size = 25)
  themeRA <- ggplot2::element_text(colour = "#000000", size = 25, hjust = 1)
  themeLA <- ggplot2::element_text(colour = "#000000", size = 25, hjust = 0)
  
  alpha <- 1 - min(0.95 * (nrow(d)/50000)^0.1, 0.95)
  plot <- ggplot2::ggplot(d, ggplot2::aes(x = logRr, y = seLogRr)) +
    ggplot2::geom_vline(xintercept = log(breaks), colour = "#AAAAAA", lty = 1, size = 0.5) +
    ggplot2::geom_vline(xintercept = 0,
                        colour = "black",
                        lty = 1,
                        size = 1.5) +
    ggplot2::geom_abline(ggplot2::aes(intercept = 0, slope = 1/qnorm(0.025)),
                         colour = rgb(0.8, 0, 0),
                         linetype = "dashed",
                         size = 1.5,
                         alpha = 0.5) +
    ggplot2::geom_abline(ggplot2::aes(intercept = 0, slope = 1/qnorm(0.975)),
                         colour = rgb(0.8, 0, 0),
                         linetype = "dashed",
                         size = 1.5,
                         alpha = 0.5) +
    ggplot2::geom_point(size = 4, color = rgb(0, 0, 1, alpha = 0.05), alpha = alpha, shape = 16) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::scale_x_continuous(xLabel, limits = log(c(0.1,
                                                       10)), breaks = log(breaks), labels = breaks) +
    ggplot2::scale_y_continuous("Standard Error", limits = c(0, 1)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   #panel.background = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.text.y = themeRA,
                   axis.text.x = theme,
                   axis.title = theme,
                   legend.key = ggplot2::element_blank(),
                   strip.text.x = theme,
                   strip.background = ggplot2::element_blank(),
                   legend.position = "none")
  return(plot)
}

