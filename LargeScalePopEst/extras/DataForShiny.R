dataFolder <- "S:/Temp/ShinyApp/data"

# Some-by-some data -------------------------------------------------------

calibrated <- read.csv("r:/DepressionResults.csv")

normName <- function(name) {
    return(gsub(" ", "_", tolower(name)))
}

# Full data overview:
d <- calibrated[calibrated$analysisId == 3, ]
fullSet <- d[d$outcomeType == "hoi", c("targetName", "comparatorName", "outcomeName", "db", "calLogRr", "calSeLogRr", "calRr", "calCi95lb", "calCi95ub")]
colnames(fullSet)[colnames(fullSet) == "calLogRr"] <- "logRr"
colnames(fullSet)[colnames(fullSet) == "calSeLogRr"] <- "seLogRr"
colnames(fullSet)[colnames(fullSet) == "calRr"] <- "rr"
colnames(fullSet)[colnames(fullSet) == "calCi95lb"] <- "ci95lb"
colnames(fullSet)[colnames(fullSet) == "calCi95ub"] <- "ci95ub"
saveRDS(fullSet, file.path(dataFolder, normName("fullset.rds")))

# Data per target-comparator:
tcs <- unique(d[, c("targetId", "comparatorId")])
for (i in 1:nrow(tcs)) {
    tc <- tcs[i,]

    # Main analysis:
    subset <- d[d$targetId == tc$targetId & d$comparatorId == tc$comparatorId & d$outcomeType == "hoi", ]
    targetName <- subset$targetName[1]
    comparatorName <- subset$comparatorName[1]
    subset$targetName <- NULL
    subset$targetId <- NULL
    subset$comparatorName <- NULL
    subset$outcomeId <- NULL
    subset$comparatorId <- NULL
    subset$analysisId <- NULL
    subset$outcomeType <- NULL
    subset$trueRr <- NULL
    fileName <- file.path(dataFolder, normName(paste0("est_", targetName, "_", comparatorName, ".rds")))
    saveRDS(subset, normName(fileName))

    # Sensitivity analysis:
    subset <- calibrated[calibrated$analysisId == 4 & calibrated$targetId == tc$targetId & calibrated$comparatorId == tc$comparatorId & calibrated$outcomeType == "hoi", ]
    targetName <- subset$targetName[1]
    comparatorName <- subset$comparatorName[1]
    subset$targetName <- NULL
    subset$targetId <- NULL
    subset$comparatorName <- NULL
    subset$outcomeId <- NULL
    subset$comparatorId <- NULL
    subset$analysisId <- NULL
    subset$outcomeType <- NULL
    subset$trueRr <- NULL
    fileName <- file.path(dataFolder, normName(paste0("sens_", targetName, "_", comparatorName, ".rds")))
    saveRDS(subset, normName(fileName))
}

# Data per target-comparator-database:
source("extras/SharedPlots.R")
dbs <- unique(d$db)
for (db in dbs) {
    omr <- readRDS(file.path(paste0("R:/PopEstDepression_", db), "cmOutput", "outcomeModelReference.rds"))
    omr <- omr[omr$analysisId == 3, ]
    tcs <- unique(d[d$db == db, c("targetId", "targetName", "comparatorId", "comparatorName")])
    omr <- merge(omr, tcs)
    tcs <- unique(omr[, c("targetId", "targetName", "comparatorId", "comparatorName")])
    for (i in 1:nrow(tcs)) {
        tc <- tcs[i,]

        omrRow <- omr[omr$targetId == tc$targetId & omr$comparatorId == tc$comparatorId,]

        tcData <- list()
        ctData <- list()

        ### PS plot ###
        psFile <- omrRow$sharedPsFile[1]
        psFile <- sub("^[sS]:/", "r:/", psFile)
        ps <- readRDS(psFile)
        if (min(ps$propensityScore) < max(ps$propensityScore)) {
            ps <- CohortMethod:::computePreferenceScore(ps)

            d1 <- density(ps$preferenceScore[ps$treatment == 1], from = 0, to = 1, n = 100)
            d0 <- density(ps$preferenceScore[ps$treatment == 0], from = 0, to = 1, n = 100)

            ps <- data.frame(x = c(d1$x, d0$x), y = c(d1$y, d0$y), treatment = c(rep(1, length(d1$x)),
                                                                                 rep(0, length(d0$x))))
            tcData$ps <- ps

            ps$x <- 1 - ps$x
            ps$treatment <- 1 - ps$treatment
            ctData$ps <- ps
        }

        ### Evalutuation distributions ###
        controls <- d[d$targetId == tc$targetId & d$comparatorId == tc$comparatorId & d$db == db & !is.na(d$trueRr), ]
        controls <- data.frame(trueRr = controls$trueRr,
                               logRr = controls$logRr,
                               ci95lb = controls$ci95lb,
                               ci95ub = controls$ci95ub,
                               seLogRr = controls$seLogRr)
        tcData$evaluationPlot <- plotScatter(controls, size = 2)

        controls <- d[d$targetId == tc$comparatorId & d$comparatorId == tc$targetId & d$db == db & !is.na(d$trueRr), ]
        controls <- data.frame(trueRr = controls$trueRr,
                               logRr = controls$logRr,
                               ci95lb = controls$ci95lb,
                               ci95ub = controls$ci95ub,
                               seLogRr = controls$seLogRr)
        ctData$evaluationPlot <- plotScatter(controls, size = 2)

        ### Calibration distribution ###
        controls <- d[d$targetId == tc$targetId & d$comparatorId == tc$comparatorId & d$db == db & !is.na(d$trueRr), ]
        controls <- data.frame(trueRr = controls$trueRr,
                               logRr = controls$calLogRr,
                               ci95lb = controls$calCi95lb,
                               ci95ub = controls$calCi95ub,
                               seLogRr = controls$calSeLogRr)
        tcData$calibrationPlot <- plotScatter(controls, size = 2)

        controls <- d[d$targetId == tc$comparatorId & d$comparatorId == tc$targetId & d$db == db & !is.na(d$trueRr), ]
        controls <- data.frame(trueRr = controls$trueRr,
                               logRr = controls$calLogRr,
                               ci95lb = controls$calCi95lb,
                               ci95ub = controls$calCi95ub,
                               seLogRr = controls$calSeLogRr)
        ctData$calibrationPlot <- plotScatter(controls, size = 2)

        ### Save to file ###
        fileName <- file.path(dataFolder, paste0("details_", tc$targetName, "_", tc$comparatorName, "_", db, ".rds"))
        saveRDS(tcData, normName(fileName))
        fileName <- file.path(dataFolder, paste0("details_", tc$comparatorName, "_", tc$targetName, "_", db, ".rds"))
        saveRDS(ctData, normName(fileName))
    }
}

