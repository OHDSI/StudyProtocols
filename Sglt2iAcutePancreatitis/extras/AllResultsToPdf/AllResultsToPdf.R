# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AhasHfBkleAmputation
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

# Make sure to install:
# MikTex
# GhostScript
# R packages: knitr, rmarkdown, kableExtra

#library(devtools)
#devtools::install_version("rmarkdown", version = "1.8", repos = "http://cran.us.r-project.org")

# studyFolder <- "y:"
# packageFolder <- "x:"

studyFolder <- "D:/Studies/EPI534"
packageFolder <- "D:/epi_534"

appendixFolder <- file.path(studyFolder, "report", "appendixV4")
evidenceExplorerFolder <- file.path(packageFolder, "extras", "EvidenceExplorer") 
shinyDataFolder <- file.path(evidenceExplorerFolder, "data") 
# tempFolder <- "c:/Temp"
tempFolder <- "D:/Temp"

if (!file.exists(tempFolder))
  dir.create(tempFolder)
if (!file.exists(appendixFolder))
  dir.create(appendixFolder)

OhdsiRTools::addDefaultFileLogger(file.path(appendixFolder, "log.txt"))
wd <- setwd(evidenceExplorerFolder)
source("global.R")
setwd(wd)

# Appendix A -----------------------------------------------------------------------------------
convertToPdf <- function(appendixFolder, rmdFile) {
  wd <- setwd(appendixFolder)
  pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
  on.exit(setwd(wd))
  rmarkdown::render(rmdFile,
                    output_file = pdfFile,
                    rmarkdown::pdf_document(latex_engine = "pdflatex"))
}


mainColumns <- c("noCana", 
                 "metforminAddOn", 
                 "priorAP",
                 "timeAtRisk", 
                 "eventType",
                 "psStrategy",
                 "database",
                 "rr", 
                 "ci95lb",
                 "ci95ub",
                 "p",
                 "calP",
                 "targetId",
                 "comparatorId",
                 "outcomeId",
                 "analysisId")

mainColumnNames <- c("Remove Cana", 
                     "Metformin add on",
                     "Prior AP",
                     "Time at risk", 
                     "Event", 
                     "PS strategy",
                     "Data source",
                     "HR (95% CI)", 
                     "P",
                     "Cal. P",
                     "App.")


template <- SqlRender::readSql(file.path(packageFolder,"extras/AllResultsToPdf/hazardRatioTableTemplate.rmd"))

aNumber <- 1
bNumber <- 1
aAppendices <- data.frame()
bAppendices <- data.frame()


# overriding for requested order
comparisons <- c(
  "canagliflozin -  GLP-1 inhibitors",
  "canagliflozin -  DPP-4 inhibitors",
  "canagliflozin - Sulfonylurea",
  "canagliflozin - TZD",
  "canagliflozin - Insulin new users",
  "canagliflozin - Other AHA",
  "canagliflozin - Empagliflozin",
  "canagliflozin - Dapagliflozin",
  "canagliflozin - Alogliptin",
  "canagliflozin - Linagliptin",
  "canagliflozin - Saxagliptin",
  "canagliflozin - Sitagliptin",
  "canagliflozin - Albiglutide",
  "canagliflozin - Dulaglutide",
  "canagliflozin - Exenatide",
  "canagliflozin - Liraglutide",
  "canagliflozin - Lixisenatide",
  "canagliflozin - Pioglitazone",
  "canagliflozin - Rosiglitazone",
  "canagliflozin - Glyburide",
  "canagliflozin - Glimepiride",
  "canagliflozin - Glipizide",
  "canagliflozin - Acarbose",
  "canagliflozin - Bromocriptine",
  "canagliflozin - Miglitol",
  "canagliflozin - Nateglinide",
  "canagliflozin - Repaglinide"
)

formatHr <- function(hr, lb, ub) {
  ifelse (is.na(lb) | is.na(ub) | is.na(hr), "NA", sprintf(
    "%s (%s-%s)",
    formatC(hr, digits = 2, format = "f"),
    formatC(lb, digits = 2, format = "f"),
    formatC(ub, digits = 2, format = "f")
  )
  )
}

