library(shiny)
library(DT)
library(ggplot2)
source("global.R")
source("functions.R")
source("Table1.R")

mainColumns <- c("database",
                 "timeAtRisk", 
                 "heterogeneous",
                 "rr", 
                 "ci95lb",
                 "ci95ub",
                 "p",
                 "calP")

mainColumnNames <- c("<span title=\"Data source\">Data source</span>",
                     "<span title=\"Time at risk\">Time at risk</span>", 
                     "<span title=\"Between database heterogeneity (i2 > 0.4)?\">Ht.</span>",
                     "<span title=\"Hazard ratio\">HR</span>", 
                     "<span title=\"Lower bound of the 95 confidence interval\">CI95LB</span>",
                     "<span title=\"Upper bound of the 95 confidence interval\">CI95UB</span>",
                     "<span title=\"P-value (uncalibrated)\">P</span>",
                     "<span title=\"Calibrated p-value\">Cal. P</span>")

powerColumns <- c("treated",
                  "comparator",
                  "treatedDays",
                  "comparatorDays",
                  "eventsTreated",
                  "eventsComparator",
                  "irTreated",
                  "irComparator",
                  "mdrr")

powerColumnNames <- c("Target subjects",
                      "Comparator subjects",
                      "Target days",
                      "Comparator days",
                      "Target events",
                      "Comparator events",
                      "Target IR (per 1,000 PY)",
                      "Comparator IR (per 1,000 PY)",
                      "MDRR")

