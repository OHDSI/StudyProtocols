library(LargeScalePopEst)

options('fftempdir' = 'S:/fftemp')
workFolder <- "S:/PopEstDepression_Mdcd"

exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
injectionSummary <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))

newRows <- data.frame()
for (i in 1:nrow(exposureSummary)) {
    targetId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    targetConceptId <- exposureSummary$tCohortDefinitionId[i]
    comparatorConceptId <- exposureSummary$cCohortDefinitionId[i]

    folderName <- file.path(workFolder, "cmOutput", paste0("CmData_l1_t", targetId, "_c", comparatorId))
    cmData <- CohortMethod::loadCohortMethodData(folderName)

    cmData <- LargeScalePopEst:::constructCohortMethodDataObject(targetId = targetId,
                                                                 comparatorId = comparatorId,
                                                                 targetConceptId = targetConceptId,
                                                                 comparatorConceptId = comparatorConceptId,
                                                                 workFolder = workFolder)
    rows <-  injectionSummary[injectionSummary$exposureId == targetConceptId, ]
    rows$observedFxSize <- NA
    rows$observedFxSize_lb <- NA
    rows$observedFxSize_ub <- NA

    for (j in 1:nrow(rows)) {
        if (rows$trueEffectSize[j] != 0){
            sp1 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                                       outcomeId = rows$outcomeId[j],
                                                       removeSubjectsWithPriorOutcome = TRUE,
                                                       minDaysAtRisk = 0,
                                                       riskWindowStart = 0,
                                                       riskWindowEnd = 0,
                                                       addExposureDaysToEnd = TRUE)
            sp2 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                                       outcomeId = rows$newOutcomeId[j],
                                                       removeSubjectsWithPriorOutcome = TRUE,
                                                       minDaysAtRisk = 0,
                                                       riskWindowStart = 0,
                                                       riskWindowEnd = 0,
                                                       addExposureDaysToEnd = TRUE)
            sp2 <- sp2[sp2$treatment == 1,]
            sp1 <- sp1[sp1$treatment == 1,]
            sp1$treatment <- 0
            sp1$rowId <- sp1$rowId + max(sp2$rowId)
            sp <- rbind(sp1, sp2)
            om <- CohortMethod::fitOutcomeModel(sp,
                                                cohortMethodData = cmData,
                                                modelType = "cox",
                                                stratified = FALSE,
                                                useCovariates = FALSE)
            rows$observedFxSize[j] <- exp(coef(om))
            rows$observedFxSize_lb[j] <- exp(confint(om)[1])
            rows$observedFxSize_ub[j] <- exp(confint(om)[2])
        }
    }
    newRows <- rbind(newRows, rows)
}

x <- rows[,c("targetEffectSize", "observedFxSize", "observedFxSize_lb", "observedFxSize_ub")]


MethodEvaluation:::generateOutcomes


exposureOutcomePairs <- data.frame(exposureId = 739138, outcomeId = 75354)
debug(injectSignals)
injectSignals(connectionDetails = connectionDetails,
              cdmDatabaseSchema = cdmDatabaseSchema,
              workDatabaseSchema = workDatabaseSchema,
              studyCohortTable = studyCohortTable,
              oracleTempSchema = oracleTempSchema,
              workFolder = workFolder,
              exposureOutcomePairs = exposureOutcomePairs,
              maxCores = maxCores)

cmData <- LargeScalePopEst:::constructCohortMethodDataObject(targetId = 739138112,
                                                             comparatorId = 797617112,
                                                             targetConceptId = 739138,
                                                             comparatorConceptId = 797617,
                                                             workFolder = workFolder)

cmData <- constructCustomCohortMethodDataObject(targetConceptId = 739138,
                                                workFolder = workFolder)



sp1 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                           outcomeId = 75354,
                                           removeSubjectsWithPriorOutcome = TRUE,
                                           minDaysAtRisk = 0,
                                           riskWindowStart = 0,
                                           riskWindowEnd = 0,
                                           addExposureDaysToEnd = TRUE)

sp2 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                           outcomeId = 10328,
                                           removeSubjectsWithPriorOutcome = TRUE,
                                           minDaysAtRisk = 0,
                                           riskWindowStart = 0,
                                           riskWindowEnd = 0,
                                           addExposureDaysToEnd = TRUE)

sp2 <- sp2[sp2$treatment == 1,]

sp1 <- sp1[sp1$treatment == 1,]
sp1$treatment <- 0
sp1$rowId <- sp1$rowId + max(sp2$rowId)

sp <- rbind(sp1, sp2)
om <- CohortMethod::fitOutcomeModel(sp,
                                    cohortMethodData = cmData,
                                    modelType = "cox",
                                    stratified = FALSE,
                                    useCovariates = FALSE)
