# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of AlendronateVsRaloxifene
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Prepare results for the Evidence Explorer Shiny app.
#'
#' @param studyFolder  The root folder containing the study results. The app expects each database to have a subfolder in this 
#'                     folder, containing the packaged results.
#'
#' @export
prepareForEvidenceExplorer <- function(studyFolder) {
  databases <- list.files(studyFolder, include.dirs = TRUE)
  for (database in databases) {
    OhdsiRTools::logInfo("Prepraring results from database ", database) 
    fileName <- file.path(studyFolder, database, "AllEstimates.csv")
    estimates <- read.csv(fileName, stringsAsFactors = FALSE)
    tcas <- unique(estimates[, c("targetId", "comparatorId", "analysisId")])
    for (i in 1:nrow(tcas)) {
      targetId <- tcas$targetId[i]
      comparatorId <- tcas$comparatorId[i]
      analysisId <- tcas$analysisId[i]
      ncs <- estimates[estimates$targetId == targetId &
                         estimates$comparatorId == comparatorId &
                         estimates$analysisId == analysisId &
                         estimates$targetEffectSize == 1,]
      null <- EmpiricalCalibration::fitMcmcNull(ncs$logRr, ncs$seLogRr)
      fileName <- file.path(studyFolder, database, paste0("null_a",analysisId,"_t",targetId,"_c",comparatorId,".rds"))
      saveRDS(null, fileName)
      idx <- estimates$targetId == targetId &
        estimates$comparatorId == comparatorId &
        estimates$analysisId == analysisId 
      calP <- EmpiricalCalibration::calibrateP(null = null,
                                               logRr = estimates$logRr[idx],
                                               seLogRr = estimates$seLogRr[idx])
      estimates$calP[idx] <- calP$p
    }
    fileName <- file.path(studyFolder, database, "AllCalibratedEstimates.rds")
    saveRDS(estimates, fileName)
  }
}


#' Launch the SqlRender Developer Shiny app
#' 
#' @param studyFolder  The root folder containing the study results. The app expects each database to have a subfolder in this 
#'                     folder, containing the packaged results.
#' @param blind        Should the user be blinded to the main results?
#' @param launch.browser    Should the app be launched in your default browser, or in a Shiny window.
#'                          Note: copying to clipboard will not work in a Shiny window.
#' 
#' @details 
#' Launches a Shiny app that allows the user to explore the evidence
#' 
#' @export
launchEvidenceExplorer <- function(studyFolder, blind = TRUE, launch.browser = TRUE) {
  ensure_installed("DT")
  appDir <- system.file("shiny", "EvidenceExplorer", package = "AlendronateVsRaloxifene")
  .GlobalEnv$shinySettings <- list(studyFolder = studyFolder, blind = blind)
  on.exit(rm(shinySettings, envir=.GlobalEnv))
  shiny::runApp(appDir) 
}

# Borrowed from devtools: https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L44
is_installed <- function (pkg, version = 0) {
  installed_version <- tryCatch(utils::packageVersion(pkg), 
                                error = function(e) NA)
  !is.na(installed_version) && installed_version >= version
}

# Borrowed and adapted from devtools: https://github.com/hadley/devtools/blob/ba7a5a4abd8258c52cb156e7b26bb4bf47a79f0b/R/utils.r#L74
ensure_installed <- function(pkg) {
  if (!is_installed(pkg)) {
    msg <- paste0(sQuote(pkg), " must be installed for this functionality.")
    if (interactive()) {
      message(msg, "\nWould you like to install it?")
      if (menu(c("Yes", "No")) == 1) {
        install.packages(pkg)
      } else {
        stop(msg, call. = FALSE)
      }
    } else {
      stop(msg, call. = FALSE)
    }
  }
}
