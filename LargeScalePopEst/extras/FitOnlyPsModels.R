# This code is used to fit propensity models on one computer, while another computer is fitting the outcome models for signal injection


constructCohortMethodDataObjectNoInjection <- function(targetId,
                                                       comparatorId,
                                                       targetConceptId,
                                                       comparatorConceptId,
                                                       workFolder) {
  # Subsetting cohorts
  ffbase::load.ffdf(dir = file.path(workFolder, "allCohorts"))
  ff::open.ffdf(cohorts, readonly = TRUE)
  idx <- cohorts$cohortDefinitionId == targetId | cohorts$cohortDefinitionId == comparatorId
  cohorts <- ff::as.ram(cohorts[ffbase::ffwhich(idx, idx == TRUE), ])
  cohorts$treatment <- 0
  cohorts$treatment[cohorts$cohortDefinitionId == targetId] <- 1
  cohorts$cohortDefinitionId <- NULL
  treatedPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 1]))
  comparatorPersons <- length(unique(cohorts$subjectId[cohorts$treatment == 0]))
  treatedExposures <- length(cohorts$subjectId[cohorts$treatment == 1])
  comparatorExposures <- length(cohorts$subjectId[cohorts$treatment == 0])
  counts <- data.frame(description = "Starting cohorts",
                       treatedPersons = treatedPersons,
                       comparatorPersons = comparatorPersons,
                       treatedExposures = treatedExposures,
                       comparatorExposures = comparatorExposures)
  metaData <- list(targetId = targetId, comparatorId = comparatorId, attrition = counts)
  attr(cohorts, "metaData") <- metaData

  # Subsetting outcomes
  ffbase::load.ffdf(dir = file.path(workFolder, "allOutcomes"))
  ff::open.ffdf(outcomes, readonly = TRUE)
  idx <- !is.na(ffbase::ffmatch(outcomes$rowId, ff::as.ff(cohorts$rowId)))
  if (ffbase::any.ff(idx)) {
    outcomes <- ff::as.ram(outcomes[ffbase::ffwhich(idx, idx == TRUE), ])
  } else {
    outcomes <- as.data.frame(outcomes[1, ])
    outcomes <- outcomes[T == F, ]
  }
  metaData <- data.frame(outcomeIds = unique(outcomes$outcomeId))
  attr(outcomes, "metaData") <- metaData

  # Subsetting covariates
  covariateData <- FeatureExtraction::loadCovariateData(file.path(workFolder, "allCovariates"))
  idx <- is.na(ffbase::ffmatch(covariateData$covariates$rowId, ff::as.ff(cohorts$rowId)))
  covariates <- covariateData$covariates[ffbase::ffwhich(idx, idx == FALSE), ]

  # Filtering covariates
  filterConcepts <- readRDS(file.path(workFolder, "filterConceps.rds"))
  filterConcepts <- filterConcepts[filterConcepts$exposureId %in% c(targetId, comparatorId), ]
  filterConceptIds <- unique(filterConcepts$filterConceptId)
  idx <- is.na(ffbase::ffmatch(covariateData$covariateRef$conceptId, ff::as.ff(filterConceptIds)))
  covariateRef <- covariateData$covariateRef[ffbase::ffwhich(idx, idx == TRUE), ]
  filterCovariateIds <- covariateData$covariateRef$covariateId[ffbase::ffwhich(idx, idx == FALSE), ]
  idx <- is.na(ffbase::ffmatch(covariates$covariateId, filterCovariateIds))
  covariates <- covariates[ffbase::ffwhich(idx, idx == TRUE), ]

  result <- list(cohorts = cohorts,
                 outcomes = outcomes,
                 covariates = covariates,
                 covariateRef = covariateRef,
                 metaData = covariateData$metaData)

  class(result) <- "cohortMethodData"
  return(result)
}