om
s <- summary(om)
(s$outcomeCounts$treatedPersons / (s$timeAtRisk$treatedDays + s$populationCounts$treatedPersons)) / (s$outcomeCounts$comparatorPersons / (s$timeAtRisk$comparatorDays + s$populationCounts$comparatorPersons))
(s$outcomeCounts$treatedPersons / s$timeAtRisk$treatedDays) / (s$outcomeCounts$comparatorPersons / s$timeAtRisk$comparatorDays)
no<- readRDS("S:/PopEstDepression_Mdcd/signalInjection/newOutcomes_e739138_o75354_rr2.rds")
no[!(no$subjectId %in% sp2$subjectId[sp2$outcomeCount != 0]),]


constructCustomCohortMethodDataObject <- function(targetConceptId,
                                            workFolder) {
    exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
    targetIds <- exposureSummary$tprimeCohortDefinitionId[exposureSummary$tCohortDefinitionId == targetConceptId]
    # Subsetting cohorts
    ffbase::load.ffdf(dir = file.path(workFolder, "allCohorts"))
    ff::open.ffdf(cohorts, readonly = TRUE)
    idx <- ffbase::'%in%'(cohorts$cohortDefinitionId, targetIds)
    cohorts <- ff::as.ram(cohorts[ffbase::ffwhich(idx, idx == TRUE), ])
    cohorts$treatment <- 1
    cohorts$cohortDefinitionId <- NULL
    cohorts <- cohorts[order(cohorts$rowId),]
    cohorts <- cohorts[!duplicated(cohorts$rowId),]
    treatedPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 1]))
    comparatorPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 0]))
    treatedExposures <- length(cohorts$subjectId[cohorts$treatment == 1])
    comparatorExposures <- length(cohorts$subjectId[cohorts$treatment == 0])
    counts <- data.frame(description = "Starting cohorts",
                         treatedPersons = treatedPersons,
                         comparatorPersons = comparatorPersons,
                         treatedExposures = treatedExposures,
                         comparatorExposures = comparatorExposures)
    metaData <- list(targetId = targetConceptId,
                     comparatorId = 0,
                     attrition = counts)
    attr(cohorts, "metaData") <- metaData

    # Subsetting outcomes
    ffbase::load.ffdf(dir = file.path(workFolder, "allOutcomes"))
    ff::open.ffdf(outcomes, readonly = TRUE)
    idx <- !is.na(ffbase::ffmatch(outcomes$rowId, ff::as.ff(cohorts$rowId)))
    if (ffbase::any.ff(idx)){
        outcomes <- ff::as.ram(outcomes[ffbase::ffwhich(idx, idx == TRUE), ])
    } else {
        outcomes <- as.data.frame(outcomes[1, ])
        outcomes <- outcomes[T == F,]
    }
    x <- outcomes[outcomes$outcomeId == 75354 & outcomes$daysToEvent < 0, ]
    length(unique(x$rowId))
    sum(!(cohorts$rowId %in% unique(x$rowId)))
    # Add injected outcomes
    ffbase::load.ffdf(dir = file.path(workFolder, "injectedOutcomes"))
    ff::open.ffdf(injectedOutcomes, readonly = TRUE)
    injectionSummary <- read.csv(file.path(workFolder, "signalInjectionSummary.csv"))
    injectionSummary <- injectionSummary[injectionSummary$exposureId == targetConceptId, ]
    idx1 <- ffbase::'%in%'(injectedOutcomes$subjectId, cohorts$subjectId)
    idx2 <- ffbase::'%in%'(injectedOutcomes$cohortDefinitionId, injectionSummary$newOutcomeId)
    idx <- idx1 & idx2
    if (ffbase::any.ff(idx)){
        injectedOutcomes <- ff::as.ram(injectedOutcomes[idx, ])
        colnames(injectedOutcomes)[colnames(injectedOutcomes) == "cohortStartDate"] <- "eventDate"
        colnames(injectedOutcomes)[colnames(injectedOutcomes) == "cohortDefinitionId"] <- "outcomeId"
        injectedOutcomes <- merge(cohorts[, c("rowId", "subjectId", "cohortStartDate")], injectedOutcomes[, c("subjectId", "outcomeId", "eventDate")])
        injectedOutcomes$daysToEvent = injectedOutcomes$eventDate - injectedOutcomes$cohortStartDate
        #any(injectedOutcomes$daysToEvent < 0)
        #min(outcomes$daysToEvent[outcomes$outcomeId == 73008])
        outcomes <- rbind(outcomes, injectedOutcomes[, c("rowId", "outcomeId", "daysToEvent")])
    }
    metaData <- data.frame(outcomeIds = unique(outcomes$outcomeId))
    attr(outcomes, "metaData") <- metaData

    # Subsetting covariates
    covariateData <- FeatureExtraction::loadCovariateData(file.path(workFolder, "allCovariates"))
    idx <- is.na(ffbase::ffmatch(covariateData$covariates$rowId, ff::as.ff(cohorts$rowId)))
    covariates <- covariateData$covariates[ffbase::ffwhich(idx, idx == FALSE), ]


    result <- list(cohorts = cohorts,
                   outcomes = outcomes,
                   covariates = covariates,
                   metaData = covariateData$metaData)

    class(result) <- "cohortMethodData"
    return(result)
}
