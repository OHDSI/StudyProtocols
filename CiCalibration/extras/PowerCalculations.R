cc <- readRDS("S:/Temp/CiCalibration_Mdcd/ccOutput/caseControls_cd1_cc1_o14.rds")
CaseControl::getAttritionTable(cc)
ccd <- readRDS("S:/Temp/CiCalibration_Mdcd/ccOutput/ccd_cd1_cc1_o14_ed1_e11_ccd1.rds")
CaseControl::computeMdrr(caseControlData = ccd)


sccsEraData <- SelfControlledCaseSeries::loadSccsEraData("S:/Temp/CiCalibration_Mdcd/sccsOutput/Analysis_1/SccsEraData_e11_o14")
length(unique(sccsEraData$outcomes$stratumId[sccsEraData$outcomes$y == 1]))
# Note: a handful of subjects drop out of the SCCS because they have no contrast. This can only happen when their observation time is shorter than a month.
