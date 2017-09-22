library(shiny)
library(ggplot2)

source("plots.R")

shinyServer(function(input, output) {
  
  # Some-by-some --------------------------------------------------------------

  # Preserve click value through window resizes as suggested here: (https://github.com/rstudio/shiny/issues/937)
  rv <- reactiveValues(click = NULL)
  
  observeEvent(input$plotClick, { rv$plotClick <- input$plotClick })
  
  clickedPoint <- reactive({
    plotClick <- rv$plotClick
    point <- nearPoints(filterData(), plotClick, threshold = 5, maxpoints = 1)
  })
  
  filterData <- reactive({
    idx <- d$db %in% input$db
    if (input$targetName != "All")
      idx <- idx & (d$targetName %in% input$targetName)
    if (input$comparatorName != "All")
      idx <- idx & (d$comparatorName %in% input$comparatorName)
    if (input$outcomeName != "All")
      idx <- idx & (d$outcomeName %in% input$outcomeName)  
    return(d[idx, ])
  })
  
  balance <- reactive({
    point <- clickedPoint()
    if (nrow(point) == 0) return(NULL)
    fileName <- file.path("data", normName(paste0("balance_", point$targetName, "_", point$comparatorName, "_", point$db, ".rds")))
    if (file.exists(fileName)) {
      balance <- readRDS(fileName)
    } else {
      fileName <- file.path("data", normName(paste0("balance_", point$comparatorName, "_", point$targetName, "_", point$db, ".rds")))
      if (file.exists(fileName)) {
        balance <- readRDS(fileName)  
        balance$beforeMatchingStdDiff <- -balance$beforeMatchingStdDiff
        balance$afterMatchingStdDiff <- -balance$afterMatchingStdDiff
      } else {
        return(NULL)
      }
    }
    balance$absBeforeMatchingStdDiff <- abs(balance$beforeMatchingStdDiff)
    balance$absAfterMatchingStdDiff <- abs(balance$afterMatchingStdDiff)
    return(balance)
  })
  
  estimates <- reactive({
    point <- clickedPoint()
    fileName <- file.path("data", normName(paste0("est_", point$targetName, "_", point$comparatorName, ".rds")))
    if (!file.exists(fileName)) return(NULL)
    estimate <- readRDS(fileName)
    return(estimate[estimate$outcomeName == point$outcomeName, ])
  })
  
  sensitivityAnalysis <- reactive({
    point <- clickedPoint()
    fileName <- file.path("data", normName(paste0("sens_", point$targetName, "_", point$comparatorName, ".rds")))
    if (!file.exists(fileName)) return(NULL)
    estimate <- readRDS(fileName)
    return(estimate[estimate$outcomeName == point$outcomeName, ])
  })
  
  details <- reactive({
    point <- clickedPoint()
    fileName <- file.path("data", normName(paste0("details_", point$targetName, "_", point$comparatorName, "_", point$db, ".rds")))
    if (!file.exists(fileName)) return(NULL)
    return(readRDS(fileName))
  })
  
  output$distPlot <- renderPlot({
    subset <- filterData()
    if (!is.null(rv$plotClick)) {
      selected <- clickedPoint()
    } else {
      selected <- NULL
    }
    return(plotScatter(subset, selected, "Hazard Ratio"))
  })
  
  output$hoverInfo <- renderUI({
    # Hover-over adapted from https://gitlab.com/snippets/16220
    hover <- input$plotHover
    point <- nearPoints(filterData(), hover, threshold = 5, maxpoints = 1, addDist = TRUE)
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
                    "left:", left_px + 2, "px; top:", top_px + 2, "px;")
    
    # actual tooltip created as wellPanel
    hr <- paste0(formatC(point$rr, digits = 2, format = "f"), 
                 " (",
                 formatC(point$ci95lb, digits = 2, format = "f"), 
                 "-",
                 formatC(point$ci95ub, digits = 2, format = "f"), 
                 ")")
    wellPanel(
      style = style,
      p(HTML(paste0("<b> target: </b>", point$targetName, "<br/>",
                    "<b> comparator: </b>", point$comparatorName, "<br/>",
                    "<b> outcome: </b>", point$outcomeName, "<br/>",
                    "<b> database: </b>", point$db, "<br/>",
                    "<b> hazard ratio: </b>", hr)))
    )
  })
  
  output$tco <- renderText({
    point <- clickedPoint()
    if (nrow(point) == 0) return(NULL)
    return(paste0("Details for ", point$targetName, " vs. ", point$comparatorName, " for ", point$outcomeName, " (", point$db, ")"))
  })
  
  output$psPlot <- renderPlot({
    point <- clickedPoint()
    details <- details()
    if (is.null(details)) return(NULL)
    plotPs(details$ps, point$targetName, point$comparatorName)
  })
  
  output$evaluation <- renderPlot({
    details <- details()
    if (is.null(details)) return(NULL)
    return(details$evaluationPlot)
  })
  
  output$calibration <- renderPlot({
    details <- details()
    if (is.null(details)) return(NULL)
    return(details$calibrationPlot)
  })

  output$balanceScatterPlot <- renderPlot({
    bal <- balance()
    if (is.null(bal))
      return(NULL)
    plotCovariateBalanceScatterPlot(bal)
  })
  
  output$hoverInfoBalanceScatter <- renderUI({
    # Hover-over adapted from https://gitlab.com/snippets/16220
    bal <- balance()
    if (is.null(bal))
      return(NULL)
    
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
                    "left:", left_px - 502, "px; top:", top_px - 100, "px; width:500px;")
    
    # actual tooltip created as wellPanel
    beforeMatchingStdDiff <- formatC(point$beforeMatchingStdDiff, digits = 2, format = "f")
    afterMatchingStdDiff <- formatC(point$afterMatchingStdDiff, digits = 2, format = "f")
    wellPanel(
      style = style,
      p(HTML(paste0("<b> covariate: </b>", point$covariateName, "<br/>",
                    "<b> Std. diff before stratification: </b>", beforeMatchingStdDiff, "<br/>",
                    "<b> Std. diff after stratification: </b>", afterMatchingStdDiff)))
    )
  })
  
  output$balanceScatterPlot <- renderPlot({
    bal <- balance()
    if (is.null(bal))
      return(NULL)
    plotCovariateBalanceScatterPlot(bal)
  })
  
  output$estimatesPlot <- renderPlot({
    estimate <- estimates()
    if (is.null(estimate)) return(NULL)
    plotForest(estimate)
  })
  
  output$estimatesTable <-  renderTable({
    estimate <- estimates()
    if (is.null(estimate)) return(NULL)
    estimate <- estimate[estimate$db == clickedPoint()$db,
                         c("treated", "comparator", "treatedDays", "comparatorDays", "eventsTreated", "eventsComparator")]
    names(estimate) <- c("Nr. of subjects (target)", "Nr. of subjects (comparator)", "Days at risk (target)", "Days at risk (comparator)", "Outcomes (target)", "outcomes (comparator)")
    estimate
  })
  
  output$estimatesText <-  renderUI({
    point <- clickedPoint()
    estimate <- estimates()
    if (is.null(estimate)) return(NULL)
    estimate <- estimate[estimate$db == point$db, ]
    
    hr <- paste0(formatC(estimate$rr, digits = 2, format = "f"), 
                 " (95% CI: ",
                 formatC(estimate$ci95lb, digits = 2, format = "f"), 
                 "-",
                 formatC(estimate$ci95ub, digits = 2, format = "f"), 
                 ", p = ",
                 formatC(estimate$p, digits = 2, format = "f"),
                 ")")
    calHr <- paste0(formatC(estimate$calRr, digits = 2, format = "f"), 
                    " (95% CI: ",
                    formatC(estimate$calCi95lb, digits = 2, format = "f"), 
                    "-",
                    formatC(estimate$calCi95ub, digits = 2, format = "f"), 
                    ", p = ",
                    formatC(estimate$calP, digits = 2, format = "f"),
                    ")")
    p(HTML(paste0("When comparing the risk of ", point$outcomeName, " between new users of ", point$targetName, 
                  " and ", point$comparatorName, " in the ", point$db, 
                  " database, the estimated <b>uncalibrated hazard ratio</b> was <b>",hr,
                  "</b>, the estimated <b>calibrated hazard ratio</b> was <b>", calHr, "</b>.")))
  })
  
  output$sensitivityAnalysisPlot <- renderPlot({
    sensitivityAnalysis <- sensitivityAnalysis()
    if (is.null(sensitivityAnalysis)) return(NULL)
    plotForest(sensitivityAnalysis)
  })
  
  output$sensitivityAnalysisTable <-  renderTable({
    sensitivityAnalysis <- sensitivityAnalysis()
    if (is.null(sensitivityAnalysis)) return(NULL)
    sensitivityAnalysis <- sensitivityAnalysis[sensitivityAnalysis$db == clickedPoint()$db,
                         c("treated", "comparator", "treatedDays", "comparatorDays", "eventsTreated", "eventsComparator")]
    names(sensitivityAnalysis) <- c("Nr. of subjects (target)", "Nr. of subjects (comparator)", "Days at risk (target)", "Days at risk (comparator)", "Outcomes (target)", "outcomes (comparator)")
    sensitivityAnalysis
  })
  
  output$sensitivityAnalysisText <-  renderUI({
    point <- clickedPoint()
    sensitivityAnalysis <- sensitivityAnalysis()
    if (is.null(sensitivityAnalysis)) return(NULL)
    estimate <- sensitivityAnalysis[sensitivityAnalysis$db == point$db, ]
    
    hr <- paste0(formatC(estimate$rr, digits = 2, format = "f"), 
                 " (95% CI: ",
                 formatC(estimate$ci95lb, digits = 2, format = "f"), 
                 "-",
                 formatC(estimate$ci95ub, digits = 2, format = "f"), 
                 ", p = ",
                 formatC(estimate$p, digits = 2, format = "f"),
                 ")")
    calHr <- paste0(formatC(estimate$calRr, digits = 2, format = "f"), 
                    " (95% CI: ",
                    formatC(estimate$calCi95lb, digits = 2, format = "f"), 
                    "-",
                    formatC(estimate$calCi95ub, digits = 2, format = "f"), 
                    ", p = ",
                    formatC(estimate$calP, digits = 2, format = "f"),
                    ")")
    p(HTML(paste0("Using an intent-to-treat  instead of a per-protocol analysis, when comparing the risk of ", point$outcomeName, " between new users of ", point$targetName, 
                  " and ", point$comparatorName, " in the ", point$db, 
                  " database, the estimated <b>uncalibrated hazard ratio</b> was <b>",hr,
                  "</b>, the estimated <b>calibrated hazard ratio</b> was <b>", calHr, "</b>.")))
  })
  
  # Literature --------------------------------------------------------------
  
  filterDataLit <- reactive({
    idx <- dLit$Year >= input$yearSlider[1] & dLit$Year <= input$yearSlider[2]
    if (input$depressionCheckBox)
      idx <- idx & dLit$Depression
    return(dLit[idx, ])
  })
  
  rvLit <- reactiveValues(plotClick = NULL)
  
  observeEvent(input$plotClickLit, { rvLit$plotClick <- input$plotClickLit })
  
  clickedPointLit <- reactive({
    plotClick <- rvLit$plotClick
    point <- nearPoints(filterDataLit(), plotClick, threshold = 5, maxpoints = 1)
  })
  
  output$distPlotLit <- renderPlot({
    subset <- filterDataLit()
    if (!is.null(rv$plotClick)) {
      selected <- clickedPointLit()
    } else {
      selected <- NULL
    }
    return(plotScatter(subset, selected, "Effect Size"))
  })  
  
  output$hoverInfoLit <- renderUI({
    # Hover-over adapted from https://gitlab.com/snippets/16220
    hover <- input$plotHoverLit
    point <- nearPoints(filterDataLit(), hover, threshold = 5, maxpoints = 1, addDist = TRUE)
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
                    "left:", left_px + 2, "px; top:", top_px + 2, "px;")
    #dLit$Title
    # actual tooltip created as wellPanel
    if (is.na(point$P.value)) {
      est <- paste0(point$rr, " (", point$ci95lb, "-", point$ci95ub, ")")
    } else { 
      est <- paste0(point$rr, " (p = ", point$P.value, ")")
    }
    wellPanel(
      style = style,
      p(HTML(paste0("<b> title: </b>", point$Title, "<br/>",
                    "<b> PMID: </b>", point$PMID, "<br/>",
                    "<b> year: </b>", point$Year, "<br/>",
                    "<b> estimate: </b>", est)))
    )
  })
  
  output$abstract <-  renderUI({
    point <- clickedPointLit()
    if (nrow(point) == 0) return(NULL)
    
    hash <- point$PMID %% 1000
    fileName <- file.path("data", normName(paste0("pmids_ending_with_", hash, ".rds")))
    subset <- readRDS(fileName)
    txt <- paste(subset[[as.character(point$PMID)]], collapse = "\n")
    
    if (is.na(point$P.value)) {
      est <- paste0(point$rr, " (", point$ci95lb, "-", point$ci95ub, ")")
    } else { 
      est <- paste0(point$rr, " (p = ", point$P.value, ")")
    }
    p(HTML(paste0("<b> Estimate: </b>", est,  "<br/>",
                  "<b> PMID: </b>", 
                  "<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/", point$PMID, "\">",
                  point$PMID,
                  "</a><br/><h4>",
                  as.character(point$Title), "</h4><br/>", 
                  gsub("\n","</br>",substr(txt, 1, point$StartPos)), 
                  "<strong>", substr(txt, point$StartPos+1, point$EndPos), "</strong>",
                  gsub("\n","</br>",substr(txt, point$EndPos+1, nchar(txt)))
                  )))
  })
  
  
})






