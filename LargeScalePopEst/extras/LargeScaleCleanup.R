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


# Reuse PS models ---------------------------------------------------------

workFolder <- "R:/PopEstDepression_MDCD"
files <- list.files(path = file.path(workFolder, "cmOutput"), pattern = "Ps_l1_s1_p2_t[0-9]+_c[0-9]+.rds")
newFiles <- gsub("_s1_", "_s2_", files)
file.copy(file.path(workFolder, "cmOutput", files), file.path(workFolder, "cmOutput", newFiles))
