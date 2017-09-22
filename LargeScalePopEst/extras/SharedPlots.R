require(ggplot2)

plotScatter <- function(d, size = 1, yPanelGroup = FALSE) {
    d <- d[!is.na(d$logRr), ]
    d <- d[!is.na(d$ci95lb), ]
    d <- d[!is.na(d$ci95ub), ]
    if (nrow(d) == 0) {
        return(NULL)
    }
    d$Group <- as.factor(d$trueRr)
    d$Significant <- d$ci95lb > d$trueRr | d$ci95ub < d$trueRr


    if (yPanelGroup) {
        temp1 <- aggregate(Significant ~ Group + yGroup, data = d, length)
        temp2 <- aggregate(Significant ~ Group + yGroup, data = d, mean)
    } else {
        temp1 <- aggregate(Significant ~ Group, data = d, length)
        temp2 <- aggregate(Significant ~ Group, data = d, mean)
    }
    temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
    temp1$Significant <- NULL

    temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"),
                              "% of CIs includes ",
                              temp2$Group)
    temp2$Significant <- NULL
    dd <- merge(temp1, temp2)
    dd$tes <- as.numeric(as.character(dd$Group))

    #breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
    breaks <- c(0.1, 0.25, 0.5, 1, 2, 4, 6, 8, 10)
    theme <- element_text(colour = "#000000", size = 12)
    themeRA <- element_text(colour = "#000000", size = 12, hjust = 1)
    themeLA <- element_text(colour = "#000000", size = 12, hjust = 0)

    d$Group <- paste("True hazard ratio =", d$Group)
    dd$Group <- paste("True hazard ratio =", dd$Group)
    alpha <- 1 - min(0.95*(nrow(d)/nrow(dd)/50000)^0.1, 0.95)
    plot <- ggplot(d, aes(x = logRr, y= seLogRr), environment = environment()) +
        geom_vline(xintercept = log(breaks), colour = "#AAAAAA", lty = 1, size = 0.5) +
        geom_abline(aes(intercept = (-log(tes))/qnorm(0.025), slope = 1/qnorm(0.025)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5, data = dd) +
        geom_abline(aes(intercept = (-log(tes))/qnorm(0.975), slope = 1/qnorm(0.975)), colour = rgb(0.8, 0, 0), linetype = "dashed", size = 1, alpha = 0.5, data = dd) +
        geom_point(size = size, color = rgb(0, 0, 0, alpha = 0.05), alpha = alpha, shape = 16) +
        geom_hline(yintercept = 0) +
        #geom_label(x = log(0.3), y = 0.95, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd) +
        geom_label(x = log(0.15), y = 0.95, alpha = 1, hjust = "left", aes(label = nLabel), size = 5, data = dd) +
        #geom_label(x = log(0.3), y = 0.8, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = dd) +
        geom_label(x = log(0.15), y = 0.8, alpha = 1, hjust = "left", aes(label = meanLabel), size = 5, data = dd) +
        #scale_x_continuous("Hazard ratio", limits = log(c(0.25, 10)), breaks = log(breaks), labels = breaks) +
        scale_x_continuous("Hazard ratio", limits = log(c(0.1, 10)), breaks = log(breaks), labels = breaks) +
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
              strip.text.y = theme,
              strip.background = element_blank(),
              legend.position = "none")

    if (yPanelGroup) {
        plot <- plot + facet_grid(yGroup ~ Group)
    } else {
        plot <- plot + facet_grid(. ~ Group)
    }
    return(plot)
}