### Balance files (saved separately because they're big)
library(OhdsiRTools)
library(CohortMethod)
options(fftempdir = "R:/fftemp")
dbs <- unique(d$db)
for (db in dbs) {
    omr <- readRDS(file.path(paste0("R:/PopEstDepression_", db), "cmOutput", "outcomeModelReference.rds"))
    omr <- omr[omr$analysisId == 3, ]
    tcs <- unique(d[d$db == db, c("targetId", "targetName", "comparatorId", "comparatorName")])
    omr <- merge(omr, tcs)
    tcs <- unique(omr[, c("targetId", "targetName", "comparatorId", "comparatorName")])

    fun <- function(i, tcs, db, omr, dataFolder){
        tc <- tcs[i,]
        omrRow <- omr[omr$targetId == tc$targetId & omr$comparatorId == tc$comparatorId,]

        normName <- function(name) {
            return(gsub(" ", "_", tolower(name)))
        }
        tcFileName <- normName(file.path(dataFolder, paste0("balance_", tc$targetName, "_", tc$comparatorName, "_", db, ".rds")))
        if (file.exists(tcFileName)) {
            return(NULL)
        }
        writeLines(paste0("Computing balance for ", tc$targetName, " and ", tc$comparatorName))
        ### Balance ###
        cohortMethodDataFolder <- omrRow$cohortMethodDataFolder[1]
        cohortMethodDataFolder <- sub("^[sS]:/", "r:/", cohortMethodDataFolder)
        cmData <- CohortMethod::loadCohortMethodData(cohortMethodDataFolder)
        strataFile <- omrRow$strataFile[1]
        strataFile <- sub("^[sS]:/", "r:/", strataFile)
        strata <- readRDS(strataFile)
        balance <- CohortMethod::computeCovariateBalance(strata, cmData)
        balance <- balance[, c("beforeMatchingStdDiff", "afterMatchingStdDiff", "covariateName")]
        saveRDS(balance, tcFileName)
    }
    cluster <- makeCluster(8)
    clusterRequire(cluster, "CohortMethod")
    clusterApply(cluster, 1:nrow(tcs), fun, tcs = tcs, db = db, omr = omr, dataFolder = dataFolder)
    #clusterApply(cluster, 1:3, fun, tcs = tcs, db = db, omr = omr, dataFolder = dataFolder)
    OhdsiRTools::stopCluster(cluster)
}

# Literature data ---------------------------------------------------------

litData <- read.csv("C:/home/Research/PublicationBias/AnalysisJitter.csv")

### Full data overview ###
seFromCI <- (log(litData$EffectEstimate_jitter)-log(litData$CI.LB_jitter))/qnorm(0.975)
seFromP <- abs(log(litData$EffectEstimate_jitter)/qnorm(litData$P.value_jitter))
litData$seLogRr <- seFromCI
litData$seLogRr[is.na(litData$seLogRr)] <- seFromP[is.na(litData$seLogRr)]
litData <- litData[!is.na(litData$seLogRr), ]
litData <- litData[litData$EffectEstimate_jitter > 0, ]
litData$logRr <- log(litData$EffectEstimate_jitter)
fullSet <- litData[, c("PMID", "Year", "Depression", "EffectEstimate", "CI.LB", "CI.UB", "P.value", "logRr", "seLogRr", "StartPos", "EndPos", "Title")]
#fullSet$Depression <- as.logical(fullSet$Depression)
fullSet$Depression <- as.logical(litData$DepressionTreatment)
colnames(fullSet)[colnames(fullSet) == "EffectEstimate"] <- "rr"
colnames(fullSet)[colnames(fullSet) == "CI.LB"] <- "ci95lb"
colnames(fullSet)[colnames(fullSet) == "CI.UB"] <- "ci95ub"
saveRDS(fullSet, file.path(dataFolder, "fullSetLit.rds"))

### Abstracts ###
pmids <- unique(litData$PMID)
hashes <- pmids %% 1000
readAbstract <- function(pmid) {
    fileName <- file.path("r:/abstracts", paste0("pmid_", pmid, ".txt"))
    return(readLines(fileName, encoding = "UTF-8"))
}
createFile <- function(hash, hashes, pmids) {
    subset <- pmids[hashes == hash]
    contents <- lapply(subset, readAbstract)
    names(contents) <- subset
    fileName <- file.path(dataFolder, paste0("pmids_ending_with_", hash, ".rds"))
    saveRDS(contents, fileName)
}
dummy <- sapply(unique(hashes), createFile, hashes = hashes, pmids = pmids)


