plotForest <- function(logRr, logLb95Ci, logUb95Ci, names, xLabel = "Relative risk", fileName = NULL) {
    # logRr <- results$logRr
    # logLb95Ci <- log(results$ci95lb)
    # logUb95Ci <- log(results$ci95ub)
    # names <- results$db
    seLogRr <- (logUb95Ci-logLb95Ci) / (2 * qnorm(0.975))
    meta <- meta::metagen(logRr, seLogRr, studlab = names, sm = "RR")
    s <- summary(meta)$random
    d1 <- data.frame(logRr = logRr,
                     logLb95Ci = logLb95Ci,
                     logUb95Ci = logUb95Ci,
                     name = names,
                     type = "db")
    d2 <- data.frame(logRr = s$TE,
                     logLb95Ci = s$lower,
                     logUb95Ci = s$upper,
                     name = "Summary",
                     type = "ma")
    d3 <- data.frame(logRr = NA,
                     logLb95Ci = NA,
                     logUb95Ci = NA,
                     name = "Source",
                     type = "header")

    d <- rbind(d1, d2, d3)
    d$name <- factor(d$name, levels = c("Summary", rev(sort(as.character(names))), "Source"))

    breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
    p <- ggplot2::ggplot(d,ggplot2::aes(x = exp(logRr), y = name, xmin = exp(logLb95Ci), xmax = exp(logUb95Ci))) +
        ggplot2::geom_vline(xintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
        ggplot2::geom_vline(xintercept = 1, size = 0.5) +
        ggplot2::geom_errorbarh(height = 0.15) +
        ggplot2::geom_point(size=3, shape = 23, ggplot2::aes(fill=type)) +
        ggplot2::scale_fill_manual(values = c("#000000", "#FFFFFF", "#FFFFFF")) +
        ggplot2::scale_x_continuous(xLabel, trans = "log10", breaks = breaks, labels = breaks) +
        ggplot2::coord_cartesian(xlim = c(0.25, 10)) +
        ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
              panel.grid.minor = ggplot2::element_blank(),
              panel.background = ggplot2::element_blank(),
              legend.position = "none",
              panel.border = ggplot2::element_blank(),
              axis.text.y = ggplot2::element_blank(),
              axis.title.y = ggplot2::element_blank(),
              axis.ticks = ggplot2::element_blank(),
              plot.margin = grid::unit(c(0,0,0.1,0), "lines"))

    labels <- paste0(formatC(exp(d$logRr),  digits = 2, format = "f"),
                     " (",
                     formatC(exp(d$logLb95Ci), digits = 2, format = "f"),
                     "-",
                     formatC(exp(d$logUb95Ci), digits = 2, format = "f"),
                     ")")

    labels <- data.frame(y = rep(d$name, 2),
                         x = rep(1:2, each = nrow(d)),
                         label = c(as.character(d$name), labels))

    levels(labels$label)[1] <-  paste(xLabel,"(95% CI)")

    data_table <- ggplot2::ggplot(labels, ggplot2::aes(x = x, y = y, label = label)) +
        ggplot2::geom_text(size = 4, hjust=0, vjust=0.5) +
        ggplot2::geom_hline(ggplot2::aes(yintercept=nrow(d) - 0.5)) +
        ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
              panel.grid.minor = ggplot2::element_blank(),
              legend.position = "none",
              panel.border = ggplot2::element_blank(),
              panel.background = ggplot2::element_blank(),
              axis.text.x = ggplot2::element_text(colour="white"),#element_blank(),
              axis.text.y = ggplot2::element_blank(),
              axis.ticks = ggplot2::element_line(colour="white"),#element_blank(),
              plot.margin = grid::unit(c(0,0,0.1,0), "lines")) +
        ggplot2::labs(x="",y="") +
        ggplot2::coord_cartesian(xlim=c(1,3))

    plot <- gridExtra::grid.arrange(data_table, p, ncol=2)

    if (!is.null(fileName))
        ggplot2::ggsave(fileName, plot, width = 7, height = 1 + length(logRr) * 0.4, dpi = 400)
}
