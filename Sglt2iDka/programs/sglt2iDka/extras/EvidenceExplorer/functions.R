plotBalance <- function(balance,
                        beforeLabel = "Before matching",
                        afterLabel = "After matching") {
  limits <- c(min(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff), na.rm = TRUE),
              max(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff), na.rm = TRUE))
  plot <- ggplot2::ggplot(balance,
                          ggplot2::aes(x = absBeforeMatchingStdDiff, y = absAfterMatchingStdDiff)) +
    ggplot2::geom_point(color = rgb(0, 0, 0.8, alpha = 0.3), shape = 16, size = 2) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_vline(xintercept = 0) +
    ggplot2::scale_x_continuous(beforeLabel, limits = limits) +
    ggplot2::scale_y_continuous(afterLabel, limits = limits) +
    ggplot2::theme(text = ggplot2::element_text(size = 15))
  return(plot)
}

plotForest <- function(subset, row) {
  comparatorName <- row$comparatorDrug
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  labels <- c(0.1, paste("0.25\nFavors" , row$targetDrug), 0.5, 1, 2, paste("4\nFavors" , row$comparatorDrug), 6, 8, 10)
  col <- c(rgb(0, 0, 0.8, alpha = 1), rgb(0.8, 0.4, 0, alpha = 1))
  colFill <- c(rgb(0, 0, 1, alpha = 0.5), rgb(1, 0.4, 0, alpha = 0.5))
  highlight <- subset[subset$targetId == row$targetId &
                        subset$comparatorId == row$comparatorId &
                        subset$outcomeId == row$outcomeId &
                        subset$analysisId == row$analysisId &
                        subset$database == row$database, ]
  plot <- ggplot2::ggplot(subset, ggplot2::aes(x = rr, 
                                               y = displayOrder, 
                                               xmin = ci95lb, 
                                               xmax = ci95ub, 
                                               fill = timeAtRisk), environment = environment()) + 
    ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
    ggplot2::geom_vline(xintercept = 1, colour = "#000000", lty = 1, size = 0.5) + 
    ggplot2::geom_errorbarh(height = 0, alpha = 0.7, size = 1.5, aes(colour = timeAtRisk)) + 
    ggplot2::geom_point(shape = 18, size = 5, alpha = 0.7, aes(colour = timeAtRisk)) + 
    ggplot2::geom_errorbarh(height = 0, alpha = 1, size = 1.5, color = rgb(0,0,0), data = highlight, show.legend = FALSE) +
    ggplot2::geom_point(shape = 18, size = 5, color = rgb(0,0,0), alpha = 1, data = highlight, show.legend = FALSE) +
    ggplot2::coord_cartesian(xlim = c(0.1, 10), clip = "off") + 
    ggplot2::scale_x_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = labels) + 
    ggplot2::scale_y_discrete() +
    ggplot2::facet_grid(database ~ ., scales = "free_y", space = "free") + 
    ggplot2::labs(color = "Time-at-risk", fill = "Time-at-risk") +
    ggplot2::theme(text = ggplot2::element_text(size = 15),
                   panel.grid.minor = ggplot2::element_blank(), 
                   panel.background = ggplot2::element_rect(fill = "gray93", colour = NA), # "#FAFAFA"
                   panel.grid.major = ggplot2::element_line(colour = "#EEEEEE"),
                   axis.ticks = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank(), 
                   axis.title.x = ggplot2::element_blank(), 
                   axis.text.y = ggplot2::element_blank(),
                   legend.position = "top")  
  return(plot)
}