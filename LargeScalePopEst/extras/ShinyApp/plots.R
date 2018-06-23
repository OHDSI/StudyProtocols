plotCovariateBalanceScatterPlot <- function(balance) {
  limits <- c(min(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff), na.rm = TRUE),
              max(c(balance$absBeforeMatchingStdDiff, balance$absAfterMatchingStdDiff), na.rm = TRUE))
  theme <- element_text(colour = "#000000", size = 12)
  plot <- ggplot(balance, aes(x = absBeforeMatchingStdDiff, y = absAfterMatchingStdDiff)) +
    geom_point(color = rgb(0, 0, 0.8, alpha = 0.3)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = 0) +
    scale_x_continuous("Before stratification", limits = limits) +
    scale_y_continuous("After stratification", limits = limits) +
    theme(text = theme)
  
  return(plot)
}

plotScatter <- function(d, selected, xLabel) {
  d$Significant <- d$ci95lb > 1 | d$ci95ub < 1
  
  oneRow <- data.frame(
    nLabel = paste0(formatC(nrow(d), big.mark = ","), " estimates"),
    meanLabel = paste0(formatC(100 * mean(!d$Significant, na.rm = TRUE), digits = 1, format = "f"), "% of CIs include 1"))
  
  breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- element_text(colour = "#000000", size = 12)
  themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
  themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)
  
  alpha <- 1 - min(0.95*(nrow(d)/50000)^0.1, 0.95)
  plot <- ggplot(d, aes(x = logRr, y = seLogRr)) +
    geom_vline(xintercept = log(breaks), colour = "#AAAAAA", lty = 1, size = 0.5) +
    geom_abline(aes(intercept = 0, slope = 1/qnorm(0.025)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5) +
    geom_abline(aes(intercept = 0, slope = 1/qnorm(0.975)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5) +
    geom_point(size = 2, color = rgb(0, 0, 0, alpha = 0.05), alpha = alpha, shape = 16) +
    geom_hline(yintercept = 0) +
    geom_label(x = log(0.11), y = 1, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = oneRow) +
    geom_label(x = log(0.11), y = 0.935, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = oneRow) +
    scale_x_continuous(xLabel, limits = log(c(0.1, 10)), breaks = log(breaks), labels = breaks) +
    scale_y_continuous("Standard Error", limits = c(0, 1)) +
    theme(panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          panel.grid.major = element_blank(),
          axis.ticks = element_blank(),
          axis.text.y = themeRA,
          axis.text.x = theme,
          axis.title = theme,
          legend.key = element_blank(),
          strip.text.x = theme,
          strip.background = element_blank(),
          legend.position = "none")
  if (!is.null(selected) && nrow(selected) != 0) {
    if (!is.null(selected$db)) {
      otherDbs <- d[d$db != selected$db[1] & d$targetName == selected$targetName[1] & d$comparatorName == selected$comparatorName[1] & d$outcomeName == selected$outcomeName[1], ]
      plot <- plot + geom_point(data = otherDbs, size=4, color = rgb(0,0,0), fill = rgb(0.5, 0.5, 1), shape = 23, alpha = 0.8)
    }
    plot <- plot + geom_point(data = selected, size=4, color = rgb(0,0,0), fill = rgb(1,1,0), shape = 23)

  }
  return(plot)
}

plotPs <- function(ps, target, comparator) {
  ps$GROUP <- as.character(target)
  ps$GROUP[ps$treatment == 0] <- as.character(comparator)
  ps$GROUP <- factor(ps$GROUP, levels = c(as.character(target), as.character(comparator)))
  theme <- element_text(colour = "#000000", size = 12)
  plot <- ggplot(ps, aes(x = x, y = y, color = GROUP, group = GROUP, fill = GROUP)) +
    geom_density(stat = "identity") +
    scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) +
    scale_x_continuous("Preference score", limits = c(0, 1)) +
    scale_y_continuous("Density") +
    theme(legend.title = element_blank(), 
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(), 
          legend.position = "top",
          legend.text = theme,
          axis.text = theme,
          axis.title = theme)
  return(plot)
}

plotForest <- function(estimate, showCalibrated = TRUE) {
  d1 <- data.frame(logRr = estimate$logRr,
                   logLb95Rr = log(estimate$ci95lb),
                   logUb95Rr = log(estimate$ci95ub),
                   database = estimate$db,
                   type = "Uncalibrated")
  if (showCalibrated) {
  d2 <- data.frame(logRr = estimate$calLogRr,
                   logLb95Rr = log(estimate$calCi95lb),
                   logUb95Rr = log(estimate$calCi95ub),
                   database = estimate$db,
                   type = "Calibrated")
  
  d <- rbind(d1, d2)
  } else {
    d <- d1
  }
  d$significant <- d$logLb95Rr > 0 | d$logUb95Rr < 0
  
  breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
  theme <- element_text(colour = "#000000", size = 12)
  themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
  col <- c(rgb(0, 0, 0.8, alpha = 1), rgb(0.8, 0.4, 0, alpha = 1))
  colFill <- c(rgb(0, 0, 1, alpha = 0.5), rgb(1, 0.4, 0, alpha = 0.5))
  if (all(!d$significant)) {
    col <- col[1]
    colFill <- colFill[1]
  }
  if (all(d$significant)) {
    col <- col[2]
    colFill <- colFill[2]
  }
  d$database <- as.factor(d$database)
  d$database <- factor(d$database, levels = rev(levels(d$database)))
  plot <- ggplot(d, aes(x = database, y = exp(logRr), ymin = exp(logLb95Rr), ymax = exp(logUb95Rr), colour = significant, fill = significant)) + 
    geom_hline(yintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) + 
    geom_hline(yintercept = 1, size = 0.5) + 
    geom_pointrange(shape = 23, size = 0.5) + 
    scale_colour_manual(values = col) + 
    scale_fill_manual(values = colFill) + 
    coord_flip(ylim = c(0.25, 10)) + 
    scale_y_continuous("Hazard ratio", trans = "log10", breaks = breaks, labels = breaks) + 
    facet_grid(type~.) + 
    theme(panel.grid.minor = element_blank(), 
          panel.background = element_rect(fill = "#FAFAFA", colour = NA), 
          panel.grid.major = element_line(colour = "#EEEEEE"), 
          axis.ticks = element_blank(), 
          axis.title.y = element_blank(), 
          axis.title.x = theme, 
          axis.text.y = themeRA, 
          axis.text.x = theme, 
          legend.key = element_blank(), 
          strip.text.y = theme, 
          strip.background = element_blank(), 
          legend.position = "none")
  return(plot)
}