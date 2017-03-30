# Extract data from Sherlock ----------------------------------------------

library(DatabaseConnector)

server <- "awsafinva1134"
schema <- "clinicaltrials"
user <- ""
password <- ""

connectionDetails <- createConnectionDetails(dbms = "sql server",
                                             user = user,
                                             password = password,
                                             server = server,
                                             schema = schema)

conn <- connect(connectionDetails)
sql <- "SELECT ClinicalTrialsId,
	EventTerm,
	EventTermPTOmopConceptId,
	ArmIntervention,
	InterventionOmopConceptId,
	AENumberOfParticipants,
	AEOther,
	AESerious
FROM SubAdverseEventV
WHERE InterventionalModel = 'Parallel Assignment'
	AND Allocation = 'Randomized'
ORDER BY ClinicalTrialsId,
	EventTerm,
	ArmIntervention;"

data <- querySql(conn, sql)
write.csv(data, "data.csv", row.names = FALSE)


# Prepare datasets for serious and non-serious events ---------------------

extractData <- function(data, type = "nonserious") {
  data <- data[data$AENUMBEROFPARTICIPANTS >= 1,]
  data <- data[data$EVENTTERMPTOMOPCONCEPTID != 10060933, ] # Total, other adverse events
  placeboControlled <- data$CLINICALTRIALSID[data$INTERVENTIONOMOPCONCEPTID == 19047135] # Placebo
  data <- data[data$CLINICALTRIALSID %in% placeboControlled, ]
  placebo <- data[!is.na(data$INTERVENTIONOMOPCONCEPTID) & data$INTERVENTIONOMOPCONCEPTID == 19047135, c("CLINICALTRIALSID", "EVENTTERMPTOMOPCONCEPTID" ,"EVENTTERM" ,"AENUMBEROFPARTICIPANTS", "AEOTHER", "AESERIOUS")]
  treatment <- data[is.na(data$INTERVENTIONOMOPCONCEPTID) | data$INTERVENTIONOMOPCONCEPTID != 19047135,c("CLINICALTRIALSID", "EVENTTERMPTOMOPCONCEPTID" ,"EVENTTERM" ,"AENUMBEROFPARTICIPANTS", "AEOTHER", "AESERIOUS", "ARMINTERVENTION", "INTERVENTIONOMOPCONCEPTID")]
  colnames(placebo)[colnames(placebo) == "AENUMBEROFPARTICIPANTS"] <- "denominatorPlacebo"
  colnames(treatment)[colnames(treatment) == "AENUMBEROFPARTICIPANTS"] <- "denominatorTreatment"
  if (type == "nonserious") {
    colnames(placebo)[colnames(placebo) == "AEOTHER"] <- "numeratorPlacebo"
    colnames(treatment)[colnames(treatment) == "AEOTHER"] <- "numeratorTreatment"
    placebo$AESERIOUS <- NULL
    treatment$AESERIOUS <- NULL
  } else {
    colnames(placebo)[colnames(placebo) == "AESERIOUS"] <- "numeratorPlacebo"
    colnames(treatment)[colnames(treatment) == "AESERIOUS"] <- "numeratorTreatment"
    placebo$AEOTHER <- NULL
    treatment$AEOTHER <- NULL
  }
  dataMerged <- merge(treatment, placebo)
  dataMerged$numeratorTreatment[is.na(dataMerged$numeratorTreatment)] <- 0
  dataMerged$numeratorPlacebo[is.na(dataMerged$numeratorPlacebo)] <- 0
  
  # Detect trials with more than 2 arms and eliminate them:
  dataMerged$count <- 1
  counts <- aggregate(count ~ CLINICALTRIALSID + INTERVENTIONOMOPCONCEPTID + EVENTTERMPTOMOPCONCEPTID, dataMerged, sum) 
  counts <- counts[counts$count > 1, ]
  dataMerged <- dataMerged[!(dataMerged$CLINICALTRIALSID %in% unique(counts$CLINICALTRIALSID)), ]
  
  computeRr <- function(x) {
    outcome <- matrix(c(x["denominatorPlacebo"],
                        x["numeratorPlacebo"],
                        x["denominatorTreatment"],
                        x["numeratorTreatment"]), ncol = 2, byrow = TRUE)
    test <- fisher.test(outcome)
    result <- c(test$estimate, test$conf.int)
    names(result) <- c("or", "lb95ci","ub95ci")
    return(result)
  }
  result <- apply(dataMerged[, c("denominatorPlacebo", "numeratorPlacebo", "denominatorTreatment", "numeratorTreatment")], MARGIN = 1, computeRr)
  result <- as.data.frame(t(result), row.names = 1:ncol(result))
  result <- cbind(result, dataMerged)
  result$logRr <- log(result$or)
  result$seLogRr <- (log(result$ub95ci) - log(result$lb95ci))/(2 * qnorm(0.975))
  result <- result[!is.na(result$seLogRr) & !is.infinite(result$seLogRr), ]
  return(result)
}