generateAllCohortMethodDataObjectsNoInjection <- function(workFolder) {
  writeLines("Constructing cohortMethodData objects")
  start <- Sys.time()
  exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
  pb <- txtProgressBar(style = 3)
  for (i in 1:nrow(exposureSummary)) {
    targetId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    targetConceptId <- exposureSummary$tCohortDefinitionId[i]
    comparatorConceptId <- exposureSummary$cCohortDefinitionId[i]
    folderName <- file.path(workFolder,
                            "cmOutput",
                            paste0("CmData_l1_t", targetId, "_c", comparatorId, "_no_inj"))
    if (!file.exists(folderName)) {
      cmData <- constructCohortMethodDataObjectNoInjection(targetId = targetId,
                                                           comparatorId = comparatorId,
                                                           targetConceptId = targetConceptId,
                                                           comparatorConceptId = comparatorConceptId,
                                                           workFolder = workFolder)
      CohortMethod::saveCohortMethodData(cmData, folderName)
    }
    setTxtProgressBar(pb, i/nrow(exposureSummary))
  }
  close(pb)
  delta <- Sys.time() - start
  writeLines(paste("Generating all CohortMethodData objects took",
                   signif(delta, 3),
                   attr(delta, "units")))
}

fitAllPsModels <- function(workFolder, fitThreads = 1, cvThreads = 4) {
  writeLines("Fitting propensity models")
  exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
  tasks <- list()
  for (i in 1:nrow(exposureSummary)) {
    targetId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    folderName <- file.path(workFolder,
                            "cmOutput",
                            paste0("CmData_l1_t", targetId, "_c", comparatorId, "_no_inj"))
    fileName <- file.path(workFolder,
                          "cmOutput",
                          paste0("Ps_l1_s1_p2_t", targetId, "_c", comparatorId, ".rds"))
    if (!file.exists(fileName)) {
      task <- data.frame(folderName = folderName,
                         fileName = fileName,
                         cvThreads = cvThreads,
                         stringsAsFactors = FALSE)
      tasks[[length(tasks) + 1]] <- task
    }
  }

  fitPropensityModel <- function(task) {
    cmData <- CohortMethod::loadCohortMethodData(task$folderName)
    studyPop <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                                    firstExposureOnly = FALSE,
                                                    washoutPeriod = 0,
                                                    removeDuplicateSubjects = FALSE,
                                                    removeSubjectsWithPriorOutcome = FALSE,
                                                    priorOutcomeLookback = 99999,
                                                    minDaysAtRisk = 1,
                                                    riskWindowStart = 0,
                                                    addExposureDaysToStart = FALSE,
                                                    riskWindowEnd = 0,
                                                    addExposureDaysToEnd = TRUE)
    ps <- CohortMethod::createPs(cohortMethodData = cmData,
                                 population = studyPop,
                                 stopOnError = FALSE,
                                 control = Cyclops::createControl(noiseLevel = "quiet",
                                                                                                                                         cvType = "auto",
                                                                                                                                         tolerance = 2e-07,
                                                                                                                                         cvRepetitions = 1,
                                                                                                                                         startingVariance = 0.01,
                                                                                                                                         threads = task$cvThreads,
                                                                                                                                         seed = 1))
    saveRDS(ps, task$fileName)
  }
  cluster <- OhdsiRTools::makeCluster(fitThreads)
  OhdsiRTools::clusterRequire(cluster, "Cyclops")
  OhdsiRTools::clusterRequire(cluster, "CohortMethod")
  dummy <- OhdsiRTools::clusterApply(cluster, tasks, fitPropensityModel, stopOnError = TRUE)
  OhdsiRTools::stopCluster(cluster)
}
options(fftempdir = "S:/fftemp")
workFolder <- "s:/PopEstDepression_Ccae"

generateAllCohortMethodDataObjectsNoInjection(workFolder)

fitAllPsModels(workFolder, fitThreads = 2, cvThreads = 10)



