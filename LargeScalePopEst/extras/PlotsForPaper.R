workFolder <- "R:/PopEstDepression_Ccae"

paperFolder <- file.path(workFolder, "paper")
if (!file.exists(paperFolder)){
    dir.create(paperFolder)
}

###########################################################################
# Get estimate for all outcomes                                           #
###########################################################################

pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)
#dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
dbs <- c("CCAE", "MDCD", "MDCR")
calibrated <- data.frame()
for (db in dbs) {
    temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
    temp$db <- db
    temp$exposureId <- substr(temp$targetId, start = 1, stop = nchar(temp$targetId) - 3)
    temp2 <- read.csv(paste0("R:/PopEstDepression_", db, "/signalInjectionSummary.csv"))
    temp3 <- data.frame(exposureId = temp2$exposureId,
                        outcomeId = temp2$newOutcomeId,
                        trueEffectSize = temp2$targetEffectSize)
    temp4 <- data.frame(exposureId = temp2$exposureId,
                        outcomeId = temp2$outcomeId,
                        trueEffectSize = 1)
    temp4 <- unique(temp4)
    temp <- merge(temp, rbind(temp3, temp4))
    calibrated <- rbind(calibrated, temp)
}

###########################################################################
# Plot evaluation                                                         #
###########################################################################

d <- calibrated[calibrated$analysisId == 3, ]
d$Group <- as.factor(d$trueEffectSize)
d$Significant <- d$ci95lb > d$trueEffectSize | d$ci95ub < d$trueEffectSize


temp1 <- aggregate(Significant ~ Group, data = d, length)
temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
temp1$Significant <- NULL
temp2 <- aggregate(Significant ~ Group, data = d, mean)
temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"), "% of CIs includes ", temp2$Group)
temp2$Significant <- NULL
dd <- merge(temp1, temp2)
dd$tes <- as.numeric(as.character(dd$Group))

require(ggplot2)
breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)

d$Group <- paste("True hazard ratio =", d$Group)
dd$Group <- paste("True hazard ratio =", dd$Group)

ggplot(d, aes(x=logRr, y=seLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.025), slope = 1/qnorm(0.025)), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5, data = dd) +
    geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.975), slope = 1/qnorm(0.975)), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5, data = dd) +
    geom_point(size=1, color = rgb(0,0,0, alpha = 0.05), alpha = 0.05, shape = 16) +
    geom_hline(yintercept=0) +
    geom_label(x = log(0.3), y = 0.95, alpha = 1, hjust = "left", label = dd$nLabel, size = 5, data = dd) +
    geom_label(x = log(0.3), y = 0.8, alpha = 1, hjust = "left", label = dd$meanLabel, size = 5, data = dd) +
    scale_x_continuous("Hazard ratio",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    facet_grid(.~Group) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_blank(),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = themeRA,
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )

ggsave(file.path(paperFolder, "Eval.png"), width=13.5, height=3, dpi = 500)

###########################################################################
# Plot calibration                                                        #
###########################################################################

d <- calibrated[calibrated$analysisId == 3, ]
d$Group <- as.factor(d$trueEffectSize)
d$Significant <- d$calCi95lb > d$trueEffectSize | d$calCi95ub < d$trueEffectSize


temp1 <- aggregate(Significant ~ Group, data = d, length)
temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
temp1$Significant <- NULL
temp2 <- aggregate(Significant ~ Group, data = d, mean)
temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"), "% of CIs includes ", temp2$Group)
temp2$Significant <- NULL
dd <- merge(temp1, temp2)
dd$tes <- as.numeric(as.character(dd$Group))

require(ggplot2)
breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)

d$Group <- paste("True hazard ratio =", d$Group)
dd$Group <- paste("True hazard ratio =", dd$Group)

