blind <- FALSE
dataLocation <- "S:/StudyResults/epi_534/shinyData"

resultsFileNames <- list.files(path = dataLocation, pattern = "resultsHois_.*.rds", full.names = TRUE)
ncsFileNames <- list.files(path = dataLocation, pattern = "resultsNcs_.*.rds", full.names = TRUE)
covarsFileNames <- list.files(path = dataLocation, pattern = "covarNames_.*.rds", full.names = TRUE)

# nonDiagFileNames <- c(resultsFileNames, ncsFileNames, covarsFileNames)
# diagFileNames <- list.files(path = dataLocation, full.names = TRUE)
# diagFileNames <- setdiff(diagFileNames, nonDiagFileNames)

# atcs <- data.frame()
# for (i in 1:length(diagFileNames)) {
#   atc <- data.frame(analysisId = NA, targetId = NA, comparatorId = NA)
#   ids <- gsub("^.*_a", "", diagFileNames[i])
#   atc$analysisId <- as.numeric(gsub("_t.*", "", ids))
#   ids <- gsub("^.*_t", "", ids)
#   atc$targetId <- as.numeric(gsub("_c.*", "", ids))
#   ids <- gsub("^.*_c", "", ids)
#   atc$comparatorId <- as.numeric(gsub("_[[:alpha:]].*$", "", ids))
#   atcs <- rbind(atcs, atc)
# }
# atcs <- unique(atcs)

resultsHois <- lapply(resultsFileNames, readRDS)
allColumns <- unique(unlist(lapply(resultsHois, colnames)))
addMissingColumns <- function(results) {
  presentCols <- colnames(results)
  missingCols <- allColumns[!(allColumns %in% presentCols)]
  for (missingCol in missingCols) {
    results[, missingCol] <- rep(NA, nrow(results))
  }
  return(results)
}
resultsHois <- lapply(resultsHois, addMissingColumns)
resultsHois <- do.call(rbind, resultsHois)

atcs <- read.csv("atcs.csv")
resultsHois <- merge(resultsHois, atcs)

# clarify naming ---------------------------------------------------------------

resultsHois[resultsHois$targetDrug == "canagliflozin", ]$targetDrug <- "Canagliflozin"
resultsHois[resultsHois$comparatorDrug == " DPP-4 inhibitors", ]$comparatorDrug <- "DPP-4 inhibitors"
resultsHois[resultsHois$comparatorDrug == " GLP-1 inhibitors", ]$comparatorDrug <- "GLP-1 agonists"

resultsHois[resultsHois$eventType == "First EVer Event" | resultsHois$eventType == "First Ever Event", ]$eventType <- "First ever event"
resultsHois[resultsHois$eventType == "First Post Index Event", ]$eventType <- "First post index event"

resultsHois[resultsHois$timeAtRisk == "On Treatment", ]$timeAtRisk <- "On treatment (+ 30 days)"
resultsHois[resultsHois$timeAtRisk == "Per Protocol Zero Day", ]$timeAtRisk <- "On treatment (+ 0 days)"
resultsHois[resultsHois$timeAtRisk == "Per Protocol Sixty Day", ]$timeAtRisk <- "On treatment (+ 60 days)"
resultsHois[resultsHois$timeAtRisk == "Intent to Treat", ]$timeAtRisk <- "Intent to treat"
#resultsHois[resultsHois$timeAtRisk == "Per Protocol Zero Day (no censor at switch)", ]$timeAtRisk <- "On Treatment (0 Day)"
#resultsHois[resultsHois$timeAtRisk == "On Treatment (no censor at switch)", ]$timeAtRisk <- "On Treatment (30 Day)"
#resultsHois[resultsHois$timeAtRisk == "Per Protocol Sixty Day (no censor at switch)", ]$timeAtRisk <- "On Treatment (60 Day)"

resultsHois[resultsHois$psStrategy == "Matching", ]$psStrategy <- "Matching 0.2 caliper"
resultsHois[resultsHois$psStrategy == "Matching 0.1 Caliper", ]$psStrategy <- "Matching 0.1 caliper"
resultsHois[resultsHois$psStrategy == "Stratification", ]$psStrategy <- "Stratification (deciles)"

