# Create codeset workbook ------------------------------------------------------
OhdsiRTools::createConceptSetWorkbook(conceptSetIds = 7468:7484, 
                                      workFolder =  "S:/StudyResults/UkaTkaSafetyFull/report",
                                      baseUrl = Sys.getenv("baseUrl"),
                                      included = TRUE,
                                      mapped = TRUE,
                                      formatName = TRUE)