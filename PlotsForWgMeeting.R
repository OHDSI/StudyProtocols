library(ggplot2)

results <- data.frame()

result <- data.frame(group = "From literature",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "From literature",
                     estimate = "Uncalibrated",
                     rr = 1.6 / 3.5,
                     lb = 1.6 / 3.5,
                     ub = 1.6 / 3.5)
results <- rbind(results, result)

result <- data.frame(group = "From literature",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "From literature",
                     estimate = "Uncalibrated",
                     rr = 1.28,
                     lb = 1.14,
                     ub = 1.44)
results <- rbind(results, result)

cal <- read.csv("S:/Temp/CiCalibration_Optum/Calibrated_Southworth_cohort_method.csv")
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "Our replication (uncalibrated)",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Southworth",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

cal <- read.csv("S:/Temp/CiCalibration_Mdcr/Calibrated_Graham_cohort_method.csv")
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "Our replication (uncalibrated)",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "Dabigatran, warfarin and GI bleed",
                     study = "Graham",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

results$label <- factor(results$label,
                        levels = c("Our replication (calibrated)","Our replication (uncalibrated)","From literature"))

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- element_text(colour = "#000000", size = 10)
themeRA <- element_text(colour = "#000000", size = 10, hjust = 1)


ggplot(results[results$label == "From literature", ],
       aes(x = label,
           y = rr,
           ymin = lb,
           ymax = ub),
       environment = environment()) +
    geom_hline(yintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
    geom_hline(yintercept = 1, size = 0.5) +
    geom_pointrange(shape = 23, color = rgb(0,0,0.2), fill = rgb(0,0,0.2), alpha = 0.5) +
    coord_flip(ylim = c(0.25, 10)) +
    scale_y_continuous("Relative risk", trans = "log10", breaks = breaks, labels = breaks) +
    facet_grid(study~topic) +
    theme(panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "#FAFAFA", colour = NA),
          panel.grid.major = element_line(colour = "#EEEEEE"),
          axis.ticks = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = themeRA,
          axis.text.x = theme,
          legend.key = element_blank(),
          strip.text.x = theme,
          strip.background = element_blank(),
          legend.position = "none")
ggsave(file.path("s:/temp/DabiWarfarinOriginal.png"), width = 6, height = 2.1, dpi = 300)

ggplot(results[results$label != "Our replication (calibrated)", ],
       aes(x = label,
           y = rr,
           ymin = lb,
           ymax = ub),
       environment = environment()) +
    geom_hline(yintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
    geom_hline(yintercept = 1, size = 0.5) +
    geom_pointrange(shape = 23, color = rgb(0,0,0.2), fill = rgb(0,0,0.2), alpha = 0.5) +
    coord_flip(ylim = c(0.25, 10)) +
    scale_y_continuous("Relative risk", trans = "log10", breaks = breaks, labels = breaks) +
    facet_grid(study~topic) +
    theme(panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "#FAFAFA", colour = NA),
          panel.grid.major = element_line(colour = "#EEEEEE"),
          axis.ticks = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = themeRA,
          axis.text.x = theme,
          legend.key = element_blank(),
          strip.text.x = theme,
          strip.background = element_blank(),
          legend.position = "none")
ggsave(file.path("s:/temp/DabiWarfarinReplication.png"), width = 6, height = 2.1, dpi = 300)

ggplot(results,
       aes(x = label,
           y = rr,
           ymin = lb,
           ymax = ub),
       environment = environment()) +
    geom_hline(yintercept = breaks, colour = "#AAAAAA", lty = 1, size = 0.2) +
    geom_hline(yintercept = 1, size = 0.5) +
    geom_pointrange(shape = 23, color = rgb(0,0,0.2), fill = rgb(0,0,0.2), alpha = 0.5) +
    coord_flip(ylim = c(0.25, 10)) +
    scale_y_continuous("Relative risk", trans = "log10", breaks = breaks, labels = breaks) +
    facet_grid(study~topic) +
    theme(panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "#FAFAFA", colour = NA),
          panel.grid.major = element_line(colour = "#EEEEEE"),
          axis.ticks = element_blank(),
          axis.title.y = element_blank(),
          axis.text.y = themeRA,
          axis.text.x = theme,
          legend.key = element_blank(),
          strip.text.x = theme,
          strip.background = element_blank(),
          legend.position = "none")
ggsave(file.path("s:/temp/DabiWarfarin.png"), width = 6, height = 2.2, dpi = 300)

# Ingrowing nail + positive controls estimates + CIs
cal <- read.csv("S:/Temp/CiCalibration_Optum/Calibrated_Southworth_cohort_method.csv")
cal <- cal[cal$outcomeId == 139099 | (!is.na(cal$oldOutcomeId) & cal$oldOutcomeId == 139099), ]
cal[, c("rr", "ci95lb", "ci95ub", "trueLogRr")]

# Coverage Southworth
cal <- read.csv("S:/Temp/CiCalibration_Optum/Calibrated_Southworth_cohort_method.csv")
cal <- cal[!is.na(cal$trueLogRr), ]
cal$trueRr <- exp(cal$trueLogRr)
cal$coverage <- cal$ci95lb <= cal$trueRr & cal$ci95ub >=  cal$trueRr
aggregate(coverage ~ trueRr, data = cal, mean)
cal$coverage <- cal$calibratedCi95lb <= cal$trueRr & cal$calibratedCi95ub >=  cal$trueRr
aggregate(coverage ~ trueRr, data = cal, mean)

# Error model Southworth + before and after calibration
results <- read.csv("S:/Temp/CiCalibration_Optum/Calibrated_Southworth_cohort_method.csv")
results[is.na(results$trueLogRr),]
controls <- results[!is.na(results$trueLogRr),]
errorModel <- EmpiricalCalibration::fitSystematicErrorModel(logRr = controls$logRr,
                                                            seLogRr = controls$seLogRr,
                                                            trueLogRr = controls$trueLogRr)
errorModel