ggplot(d, aes(x=calLogRr, y=calSeLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.025), slope = 1/qnorm(0.025)), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5, data = dd) +
    geom_abline(aes(intercept = (-log(dd$tes))/qnorm(0.975), slope = 1/qnorm(0.975)), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5, data = dd) +
    geom_point(size=1, color = rgb(0,0,0, alpha = 0.05), alpha = 0.05, shape = 16) +
    geom_hline(yintercept=0) +
    geom_label(x = log(0.3), y = 0.95, alpha = 1, hjust = "left", label = dd$nLabel, size = 5, data = dd) +
    geom_label(x = log(0.3), y = 0.8, alpha = 1, hjust = "left", label = dd$meanLabel, size = 5, data = dd) +
    scale_x_continuous("Hazard ratio",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    facet_grid(.~Group) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_blank(),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = themeRA,
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )

ggsave(file.path(paperFolder, "EvalCal.png"), width=13.5, height=3, dpi = 500)

###########################################################################
# Plot results for depression                                             #
###########################################################################


pathToCsv <- system.file("settings", "OutcomesOfInterest.csv", package = "LargeScalePopEst")
outcomes <- read.csv(pathToCsv)
#dbs <- c("CCAE", "MDCD", "MDCR", "Optum")
dbs <- c("CCAE", "MDCD", "MDCR")
dbs <- c("MDCD", "MDCR")
calibrated <- data.frame()
for (db in dbs) {
    temp <- read.csv(paste0("R:/PopEstDepression_", db, "/calibratedEstimates.csv"))
    temp$db <- db
    calibrated <- rbind(calibrated, temp)
}

d <- calibrated[calibrated$analysisId == 3 &
                      calibrated$outcomeId %in% outcomes$cohortDefinitionId,]


d$Significant <- d$calCi95lb > 1 | d$calCi95ub < 1
d$Group <- "Depression"

temp1 <- aggregate(Significant ~ Group, data = d, length)
temp1$nLabel <- paste0(formatC(temp1$Significant, big.mark = ","), " estimates")
temp1$Significant <- NULL
temp2 <- aggregate(Significant ~ Group, data = d, mean)
temp2$meanLabel <- paste0(formatC(100 * (1 - temp2$Significant), digits = 1, format = "f"), "% of CIs includes 1")
temp2$Significant <- NULL
dd <- merge(temp1, temp2)

require(ggplot2)
breaks <- c(0.25,0.5,1,2,4,6,8,10)
theme <- element_text(colour="#000000", size=12)
themeRA <- element_text(colour="#000000", size=12,hjust=1)
themeLA <- element_text(colour="#000000", size=12,hjust=0)

ggplot(d, aes(x=calLogRr, y=calSeLogRr), environment=environment())+
    geom_vline(xintercept=log(breaks), colour ="#AAAAAA", lty=1, size=0.5) +
    geom_abline(slope = 1/qnorm(0.025), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5) +
    geom_abline(slope = 1/qnorm(0.975), colour=rgb(0.8,0,0), linetype="dashed", size=1, alpha=0.5) +
    geom_point(size=1, color = rgb(0,0,0, alpha = 0.25), alpha = 0.25, shape = 16) +
    geom_hline(yintercept=0) +
    geom_label(x = log(0.3), y = 1, alpha = 1, hjust = "left", label = dd$nLabel, size = 5, data = dd) +
    geom_label(x = log(0.3), y = 0.9, alpha = 1, hjust = "left", label = dd$meanLabel, size = 5, data = dd) +
    scale_x_continuous("Hazard ratio",limits = log(c(0.25,10)), breaks=log(breaks),labels=breaks) +
    scale_y_continuous("Standard Error",limits = c(0,1)) +
    facet_grid(.~Group) +
    theme(
        panel.grid.minor = element_blank(),
        panel.background= element_blank(),
        panel.grid.major= element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = themeRA,
        axis.text.x = theme,
        legend.key= element_blank(),
        strip.text.x = theme,
        strip.background = element_blank(),
        legend.position = "none"
    )

ggsave(file.path(paperFolder, "DepressionCal.png"), width=6, height=4.5, dpi = 500)



### Fit mixture model ###

