# # studyFolder <- "D:/Studies/EPI534"
# # appendixFolder <- file.path(studyFolder, "report", "appendix")
# # shinyDataFolder <- file.path(getwd(), "extras", "EvidenceExplorer", "data")
# # tempFolder <- "D:/FFTemp"
# # 
# # if (!file.exists(tempFolder))
# #   dir.create(tempFolder)
# # if (!file.exists(appendixFolder))
# #   dir.create(appendixFolder)
# # 
# # OhdsiRTools::addDefaultFileLogger(file.path(appendixFolder, "log.txt"))
# # wd <- setwd("extras/EvidenceExplorer")
# # source("global.R")
# # setwd(wd)
# # 
# # # Appendix A -----------------------------------------------------------------------------------
# # convertToPdf <- function(appendixFolder, rmdFile) {
# #   wd <- setwd(appendixFolder)
# #   pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
# #   on.exit(setwd(wd))
# #   rmarkdown::render(rmdFile,
# #                     output_file = pdfFile,
# #                     rmarkdown::pdf_document(latex_engine = "pdflatex"))
# # }
# # 
# # 
# # # YOU ARE HERE - MUST CONVERT FROM HERE DOWN :)
# mainColumns <- c("timeAtRisk", 
#                  "eventType",
#                  "psStrategy",
#                  "database",
#                  "noCana",
#                  "noCensor",
#                  "priorAP",
#                  "metforminAddOn",
#                  "rr", 
#                  "ci95lb",
#                  "ci95ub",
#                  "p",
#                  "calP")
# 
# mainColumnNames <- c("Time at Risk", 
#                      "Event Type",
#                      "Propensity Score Strategy",
#                      "Database",
#                      "Cana",
#                      "Censoring",
#                      "Prior AP",
#                      "Metformin Add On",
#                      "CI95 LB",
#                      "CI95 UB",
#                      "P",
#                      "Cal. P"
#                      )
# 
# template <- SqlRender::readSql("extras/AllResultsToPdf/hazardRatioTableTemplate.rmd")
# # 
# # 
# # comparison <- comparisons[1]
# # outcome <- outcomes[1]
# # database <- dbs[1]
# # aNumber <- 1
# # bNumber <- 1
# # aAppendices <- data.frame()
# # bAppendices <- data.frame()
# # for (comparison in comparisons) {
# #   for (outcome in outcomes) {
# #     table <- resultsHois[resultsHois$comparison == comparison & resultsHois$outcomeName == outcome, mainColumns]
# #     table$dbOrder <- match(table$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis (HKSJ)", "Meta-analysis (DL)"))
# #     table$timeAtRiskOrder <- match(table$timeAtRisk, c("On Treatment", 
# #                                                        "On Treatment (no censor at switch)", 
# #                                                        "Lag", 
# #                                                        "Lag (no censor at switch)",
# #                                                        "Intent to Treat", 
# #                                                        "Modified ITT"))
# #     table <- table[order(table$establishedCvd,
# #                          table$priorExposure,
# #                          table$timeAtRiskOrder,
# #                          table$evenType,
# #                          table$psStrategy,
# #                          table$dbOrder), ]
# #     table$dbOrder <- NULL
# #     table$timeAtRiskOrder <- NULL
# #     
# #     table$rr[table$rr > 100] <- NA
# #     table$ci95ub[table$ci95ub > 100] <- NA
# #     table$rr <- sprintf("%.2f (%.2f - %.2f)", table$rr, table$ci95lb, table$ci95ub)
# #     table$ci95lb <- NULL
# #     table$ci95ub <- NULL
# #     # table$rr <- formatC(table$rr, digits = 2, format = "f")
# #     # table$rr <- gsub("NA", "", table$rr)
# #     # table$ci95lb <- formatC(table$ci95lb, digits = 2, format = "f")
# #     # table$ci95lb <- gsub("NA", "", table$ci95lb)
# #     # table$ci95ub <- formatC(table$ci95ub, digits = 2, format = "f")
# #     # table$ci95ub <- gsub("NA", "", table$ci95ub)
# #     table$p <- formatC(table$p, digits = 2, format = "f")
# #     table$p <- gsub("NA", "", table$p)
# #     table$calP <- formatC(table$calP, digits = 2, format = "f")
# #     table$calP <- gsub("NA", "", table$calP)
# #     table$timeAtRisk[table$timeAtRisk == "Intent to Treat"] <- "ITT"
# #     table$evenType <- gsub("First", "1st", table$evenType)
# #     table$priorExposure <- gsub("at least 1", ">= 1", table$priorExposure)
# #     table$priorExposure <- gsub("exposure$", "", table$priorExposure)
# #     table$appendix <- sprintf("B%05d", bNumber:(bNumber + nrow(table) - 1))
# #     bAppendices <- rbind(bAppendices, data.frame(targetId = table$targetId,
# #                                                  comparatorId = table$comparatorId,
# #                                                  outcomeId = table$outcomeId,
# #                                                  analysisId = table$analysisId,
# #                                                  database = table$database, 
# #                                                  appendix = table$appendix))
# #     table$targetId <- NULL
# #     table$comparatorId <- NULL
# #     table$outcomeId <- NULL
# #     table$analysisId <- NULL
# #     colnames(table) <- mainColumnNames
# #     # table <- table[1:100, ] 
# #     saveRDS(table, file.path(tempFolder, "temp.rds"))
# #     
# #     rmd <- template
# #     rmd <- gsub("%number%", sprintf("A%02d", aNumber), rmd)
# #     rmd <- gsub("%comparison%", comparison, rmd)
# #     rmd <- gsub("%outcome%", outcome, rmd)
# #     rmdFile <- sprintf("AppendixA%02d.Rmd", aNumber)
# #     sink(file.path(appendixFolder, rmdFile))
# #     writeLines(rmd)  
# #     sink()
# #     convertToPdf(appendixFolder, rmdFile)
# #     
# #     
# #     aNumber <- aNumber + 1
# #     bNumber <- bNumber + nrow(table)
# #     
# #     # Cleanup
# #     unlink(file.path(appendixFolder, rmdFile))
# #     unlink(list.files(tempFolder, pattern = "^temp"))
# #   }
# # }
# # saveRDS(bAppendices, file.path(appendixFolder, "bAppendices.rds"))
# # 
# # 
# # # Appendix B -----------------------------------------------------------------------------
# # bAppendices <- readRDS(file.path(appendixFolder, "bAppendices.rds"))
# # 
# # i = 544
# # i = 2
# # # for (i in 1:nrow(bAppendices)) { 
# # generateAppendixB <- function(i) {
# #   pdfFile <- sprintf("Appendix%s.pdf", bAppendices$appendix[i])
# #   if (!file.exists(file.path(appendixFolder, pdfFile))) { 
# #     OhdsiRTools::logInfo("Generating ", pdfFile)
# #     
# #     tempFolder <- paste0("s:/temp/cana",i)
# #     dir.create(tempFolder)
# #     
# #     wd <- setwd("extras/EvidenceExplorer")
# #     source("Table1.R")
# #     setwd(wd)
# #     
# #     convertToPdf <- function(appendixFolder, rmdFile) {
# #       wd <- setwd(appendixFolder)
# #       pdfFile <- gsub(".Rmd$", ".pdf", rmdFile)
# #       on.exit(setwd(wd))
# #       rmarkdown::render(rmdFile,
# #                         output_file = pdfFile,
# #                         rmarkdown::pdf_document(latex_engine = "pdflatex"))
# #     }
# #     
# #     
# #     row <- resultsHois[resultsHois$targetId == bAppendices$targetId[i] &
# #                          resultsHois$comparatorId == bAppendices$comparatorId[i] &
# #                          resultsHois$outcomeId == bAppendices$outcomeId[i] &
# #                          resultsHois$analysisId == bAppendices$analysisId[i] &
# #                          resultsHois$database == bAppendices$database[i], ]
# #     isMetaAnalysis <- row$database == "Meta-analysis (HKSJ)" || row$database == "Meta-analysis (DL)"
# #     
# #     # Power table
# #     powerColumns <- c("treated",
# #                       "comparator",
# #                       "treatedDays",
# #                       "comparatorDays",
# #                       "eventsTreated",
# #                       "eventsComparator",
# #                       "irTreated",
# #                       "irComparator",
# #                       "mdrr")
# #     
# #     powerColumnNames <- c("Target",
# #                           "Comparator",
# #                           "Target",
# #                           "Comparator",
# #                           "Target",
# #                           "Comparator",
# #                           "Target",
# #                           "Comparator",
# #                           "MDRR")
# #     table <- row
# #     table$irTreated <- formatC(1000 * table$eventsTreated / (table$treatedDays / 365.25), digits = 2, format = "f")
# #     table$irComparator <- formatC(1000 * table$eventsComparator / (table$comparatorDays / 365.25), digits = 2, format = "f")
# #     table$treated <- formatC(table$treated, big.mark = ",", format = "d")
# #     table$comparator <- formatC(table$comparator, big.mark = ",", format = "d")
# #     table$treatedDays <- formatC(table$treatedDays, big.mark = ",", format = "d")
# #     table$comparatorDays <- formatC(table$comparatorDays, big.mark = ",", format = "d")
# #     table$eventsTreated <- formatC(table$eventsTreated, big.mark = ",", format = "d")
# #     table$eventsComparator <- formatC(table$eventsComparator, big.mark = ",", format = "d")
# #     table$mdrr <- formatC(table$mdrr, digits = 2, format = "f")
# #     if (table$database == "Meta-analysis (HKSJ)" || table$database == "Meta-analysis (DL)") {
# #       table <- table[, c(powerColumns, "i2")]
# #       colnames(table) <- c(powerColumnNames, "I2")
# #     } else {
# #       table <- table[, powerColumns]
# #       colnames(table) <- powerColumnNames
# #     }
# #     saveRDS(table, file.path(tempFolder, "tempPower.rds"))
# #     
# #     # Follow-up table
# #     if (!isMetaAnalysis) {
# #       table <- data.frame(Cohort = c("Target", "Comparator"),
# #                           Mean = formatC(c(row$tarTargetMean, row$tarComparatorMean), digits = 1, format = "f"),
# #                           SD = formatC(c(row$tarTargetSd, row$tarComparatorSd), digits = 1, format = "f"),
# #                           Min = formatC(c(row$tarTargetMin, row$tarComparatorMin), big.mark = ",", format = "d"),
# #                           P10 = formatC(c(row$tarTargetP10, row$tarComparatorP10), big.mark = ",", format = "d"),
# #                           P25 = formatC(c(row$tarTargetP25, row$tarComparatorP25), big.mark = ",", format = "d"),
# #                           Median = formatC(c(row$tarTargetMedian, row$tarComparatorMedian), big.mark = ",", format = "d"),
# #                           P75 = formatC(c(row$tarTargetP75, row$tarComparatorP75), big.mark = ",", format = "d"),
# #                           P90 = formatC(c(row$tarTargetP90, row$tarComparatorP90), big.mark = ",", format = "d"),
# #                           Max = formatC(c(row$tarTargetMax, row$tarComparatorMax), big.mark = ",", format = "d"))
# #       saveRDS(table, file.path(tempFolder, "tempTar.rds"))
# #     }
# #     
# #     # Population characteristics
# #     if (!isMetaAnalysis) {
# #       fileName <- paste0("bal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
# #       bal  <- readRDS(file.path(shinyDataFolder, fileName))
# #       bal$absBeforeMatchingStdDiff <- abs(bal$beforeMatchingStdDiff)
# #       bal$absAfterMatchingStdDiff <- abs(bal$afterMatchingStdDiff)
# #       bal <- merge(bal, covarNames)
# #       fileName <- paste0("ahaBal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
# #       priorAhaBalance  <- readRDS(file.path(shinyDataFolder, fileName))
# #       bal$absBeforeMatchingStdDiff <- NULL
# #       bal$absAfterMatchingStdDiff <- NULL
# #       priorAhaBalance <- priorAhaBalance[, colnames(bal)]
# #       bal <- rbind(bal, priorAhaBalance)
# #       bal$covariateName <- gsub("hospitalizations for heart failure .primary inpatient diagnosis.$", "Hospitalizations for heart failure", bal$covariateName)
# #       bal$covariateName <- gsub("Below Knee Lower Extremity Amputation events$", "Below knee lower extremity amputation", bal$covariateName)
# #       bal$covariateName <- gsub("Neurologic disorder associated with diabetes mellitus$", "Neurologic disorder associated with diabetes", bal$covariateName)
# #       bal$covariateName <- gsub("PSYCHOSTIMULANTS, AGENTS USED FOR ADHD AND NOOTROPICS", "Psychostimulants, agents for adhd & nootropics", bal$covariateName)
# #       
# #       # which(grepl("AGENTS USED FOR ADHD", bal$covariateName))
# #       
# #       wd <- setwd("extras/EvidenceExplorer")
# #       table <- prepareTable1(bal, 
# #                              beforeTargetPopSize = row$treatedBefore,
# #                              beforeComparatorPopSize = row$comparatorBefore,
# #                              afterTargetPopSize = row$treated,
# #                              afterComparatorPopSize = row$comparator,
# #                              beforeLabel = paste("Before", tolower(row$psStrategy)),
# #                              afterLabel = paste("After", tolower(row$psStrategy)))
# #       setwd(wd)
# #       table <- cbind(apply(table, 2, function(x) gsub("&nbsp;", " ", x)))
# #       colnames(table) <- table[2, ]
# #       table <- table[3:nrow(table), ]
# #       saveRDS(table, file.path(tempFolder, "tempPopChar.rds"))
# #       
# #       fileName <- paste0("ps_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_",row$database,".rds")
# #       data <- readRDS(file.path(shinyDataFolder, fileName))
# #       data$GROUP <- row$targetDrug
# #       data$GROUP[data$treatment == 0] <- row$comparatorDrug
# #       data$GROUP <- factor(data$GROUP, levels = c(row$targetDrug, 
# #                                                   row$comparatorDrug))
# #       saveRDS(data, file.path(tempFolder, "tempPs.rds"))
# #     }
# #     
# #     # Covariate balance
# #     if (!isMetaAnalysis) {
# #       fileName <- paste0("bal_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
# #       bal  <- readRDS(file.path(shinyDataFolder, fileName))
# #       bal$absBeforeMatchingStdDiff <- abs(bal$beforeMatchingStdDiff)
# #       bal$absAfterMatchingStdDiff <- abs(bal$afterMatchingStdDiff)
# #       saveRDS(bal, file.path(tempFolder, "tempBalance.rds"))
# #     }
# #     
# #     # Negative controls
# #     ncs <- resultsNcs[resultsNcs$targetId == row$targetId & 
# #                         resultsNcs$comparatorId == row$comparatorId & 
# #                         resultsNcs$analysisId == row$analysisId &
# #                         resultsNcs$database == row$database, ]
# #     saveRDS(ncs, file.path(tempFolder, "tempNcs.rds"))
# #     
# #     # Kaplan Meier
# #     if (!isMetaAnalysis) {
# #       fileName <- paste0("km_a",row$analysisId,"_t",row$targetId,"_c",row$comparatorId,"_o",row$outcomeId,"_",row$database,".rds")
# #       plot <- readRDS(file.path(shinyDataFolder, fileName))
# #       saveRDS(plot, file.path(tempFolder, "tempKm.rds"))
# #     }
# #     
# #     template <- SqlRender::readSql("extras/AllResultsToPdf/detailsTemplate.rmd")
# #     rmd <- template
# #     rmd <- gsub("%tempFolder%", tempFolder, rmd)
# #     rmd <- gsub("%number%", bAppendices$appendix[i], rmd)
# #     rmd <- gsub("%comparison%", row$comparison, rmd)
# #     rmd <- gsub("%outcome%", row$outcomeName, rmd)
# #     rmd <- gsub("%target%", row$targetDrug, rmd)
# #     rmd <- gsub("%comparator%", row$comparatorDrug, rmd)
# #     rmd <- gsub("%psStrategy%", row$psStrategy, rmd)
# #     rmd <- gsub("%logRr%", if (is.na(row$logRr)) 999 else row$logRr, rmd)
# #     rmd <- gsub("%seLogRr%", if (is.na(row$seLogRr)) 999 else row$seLogRr, rmd)
# #     rmd <- gsub("%cvd%", row$establishedCvd, rmd)
# #     rmd <- gsub("%priorExposure%", row$priorExposure, rmd)
# #     rmd <- gsub("%timeAtRisk%", row$timeAtRisk, rmd)
# #     rmd <- gsub("%eventType%", row$evenType, rmd)
# #     rmd <- gsub("%psStrategy%", row$psStrategy, rmd)
# #     rmd <- gsub("%database%", row$database, rmd)
# #     rmd <- gsub("%isMetaAnalysis%", isMetaAnalysis, rmd)
# #     
# #     rmdFile <- sprintf("Appendix%s.Rmd", bAppendices$appendix[i])
# #     sink(file.path(appendixFolder, rmdFile))
# #     writeLines(rmd)  
# #     sink()
# #     convertToPdf(appendixFolder, rmdFile)
# #     
# #     # Cleanup
# #     unlink(file.path(appendixFolder, rmdFile))
# #     # unlink(list.files(tempFolder, pattern = "^temp"))
# #     unlink(tempFolder, recursive = TRUE)
# #   }
# # }
# # #bAppendices <- readRDS(file.path(appendixFolder, "bAppendices.rds"))
# # 
# # 
# # nThreads <- 15
# # cluster <- OhdsiRTools::makeCluster(nThreads)
# # setGlobalVars <- function(i, bAppendices, resultsHois, resultsNcs, covarNames, appendixFolder, shinyDataFolder){
# #   bAppendices <<- bAppendices
# #   resultsHois <<- resultsHois
# #   resultsNcs <<- resultsNcs
# #   covarNames <<- covarNames
# #   appendixFolder <<- appendixFolder
# #   shinyDataFolder <<- shinyDataFolder
# # }
# # dummy <- OhdsiRTools::clusterApply(cluster = cluster, 
# #                                    x = 1:nThreads, 
# #                                    fun = setGlobalVars,  
# #                                    bAppendices = bAppendices, 
# #                                    resultsHois = resultsHois, 
# #                                    resultsNcs = resultsNcs,
# #                                    covarNames = covarNames,
# #                                    appendixFolder = appendixFolder,
# #                                    shinyDataFolder = shinyDataFolder)
# # n <- nrow(bAppendices)
# # # when running clusterApply, the context of a function (in this case the global environment)
# # # is also transmitted with every function call. Making sure it doesn't contain anything big:
# # bAppendices <- NULL
# # resultsHois <- NULL
# # resultsNcs <- NULL
# # covarNames <- NULL
# # appendixFolder <- NULL
# # heterogeneous <- NULL
# # dummy <- NULL
# # 
# # dummy <- OhdsiRTools::clusterApply(cluster = cluster, 
# #                                    x = 1:n, 
# #                                    fun = generateAppendixB)
# # 
# # OhdsiRTools::stopCluster(cluster)
# # 
# # # Post processing using GhostScript -------------------------------------------------------------
# # gsPath <- "\"C:/Program Files/gs/gs9.23/bin/gswin64.exe\""
# # studyFolder <- "r:/AhasHfBkleAmputation"
# # appendixFolder <- file.path(studyFolder, "report", "appendix")
# # tempFolder <- file.path(appendixFolder, "optimized")
# # if (!file.exists(tempFolder))
# #   dir.create(tempFolder)
# # 
# # fileName <- "AppendixA01.pdf"
# # fileName <- "AppendixB00001.pdf"
# # files <- list.files(appendixFolder, pattern = ".*\\.pdf", recursive = FALSE)
# # 
# # for (fileName in files) {
# #   args <- "-dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dFastWebView -sOutputFile=%s %s %s"
# #   command <- paste(gsPath, sprintf(args, file.path(tempFolder, fileName), file.path(appendixFolder, fileName), file.path(getwd(), "extras/AllResultsToPdf/pdfmarks")))
# #   shell(command)
# # }
# # 
# # unlink(file.path(appendixFolder, files))
# # 
# # file.rename(from = file.path(tempFolder, files), to = file.path(appendixFolder, files))
# # 
# # unlink(tempFolder, recursive = TRUE)