normName <- function(name) {
  return(gsub(" ", "_", tolower(name)))
}

d <- readRDS(file.path("data", normName("fullset.rds")))
dbs <- as.character(unique(d$db))
dbs <- dbs[order(dbs)]
treatments <- as.character(unique(d$targetName))
treatments <- treatments[order(treatments)]
outcomes <- as.character(unique(d$outcomeName))
outcomes <- outcomes[order(outcomes)]

dLit <- readRDS(file.path("data", normName("fullsetlit.rds")))
years <- as.integer(unique(dLit$Year))