shinyServer(function(input, output) {
  
  tableSubset <- reactive({
    idx <- resultsHois$comparison == input$comparison &
      resultsHois$outcomeName == input$outcome &
      resultsHois$timeAtRisk %in% input$timeAtRisk &
      resultsHois$database %in% input$db
    resultsHois[idx, ]
  })
  
  selectedRow <- reactive({
    idx <- input$mainTable_rows_selected
    if (is.null(idx)) {
      return(NULL)
    } else {
      return(tableSubset()[idx, ])  
    }
  })
  
  forestPlotSubset <- reactive({
    row <- selectedRow()
    if (is.null(row)) {
      return(NULL)
    } else {
      subset <- resultsHois[resultsHois$comparison == row$comparison & 
                              resultsHois$outcomeId == row$outcomeId, ]
      subset$dbOrder <- match(subset$database, c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))
      subset$timeAtRiskOrder <- match(subset$timeAtRisk, c("Intent-to-Treat", 
                                                           "Per-Protocol"))
      
      subset <- subset[order(subset$dbOrder,
                             subset$timeAtRiskOrder), ]
      subset$rr[is.na(subset$seLogRr)] <- NA
      subset$database <- factor(subset$database, levels = c("CCAE", "MDCD","MDCR", "Optum", "Meta-analysis"))
      subset$timeAtRisk <- factor(subset$timeAtRisk, levels = c("Intent-to-Treat", "Per-Protocol"))
      subset$displayOrder <- nrow(subset):1
      return(subset)
    }
  })
  
  output$rowIsSelected <- reactive({
    return(!is.null(selectedRow()))
  })
  outputOptions(output, "rowIsSelected", suspendWhenHidden = FALSE)
  
  output$isMetaAnalysis <- reactive({
    row <- selectedRow()
    isMetaAnalysis <- !is.null(row) && row$database == "Meta-analysis"
    if (isMetaAnalysis) {
      hideTab("tabsetPanel", "Population characteristics")
      hideTab("tabsetPanel", "Propensity scores")
      hideTab("tabsetPanel", "Covariate balance")
      hideTab("tabsetPanel", "Kaplan-Meier")
    } else {
      showTab("tabsetPanel", "Population characteristics")
      showTab("tabsetPanel", "Propensity scores")
      showTab("tabsetPanel", "Covariate balance")
      showTab("tabsetPanel", "Kaplan-Meier")    
    }
    return(isMetaAnalysis)
  })
  outputOptions(output, "isMetaAnalysis", suspendWhenHidden = FALSE)
  
  balance <- reactive({
    row <- selectedRow()
    if (is.null(row) || row$database == "Meta-analysis") {
      return(NULL)
    } else {
      fileName <- paste0("bal_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database,".rds")
      data <- readRDS(file.path("data", fileName))
      data$absBeforeMatchingStdDiff <- abs(data$beforeMatchingStdDiff)
      data$absAfterMatchingStdDiff <- abs(data$afterMatchingStdDiff)
      data <- merge(data, covarNames)
      return(data)
    } 
  })
  
  output$mainTable <- renderDataTable({
    table <- tableSubset()[, mainColumns]
    if (nrow(table) == 0)
      return(NULL)
    table$rr[table$rr > 100] <- NA
    table$rr <- formatC(table$rr, digits = 2, format = "f")
    table$ci95lb <- formatC(table$ci95lb, digits = 2, format = "f")
    table$ci95ub <- formatC(table$ci95ub, digits = 2, format = "f")
    table$p <- formatC(table$p, digits = 2, format = "f")
    table$calP <- formatC(table$calP, digits = 2, format = "f")
    colnames(table) <- mainColumnNames
    options = list(pageLength = 15, 
                   searching = FALSE, 
                   lengthChange = TRUE,
                   ordering = TRUE,
                   paging = TRUE)
    selection = list(mode = "single", target = "row")
    table <- datatable(table, 
                       options = options, 
                       selection = selection,
                       rownames = FALSE,
                       escape = FALSE,
                       class = "stripe nowrap compact")
    return(table)
  })

  output$powerTableCaption <- renderUI({
    row <- selectedRow()
    if (!is.null(row)) {
      text <- "<strong>Table 1a.</strong> Number of subjects, follow-up time (in days), number of outcome 
      events, and event incidence rate (IR) per 1,000 patient years (PY) in the target (<em>%s</em>) and 
      comparator (<em>%s</em>) group after matching, as  well as the minimum detectable  relative risk (MDRR). 
      Note that the IR does not account for any stratification."
      return(HTML(sprintf(text, row$targetDrug, row$comparatorDrug)))
    } else {
      return(NULL)
    }
  })
  
  output$powerTable <- renderTable({
    table <- selectedRow()
    if (!is.null(table)) {
      table$irTreated <- formatC(1000 * table$eventsTreated / (table$treatedDays / 365.25), digits = 2, format = "f")
      table$irComparator <- formatC(1000 * table$eventsComparator / (table$comparatorDays / 365.25), digits = 2, format = "f")
      
      table$treated <- formatC(table$treated, big.mark = ",", format = "d")
      table$comparator <- formatC(table$comparator, big.mark = ",", format = "d")
      table$treatedDays <- formatC(table$treatedDays, big.mark = ",", format = "d")
      table$comparatorDays <- formatC(table$comparatorDays, big.mark = ",", format = "d")
      table$eventsTreated <- formatC(table$eventsTreated, big.mark = ",", format = "d")
      table$eventsComparator <- formatC(table$eventsComparator, big.mark = ",", format = "d")
      table$mdrr <- formatC(table$mdrr, digits = 2, format = "f")
      if (table$database == "Meta-analysis") {
        table <- table[, c(powerColumns, "i2")]
        colnames(table) <- c(powerColumnNames, "I2")
      } else {
        table <- table[, powerColumns]
        colnames(table) <- powerColumnNames
      }
      return(table)
    } else {
      return(table)
    }
  })

  output$timeAtRiskTableCaption <- renderUI({
    row <- selectedRow()
    if (!is.null(row)) {
      text <- "<strong>Table 1b.</strong> Time (days) at risk distribution expressed as mean, standard deviation (SD),
      minimum (min), median, and maximum (max) in the target 
     (<em>%s</em>) and comparator (<em>%s</em>) cohort after matching."
      return(HTML(sprintf(text, row$targetDrug, row$comparatorDrug)))
    } else {
      return(NULL)
    }
  })
  
  output$timeAtRiskTable <- renderTable({
    row <- selectedRow()
    if (!is.null(table)) {
       table <- data.frame(Cohort = c("Target", "Comparator"),
                          Mean = formatC(c(row$tarTargetMean, row$tarComparatorMean), digits = 1, format = "f"),
                          SD = formatC(c(row$tarTargetSd, row$tarComparatorSd), digits = 1, format = "f"),
                          Min = formatC(c(row$tarTargetMin, row$tarComparatorMin), big.mark = ",", format = "d"),
                          Median = formatC(c(row$tarTargetMedian, row$tarComparatorMedian), big.mark = ",", format = "d"),
                          Max = formatC(c(row$tarTargetMax, row$tarComparatorMax), big.mark = ",", format = "d"))
      return(table)
    } else {
      return(table)
    }
  })
  
  output$table1Caption <- renderUI({
    bal <- balance()
    if (!is.null(bal)) {
      row <- selectedRow()
      text <- "<strong>Table 2.</strong> Select characteristics before and after matching, showing the
      percentage of subjects  with the characteristics in the target (<em>%s</em>) and comparator (<em>%s</em>) group, as 
      well as the standardized difference of the means."
      return(HTML(sprintf(text, row$targetDrug, row$comparatorDrug)))
    } else {
      return(NULL)
    }
  })
  
  output$table1Table <- renderDataTable({
    bal <- balance()
    if (!is.null(bal)) {
      row <- selectedRow()
      fileName <- paste0("multiTherBal_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_", row$database,".rds")
      multiTherapyBalance  <- readRDS(file.path("data", fileName))
      bal$absBeforeMatchingStdDiff <- NULL
      bal$absAfterMatchingStdDiff <- NULL
      multiTherapyBalance <- multiTherapyBalance[, colnames(bal)]
      bal <- rbind(bal, multiTherapyBalance)
      table1 <- prepareTable1(bal, 
                              beforeTargetPopSize = row$treatedBefore,
                              beforeComparatorPopSize = row$comparatorBefore,
                              afterTargetPopSize = row$treated,
                              afterComparatorPopSize = row$comparator,
                              beforeLabel = "Before matching",
                              afterLabel = "After matching")
      container <- htmltools::withTags(table(
        class = 'display',
        thead(
          tr(
            th(rowspan = 3, "Characteristic"),
            th(colspan = 3, class = "dt-center", "Before matching"),
            th(colspan = 3, class = "dt-center", "After matching")
          ),
          tr(
            lapply(table1[1, 2:ncol(table1)], th)
          ),
          tr(
            lapply(table1[2, 2:ncol(table1)], th)
          )
        )
      ))
      options <- list(columnDefs = list(list(className = 'dt-right',  targets = 1:6)),
                     searching = FALSE,
                     ordering = FALSE,
                     paging = FALSE,
                     bInfo = FALSE)
      table1 <- datatable(table1[3:nrow(table1), ], 
                          options = options, 
                          rownames = FALSE,
                          escape = FALSE,
                          container = container,
                          class = "stripe nowrap compact")
      return(table1)
    } else {
      return(NULL)
    }
  })
  
  output$psPlot <- renderPlot({
    row <- selectedRow()
    if (!is.null(row) && row$database != "Meta-analysis") {
      fileName <- paste0("ps_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_", row$database,".rds")
      data <- readRDS(file.path("data", fileName))
      data$GROUP <- row$targetDrug
      data$GROUP[data$treatment == 0] <- row$comparatorDrug
      data$GROUP <- factor(data$GROUP, levels = c(row$targetDrug, 
                                                  row$comparatorDrug))
      plot <- ggplot2::ggplot(data, ggplot2::aes(x = preferenceScore, y = y, color = GROUP, group = GROUP, fill = GROUP)) + 
        ggplot2::geom_area(position = "identity") + 
        ggplot2::scale_fill_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) + 
        ggplot2::scale_color_manual(values = c(rgb(0.8, 0, 0, alpha = 0.5), rgb(0, 0, 0.8, alpha = 0.5))) + 
        ggplot2::scale_x_continuous("Preference score", limits = c(0, 1)) + 
        ggplot2::scale_y_continuous("Density") + 
        ggplot2::theme(legend.title = ggplot2::element_blank(),
                       legend.position = "top",
                       legend.direction = "horizontal",
                       text = ggplot2::element_text(size = 15))
      return(plot)
    } else {
      return(NULL)
    }
  })

  output$balancePlotCaption <- renderUI({
    bal <- balance()
    if (!is.null(bal)) {
      row <- selectedRow()
      text <- "<strong>Figure 2.</strong> Covariate balance before and after matching. Each dot represents 
      the standardizes difference of means for a single covariate before and after matching on the propensity 
      score. Move the mouse arrow over a dot for more details."
      return(HTML(sprintf(text)))
    } else {
      return(NULL)
    }
  })
  
  output$balancePlot <- renderPlot({
    bal <- balance()
    if (!is.null(bal)) {
      row <- selectedRow()
      plotBalance(bal,
                  beforeLabel = "Std. diff. before matching",
                  afterLabel = "Std. diff. after matching")
    } else {
      return(NULL)
    }
  })
  
  output$hoverInfoBalanceScatter <- renderUI({
    # Hover-over adapted from https://gitlab.com/snippets/16220
    bal <- balance()
    if (is.null(bal))
      return(NULL)
    row <- selectedRow()
    hover <- input$plotHoverBalanceScatter
    point <- nearPoints(bal, hover, threshold = 5, maxpoints = 1, addDist = TRUE)
    if (nrow(point) == 0) return(NULL)
    
    # calculate point position INSIDE the image as percent of total dimensions
    # from left (horizontal) and from top (vertical)
    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    # calculate distance from left and bottom side of the picture in pixels
    left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
    top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
    
    # create style property fot tooltip
    # background color is set so tooltip is a bit transparent
    # z-index is set so we are sure are tooltip will be on top
    style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                    "left:", left_px - 251, "px; top:", top_px - 150, "px; width:500px;")
    
    # actual tooltip created as wellPanel
    beforeMatchingStdDiff <- formatC(point$beforeMatchingStdDiff, digits = 2, format = "f")
    afterMatchingStdDiff <- formatC(point$afterMatchingStdDiff, digits = 2, format = "f")
    div(
      style="position: relative; width: 0; height: 0",
      wellPanel(
        style = style,
        p(HTML(paste0("<b> Covariate: </b>", point$covariateName, "<br/>",
                      "<b> Std. diff before matching: </b>", beforeMatchingStdDiff, "<br/>",
                      "<b> Std. diff after matching: </b>", afterMatchingStdDiff)))
      )
    )
  })
  
  output$negativeControlPlot <- renderPlot({
    row <- selectedRow()
    if (!is.null(row)) {
      ncs <- resultsNcs[resultsNcs$targetId == row$targetId & 
                          resultsNcs$comparatorId == row$comparatorId & 
                          resultsNcs$analysisId == row$analysisId &
                          resultsNcs$database == row$database, ]
      fileName <- paste0("null_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_",row$database,".rds")
      if (file.exists(file.path("data", fileName))) {
        null <- readRDS(file.path("data", fileName))
      } else {
        null <- NULL
      }
      plot <- EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = ncs$logRr,
                                                          seLogRrNegatives = ncs$seLogRr,
                                                          logRrPositives = row$logRr,
                                                          seLogRrPositives = row$seLogRr,
                                                          null = null,
                                                          xLabel = "Hazard ratio",
                                                          showCis = !is.null(null))
      plot <- plot + ggplot2::theme(text = ggplot2::element_text(size = 15))
      return(plot)
    } else {
      return(NULL)
    }
  })
  
  output$kaplanMeierPlot <- renderPlot({
    row <- selectedRow()
    if (!is.null(row)) {
      fileName <- paste0("km_a", row$analysisId,
                         "_t", row$targetId,
                         "_c", row$comparatorId,
                         "_o", row$outcomeId,
                         "_",row$database,".rds")
      if (file.exists(file.path("data", fileName))) {
        plot <- readRDS(file.path("data", fileName))
        return(grid::grid.draw(plot))
      } 
    }
    return(NULL)
  }, res = 100)
  
  output$kmPlotCaption <- renderUI({
    bal <- balance()
    if (!is.null(bal)) {
      row <- selectedRow()
      text <- "<strong>Table 5.</strong> Kaplan Meier plot, showing survival as a function of time. This plot
      is adjusted for the propensity score matching: The target curve (<em>%s</em>) shows the actual observed survival. The
      comparator curve (<em>%s</em>) applies reweighting to approximate the counterfactual of what the target survival
      would look like had the target cohort been exposed to the comparator instead. The shaded area denotes 
      the 95 percent confidence interval."
      return(HTML(sprintf(text, row$targetDrug, row$comparatorDrug)))
    } else {
      return(NULL)
    }
  })
  
  output$forestPlot <- renderPlot({
    row <- selectedRow()
    if (!is.null(row)) {
      subset <- forestPlotSubset()
      return(plotForest(subset, row))
    }
    return(NULL)
  }, height = 500)
  
  output$hoverInfoForestPlot <- renderUI({
    # Hover-over adapted from https://gitlab.com/snippets/16220
    subset <- forestPlotSubset()
    if (is.null(subset))
      return(NULL)
    hover <- input$plotHoverForestPlot
    point <- nearPoints(subset, hover, threshold = 5, maxpoints = 1, addDist = TRUE)
    if (nrow(point) == 0) return(NULL)
    # calculate point position INSIDE the image as percent of total dimensions
    # from left (horizontal) and from top (vertical)
    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    # calculate distance from left and bottom side of the picture in pixels
    left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
    top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
    
    # create style property fot tooltip
    # background color is set so tooltip is a bit transparent
    # z-index is set so we are sure are tooltip will be on top
    style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                    "left:100px; top:", top_px - 200, "px; width:500px;")
    
    # actual tooltip created as wellPanel
    hr <- sprintf("%.2f (%.2f - %.2f)", point$rr, point$ci95lb, point$ci95ub)
    div(
      style="position: relative; width: 0; height: 0",
      wellPanel(
        style = style,
        p(HTML(paste0("<b> Database: </b>", point$database, "<br/>",
                      "<b> Time at risk: </b>", point$timeAtRisk, "<br/>",
                      "<b> Harard ratio (95% CI): </b>", hr, "<br/>")))
      )
    )
  })
  
  observeEvent(input$dbInfo, {
    showModal(modalDialog(
      title = "Data sources",
      easyClose = TRUE,
      footer = NULL,
      size = "l",
      HTML(dbInfoHtml)
    ))
  })
  
  observeEvent(input$comparisonsInfo, {
    showModal(modalDialog(
      title = "Comparisons",
      easyClose = TRUE,
      footer = NULL,
      size = "l",
      HTML(comparisonsInfoHtml)
    ))
  })
  
  observeEvent(input$outcomesInfo, {
    showModal(modalDialog(
      title = "Outcomes",
      easyClose = TRUE,
      footer = NULL,
      size = "l",
      HTML(outcomesInfoHtml)
    ))
  })
  
  observeEvent(input$tarInfo, {
    showModal(modalDialog(
      title = "Time-at-risk",
      easyClose = TRUE,
      footer = NULL,
      size = "l",
      HTML(tarInfoHtml)
    ))
  })
  
})
