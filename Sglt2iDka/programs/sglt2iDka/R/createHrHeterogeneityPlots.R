#' @export
createHrHeterogeneityPlots <- function(outputFolders,
                                       databaseNames,
                                       reportFolder) {
  loadResultsHrsByQ <- function(outputFolder) {
    file <- file.path(outputFolder, "diagnostics", "effectHeterogeneity.csv")
    x <- read.csv(file, stringsAsFactors = FALSE)
    return(x)
  }
  results <- lapply(outputFolders, loadResultsHrsByQ)
  results <- do.call(rbind, results)
  results$tOrder <- match(results$targetName, c("SGLT2i-BROAD-90",
                                                "SGLT2i-NARROW-90",
                                                "Canagliflozin-BROAD-90",
                                                "Canagliflozin-NARROW-90",
                                                "Dapagliflozin-BROAD-90",
                                                "Dapagliflozin-NARROW-90",
                                                "Empagliflozin-BROAD-90",
                                                "Empagliflozin-NARROW-90"))
  results$cOrder <- match(results$comparatorName, c("SU-BROAD-90",
                                                    "SU-NARROW-90",
                                                    "DPP-4i-BROAD-90",
                                                    "DPP-4i-NARROW-90",
                                                    "GLP-1a-BROAD-90",
                                                    "GLP-1a-NARROW-90",
                                                    "TZDs-BROAD-90",
                                                    "TZDs-NARROW-90",
                                                    "Insulin-BROAD-90",
                                                    "Insulin-NARROW-90",
                                                    "Metformin-BROAD-90",
                                                    "Metformin-NARROW-90",
                                                    "Insulinotropic AHAs-BROAD-90",
                                                    "Insulinotropic AHAs-NARROW-90",
                                                    "Other AHAs-BROAD-90",
                                                    "Other AHAs-NARROW-90"))
  results <- results[order(results$tOrder, results$cOrder), ]
  dbPlots <- list()
  for (db in unique(results$database)) { #     db="MDCR"
    dbResults <- results[results$analysisId == 1 & results$targetId %in% c(11, 14) & results$outcomeId == 200 & results$database == db, ]
    dbResults$logRr[dbResults$eventsTreated == 0 | dbResults$eventsComparator == 0] <- NA
    tcsOfInterest <- unique(dbResults[, c("targetId", "comparatorId")])
    plots <- list()
    for (i in 1:nrow(tcsOfInterest)) { # i=6
      targetId <- tcsOfInterest$targetId[i]
      comparatorId <- tcsOfInterest$comparatorId[i]
      tcResult <- dbResults[dbResults$targetId == targetId & dbResults$comparatorId == comparatorId, ]
      targetName <- sub(pattern = "-90", replacement = "", x = tcResult$targetName[1])
      comparatorName <- sub(pattern = "-90", replacement = "", x = tcResult$comparatorName[1])
      comparatorName <- sub("Insulinotropic", "Ins.", comparatorName)
      data <- data.frame(database = tcResult$database,
                         Quintile = tcResult$quintile,
                         logRr = tcResult$logRr,
                         logLb = tcResult$logRr + qnorm(0.025) * tcResult$seLogRr,
                         logUb = tcResult$logRr + qnorm(0.975) * tcResult$seLogRr)
      breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 10)
      labels <- c(0.1, paste("0.25\nFavors", targetName), 0.5, 1, 2, paste("4\nFavors", comparatorName), 10)
      plot <- ggplot2::ggplot(data,
                              ggplot2::aes(x = exp(logRr),
                                           y = Quintile,
                                           xmin = exp(logLb),
                                           xmax = exp(logUb)),
                              environment = environment()) +
        ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.1) +
        ggplot2::geom_vline(xintercept = 1, colour = "#000000", lty = 1, size = 0.75) +
        ggplot2::geom_errorbarh(height = 0, size = 1, alpha = 0.7, ggplot2::aes(colour = database)) +
        ggplot2::geom_point(shape = 16, size = 2.2, alpha = 0.7, ggplot2::aes(colour = database)) +
        ggplot2::coord_cartesian(xlim = c(0.1, 10)) +
        ggplot2::scale_x_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = labels) +
        ggplot2::scale_y_continuous(trans = "reverse") +
        ggplot2::theme(text = ggplot2::element_text(size = 15),
                       panel.grid.minor = ggplot2::element_blank(),
                       panel.background = ggplot2::element_rect(fill = "#FAFAFA",colour = NA),
                       panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                       axis.ticks = ggplot2::element_blank(),
                       axis.title.y = ggplot2::element_blank(),
                       axis.title.x = ggplot2::element_blank(),
                       #axis.text.y = ggplot2::element_blank(),
                       axis.text.y = ggplot2::element_text(size = 8),
                       axis.text.x = ggplot2::element_text(size = 8),
                       legend.position = "none")
      plots[[length(plots) + 1]] <- plot
    }
    col0 <- grid::textGrob(db, gp = grid::gpar(fontface = "bold"))
    col1 <- grid::textGrob("SGLT2i-BROAD")
    col2 <- grid::textGrob("SGLT2i-NARROW")
    row1 <- grid::textGrob("SU", rot = 90)
    row2 <- grid::textGrob("DPP-4i", rot = 90)
    row3 <- grid::textGrob("GLP-1a", rot = 90)
    row4 <- grid::textGrob("TZDs", rot = 90)
    row5 <- grid::textGrob("Insulin", rot = 90)
    row6 <- grid::textGrob("Metformin", rot = 90)
    row7 <- grid::textGrob("Ins. AHAs", rot = 90)

    dbPlot <- gridExtra::grid.arrange(col0, col1, col2,
                                      row1, plots[[1]], plots[[8]],
                                      row2, plots[[2]], plots[[9]],
                                      row3, plots[[3]], plots[[10]],
                                      row4, plots[[4]], plots[[11]],
                                      row5, plots[[5]], plots[[12]],
                                      row6, plots[[6]], plots[[13]],
                                      row7, plots[[7]], plots[[14]], nrow = 8,
                                      heights = grid::unit(c(5, rep(30,7)), rep("mm",7)),
                                      widths =  grid::unit(c(10, rep(75,2)), rep("mm",3)))
    dbPlots[[length(dbPlots) + 1]] <- dbPlot
  }

  finalPlot <- gridExtra::grid.arrange(dbPlots[[1]], dbPlots[[2]],
                                       dbPlots[[3]], dbPlots[[4]],
                                       ncol = 2)
  plotFile <- file.path(reportFolder, "hrHeterogeneityPlot.png")
  ggplot2::ggsave(filename = plotFile, plot = finalPlot, width = 14, height = 18)
}
