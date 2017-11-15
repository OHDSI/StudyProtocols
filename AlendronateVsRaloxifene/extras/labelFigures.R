# Table 1
obj = printOutcomeTable(analysisId = 1, folders, paste0(label1, " ", label2), "HipFracture", "", singleTable = TRUE,
                        caption = "Number of patients, observation years, and number of hip fracture events in study cohort by database",
                        floating = TRUE)
saveTable(obj, 1, filename = "outcomeCountHipFracture")

# Table 2
obj = printAttrition(folders, paste0(label1, " ", label2),
                     caption = "Percentage of cohort eliminated by trimming to 0.25-0.75 preference score",
                     floating = TRUE)
saveTable(obj, 2, filename = "trimmingLoss")

# Table 3
obj = printBalance(folders,
                   caption = "Mean standardized difference of all covariates before and after propensity score trimming and stratification, by data source",
                   floating = TRUE)
saveTable(obj, 3, filename = "balanceTable")

# Figure 1
saveFigure("extras/figures/unnamed-chunk-2-1.pdf", "cohortYear",
           caption = "Year of study entry, stratified by drug exposure and data source. Note patient counts are on the log-scale",
           1, "4.00in", "7.53in", newWidth = "3in")

# Figure 2
saveFigure("extras/figures/unnamed-chunk-3-1.pdf", "cohortAge",
           caption = "Age at study entry, stratified by drug exposure and data source. Note patient counts are on the log-scale",
           2, "4.04in", "7.60in", newWidth = "3in")

# Figure 3
saveFigure("extras/figures/unnamed-chunk-34-2.pdf", "forestPlots",
           caption = "Main analysis hazard ratios for A) hip fracture, B) vertebral fracture, and C) atypical femoral fracture. More precise estimates have greater opacity",
           3, "6.90in", "7.99in", newWidth = "5in")

# Figure 4
saveFigure("KM_Optum.png", "KM_Optum_label",
           caption = "Kaplan-Meier plot for hip fracture outcome in Optum CEDM data source",
           4, width = "309.3pt", height = "184.5pt")

# Figure 5
saveFigure("PsAfter_Optum.png", "PsAfter_Optum_label",
           caption = "Preference score distribution of study subjects in Optum CEDM data source. Trimmed to 0.25-0.75, with black lines indicating stratification thresholds",
           5, "240.9pt", "168.63pt")

# Figure 6
saveFigure("Balance_Optum.png", "Balance_Optum_label",
           caption = "Standardized difference of covariates (1 dot = 1 covariate) in Optum CEDM study population before and after propensity score trimming and stratification",
           6, "192.72pt", "192.72pt")

# Figure 7
saveFigure("extras/figures/unnamed-chunk-35-1.pdf", "TopBalance_Optum_label",
           caption = "Top 20 covariates by absolute standardized difference between alendronate and raloxifene groups in Optum CEDM study. Positive difference indicates higher alendronate group frequency",
           7, "6.42in", "4.32in")

# Figure 8
saveFigure("NegControl_Optum.png", "NegControl_Optum_label",
           caption = "Negative control results from Optum CEDM. A) Traditional and calibrated significance testing. Estimates below the dashed line have $\\textrm{p}<0.05$ using traditional p-value calculation.
           Estimates in the orange areas have $\\textrm{p}<0.05$ using the calibrated p-value calculation. Blue dots indicate negative controls.
           B) Calibration plot showing the fraction of negative controls with $\\textrm{p}<\\alpha$, for different levels of $\\alpha$.
           Both traditional p-value calculation and p-values using calibration are shown. For the calibrated p-value, a leave-one-out design was used.",
           8, "7in", "3.5in", newWidth = "6in")

# pixel to pt factor: 72.27/600

