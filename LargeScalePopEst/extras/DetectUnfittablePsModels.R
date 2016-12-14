# This code is used to find propensity models that are unfittable and currently take days to (try to) fit


library(CohortMethod)

fitAllPsModels <- function(workFolder, fitThreads = 1) {
  writeLines("Fitting propensity models")
  exposureSummary <- read.csv(file.path(workFolder, "exposureSummaryFilteredBySize.csv"))
  tasks <- list()
  for (i in 1:nrow(exposureSummary)) {
    targetId <- exposureSummary$tprimeCohortDefinitionId[i]
    comparatorId <- exposureSummary$cprimeCohortDefinitionId[i]
    folderName <- file.path(workFolder,
                            "cmOutput",
                            paste0("CmData_l1_t", targetId, "_c", comparatorId))
    fileName <- file.path(workFolder,
                          "cmOutput",
                          paste0("Ps_l1_s1_p2_t", targetId, "_c", comparatorId, ".rds"))
    if (!file.exists(fileName)) {
      task <- data.frame(folderName = folderName, fileName = fileName, stringsAsFactors = FALSE)
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
    for (seed in 1:3) {
      set.seed(seed)
      studyPopSample <- studyPop[sample.int(n = nrow(studyPop), size = 10000, replace = FALSE), ]
      if (sum(studyPopSample$treatment == 1) < 1000 || sum(studyPopSample$treatment == 0) < 1000) {
        studyPopSample <- studyPop[sample.int(n = nrow(studyPop), size = 25000, replace = FALSE), ]
      }
      if (sum(studyPopSample$treatment == 1) < 1000 || sum(studyPopSample$treatment == 0) < 1000) {
        return()
      }
      ps <- CohortMethod::createPs(cohortMethodData = cmData,
                                   population = studyPopSample,
                                   stopOnError = FALSE,
                                   control = createControl(noiseLevel = "quiet",
                                                                                                                                        cvType = "auto",
                                                                                                                                        cvRepetitions = 1,
                                                                                                                                        startingVariance = 0.01,
                                                                                                                                        seed = 1,
                                                                                                                                        threads = 10))
      if (computePsAuc(ps) == 1) {
        writeLines(paste("Model for", task$fileName, "is perfectly predictive"))
        studyPop$propensityScore <- studyPop$treatment
        studyPop$preferenceScore <- studyPop$treatment
        saveRDS(ps, task$fileName)
        return()
      }
    }
  }
  cluster <- OhdsiRTools::makeCluster(fitThreads)
  OhdsiRTools::clusterRequire(cluster, "Cyclops")
  OhdsiRTools::clusterRequire(cluster, "CohortMethod")
  dummy <- OhdsiRTools::clusterApply(cluster, tasks, fitPropensityModel, stopOnError = TRUE)
  OhdsiRTools::stopCluster(cluster)
}
options(fftempdir = "r:/fftemp")
workFolder <- "r:/PopEstDepression_Ccae"

# fitAllPsModels(workFolder, fitThreads = 1)




cmData <- CohortMethod::loadCohortMethodData("r:/PopEstDepression_Ccae/cmOutput/CmData_l1_t755695129_c4327941129")
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
set.seed(2)
studyPopSample <- studyPop[sample.int(n = nrow(studyPop), size = 10000, replace = FALSE), ]
if (sum(studyPopSample$treatment == 1) < 1000 || sum(studyPopSample$treatment == 0) < 1000) {
  studyPopSample <- studyPop[sample.int(n = nrow(studyPop), size = 25000, replace = FALSE), ]
}
if (sum(studyPopSample$treatment == 1) < 1000 || sum(studyPopSample$treatment == 0) < 1000) {
  return()
}
ps <- CohortMethod::createPs(cohortMethodData = cmData,
                             population = studyPopSample,
                             stopOnError = FALSE,
                             control = createControl(noiseLevel = "quiet",
                                                                                                                                  cvType = "auto",
                                                                                                                                  cvRepetitions = 1,
                                                                                                                                  startingVariance = 0.01,
                                                                                                                                  seed = 1,
                                                                                                                                  threads = 1))
computePsAuc(ps)
plotPs(ps, scale = "propensity")
mean(ps$preferenceScore)
model <- getPsModel(ps, cmData)
head(model)
