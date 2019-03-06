# AUTOMATE ALL BELOW WITH A PREPARE FUNCTION ------------------------------------------------------
# moved outcome_of_interest_DB -> outcome_of_interest_Meta-analysis.rds
# moved exposure_of_interest_DB -> exposure_of_interest_Meta-analysis.rds
# moved and altered database_D.rds -> database_Meta-analysis.rds
database <- data.frame(database_id = "Meta-analysis",
                       database_name = "Meta-analysis",
                       description = "Meta-analysis",
                       is_meta_analysis = 1)
fileName <- file.path("D:/jweave17/UkaTkaSafetyFullMetaAnalysis/results/shinyData", "database_Meta-analysis.rds")
saveRDS(database, fileName)
# moved cohort_method_analysis_DB.rds -> cohort_method_analysis_Meta-analysis.rds
# moved negative/positive control outcome rds files
#files from export seem to have fewer than full negative controls
pathToCsv <- system.file("settings", "NegativeControls.csv", package = "UkaTkaSafetyFull")
negativeControls <- read.csv(pathToCsv)
negativeControls <- negativeControls[tolower(negativeControls$type) == "outcome", ]
negativeControls <- negativeControls[, c("outcomeId", "outcomeName")]
colnames(negativeControls) <- SqlRender::camelCaseToSnakeCase(colnames(negativeControls))
saveRDS(negativeControls, "D:/jweave17/UkaTkaSafetyFullMetaAnalysis/results/shinyData/negative_control_outcome_Meta-analysis.rds")

dataFolder <- "D:/jweave17/UkaTkaSafetyFullMetaAnalysis/results/shinyData"
dataFolder <- "S:/StudyResults/UkaTkaSafetyFull/metaAnalysis/shinyData"
launchEvidenceExplorer(dataFolder = dataFolder, blind = FALSE, launch.browser = FALSE)