plotCiCalibration <- function(d) {

    # data <- d[d$targetId == 750982076 & d$comparatorId ==721724076, ]
    # data <- d[d$comparatorName == "Psychotherapy", ]
    data <- d
    data$trueLogRr <- log(data$trueRr)
    data$strata = as.factor(data$trueLogRr)
    if (any(is.infinite(data$seLogRr))) {
        warning("Estimate(s) with infinite standard error detected. Removing before fitting error model")
        data <- data[!is.infinite(data$seLogRr), ]
    }
    if (any(is.infinite(data$logRr))) {
        warning("Estimate(s) with infinite logRr detected. Removing before fitting error model")
        data <- data[!is.infinite(data$logRr), ]
    }
    if (any(is.na(data$seLogRr))) {
        warning("Estimate(s) with NA standard error detected. Removing before fitting error model")
        data <- data[!is.na(data$seLogRr), ]
    }
    if (any(is.na(data$logRr))) {
        warning("Estimate(s) with NA logRr detected. Removing before fitting error model")
        data <- data[!is.na(data$logRr), ]
    }
    #data <- data[sample.int(nrow(data), 1000),]


    computeLooCoverage <- function(i, data, result) {
        computeCoverage <- function(j, subResult, dataLeftOut, model) {
            subset <- dataLeftOut[dataLeftOut$strata == subResult$strata[j],]
            if (nrow(subset) == 0)
                return(0)
            ci <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = subset$logRr,
                                                                    seLogRr = subset$seLogRr,
                                                                    ciWidth = subResult$ciWidth[j],
                                                                    model = model)
            return(sum(ci$logLb95Rr <= subset$trueLogRr & ci$logUb95Rr >= subset$trueLogRr))
        }
        computeTheoreticalCoverage <- function(j, subResult, dataLeftOut) {
            subset <- dataLeftOut[dataLeftOut$strata == subResult$strata[j],]
            ciWidth <- subResult$ciWidth[j]
            return(sum((subset$trueLogRr >= subset$logRr + qnorm((1-ciWidth)/2)*subset$seLogRr) & (subset$trueLogRr <= subset$logRr - qnorm((1-ciWidth)/2)*subset$seLogRr)))
        }
        tcdbIndex <- data$targetId == result$targetId[i] & data$comparatorId == result$comparatorId[i] & data$db == result$db[i]
        dataLeaveOneOut <- data[tcdbIndex & data$group != result$leaveOutGroup[i], ]
        dataLeftOut <- data[tcdbIndex & data$group == result$leaveOutGroup[i], ]
        if (nrow(dataLeaveOneOut) == 0 || nrow(dataLeftOut) == 0)
            return(data.frame())

        model <- EmpiricalCalibration::fitSystematicErrorModel(logRr = dataLeaveOneOut$logRr,
                                                               seLogRr = dataLeaveOneOut$seLogRr,
                                                               trueLogRr = dataLeaveOneOut$trueLogRr,
                                                               estimateCovarianceMatrix = FALSE)

        strata <- unique(data$strata)
        ciWidth <- seq(0.01, 0.99, by = 0.01)

        subResult <- expand.grid(strata, ciWidth)
        names(subResult) <- c("strata", "ciWidth")
        subResult$coverage <- sapply(1:nrow(subResult), computeCoverage, subResult = subResult, dataLeftOut = dataLeftOut, model = model)
        subResult$theoreticalCoverage <- sapply(1:nrow(subResult), computeTheoreticalCoverage, subResult = subResult, dataLeftOut = dataLeftOut)
        #subResult$leaveOutGroup <- rep(leaveOutGroup, nrow(subResult))
        return(subResult)
    }
    writeLines("Fitting error models within leave-one-out cross-validation")
    tcdbs <- unique(data[, c("targetId", "comparatorId", "db")])

    # tcdbs <- tcdbs[sample.int(nrow(tcdbs), 10),]
    # temp <- data
    # data <- merge(data, tcdbs)
 #data <- temp
    leaveOutGroups <- unique(data$group)
    result <- data.frame(targetId = rep(tcdbs$targetId, length(leaveOutGroups)),
                         comparatorId = rep(tcdbs$comparatorId, length(leaveOutGroups)),
                         db = rep(tcdbs$db, length(leaveOutGroups)),
                         leaveOutGroup = rep(leaveOutGroups, each = nrow(tcdbs)))

    #rm(calibrated)
    #rm(d)
    cluster <- OhdsiRTools::makeCluster(15)
    coverages <- OhdsiRTools::clusterApply(cluster, 1:nrow(result), computeLooCoverage, data = data, result = result)
    OhdsiRTools::stopCluster(cluster)
    #coverages <- lapply(unique(leaveOutGrouping), computeLooCoverage, data = data)
    coverage <- do.call("rbind", coverages)
    data$count <- 1
    counts <- aggregate(count ~ strata, data = data, sum)
    naCounts <- aggregate(coverage ~ strata + ciWidth, data = coverage, function(x) sum(is.na(x)), na.action = na.pass)
    colnames(naCounts)[colnames(naCounts) == "coverage"] <- "naCount"
    coverageCali <- aggregate(coverage ~ strata + ciWidth, data = coverage, sum)
    coverageCali <- merge(coverageCali, counts, by = "strata")
    coverageCali <- merge(coverageCali, naCounts, by = c("strata", "ciWidth"))
    coverageCali$coverage <- coverageCali$coverage / (coverageCali$count - coverageCali$naCount)
    coverageCali$label <- "Calibrated"
    coverageTheoretical <- aggregate(theoreticalCoverage ~ strata + ciWidth, data = coverage, sum, na.action = na.pass)
    coverageTheoretical <- merge(coverageTheoretical, counts, by = "strata")
    coverageTheoretical$coverage <- coverageTheoretical$theoreticalCoverage / coverageCali$count
    coverageTheoretical$label <- "Uncalibrated"
    vizData <- rbind(coverageCali[, c("strata", "label", "ciWidth", "coverage")],
                     coverageTheoretical[, c("strata", "label", "ciWidth", "coverage")])

    names(vizData)[names(vizData) == "label"] <- "CI calculation"
    vizData$trueRr <- as.factor(exp(as.numeric(as.character(vizData$strata))))
    breaks <- c(0, 0.25, 0.5, 0.75, 1)
    theme <- ggplot2::element_text(colour = "#000000", size = 10)
    themeRA <- ggplot2::element_text(colour = "#000000", size = 10, hjust = 1)
    #saveRDS(vizData, file.path(paperFolder, "vizData.rds"))
    plot <- with(vizData, {
        ggplot2::ggplot(vizData,
                        ggplot2::aes(x = ciWidth,
                                     y = coverage,
                                     colour = `CI calculation`,
                                     linetype = `CI calculation`),
                        environment = environment()) +
            ggplot2::geom_vline(xintercept = breaks,
                                colour = "#AAAAAA",
                                lty = 1,
                                size = 0.3) +
            ggplot2::geom_vline(xintercept = 0.95, colour = "#888888", linetype = "dashed", size = 1) +
            ggplot2::geom_hline(yintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.3) +
            ggplot2::geom_abline(colour = "#AAAAAA", lty = 1, size = 0.3) +
            ggplot2::geom_line(size = 1) +
            ggplot2::scale_colour_manual(values = c(rgb(0, 0, 0), rgb(0, 0, 0), rgb(0.5, 0.5, 0.5))) +
            ggplot2::scale_linetype_manual(values = c("solid", "twodash")) +
            ggplot2::scale_x_continuous("Width of CI", limits = c(0, 1), breaks = c(breaks, 0.95), labels = c("0", ".25", ".50", ".75", "", ".95")) +
            ggplot2::scale_y_continuous("Coverage", limits = c(0, 1), breaks = breaks, labels = c("0", ".25", ".50", ".75", "1")) +
            ggplot2::facet_grid(. ~ trueRr) +
            ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                           panel.background = ggplot2::element_rect(fill = "#FAFAFA", colour = NA),
                           panel.grid.major = ggplot2::element_blank(),
                           axis.ticks = ggplot2::element_blank(),
                           axis.text.y = themeRA,
                           axis.text.x = theme,
                           strip.text.x = theme,
                           strip.background = ggplot2::element_blank(),
                           legend.position = "top")
    })

    return(plot)
}
