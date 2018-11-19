# Swap ggplot figures with underlying data to make more robust against changes in ggplot2:

dataFolder <- "C:/Users/mschuemi/git/ShinyDeploy/SystematicEvidence/data"


# Fix details evaluation and calibration plots ----------------------------------
# source("extras/SharedPlots.R")
files <- list.files(dataFolder, "details")
file <- files[1]
for (file in files) {
  # targetName <- gsub("_.*", "", gsub("details_", "", file))
  # comparatorName <- gsub("_.*", "", gsub("details_[^_]*_", "", file))
  # db <- gsub(".rds$", "", gsub("details_[^_]*_[^_]*_", "", file))
  details <- readRDS(file.path(dataFolder, file))

  controls <- details$evaluationPlot$data
  controls <- controls[, c("trueRr", "logRr", "ci95lb", "ci95ub", "seLogRr")]
  details$controlEstimates <- controls

  controls <- details$calibrationPlot$data
  controls <- controls[, c("trueRr", "logRr", "ci95lb", "ci95ub", "seLogRr")]
  details$controlCalibratedEstimates <- controls

  details$evaluationPlot <- NULL
  details$calibrationPlot <- NULL

  saveRDS(details, file.path(dataFolder, file))
}
