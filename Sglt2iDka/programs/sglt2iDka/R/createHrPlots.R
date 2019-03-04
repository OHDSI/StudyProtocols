#' @export
createHrPlots <- function(outputFolders,
                          maOutputFolder,
                          reportFolder) {
  loadResultsHois <- function(outputFolder,
                              fileName) {
    shinyDataFolder <- file.path(outputFolder, "results", "shinyData")
    file <- list.files(shinyDataFolder, pattern = "resultsHois_.*.rds", full.names = TRUE)
    x <- readRDS(file)
    if (is.null(x$i2))
      x$i2 <- NA
    return(x)
  }
  results <- lapply(c(outputFolders, maOutputFolder), loadResultsHois)
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
  results$targetName <- sub(pattern = "-90", replacement = "", x = results$targetName)
  results$comparatorName <- sub(pattern = "-90", replacement = "", x = results$comparatorName)
  results$comparatorName <- sub("Insulinotropic", "Ins.", results$comparatorName)
  results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Intent to Treat Matching"] <- "ITT"
  results$timeAtRisk[results$analysisDescription == "Time to First Post Index Event Per Protocol Matching"] <- "PP"
  results$logRr[results$eventsTreated == 0 | results$eventsComparator == 0] <- NA

  resultsTable4 <- results[(results$targetName == "SGLT2i-BROAD" | results$targetName == "SGLT2i-NARROW") &
                             results$outcomeName == "DKA (IP & ER)" & results$timeAtRisk == "ITT", ]
  resultsTable5 <- results[(results$targetName == "Canagliflozin-BROAD" | results$targetName == "Canagliflozin-NARROW") &
                             results$outcomeName == "DKA (IP & ER)" & results$timeAtRisk == "ITT", ]
  resultsTable6 <- results[(results$targetName == "Dapagliflozin-BROAD" | results$targetName == "Dapagliflozin-NARROW") &
                             results$outcomeName == "DKA (IP & ER)" & results$timeAtRisk == "ITT", ]
  resultsTable7 <- results[(results$targetName == "Empagliflozin-BROAD" | results$targetName == "Empagliflozin-NARROW") &
                             results$outcomeName == "DKA (IP & ER)" & results$timeAtRisk == "ITT", ]
  resultsAppendix4 <- results[(results$targetName == "SGLT2i-BROAD" | results$targetName == "SGLT2i-NARROW") &
                                results$outcomeName == "DKA (IP)" & results$timeAtRisk == "ITT", ]
  resultsAppendix5 <- results[(results$targetName == "SGLT2i-BROAD" | results$targetName == "SGLT2i-NARROW") &
                                results$outcomeName == "DKA (IP & ER)" & results$timeAtRisk == "PP", ]
  resultSets <- list(Table4 = resultsTable4,
                     Table5 = resultsTable5,
                     Table6 = resultsTable6,
                     Table7 = resultsTable7,
                     AppendixTable4 = resultsAppendix4,
                     AppendixTable5 = resultsAppendix5)

  generatePlot <- function(analysisData,
                           targetDrug,
                           tableName) {
    tcsOfInterest <- unique(analysisData[, c("targetId", "comparatorId")])
    plots <- list()
    for (i in 1:nrow(tcsOfInterest)) { # i=9
      targetId <- tcsOfInterest$targetId[i]
      comparatorId <- tcsOfInterest$comparatorId[i]
      tcResult <- analysisData[analysisData$targetId == targetId & analysisData$comparatorId == comparatorId, ]
      targetName <- tcResult$targetName[1]
      comparatorName <- tcResult$comparatorName[1]
      data <- data.frame(database = tcResult$database,
                         logRr = tcResult$logRr,
                         logLb = tcResult$logRr + qnorm(0.025) * tcResult$seLogRr,
                         logUb = tcResult$logRr + qnorm(0.975) * tcResult$seLogRr)
      breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 10)
      labels <- c(0.1, paste("0.25\nFavors", targetName), 0.5, 1, 2, paste("4\nFavors", comparatorName), 10)
      plot <- ggplot2::ggplot(data,
                              ggplot2::aes(x = exp(logRr),
                                           y = database,
                                           xmin = exp(logLb),
                                           xmax = exp(logUb)),
                              environment = environment()) +
        ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.1) +
        ggplot2::geom_vline(xintercept = 1, colour = "#000000", lty = 1, size = 1) +
        ggplot2::geom_errorbarh(height = 0, size = 2, alpha = 0.7, ggplot2::aes(colour = "red")) +
        ggplot2::geom_point(shape = 16, size = 4.4, alpha = 0.7, ggplot2::aes(colour = "red")) +
        ggplot2::coord_cartesian(xlim = c(0.1, 10)) +
        ggplot2::scale_x_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = labels) +
        ggplot2::scale_y_discrete(limits = c("Meta-analysis", "Optum", "MDCR", "MDCD", "CCAE")) +
        ggplot2::theme(text = ggplot2::element_text(size = 15),
                       panel.grid.minor = ggplot2::element_blank(),
                       panel.background = ggplot2::element_rect(fill = "#FAFAFA",colour = NA),
                       panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                       axis.ticks = ggplot2::element_blank(),
                       axis.title.y = ggplot2::element_blank(),
                       axis.title.x = ggplot2::element_blank(),
                       #axis.text.y = ggplot2::element_blank(),
                       axis.text.y = ggplot2::element_text(size = 14),
                       axis.text.x = ggplot2::element_text(size = 13),
                       legend.position = "none")
      plots[[length(plots) + 1]] <- plot
    }
    col1 <- grid::textGrob(paste0(targetDrug, "-BROAD"), gp = grid::gpar(fontsize = 18))
    col2 <- grid::textGrob(paste0(targetDrug, "-NARROW"), gp = grid::gpar(fontsize = 18))
    col0 <- grid::textGrob("")
    row1 <- grid::textGrob("SU", rot = 90, gp = grid::gpar(fontsize = 18))
    row2 <- grid::textGrob("DPP-4i", rot = 90, gp = grid::gpar(fontsize = 18))
    row3 <- grid::textGrob("GLP-1a", rot = 90, gp = grid::gpar(fontsize = 18))
    row4 <- grid::textGrob("TZDs", rot = 90, gp = grid::gpar(fontsize = 18))
    row5 <- grid::textGrob("Insulin", rot = 90, gp = grid::gpar(fontsize = 18))
    row6 <- grid::textGrob("Metformin", rot = 90, gp = grid::gpar(fontsize = 18))
    row7 <- grid::textGrob("Ins. AHAs", rot = 90, gp = grid::gpar(fontsize = 18))
    row8 <- grid::textGrob("Other AHAs", rot = 90, gp = grid::gpar(fontsize = 18))
    if (nrow(tcsOfInterest) == 14) {
      plot <- gridExtra::grid.arrange(col0, col1, col2,
                                      row1, plots[[1]], plots[[8]],
                                      row2, plots[[2]], plots[[9]],
                                      row3, plots[[3]], plots[[10]],
                                      row4, plots[[4]], plots[[11]],
                                      row5, plots[[5]], plots[[12]],
                                      row6, plots[[6]], plots[[13]],
                                      row7, plots[[7]], plots[[14]], nrow = 8,
                                      heights = grid::unit(c(5*2, rep(30*2,7)), rep("mm",7)),
                                      widths =  grid::unit(c(10*2, rep(75*2,2)), rep("mm",3)))
      height <- 18
    }
    if (nrow(tcsOfInterest) == 16) {
      plot <- gridExtra::grid.arrange(col0, col1, col2,
                                      row1, plots[[1]], plots[[9]],
                                      row2, plots[[2]], plots[[10]],
                                      row3, plots[[3]], plots[[11]],
                                      row4, plots[[4]], plots[[12]],
                                      row5, plots[[5]], plots[[13]],
                                      row6, plots[[6]], plots[[14]],
                                      row7, plots[[7]], plots[[15]],
                                      row8, plots[[8]], plots[[16]], nrow = 9,
                                      heights = grid::unit(c(5*2, rep(30*2,8)), rep("mm",8)),
                                      widths =  grid::unit(c(10*2, rep(75*2,2)), rep("mm",3)))
      height <- 20
    }
    plotFile <- file.path(reportFolder, paste0("hrPlot_", tableName, ".png"))
    ggplot2::ggsave(filename = plotFile, plot = plot, width = 14, height = height)
  }
  targetDrugs <- c("SGLT2i", "Canagliflozin", "Dapagliflozin", "Empagliflozin", "SGLT2i", "SGLT2i")
  for (i in 1:length(resultSets)) {
    generatePlot(analysisData = resultSets[[i]],
                 targetDrug = targetDrugs[i],
                 tableName = names(resultSets)[i])
  }
}