data <- read.csv("data.csv")

nonSerious <- extractData(data, type = "nonserious")
write.csv(nonSerious, "EstimatesNonSerious.csv", row.names = FALSE)

serious <- extractData(data, type = "serious")
write.csv(serious, "EstimatesSerious.csv", row.names = FALSE)


# Prepare exposure-outcome pairs for negative control status evaluation --------------------

estimatesNonSerious <- read.csv("EstimatesNonSerious.csv")
estimatesSerious <- read.csv("EstimatesSerious.csv")
exposureOutcomePairs <- rbind(data.frame(exposureId = estimatesNonSerious$INTERVENTIONOMOPCONCEPTID,
                                         exposureName = estimatesNonSerious$ARMINTERVENTION,
                                         outcomeId = estimatesNonSerious$EVENTTERMPTOMOPCONCEPTID,
                                         outcomeName = estimatesNonSerious$EVENTTERM),
                              data.frame(exposureId = estimatesSerious$INTERVENTIONOMOPCONCEPTID,
                                         exposureName = estimatesSerious$ARMINTERVENTION,
                                         outcomeId = estimatesSerious$EVENTTERMPTOMOPCONCEPTID,
                                         outcomeName = estimatesSerious$EVENTTERM))
exposureOutcomePairs <- unique(exposureOutcomePairs)
exposureOutcomePairs <- exposureOutcomePairs[!is.na(exposureOutcomePairs$exposureId) & !is.na(exposureOutcomePairs$outcomeId), ]
exposureOutcomePairs <- exposureOutcomePairs[!grepl("[,;]", exposureOutcomePairs$exposureId) & !grepl("[,;]", exposureOutcomePairs$outcomeId), ]
exposureOutcomePairs <- exposureOutcomePairs[order(exposureOutcomePairs$exposureId, exposureOutcomePairs$outcomeId), ]
writeLines(paste0(nrow(exposureOutcomePairs), " unique exposure-outcome pairs in ", length(unique(estimatesSerious$CLINICALTRIALSID)), " trials"))
write.csv(exposureOutcomePairs, "ExposureOutcomePairsForEval.csv", row.names = FALSE)

# Load NC status generated elsewhere -------------------------------------

library(SqlRender)
library(DatabaseConnector)

password <- NULL
dbms <- "sql server"
user <- NULL
server <- "RNDUSRDHIT01"
schema <- 'NCInvestigation.dbo'

connectionDetails <- createConnectionDetails(dbms = dbms,
                                             user = user,
                                             password = password,
                                             server = server,
                                             schema = schema)

conn <- connect(connectionDetails)


sql <- "SELECT DISTINCT eo.exposureId,
eo.exposureName,
eo.outcomeId,
eo.outcomeName
INTO #eval_pairs_in_universe
FROM dbo.ExposureOutcomePairsForEval eo
INNER JOIN drug_universe
ON eo.exposureId = drug_universe.ingredient_concept_id
INNER JOIN temp_sena_vocab_map
ON eo.outcomeId = temp_sena_vocab_map.outcomeId
INNER JOIN condition_universe
ON temp_sena_vocab_map.concept_id = condition_universe.condition_concept_id"

executeSql(conn, sql)

sql <- "SELECT ep.exposureId,
ep.exposureName,
ep.outcomeId,
ep.outcomeName,
COUNT(*) AS concept_count, 
MIN(nc_candidate) AS nc_candidate
FROM #eval_pairs_in_universe ep
LEFT JOIN ExposureOutcomePairsWithEvidenceBase eb 
ON ep.exposureId = eb.exposureId AND ep.outcomeId = eb.outcomeId
WHERE prediction IS NOT NULL
GROUP BY ep.exposureId,
ep.exposureName,
ep.outcomeId,
ep.outcomeName"

d <- querySql(conn, sql)
dbDisconnect(conn)
write.csv(d, "ExposureOutcomePairsNc.csv", row.names = FALSE)


# Plot distribution for NCs -----------------------------------------------
library(EmpiricalCalibration)
library(ggplot2)

ncs <- read.csv("ExposureOutcomePairsNc.csv")
colnames(ncs)[colnames(ncs) == "EXPOSUREID"] <- "exposureId"
colnames(ncs)[colnames(ncs) == "OUTCOMEID"] <- "outcomeId"
exposureOutcomePairs <- read.csv("ExposureOutcomePairsForEval.csv")
m <- merge(ncs, exposureOutcomePairs)
writeLines(paste0(sum(m$NC_CANDIDATE), " pairs qualified as negative controls"))


