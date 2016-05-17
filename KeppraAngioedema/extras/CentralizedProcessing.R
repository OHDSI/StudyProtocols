library(KeppraAngioedema)
library(ReporteRs)
createTableAndFigures("S:/Angioedema/IMEDS_MDCR")
writeReport("S:/Angioedema/IMEDS_MDCR")
writeReportKnitr("S:/Angioedema/IMEDS_MDCR")



# exportFolder <- "S:/Angioedema/IMEDS_MDCR"
# mr <- read.csv("S:/Angioedema/IMEDS_MDCR/MainResults.csv")
# mr <- KeppraAngioedema:::addAnalysisDescriptions(mr)
# mr <- KeppraAngioedema:::addCohortNames(mr, "outcomeId", "outcomeName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "targetId", "targetName")
# mr <- KeppraAngioedema:::addCohortNames(mr, "comparatorId", "comparatorName")
# write.csv(mr, "S:/Angioedema/IMEDS_MDCR/MainResults.csv", row.names = FALSE)
