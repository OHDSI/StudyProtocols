workFolder <- "R:/PopEstDepression_MDCD"

badIds <- c(4030840, 4327941)

findFiles <- function(id, files) {
  nameOnly <- gsub("^.*/", "", files)
  return(files[grepl(id, nameOnly)])
}

findFilesInFolder <- function(folder, badIds) {
  files <- list.files(path = folder, recursive = TRUE, include.dirs = TRUE)
  toDel <- unique(do.call("c", sapply(badIds, findFiles, files)))
  toDel <- toDel[order(toDel)]
  toDel <- file.path(folder, toDel)
  return(toDel)
}
toDel <- findFilesInFolder(file.path(workFolder, "cmOutput"), badIds)

unlink(toDel, recursive = TRUE)

unlink(file.path(workFolder, "signalInjection"), recursive = TRUE)
unlink(file.path(workFolder, "injectedOutcomes"), recursive = TRUE)
unlink(file.path(workFolder, "allCohorts"), recursive = TRUE)
unlink(file.path(workFolder, "allCovariates"), recursive = TRUE)
unlink(file.path(workFolder, "allOutcomes"), recursive = TRUE)
