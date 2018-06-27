# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of EvaluatingCaseControl
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

computeSampleSize <- function(outputFolder) {
  OhdsiRTools::logInfo("Computing sample size and power")
  ccdFile = file.path(outputFolder, "ccIbd", "ccd_cd1_cc1_o3_ed1_e5_ccd1.rds")
  ccd <- readRDS(ccdFile)
  row1 <- CaseControl::computeMdrr(ccd)
  row1$Study <- "Crockett et al."
  row1$Outcome <- "Ulcerative colitis"
  row1$exposure <- "Isotretinoin"

  ccdFile = file.path(outputFolder, "ccAp", "ccd_cd1_n1_cc1_o2_ed1_e4_ccd1.rds")
  ccd <- readRDS(ccdFile)
  row2 <- CaseControl::computeMdrr(ccd)
  row2$Study <- "Chou et al."
  row2$Outcome <- "Acute pancreatitis"
  row2$exposure <- "DPP-4 inhibitors"

  table <- rbind(row1, row2)
  write.csv(table, file.path(outputFolder, "SampleSize.csv"), row.names = FALSE)
}
