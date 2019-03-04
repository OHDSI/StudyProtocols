

#' Create 2x2 KM Plot Panels using existing KM plot RDS files
#'
#' @param rdsPath               The path to the already generated KM plots stored as RDS files
#' @param cdmDatabaseSchemas    A list of CDM names
#' @param tcos                  (OPTIONAL) A list of Target-Comparator-Outcome lists. By default, run the createTcos function.
#' @param cohorts               (OPTIONAL) A data frame of the cohort universe. By default, read the CohortUniverse CSV file.
#' @param outcomes              (OPTIONAL) A data frame of outcome cohorts ("id" and "name" are the fields). By default, this is auto-generated.
#'
#' @export
createKmPlotPanels <- function(rdsPath,
                               cdmDatabaseSchemas,
                               tcos = NULL,
                               cohorts = NULL,
                               outcomes = NULL) {

  if (!dir.exists("kmPanels")) {
    dir.create("kmPanels")
  }

  if (missing(tcos)) {
    tcos <- createTcos()
  }
  if (missing(cohorts)) {
    cohorts <- read.csv(system.file("settings", "cohortUniverse.csv", package = "sglt2iDka"), stringsAsFactors = FALSE)
  }

  if (missing(outcomes)) {
    outcomes <- data.frame(
      id = c(200, 201),
      name = c("DKA (IP & ER)", "DKA (IP)")
    )
  }

  # for each analysis, go through TC-pairs and their outcomes to then obtain the associated RDS file
  for (analysis in c(1:2)) {
    for (tco in tcos) {
      for (outcomeId in outcomes$id) {
        grobs <- lapply(cdmDatabaseSchemas, function(cdmDb) {

          rdsFilePath <- file.path(rdsPath, sprintf("km_a%1d_t%2d_c%3d_o%4d_%1s.rds",
                                                    analysis,
                                                    tco$targetId,
                                                    tco$comparatorId,
                                                    outcomeId,
                                                    cdmDb))
          rdsFilePath <- gsub(pattern = " ", replacement = "", x = rdsFilePath)
          writeLines(rdsFilePath)

          if (file.exists(rdsFilePath)) {

            # the file exists, format it

            thisRds <- readRDS(rdsFilePath)

            title <- textGrob(cdmDb, gp = gpar(fontsize = 12, fontface = "bold"))
            padding <- grid::unit(x = 1, units = "line")

            thisPlot <- gtable::gtable_add_rows(x = thisRds, heights = grobHeight(title) + padding, pos = 0)
            thisPlot <- gtable::gtable_add_grob(thisPlot, title, t = 1, l = 1, r = ncol(thisPlot))
          } else {
            thisPlot <- NULL
          }

          thisPlot
        })

        # only grab non-null plots
        grobs <- grobs[!sapply(grobs, is.null)]


        # create the new panel image file path
        panelPath <- sprintf("kmPanels/km_a%1d_t%2d_c%3d_o%4d.png",
                             analysis,
                             tco$targetId,
                             tco$comparatorId,
                             outcomeId)
        panelPath <- gsub(pattern = " ", replacement = "", x = panelPath)

        # format the panel plot and save it
        titleText <- sprintf("%1s vs %2s: %3s",
                             gsub(pattern = "-90", replacement = "", x = cohorts$FULL_NAME[cohorts$COHORT_DEFINITION_ID == tco$targetId]),
                             gsub(pattern = "-90", replacement = "", x = cohorts$FULL_NAME[cohorts$COHORT_DEFINITION_ID == tco$comparatorId]),
                             outcomes$name[outcomes$id == outcomeId])

        gridTitle <- textGrob(titleText, gp = gpar(fontface = "bold"))

        plotGrid <- do.call("grid.arrange", c(grobs, ncol = 2))

        padding <- grid::unit(x = 1, units = "line")
        plotGrid <- gtable::gtable_add_rows(x = plotGrid, heights = grobHeight(gridTitle) + padding, pos = 0)
        plotGrid <- gtable::gtable_add_grob(plotGrid, gridTitle, t = 1, l = 1, r = ncol(plotGrid))

        ggplot2::ggsave(filename = panelPath, plot = plotGrid,
                        width = 14, height = 18)


      }
    }
  }
}



