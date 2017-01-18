require(ggplot2)

plotScatter <- function(d, size = 1) {
    d <- d[!is.na(d$logRr), ]
    if (nrow(d) == 0) {
        return(NULL)
    }
    d$Group <- as.factor(d$trueRr)
    d$Significant <- d$ci95lb > d$trueRr | d$ci95ub < d$trueRr


    temp1 <- aggregate(Significant ~ Group, data = d, length)
    temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
    temp1$Significant <- NULL
    temp2 <- aggregate(Significant ~ Group, data = d, mean)
    temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"),
                              "% of CIs includes ",
                              temp2$Group)
    temp2$Significant <- NULL
    dd <- merge(temp1, temp2)
    dd$tes <- as.numeric(as.character(dd$Group))

    breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
    theme <- element_text(colour = "#000000", size = 12)
    themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
    themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)

    d$Group <- paste("True hazard ratio =", d$Group)
    dd$Group <- paste("True hazard ratio =", dd$Group)
    alpha <- 1 - min(0.95*(nrow(d)/nrow(dd)/50000)^0.1, 0.95)
    plot <- ggplot(d, aes(x = logRr, y= seLogRr), environment = environment()) +
        geom_vline(xintercept = log(breaks), colour = "#AAAAAA", lty = 1, size = 0.5) +
        geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.025), slope = 1/qnorm(0.025)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5, data = dd) +
        geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.975), slope = 1/qnorm(0.975)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5, data = dd) +
        geom_point(size = size, color = rgb(0, 0, 0, alpha = 0.05), alpha = alpha, shape = 16) +
        geom_hline(yintercept = 0) +
        geom_label(x = log(0.3), y = 0.95, alpha = 1, hjust = "left", label = dd$nLabel, size = 5, data = dd) +
        geom_label(x = log(0.3), y = 0.8, alpha = 1, hjust = "left", label = dd$meanLabel, size = 5, data = dd) +
        scale_x_continuous("Hazard ratio", limits = log(c(0.25, 10)), breaks = log(breaks), labels = breaks) +
        scale_y_continuous("Standard Error", limits = c(0, 1)) +
        facet_grid(. ~ Group) +
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

    return(plot)
}
