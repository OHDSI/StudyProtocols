library(ggplot2)

workFolder <- "S:/Temp/CiCalibration_Mdcd"

paperFolder <- file.path(workFolder, "papers")
if (!file.exists(paperFolder)) {
    dir.create(paperFolder)
}


# SSRIs and upper GI bleed ------------------------------------------------

results <- data.frame()

result <- data.frame(group = "From literature",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "From literature",
                     estimate = "Uncalibrated",
                     rr = 2.38,
                     lb = 2.08,
                     ub = 2.72)
results <- rbind(results, result)

result <- data.frame(group = "From literature",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "From literature",
                     estimate = "Uncalibrated",
                     rr = 1.71,
                     lb = 1.48,
                     ub = 1.98)
results <- rbind(results, result)

cal <- read.csv("S:/Temp/CiCalibration_Mdcd/Calibrated_Tata_case_control.csv")
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "Our replication (uncalibrated)",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - CC",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

cal <- read.csv("S:/Temp/CiCalibration_Mdcd/Calibrated_Tata_sccs.csv")
cal <- cal[is.na(cal$trueLogRr), ]
result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "Our replication (uncalibrated)",
                     estimate = "Uncalibrated",
                     rr = cal$rr,
                     lb = cal$ci95lb,
                     ub = cal$ci95ub)
results <- rbind(results, result)

result <- data.frame(group = "Our replication",
                     topic = "SSRIs and upper GI bleed",
                     study = "Tata - SCCS",
                     label = "Our replication (calibrated)",
                     estimate = "Calibrated",
                     rr = cal$calibratedRr,
                     lb = cal$calibratedCi95lb,
                     ub = cal$calibratedCi95ub)
results <- rbind(results, result)

results$label <- factor(results$label,
                        levels = c("Our replication (calibrated)","Our replication (uncalibrated)","From literature"))
# results$label <- factor(paste0(results$group, " (", results$estimate, ")"),
#                         levels = c("Our replication (Calibrated)","Our replication (Uncalibrated)","From literature (Uncalibrated)"))

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- element_text(colour = "#000000", size = 10)
themeRA <- element_text(colour = "#000000", size = 10, hjust = 1)

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
ggsave(file.path(paperFolder, "Tata.png"), width = 6, height = 2.2, dpi = 300)


# Dabigatran vs warfarin for GI bleed -------------------------------------

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
# results$label <- factor(paste0(results$group, " (", results$estimate, ")"),
#                         levels = c("Our replication (Calibrated)","Our replication (Uncalibrated)","From literature (Uncalibrated)"))

breaks <- c(0.25, 0.5, 1, 2, 4, 6, 8, 10)
theme <- element_text(colour = "#000000", size = 10)
themeRA <- element_text(colour = "#000000", size = 10, hjust = 1)

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
ggsave(file.path(paperFolder, "DabiWarfarin.png"), width = 6, height = 2.2, dpi = 300)


