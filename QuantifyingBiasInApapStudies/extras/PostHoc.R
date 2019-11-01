


# Understanding why no estimate for renal cell carcinoma in analysis 4
ccOutputFolder <- file.path(outputFolder, "ccOutput")
omr <- readRDS(file.path(ccOutputFolder, "outcomeModelReference.rds"))
idx <- omr$analysisId == 4 &  omr$outcomeId == 11666
om <- readRDS(file.path(ccOutputFolder, omr$modelFile[idx]))
summary(om)
# Ill-conditioned

ccd <- readRDS(file.path(ccOutputFolder, omr$caseControlDataFile[idx]))
ed <- CaseControl::loadCaseControlsExposure(file.path(ccOutputFolder, omr$exposureDataFile[idx]))
undebug(CaseControl::fitCaseControlModel)
om <- CaseControl::fitCaseControlModel(caseControlData = ccd,
                                       useCovariates = TRUE,
                                       caseControlsExposure = ed,
                                       prior = Cyclops::createPrior("normal", variance = 1),
                                       control = Cyclops::createControl(noiseLevel = "noisy"))
