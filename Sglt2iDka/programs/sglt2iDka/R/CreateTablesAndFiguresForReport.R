#' @export
createTableAndFiguresForReport <- function(outputFolders,
                                           databaseNames,
                                           maOutputFolder,
                                           reportFolder) {
  if (!file.exists(reportFolder))
    dir.create(reportFolder, recursive = TRUE)

  # population characteristics
  sglt2iDka::createPopCharTable(outputFolders, databaseNames, reportFolder)

  # IR tables main
  sglt2iDka::createIrTable(outputFolders, databaseNames, reportFolder, sensitivity = FALSE)
  sglt2iDka::createIrTableFormatted(outputFolders, databaseNames, reportFolder, sensitivity = FALSE)

  # IR tables sensitivity
  sglt2iDka::createIrTable(outputFolders, databaseNames, reportFolder, sensitivity = TRUE)
  sglt2iDka::createIrSensitivityTableFormatted(outputFolders, databaseNames, reportFolder)
  sglt2iDka::createIrSubgroupsTableFormatted(outputFolders, databaseNames, reportFolder)

  # IR tables dose
  sglt2iDka::createIrDoseTable(outputFolders, databaseNames, reportFolder)
  sglt2iDka::createIrDoseTableFormatted(outputFolders, databaseNames, reportFolder)

  # HR tables
  sglt2iDka::createHrTable(outputFolders, databaseNames, maOutputFolder, reportFolder)
  sglt2iDka::createHrTableFormatted(outputFolders, databaseNames, maOutputFolder, reportFolder)
  sglt2iDka::createHrPlots(outputFolders, maOutputFolder, reportFolder)
  sglt2iDka::createHrHeterogeneityTable(outputFolders, databaseNames, reportFolder)
  sglt2iDka::createHrHeterogeneityPlots(outputFolders, databaseNames, reportFolder)
}