# create additional filter variables -------------------------------------------
resultsHois$noCana <- with(resultsHois, ifelse(grepl("no cana", comparatorName), "No comparator exposure ever", "No restriction"))
#resultsHois$noCensor <- with(resultsHois, ifelse(grepl("no censoring", comparatorName), TRUE, FALSE))

resultsHois$metforminAddOn <- "Not required"
resultsHois[resultsHois$comparatorId > 1000000 & resultsHois$comparatorId < 2000000, ]$metforminAddOn <- "Required"

resultsHois$priorAP <- FALSE
resultsHois[resultsHois$comparatorId > 2000000, ]$priorAP <- TRUE
resultsHois <- resultsHois[resultsHois$priorAP == FALSE, ]

# these sensitivity analyses were all using restricted cana cohorts
# because "no cana" wasn't in the names of the cohort the earlier flag wasn't set properly
resultsHois[resultsHois$comparatorId > 1000000, ]$noCana <- "No comparator exposure ever"
#resultsHois[resultsHois$comparatorId > 1000000, ]$noCensor <- FALSE
#resultsHois <- resultsHois[resultsHois$noCensor == FALSE, ]

resultsNcs <- lapply(ncsFileNames, readRDS)
resultsNcs <- do.call(rbind, resultsNcs)
resultsNcs <- merge(resultsNcs, atcs)

covarNames <- lapply(covarsFileNames, readRDS)
covarNames <- do.call(rbind, covarNames)
covarNames <- unique(covarNames)

resultsHois$comparison <- paste(resultsHois$targetDrug, resultsHois$comparatorDrug, sep = " vs. ")
comparisons <- unique(resultsHois$comparison)
comparisonsOrder <- match(comparisons, c("Canagliflozin vs. GLP-1 agonists",
                                         "Canagliflozin vs. DPP-4 inhibitors",
                                         "Canagliflozin vs. Sulfonylurea",
                                         "Canagliflozin vs. TZD",
                                         "Canagliflozin vs. Insulin new users",
                                         "Canagliflozin vs. Other AHA",
                                         "Canagliflozin vs. Albiglutide",
                                         "Canagliflozin vs. Dulaglutide",
                                         "Canagliflozin vs. Exenatide",
                                         "Canagliflozin vs. Liraglutide",
                                         "Canagliflozin vs. Lixisenatide",
                                         "Canagliflozin vs. Alogliptin",
                                         "Canagliflozin vs. Linagliptin",
                                         "Canagliflozin vs. Saxagliptin",
                                         "Canagliflozin vs. Sitagliptin",
                                         "Canagliflozin vs. Glipizide",
                                         "Canagliflozin vs. Glyburide",
                                         "Canagliflozin vs. Glimepiride",
                                         "Canagliflozin vs. Pioglitazone",
                                         "Canagliflozin vs. Rosiglitazone", 
                                         "Canagliflozin vs. Acarbose",
                                         "Canagliflozin vs. Bromocriptine",
                                         "Canagliflozin vs. Miglitol",
                                         "Canagliflozin vs. Nateglinide",      
                                         "Canagliflozin vs. Repaglinide", 
                                         "Canagliflozin vs. Dapagliflozin",
                                         "Canagliflozin vs. Empagliflozin"))
comparisons <- comparisons[order(comparisonsOrder)]
outcomes <- unique(resultsHois$outcomeName)

eventTypes <- unique(resultsHois$eventType)
eventTypesOrder <- match(eventTypes, c("First post index event",
                                       "First ever event"))
eventTypes <- eventTypes[order(eventTypesOrder)]

timeAtRisks <- unique(resultsHois$timeAtRisk)
timeAtRisksOrder <- match(timeAtRisks, c("On treatment (+ 30 days)",
                                         "Intent to treat",
                                         'On treatment (+ 0 days)',
                                         "On treatment (+ 60 days)"))
timeAtRisks <- timeAtRisks[order(timeAtRisksOrder)]
psStrategies <- unique(resultsHois$psStrategy)
canaFilters <- unique(resultsHois$noCana)
#censorFilters <- unique(resultsHois$noCensor)
metforminAddOns <- unique(resultsHois$metforminAddOn)
metforminAddOnsOrder <- match(metforminAddOns, c("Not required", "Required"))
metforminAddOns <- metforminAddOns[order(metforminAddOnsOrder)]
dbs <- unique(resultsHois$database)

#priorAPs <- unique(resultsHois$priorAP)

