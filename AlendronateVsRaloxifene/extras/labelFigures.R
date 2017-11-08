# Table 1
obj = printOutcomeTable(analysisId = 1, folders, paste0(label1, " ", label2), "HipFracture", "", singleTable = TRUE,
                        caption = "Number of patients, observation years, and number of hip fracture events in study cohort by database",
                        floating = TRUE)
saveTable(obj, filename = "outcomeCountHipFracture")

# Figure 1
saveFigure("extras/figures/unnamed-chunk-2-1.pdf", "cohortYear",
           caption = "Year of study entry, stratified by drug exposure and data source. Note patient counts are on the log-scale",
           1, "4.00in", "7.53in", newWidth = "3in")

# Figure 2
saveFigure("extras/figures/unnamed-chunk-3-1.pdf", "cohortAge",
           caption = "Age at study entry, stratified by drug exposure and data source. Note patient counts are on the log-scale",
           2, "4.04in", "7.60in", newWidth = "3in")

# Figure 3
saveFigure("extras/figures/unnamed-chunk-40-2.pdf", "forestPlots",
           caption = "Main analysis hazard ratios for A) hip fracture, B) vertebral fracture, and C) atypical femoral fracture. More precise estimates have greater opacity",
           3, "6.90in", "7.99in", newWidth = "5in")

# Figure 4
saveFigure("KM_Optum.png", "KM_Optum_label", caption = "Kaplan-Meier plot for hip fracture outcome in Optum CEDM data source",
           4, width = "309.3pt", height = "184.5pt")

# pixel to pt factor: 72.27/600