# eo <- querySql(conn, "SELECT * FROM dbo.ExposureOutcomePairsForEval")
# colnames(eo)[colnames(eo) == "EXPOSUREID"] <- "exposureId"
# colnames(eo)[colnames(eo) == "OUTCOMEID"] <- "outcomeId"
# m <- merge(eo, exposureOutcomePairs[,c("exposureId", "outcomeId")])
# u <- unique(m[,c("exposureId", "outcomeId")])
# u <- unique(exposureOutcomePairs[,c("exposureId", "outcomeId")])

estimatesNonSerious <- read.csv("EstimatesNonSerious.csv")
ncs <- read.csv("ExposureOutcomePairsNc.csv")
ncs$INTERVENTIONOMOPCONCEPTID <- as.integer(as.character(ncs$EXPOSUREID))
ncs$EVENTTERMPTOMOPCONCEPTID <- as.integer(as.character(ncs$OUTCOMEID))
ncs$negativeControl <- ncs$NC_CANDIDATE
estimatesNonSerious$INTERVENTIONOMOPCONCEPTID <- as.integer(as.character(estimatesNonSerious$INTERVENTIONOMOPCONCEPTID))
estimatesNonSerious$EVENTTERMPTOMOPCONCEPTID <- as.integer(as.character(estimatesNonSerious$EVENTTERMPTOMOPCONCEPTID))
estimatesNonSerious <- estimatesNonSerious[!is.na(estimatesNonSerious$INTERVENTIONOMOPCONCEPTID) & !is.na(estimatesNonSerious$EVENTTERMPTOMOPCONCEPTID), ]
# nrow(unique(estimatesNonSerious[, c("INTERVENTIONOMOPCONCEPTID", "EVENTTERMPTOMOPCONCEPTID")]))
m <- merge(estimatesNonSerious, ncs[, c("INTERVENTIONOMOPCONCEPTID", "EVENTTERMPTOMOPCONCEPTID", "negativeControl")])
# nrow(unique(m[, c("INTERVENTIONOMOPCONCEPTID", "EVENTTERMPTOMOPCONCEPTID")]))
writeLines(paste0(nrow(unique(m[m$negativeControl == 1, c("INTERVENTIONOMOPCONCEPTID", "EVENTTERMPTOMOPCONCEPTID")])), " exposure-outcome pairs qualify as negative controls"))
m <- m[m$negativeControl == 1,]
m$significant <- m$lb95ci > 1 | m$ub95ci < 1
writeLines(paste0(nrow(m), " estimates for non serious effects, ", sum(m$significant), " (", 100*sum(m$significant)/nrow(m), "%) are significant"))

# plotCalibrationEffect(m$logRr, m$seLogRr)


null <- fitMcmcNull(m$logRr, m$seLogRr)
saveRDS(null, "nonSeriousNcNull.rds")

plotCalibrationEffect(m$logRr, m$seLogRr, showCis = TRUE, null = null, xLabel = "Odds ratio")
ggsave("nonSeriousNegativeControlsCali.png", width = 6, height = 4.5, dpi = 400)


estimatesSerious <- read.csv("EstimatesSerious.csv")
ncs <- read.csv("ExposureOutcomePairsNc.csv")
ncs$INTERVENTIONOMOPCONCEPTID <- as.integer(as.character(ncs$EXPOSUREID))
ncs$EVENTTERMPTOMOPCONCEPTID <- as.integer(as.character(ncs$OUTCOMEID))
ncs$negativeControl <- ncs$NC_CANDIDATE
estimatesSerious$INTERVENTIONOMOPCONCEPTID <- as.integer(as.character(estimatesSerious$INTERVENTIONOMOPCONCEPTID))
estimatesSerious$EVENTTERMPTOMOPCONCEPTID <- as.integer(as.character(estimatesSerious$EVENTTERMPTOMOPCONCEPTID))
estimatesSerious <- estimatesSerious[!is.na(estimatesSerious$INTERVENTIONOMOPCONCEPTID) & !is.na(estimatesSerious$EVENTTERMPTOMOPCONCEPTID), ]
m <- merge(estimatesSerious, ncs[, c("INTERVENTIONOMOPCONCEPTID", "EVENTTERMPTOMOPCONCEPTID", "negativeControl")])
m <- m[m$negativeControl == 1,]
m$significant <- m$lb95ci > 1 | m$ub95ci < 1
writeLines(paste0(nrow(m), " estimates for serious effects, ", sum(m$significant), " (", 100*sum(m$significant)/nrow(m), "%) are significant"))

null <- fitMcmcNull(m$logRr, m$seLogRr)
saveRDS(null, "seriousNcNull.rds")

plotCalibrationEffect(m$logRr, m$seLogRr, showCis = TRUE, null = null, xLabel = "Odds ratio")
ggsave("seriousNegativeControlsCali.png", width = 6, height = 4.5, dpi = 400)
