# tcosFile <- system.file("settings", "TcosOfInterest.csv", package = "AHAsAcutePancreatitis")
# tcos <- read.csv(tcosFile, stringsAsFactors = FALSE)
# studyFolder <- "S:/Studies/EPI534"
# databases <- c("optum", "mdcr", "ccae")
# reportFolder = file.path(studyFolder, "report")
# 
# cleanResults <- function(results) {
#   #fix a typo
#   results[results$eventType == "First EVer Event", ]$eventType <-
#     "First Ever Event"
#   #create additional filter variables
#   results$noCana <-
#     with(results, ifelse(grepl("no cana", comparatorName), TRUE, FALSE))
#   results$noCensor <-
#     with(results, ifelse(grepl("no censoring", comparatorName), TRUE, FALSE))
#   #simplify naming
#   results[results$timeAtRisk == "Per Protocol Zero Day (no censor at switch)", ]$timeAtRisk <-
#     "On Treatment (0 Day)"
#   results[results$timeAtRisk == "On Treatment", ]$timeAtRisk <-
#     "On Treatment (30 Day)"
#   results[results$timeAtRisk == "On Treatment (no censor at switch)", ]$timeAtRisk <-
#     "On Treatment (30 Day)"
#   results[results$timeAtRisk == "Per Protocol Sixty Day (no censor at switch)", ]$timeAtRisk <-
#     "On Treatment (60 Day)"
#   results[results$timeAtRisk == "Per Protocol Zero Day", ]$timeAtRisk <-
#     "On Treatment (0 Day)"
#   results[results$timeAtRisk == "Per Protocol Sixty Day", ]$timeAtRisk <-
#     "On Treatment (60 Day)"
#   return(results)
# }
# 
# loadResultsHois <- function(outputFolder) {
#   shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
#   file <-
#     list.files(shinyDataFolder,
#                pattern = "resultsHois_.*.rds",
#                full.names = TRUE)
#   x <- readRDS(file)
#   return(x)
# }
# 
# for (database in databases) {
#   outputFolder <- file.path(studyFolder, database)
#   results <- loadResultsHois(outputFolder)
#   results <- cleanResults(results)
#   
#   # limit to primary analysis per specification
#   primary <- results[
#     results$analysisId==2 & 
#     results$timeAtRisk=="On Treatment (30 Day)" & 
#     !is.na(results$p) &
#     results$canaRestricted == T &
#     results$noCensor == F,] 
#   
#   primary$hochbergP <- p.adjust(primary$p,method="hochberg")
#   final <- primary[c("comparatorDrug", "rr", "ci95lb", "ci95ub", "p", "hochbergP")]
#   write.table(final, file.path(reportFolder, paste0("hochbergResult_", database, ".csv" )), row.names=F, sep=",")
# }
# 
