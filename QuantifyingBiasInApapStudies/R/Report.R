# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of QuantifyingBiasInApapStudies
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

#' Generate a report containing the main results
#'
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#'
#' @export
generateReport <- function(outputFolder) {
  fileName <- file.path(outputFolder, "QuantifyingBiasInApapStudiesReport.docx")
  rmarkdown::render(system.file("rmarkdown", "report.Rmd", package = "QuantifyingBiasInApapStudies"),
                    params = list(outputFolder = outputFolder),
                    output_file = fileName,
                    rmarkdown::word_document(toc = TRUE, fig_caption = TRUE))
  ParallelLogger::logInfo("Report generated: ", fileName)
}