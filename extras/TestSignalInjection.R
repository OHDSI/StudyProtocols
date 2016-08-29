

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

sp1 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                           outcomeId = 75354,
                                           removeSubjectsWithPriorOutcome = TRUE,
                                           minDaysAtRisk = 0,
                                           riskWindowStart = 0,
                                           riskWindowEnd = 0,
                                           addExposureDaysToEnd = TRUE)

sp2 <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,
                                           outcomeId = 10001,
                                           removeSubjectsWithPriorOutcome = TRUE,
                                           minDaysAtRisk = 0,
                                           riskWindowStart = 0,
                                           riskWindowEnd = 0,
                                           addExposureDaysToEnd = TRUE)

sp2 <- sp2[sp2$treatment == 1,]
sp2$stratumId <- sp2$rowId

sp1 <- sp1[sp1$treatment == 1,]
sp1$treatment <- 0
sp1$stratumId <- sp1$rowId
sp1$rowId <- sp1$rowId + max(sp2$rowId)

sp <- rbind(sp1, sp2)
# sp$survivalTime <- sp$survivalTime -1
# sp <- sp[sp$survivalTime > 0,]
om <- CohortMethod::fitOutcomeModel(sp,
                                    cohortMethodData = cmData,
                                    modelType = "cox",
                                    stratified = FALSE,
                                    useCovariates = FALSE)
om
