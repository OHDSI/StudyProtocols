# Copyright 2017 Observational Health Data Sciences and Informatics
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

#' Write a report summarizing all the results for a single database
#'
#' @details
#' Requires that the \code{\link{createTableAndFigures}} has been executed first.
#'
#' @param exportFolder   The path to the export folder containing the results.
#' @param outputFile     The name of the output file that will be created.
#' @param outputFormat   Format for output
#'
#' @export
writeReport <- function(exportFolder, outputFile,
                        outputFormat = rmarkdown::word_document(toc = TRUE, fig_caption = TRUE)) {
    rmarkdown::render(system.file("markdown", "Report.rmd", package = "AlendronateVsRaloxifene"),
                      params = list(exportFolder = exportFolder),
                      output_file = outputFile,
                      output_format = outputFormat
                      )
}