fitMix <- function(logRr, seLogRr) {
    if (any(is.infinite(seLogRr))){
        warning("Estimate(s) with infinite standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.infinite(seLogRr)]
        seLogRr <- seLogRr[!is.infinite(seLogRr)]
    }
    if (any(is.infinite(logRr))){
        warning("Estimate(s) with infinite logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.infinite(logRr)]
        logRr <- logRr[!is.infinite(logRr)]
    }
    if (any(is.na(seLogRr))){
        warning("Estimate(s) with NA standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.na(seLogRr)]
        seLogRr <- seLogRr[!is.na(seLogRr)]
    }
    if (any(is.na(logRr))){
        warning("Estimate(s) with NA logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.na(logRr)]
        logRr <- logRr[!is.na(logRr)]
    }

    gaussianProduct <- function(mu1, mu2, sd1, sd2) {
        (2 * pi)^(-1/2) * (sd1^2 + sd2^2)^(-1/2) * exp(-(mu1 - mu2)^2/(2 * (sd1^2 + sd2^2)))
    }

    # Use logit function to prevent mixture fraction from straying from [0,1]
    link <- function(x) {
        return(exp(x) / (exp(x) + 1))
    }

    LL <- function(theta, estimate, se) {
        result <- 0
        for (i in 1:length(estimate)) {
            result <- result - log(link(theta[1])*gaussianProduct(estimate[i], theta[2], se[i], exp(theta[3])) + (1-link(theta[1]))*gaussianProduct(estimate[i], theta[4], se[i], exp(theta[5])))
        }
        if (is.infinite(result))
            result <- 99999
        result
    }
    theta <- c(0, 0, -2, 1, -0.5)
    fit <- optim(theta, LL, estimate = logRr, se = seLogRr)

    result <- data.frame(mix = link(fit$par[1]),
                         mean1 = fit$par[2],
                         sd1 = exp(fit$par[3]),
                         mean2 = fit$par[4],
                         sd2 = exp(fit$par[5]))


    return(result)
}

fitMix(d$logRr, d$seLogRr)


fitMixFix1 <- function(logRr, seLogRr) {
    if (any(is.infinite(seLogRr))){
        warning("Estimate(s) with infinite standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.infinite(seLogRr)]
        seLogRr <- seLogRr[!is.infinite(seLogRr)]
    }
    if (any(is.infinite(logRr))){
        warning("Estimate(s) with infinite logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.infinite(logRr)]
        logRr <- logRr[!is.infinite(logRr)]
    }
    if (any(is.na(seLogRr))){
        warning("Estimate(s) with NA standard error detected. Removing before fitting null distribution")
        logRr <- logRr[!is.na(seLogRr)]
        seLogRr <- seLogRr[!is.na(seLogRr)]
    }
    if (any(is.na(logRr))){
        warning("Estimate(s) with NA logRr detected. Removing before fitting null distribution")
        seLogRr <- seLogRr[!is.na(logRr)]
        logRr <- logRr[!is.na(logRr)]
    }

    gaussianProduct <- function(mu1, mu2, sd1, sd2) {
        (2 * pi)^(-1/2) * (sd1^2 + sd2^2)^(-1/2) * exp(-(mu1 - mu2)^2/(2 * (sd1^2 + sd2^2)))
    }

    # Use logit function to prevent mixture fraction from straying from [0,1]
    link <- function(x) {
        return(exp(x) / (exp(x) + 1))
    }

    LL <- function(theta, estimate, se) {
        result <- 0
        for (i in 1:length(estimate)) {
            result <- result - log(link(theta[1])*dnorm(0, mean = estimate[i], sd = se[i]) + (1-link(theta[1]))*gaussianProduct(estimate[i], theta[2], se[i], exp(theta[3])))
        }
        if (is.infinite(result))
            result <- 99999
        result
    }
    theta <- c(0, 1, -0.5)
    fit <- optim(theta, LL, estimate = logRr, se = seLogRr)

    result <- data.frame(mix = link(fit$par[1]),
                         mean1 = 0,
                         sd1 = 0,
                         mean2 = fit$par[2],
                         sd2 = exp(fit$par[3]))


    return(result)
}

fitMixFix1(d$logRr, d$seLogRr)
