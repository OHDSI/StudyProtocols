# Create analysis details ------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = Sys.getenv("dbms"),
                                                                server = Sys.getenv("server"),
                                                                port = as.numeric(Sys.getenv("port")),
                                                                user = NULL,
                                                                password = NULL)

# estimation settings
sglt2iDka::createEstimateVariants(connectionDetails = connectionDetails,
                                  cohortDefinitionSchema = "scratch.dbo",
                                  cohortDefinitionTable = "epi535_cohort_universe",
                                  codeListSchema = "scratch.dbo",
                                  codeListTable = "epi535_code_list",
                                  vocabularyDatabaseSchema = "vocabulary_20171201.dbo",
                                  outputFolder = "inst/settings")

sglt2iDka::createAnalysesDetails(outputFolder = "inst/settings")


# settings to pull data for IR analyses with 60 and 120 gap days ---------------
sglt2iDka::createIrSensitivityVariants(connectionDetails = connectionDetails,
                                       cohortDefinitionSchema = "scratch.dbo",
                                       cohortDefinitionTable = "epi535_cohort_universe",
                                       outputFolder = "inst/settings")

sglt2iDka::createIrSensitivityAnalysesDetails(outputFolder = "inst/settings")


# settings to pull data for IR dose-specific analysis --------------------------
sglt2iDka::createIrDoseVariants(connectionDetails = connectionDetails,
                                cohortDefinitionSchema = "scratch.dbo",
                                cohortDoseDefinitionTable = "epi535_cohort_universe_dose",
                                cohortDefinitionTable = "epi535_cohort_universe",
                                outputFolder = "inst/settings")

sglt2iDka::createIrDoseAnalysesDetails(outputFolder = "inst/settings")




# Store environment in which the study was executed ----------------------------
OhdsiRTools::insertEnvironmentSnapshotInPackage("sglt2iDka")




# rename directory locations in outcomeModelReference.rds from run on other box
# ref <- readRDS("S:/StudyResults/epi_535_4/CCAE/cmOutput/outcomeModelReference.rds")
# ref$cohortMethodDataFolder <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$cohortMethodDataFolder)
# ref$studyPopFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$studyPopFile)
# ref$sharedPsFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$sharedPsFile)
# ref$psFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$psFile)
# ref$strataFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$strataFile)
# ref$outcomeModelFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$outcomeModelFile)
# saveRDS(ref, "S:/StudyResults/epi_535_4/CCAE/cmOutput/outcomeModelReference.rds")
#
# ref <- readRDS("S:/StudyResults/epi_535_4/MDCD/cmOutput/outcomeModelReference.rds")
# ref$cohortMethodDataFolder <- sub(pattern = "D:", replacement = "S:", x = ref$cohortMethodDataFolder)
# ref$studyPopFile <- sub(pattern = "D:", replacement = "S:", x = ref$studyPopFile)
# ref$sharedPsFile <- sub(pattern = "D:", replacement = "S:", x = ref$sharedPsFile)
# ref$psFile <- sub(pattern = "D:", replacement = "S:", x = ref$psFile)
# ref$strataFile <- sub(pattern = "D:", replacement = "S:", x = ref$strataFile)
# ref$outcomeModelFile <- sub(pattern = "D:", replacement = "S:", x = ref$outcomeModelFile)
# saveRDS(ref, "S:/StudyResults/epi_535_4/MDCD/cmOutput/outcomeModelReference.rds")


# rename directory locations in outcomeModelReference.rds from run on other box
# ref <- readRDS("S:/StudyResults/epi_535_4/CCAE/cmIrSensitivityOutput/outcomeModelReference.rds")
# ref$cohortMethodDataFolder <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$cohortMethodDataFolder)
# ref$studyPopFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$studyPopFile)
# ref$sharedPsFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$sharedPsFile)
# ref$psFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$psFile)
# ref$strataFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$strataFile)
# ref$outcomeModelFile <- sub(pattern = "D:/jweave17", replacement = "S:/StudyResults", x = ref$outcomeModelFile)
# saveRDS(ref, "S:/StudyResults/epi_535_4/CCAE/cmIrSensitivityOutput/outcomeModelReference.rds")
#
# ref <- readRDS("S:/StudyResults/epi_535_4/MDCD/cmIrSensitivityOutput/outcomeModelReference.rds")
# ref$cohortMethodDataFolder <- sub(pattern = "D:", replacement = "S:", x = ref$cohortMethodDataFolder)
# ref$studyPopFile <- sub(pattern = "D:", replacement = "S:", x = ref$studyPopFile)
# ref$sharedPsFile <- sub(pattern = "D:", replacement = "S:", x = ref$sharedPsFile)
# ref$psFile <- sub(pattern = "D:", replacement = "S:", x = ref$psFile)
# ref$strataFile <- sub(pattern = "D:", replacement = "S:", x = ref$strataFile)
# ref$outcomeModelFile <- sub(pattern = "D:", replacement = "S:", x = ref$outcomeModelFile)
# saveRDS(ref, "S:/StudyResults/epi_535_4/MDCD/cmIrSensitivityOutput/outcomeModelReference.rds")