for (comparison in comparisons) {
  for (outcome in outcomes) {
    table <- resultsHois[resultsHois$comparison == comparison & resultsHois$outcomeName == outcome, mainColumns]
    table$dbOrder <- match(table$database, c("CCAE", "MDCR", "Optum"))
    table$timeAtRiskOrder <- match(table$timeAtRisk, c("On Treatment (30 Day)", 
                                                       "Intent to Treat", 
                                                       "On Treatment (0 Day)", 
                                                       "On Treatment (60 Day)"))
    table <- table[order(table$noCana,
                         table$metforminAddOn,
                         table$priorAP,
                         table$timeAtRiskOrder,
                         table$eventType,
                         table$psStrategy), ]
    table$dbOrder <- NULL
    table$timeAtRiskOrder <- NULL
    
    table$rr[table$rr > 100] <- NA
    table$ci95ub[table$ci95ub > 100] <- NA
    table$rr <- formatHr(table$rr, table$ci95lb, table$ci95ub)
    table$ci95lb <- NULL
    table$ci95ub <- NULL
    table$p <- formatC(table$p, digits = 2, format = "f")
    table$p <- gsub("NA", "", table$p)
    table$calP <- formatC(table$calP, digits = 2, format = "f")
    table$calP <- gsub("NA", "", table$calP)
    table$timeAtRisk[table$timeAtRisk == "Intent to Treat"] <- "ITT"
    table$eventType <- gsub("First", "1st", table$eventType)
    table$appendix <- sprintf("b%05d", bNumber:(bNumber + nrow(table) - 1))
    bAppendices <- rbind(bAppendices, data.frame(targetId = table$targetId,
                                                 comparatorId = table$comparatorId,
                                                 outcomeId = table$outcomeId,
                                                 analysisId = table$analysisId,
                                                 database = table$database, 
                                                 appendix = table$appendix))
    table$targetId <- NULL
    table$comparatorId <- NULL
    table$outcomeId <- NULL
    table$analysisId <- NULL
    colnames(table) <- mainColumnNames
    saveRDS(table, file.path(tempFolder, "temp.rds"))
    
    rmd <- template
    rmd <- gsub("%number%", sprintf("a%02d", aNumber), rmd)
    rmd <- gsub("%comparison%", gsub("GLP-1 inhibitors", "GLP-1 agonists", comparison), rmd)
    rmd <- gsub("%outcome%", outcome, rmd)
    rmd <- gsub("%tempFolder%", tempFolder, rmd)
    rmdFile <- sprintf("appendix-a%02d.Rmd", aNumber)
    sink(file.path(appendixFolder, rmdFile))
    writeLines(rmd)  
    sink()
    convertToPdf(appendixFolder, rmdFile)

    aNumber <- aNumber + 1
    bNumber <- bNumber + nrow(table)
    
    # Cleanup
    unlink(file.path(appendixFolder, rmdFile))
    unlink(list.files(tempFolder, pattern = "^temp"))
  }
}
saveRDS(bAppendices, file.path(appendixFolder, "bAppendices.rds"))

# Appendix B -----------------------------------------------------------------------------
bAppendices <- readRDS(file.path(appendixFolder, "bAppendices.rds"))

