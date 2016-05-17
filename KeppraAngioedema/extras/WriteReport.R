writeReport <- function(exportFolder, dbName) {
    results <- read.csv(file.path(exportFolder, "tablesAndFigures", "EmpiricalCalibration.csv"))
    analysisIds <- unique(results$analysisId)
    analysisIds <- analysisIds[order(analysisIds)]
    hois <- 3

    report <- ReporteRs::docx()

    ### Table of contents ###
    report <- ReporteRs::addTitle(report, "Table of contents", level = 1)
    report <- ReporteRs::addTOC(report)

    ### Intro ###
    report <- ReporteRs::addTitle(report, "Introduction", level = 1)
    text <- "This reports describes the results from a comparative effectiveness study comparing new users of levetiracetam to new users of phenytoin. Propensity scores were generated using large scale regression, and one-on-one and variable ratio matching was performed. Effect sizes were estimated using a univariate Cox regression, conditioned on the matched sets. A set of negative control outcomes was included to estimate residual bias and calibrate p-values."
    report <- ReporteRs::addParagraph(report, value = text)

    ## Analysis variations ##
    report <- ReporteRs::addTitle(report, "Analyses variations", level = 2)
    text <- paste("In total,", length(analysisIds), "analysis variations were executed:")
    for (analysisId in analysisIds) {
        text <- c(text, paste0(analysisId, ". ", results$analysisDescription[results$analysisId == analysisId][1]))
    }
    report <- ReporteRs::addParagraph(report, value = text)

    ### Model diagnostics ###
    report <- ReporteRs::addTitle(report, "Model diagnostics", level = 1)

    ## Propensity score distribution ##
    report <- ReporteRs::addTitle(report, "Propensity score distribution", level = 2)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "PsPrefScale.png"), width = 6.5, height = 5)
    text <- "Propensity score distribution plot. This plot shows the propensity score distribution using the preference score scale."
    report <- ReporteRs::addParagraph(report, value = text)

    ## Covariate balance ##
    report <- ReporteRs::addTitle(report, "Covariate balance", level = 2)

    # After one-on-one matching #
    report <- ReporteRs::addTitle(report, "After one-on-one matching", level = 3)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", "BalanceScatterPlot1On1Matching.png"), width = 5, height = 5)
    text <- "Balance scatter plot. This plot shows the standardized difference before and after matching for all covariates used in the propensity score model."
    report <- ReporteRs::addParagraph(report, value = text)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", "BalanceTopVariables1On1Matching.png"), width = 7, height = 5)
    text <- "Balance plot for top covariates. This plot shows the standardized difference before and after matching for those covariates with the largest difference before matching (top) and after matching (bottom). A negative difference means the value in the treated group was lower than in the comparator group."
    report <- ReporteRs::addParagraph(report, value = text)

    # After variable ratio matching #
    report <- ReporteRs::addTitle(report, "After variable ratio matching", level = 3)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", "BalanceScatterPlotVarRatioMatching.png"), width = 5, height = 5)
    text <- "Balance scatter plot. This plot shows the standardized difference before and after matching for all covariates used in the propensity score model."
    report <- ReporteRs::addParagraph(report, value = text)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", "BalanceTopVariablesVarRatioMatching.png"), width = 7, height = 5)
    text <- "Balance plot for top covariates. This plot shows the standardized difference before and after matching for those covariates with the largest difference before matching (top) and after matching (bottom). A negative difference means the value in the treated group was lower than in the comparator group."
    report <- ReporteRs::addParagraph(report, value = text)

    ## Empirical calibration ##
    report <- ReporteRs::addTitle(report, "Empirical calibration", level = 2)

    # Per analysis #
    for (analysisId in analysisIds) {
        title <- paste0("Analysis ", analysisId, ": ", results$analysisDescription[results$analysisId == analysisId][1])
        report <- ReporteRs::addTitle(report, title, level = 3)
        report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", paste0("CalEffectNoHoi_a", analysisId, ".png")), width = 5, height = 4)
        text <- "Calibration effect plot. Blue dots represent the negative controls used in this study. The dashed line indicates the boundary below which p < 0.05 using traditional p-value computation. The orange area indicated the area where p < 0.05 using calibrated p-value computation."
        report <- ReporteRs::addParagraph(report, value = text)
        report <- ReporteRs::addImage(report, file.path(exportFolder, "tablesAndFigures", paste0("Cal_a", analysisId, ".png")), width = 4, height = 4)
        text <- "Calibration plot. This plot shows the fraction of negative controls with p-values below alpha, for every level of alpha. Ideally, the plots should follow the diagonal. This plot has been generated using leave-one-out: when computing the calibrated p-value for a negative control, the bias distribution was fitted using all other negative controls."
        report <- ReporteRs::addParagraph(report, value = text)
    }

    ### Main results ###
    report <- ReporteRs::addTitle(report, "Main results", level = 1)

    report <- ReporteRs::addTitle(report, "Analyses variations", level = 2)
    text <- paste("In total,", length(analysisIds), "analysis variations were executed:")
    for (analysisId in analysisIds) {
        text <- c(text, paste0(analysisId, ". ", results$analysisDescription[results$analysisId == analysisId][1]))
    }
    text <- c(text, "")
    report <- ReporteRs::addParagraph(report, value = text)

    table <- results[results$outcomeId %in% hois, c("analysisId", "treated", "comparator", "eventsTreated", "eventsComparator")]
    table <- table[order(table$analysisId), ]
    colnames(table) <- c("Analysis ID", "# treated", "# comparator", "# treated with event", "# comparator with event")
    report <- ReporteRs::addFlexTable(report, ReporteRs::FlexTable(table))
    text <- "Counts of subjects and events for the treated and comparator groups."
    text <- c(text, "")
    report <- ReporteRs::addParagraph(report, value = text)

    table <- results[results$outcomeId %in% hois, c("analysisId", "rr", "ci95lb" , "ci95ub", "p", "calibratedP" ,"calibratedP_lb95ci" ,"calibratedP_ub95ci")]
    table <- table[order(table$analysisId), ]
    colnames(table) <- c("Analysis ID", "Hazard Ratio", "95% CI LB", "95% CI UB", "P", "Calibrated P", "Cal. P 95% CI LB", "Cal. P 95% CI UB")
    table <- sapply(table, function(x) {if (is.numeric(x)) round(x,2) else as.character(x)})
    report <- ReporteRs::addFlexTable(report, ReporteRs::FlexTable(table))
    text <- "Harard ratios for angioedema in the levetiracetam group compared to the phenytoin group. Also included are traditional and calibrated p-values, as well as the 95% credible interval for the calibrated p-value."
    report <- ReporteRs::addParagraph(report, value = text)

    ## Kaplan-Meier plots ##
    report <- ReporteRs::addTitle(report, "Kaplan-Meier plots", level = 2)

    # Per-protocol analysis #
    report <- ReporteRs::addTitle(report, "Per-protocol analysis", level = 3)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "KaplanMeierPerProtocol.png"), width = 5, height = 4)
    paragraph <- "Kaplan-Meier plot. Shaded areas indicate the 95% confidence interval. Note that this plot does not take into account conditioning on the matched sets, as done when fitting the Cox model."
    report <- ReporteRs::addParagraph(report, value = paragraph)

    # Intent-to-treat analysis #
    report <- ReporteRs::addTitle(report, "Intent-to-treat analysis", level = 3)
    report <- ReporteRs::addImage(report, file.path(exportFolder, "KaplanMeierIntentToTreat.png"), width = 5, height = 4)
    paragraph <- "Kaplan-Meier plot. Shaded areas indicate the 95% confidence interval. Note that this plot does not take into account conditioning on the matched sets, as done when fitting the Cox model."
    report <- ReporteRs::addParagraph(report, value = paragraph)

    ReporteRs::writeDoc(report, file.path(exportFolder, "Report.docx"))
}

writeReportKnitr <- function(exportFolder) {
    rmarkdown::render("extras/Report.rmd",
                      params = list(exportFolder = exportFolder),
                      output_file = file.path(exportFolder, "ReportKnitr.docx"),
                      rmarkdown::word_document(toc = TRUE))
}
