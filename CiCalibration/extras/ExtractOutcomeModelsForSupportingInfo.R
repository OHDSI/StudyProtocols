mdcrFolder <- "S:/Temp/CiCalibration_Mdcr"
optumFolder <- "S:/Temp/CiCalibration_Optum"
mdcdFolder <- "S:/Temp/CiCalibration_Mdcd"

paperFolder <- "S:/temp/CiCalibrationPaper"
if (!file.exists(paperFolder))
    dir.create(paperFolder, recursive = TRUE)

pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CiCalibration")
negativeControls <- read.csv(pathToCsv)

getModels <- function(studyFolder, study) {
   signalInjectionFolder <- file.path(studyFolder, "signalInjection")
   ncs <- negativeControls[negativeControls$study == study, ]
   models <- data.frame()
   for (i in 1:nrow(ncs)) {
     modelFolder <- file.path(signalInjectionFolder, paste0("model_o", ncs$conceptId[i]))
     if (file.exists(modelFolder)) {
        betas <- readRDS(file.path(modelFolder, "betas.rds"))
        models <- rbind(models,
                        data.frame(Study = paste(study, "replication"),
                                   Outcome = as.character(ncs$name[i]),
                                   Beta = betas$beta,
                                   Covariate = as.character(betas$covariateName),
                                   stringsAsFactors = FALSE))
     }
   }
   return(models)
}

allModels <- data.frame()
allModels <- rbind(allModels, getModels(optumFolder, "Southworth"))
allModels <- rbind(allModels, getModels(mdcrFolder, "Graham"))
allModels <- rbind(allModels, getModels(mdcdFolder, "Tata"))
write.csv(allModels, file.path(paperFolder, "OutcomeModels.csv"), row.names = FALSE)
# studyFolder <- optumFolder
# study <- "Southworth"