generateAppendixB <- function(i) {
  pdfFile <- sprintf("appendix-%s.pdf", bAppendices$appendix[i])
  if (!file.exists(file.path(appendixFolder, pdfFile))) { 
    OhdsiRTools::logInfo("Generating ", pdfFile)
    
    tempFolderI <- paste0(tempFolder, i)
    dir.create(tempFolderI)

    wd <- setwd(evidenceExplorerFolder)
    source("Table1.R")
    setwd(wd)
    
    convertToPdf <- function(appendixFolder, rmdFile) {
      wd <- setwd(appendixFolder)
      pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
      on.exit(setwd(wd))
      rmarkdown::render(rmdFile,
                        output_file = pdfFile,
                        rmarkdown::pdf_document(latex_engine = "pdflatex"))
    }
    
        
    row <- resultsHois[resultsHois$targetId == bAppendices$targetId[i] &
                       resultsHois$comparatorId == bAppendices$comparatorId[i] &
                       resultsHois$outcomeId == bAppendices$outcomeId[i] &
                       resultsHois$analysisId == bAppendices$analysisId[i] &
                       resultsHois$database == bAppendices$database[i], ]
    isMetaAnalysis <- F
    # Power table
    powerColumns <- c("treated",
                      "comparator",
                      "treatedDays",
                      "comparatorDays",
                      "eventsTreated",
                      "eventsComparator",
                      "irTreated",
                      "irComparator",
                      "mdrr")
    
    powerColumnNames <- c("Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "Target",
                          "Comparator",
                          "MDRR")
    table <- row
    table$irTreated <- formatC(1000 * table$eventsTreated / (table$treatedDays / 365.25), digits = 2, format = "f")
    table$irComparator <- formatC(1000 * table$eventsComparator / (table$comparatorDays / 365.25), digits = 2, format = "f")
    table$treated <- formatC(table$treated, big.mark = ",", format = "d")
    table$comparator <- formatC(table$comparator, big.mark = ",", format = "d")
    table$treatedDays <- formatC(table$treatedDays, big.mark = ",", format = "d")
    table$comparatorDays <- formatC(table$comparatorDays, big.mark = ",", format = "d")
    table$eventsTreated <- formatC(table$eventsTreated, big.mark = ",", format = "d")
    table$eventsComparator <- formatC(table$eventsComparator, big.mark = ",", format = "d")
    table$mdrr <- formatC(table$mdrr, digits = 2, format = "f")
    table <- table[, powerColumns]
    colnames(table) <- powerColumnNames

    saveRDS(table, file.path(tempFolderI, "tempPower.rds"))
    
    # Follow-up table
    if (!isMetaAnalysis) {
      table <- data.frame(Cohort = c("Target", "Comparator"),
                          Mean = formatC(c(row$tarTargetMean, row$tarComparatorMean), digits = 1, format = "f"),
                          SD = formatC(c(row$tarTargetSd, row$tarComparatorSd), digits = 1, format = "f"),
                          Min = formatC(c(row$tarTargetMin, row$tarComparatorMin), big.mark = ",", format = "d"),
                          P10 = formatC(c(row$tarTargetP10, row$tarComparatorP10), big.mark = ",", format = "d"),
                          P25 = formatC(c(row$tarTargetP25, row$tarComparatorP25), big.mark = ",", format = "d"),
                          Median = formatC(c(row$tarTargetMedian, row$tarComparatorMedian), big.mark = ",", format = "d"),
                          P75 = formatC(c(row$tarTargetP75, row$tarComparatorP75), big.mark = ",", format = "d"),
                          P90 = formatC(c(row$tarTargetP90, row$tarComparatorP90), big.mark = ",", format = "d"),
                          Max = formatC(c(row$tarTargetMax, row$tarComparatorMax), big.mark = ",", format = "d"))
      saveRDS(table, file.path(tempFolderI, "tempTar.rds"))
    }
    
    # Population characteristics
    if (!isMetaAnalysis) {
      fileName <- paste0("bal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
      
      if (!file.exists(file.path(shinyDataFolder, fileName))) {
        ParallelLogger::logError(paste("missing file: ", fileName))
        return();
      }
      
      bal  <- readRDS(file.path(shinyDataFolder, fileName))
      if ("beforeMatchingMeanTarget" %in% colnames(bal)) {
        colnames(bal)[colnames(bal) == "beforeMatchingMeanTarget"] <- "beforeMatchingMeanTreated"
        colnames(bal)[colnames(bal) == "beforeMatchingSumTarget"] <- "beforeMatchingSumTreated"
        colnames(bal)[colnames(bal) == "afterMatchingMeanTarget"] <- "afterMatchingMeanTreated"
        colnames(bal)[colnames(bal) == "afterMatchingSumTarget"] <- "afterMatchingSumTreated"
      }
      bal$beforeMatchingSumTreated <- NULL
      bal$afterMatchingSumTreated <- NULL
      bal <- merge(bal, covarNames)
      fileName <- paste0("ahaBal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
      if (!file.exists(file.path(shinyDataFolder, fileName))) {
        ParallelLogger::logError(paste("missing file: ", fileName))
        return();
      }
      
      priorAhaBalance  <- readRDS(file.path(shinyDataFolder, fileName))
      priorAhaBalance <- priorAhaBalance[, colnames(bal)]
      bal <- rbind(bal, priorAhaBalance)
      
      wd <- setwd(evidenceExplorerFolder)
      table <- prepareTable1(bal, 
                             beforeTargetPopSize = row$treatedBefore,
                             beforeComparatorPopSize = row$comparatorBefore,
                             afterTargetPopSize = row$treated,
                             afterComparatorPopSize = row$comparator,
                             beforeLabel = paste("Before", tolower(row$psStrategy)),
                             afterLabel = paste("After", tolower(row$psStrategy)))
      setwd(wd)
      table <- cbind(apply(table, 2, function(x) gsub("&nbsp;", " ", x)))
      colnames(table) <- table[2, ]
      table <- table[3:nrow(table), ]
      saveRDS(table, file.path(tempFolderI, "tempPopChar.rds"))
      
      fileName <- paste0("ps_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_",row$database,".rds")
      if (!file.exists(file.path(shinyDataFolder, fileName))) {
        ParallelLogger::logError(paste("missing file: ", fileName))
        return();
      }
      
      data <- readRDS(file.path(shinyDataFolder, fileName))
      data$GROUP <- row$targetDrug
      data$GROUP[data$treatment == 0] <- row$comparatorDrug
      data$GROUP <- factor(data$GROUP, levels = c(row$targetDrug, 
                                                  row$comparatorDrug))
      saveRDS(data, file.path(tempFolderI, "tempPs.rds"))
    }
    
    # Covariate balance
    if (!isMetaAnalysis) {
      fileName <- paste0("bal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
      if (!file.exists(file.path(shinyDataFolder, fileName))) {
        ParallelLogger::logError(paste("missing file: ", fileName))
        return();
      }
      
      bal  <- readRDS(file.path(shinyDataFolder, fileName))
      bal$absBeforeMatchingStdDiff <- abs(bal$beforeMatchingStdDiff)
      bal$absAfterMatchingStdDiff <- abs(bal$afterMatchingStdDiff)
      saveRDS(bal, file.path(tempFolderI, "tempBalance.rds"))
    }
    
    # Negative controls
    ncs <- resultsNcs[resultsNcs$targetId == row$targetId & 
                      resultsNcs$comparatorId == row$comparatorId & 
                      resultsNcs$analysisId == row$analysisId &
                      resultsNcs$database == row$database, ]
    saveRDS(ncs, file.path(tempFolderI, "tempNcs.rds"))
    
    # Kaplan Meier
    if (!isMetaAnalysis) {
      fileName <- paste0("km_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
      if (!file.exists(file.path(shinyDataFolder, fileName))) {
        ParallelLogger::logError(paste("missing file: ", fileName))
        return();
      }
      
      plot <- readRDS(file.path(shinyDataFolder, fileName))
      saveRDS(plot, file.path(tempFolderI, "tempKm.rds"))
    }
    
    template <- SqlRender::readSql("extras/AllResultsToPdf/detailsTemplate.rmd")
    rmd <- template
    rmd <- gsub("%tempFolder%", tempFolderI, rmd)
    rmd <- gsub("%number%", bAppendices$appendix[i], rmd)
    rmd <- gsub("%comparison%", gsub("GLP-1 inhibitors", "GLP-1 agonists", comparison), rmd)
    rmd <- gsub("%outcome%", row$outcomeName, rmd)
    rmd <- gsub("%target%", row$targetDrug, rmd)
    rmd <- gsub("%comparator%", row$comparatorDrug, rmd)
    rmd <- gsub("%psStrategy%", row$psStrategy, rmd)
    rmd <- gsub("%logRr%", if (is.na(row$logRr)) 999 else row$logRr, rmd)
    rmd <- gsub("%seLogRr%", if (is.na(row$seLogRr)) 999 else row$seLogRr, rmd)
    rmd <- gsub("%noCana%", row$noCana, rmd)
    rmd <- gsub("%metforminAddOn%", row$metforminAddOn, rmd)
    rmd <- gsub("%priorAP%", row$priorAP, rmd)
    rmd <- gsub("%timeAtRisk%", row$timeAtRisk, rmd)
    rmd <- gsub("%eventType%", row$eventType, rmd)
    rmd <- gsub("%psStrategy%", row$psStrategy, rmd)
    rmd <- gsub("%database%", row$database, rmd)
    rmd <- gsub("%isMetaAnalysis%", isMetaAnalysis, rmd)
    
    rmdFile <- sprintf("appendix-%s.Rmd", bAppendices$appendix[i])
    sink(file.path(appendixFolder, rmdFile))
    writeLines(rmd)  
    sink()
    convertToPdf(appendixFolder, rmdFile)
    
    # Cleanup
    unlink(file.path(appendixFolder, rmdFile))
    unlink(tempFolderI, recursive = TRUE)
  }
}

#nThreads <- parallel::detectCores() - 1
nThreads <- 1
cluster <- OhdsiRTools::makeCluster(nThreads)
setGlobalVars <- function(i, bAppendices, resultsHois, resultsNcs, covarNames, appendixFolder, tempFolder, evidenceExplorerFolder, shinyDataFolder){
  bAppendices <<- bAppendices
  resultsHois <<- resultsHois
  resultsNcs <<- resultsNcs
  covarNames <<- covarNames
  appendixFolder <<- appendixFolder
  shinyDataFolder <<- shinyDataFolder
  evidenceExplorerFolder <<- evidenceExplorerFolder
  tempFolder <<- tempFolder
}
n <- nrow(bAppendices)
if (nThreads > 1) {
  dummy <- OhdsiRTools::clusterApply(cluster = cluster, 
                                     x = 1:nThreads, 
                                     fun = setGlobalVars,  
                                     bAppendices = bAppendices, 
                                     resultsHois = resultsHois, 
                                     resultsNcs = resultsNcs,
                                     covarNames = covarNames,
                                     appendixFolder = appendixFolder,
                                     tempFolder = tempFolder,
                                     shinyDataFolder = shinyDataFolder)
  
  
  # when running clusterApply, the context of a function (in this case the global environment)
  # is also transmitted with every function call. Making sure it doesn't contain anything big:
  bAppendices <- NULL
  resultsHois <- NULL
  resultsNcs <- NULL
  covarNames <- NULL
  appendixFolder <- NULL
  heterogeneous <- NULL
  dummy <- NULL
}
dummy <- OhdsiRTools::clusterApply(cluster = cluster, 
                          x = 1:n, 
                          fun = generateAppendixB)

OhdsiRTools::stopCluster(cluster)

# Post processing using GhostScript -------------------------------------------------------------
gsPath <- "\"C:/Program Files/gs/gs9.23/bin/gswin64.exe\""

tempFolder <- file.path(appendixFolder, "optimized")
if (!file.exists(tempFolder))
  dir.create(tempFolder)
files <- list.files(appendixFolder, pattern = ".*\\.pdf", recursive = FALSE)

for (fileName in files) {
  args <- "-dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dFastWebView -sOutputFile=%s %s %s"
  command <- paste(gsPath, sprintf(args, file.path(tempFolder, fileName), file.path(appendixFolder, fileName), file.path(getwd(), "extras/AllResultsToPdf/pdfmarks")))
  shell(command)
}

unlink(file.path(appendixFolder, files))

file.rename(from = file.path(tempFolder, files), to = file.path(appendixFolder, files))

unlink(tempFolder, recursive = TRUE)
