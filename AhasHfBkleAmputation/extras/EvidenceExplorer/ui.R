library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1400px;',

  titlePanel(paste("Comparison of Canagliflozin vs. Alternative Antihyperglycemic Treatments", if(blind){"*Blinded*"}else{""})),
  fluidRow(
    column(3,
      selectInput("comparison", "Comparison:", comparisons),
      selectInput("outcome", "Outcome:", outcomes),
      checkboxGroupInput("establishedCVd", "Established cardiovascular disease (CVD):", establishCvds, selected = establishCvds),
      checkboxGroupInput("priorExposure", "Prior exposure:", priorExposures, selected = priorExposures),
      checkboxGroupInput("timeAtRisk", "Time at risk:", timeAtRisks, selected = timeAtRisks),
      checkboxGroupInput("evenType", "Event type:", evenTypes, selected = evenTypes),
      checkboxGroupInput("psStrategy", "Propensity score (PS) strategy:", psStrategies, selected = psStrategies),
      checkboxGroupInput("db", "Database:", dbs, selected = dbs)
    ),

    # Show a plot of the generated distribution
    column(9,
           dataTableOutput("mainTable"),
           conditionalPanel("output.rowIsSelected == true",
             tabsetPanel(id = "tabsetPanel",
               tabPanel("Power",
                        uiOutput("powerTableCaption"),
                        tableOutput("powerTable"),
                        conditionalPanel("output.isMetaAnalysis == false",
                            uiOutput("timeAtRiskTableCaption"),
                            tableOutput("timeAtRiskTable"))),
               tabPanel("Population characteristics",
                          uiOutput("table1Caption"),
                          dataTableOutput("table1Table")),
               tabPanel("Propensity scores",
                        plotOutput("psPlot"),
                        div(strong("Figure 1."),"Preference score distribution. The preference score is a transformation of the propensity score 
                                       that adjusts for differences in the sizes of the two treatment groups. A higher overlap indicates subjects in the 
                            two groups were more similar in terms of their predicted probability of receiving one treatment over the other.")),
               tabPanel("Covariate balance",
                        uiOutput("hoverInfoBalanceScatter"),
                        plotOutput("balancePlot",
                                   hover = hoverOpts("plotHoverBalanceScatter", delay = 100, delayType = "debounce")),
                        uiOutput("balancePlotCaption")),
               tabPanel("Systematic error",
                        plotOutput("negativeControlPlot"),
                        div(strong("Figure 3."),"Negative control estimates. Each blue dot represents the estimated hazard
                            ratio and standard error (related to the width of the confidence interval) of each of the negative
                            control outcomes. The yellow diamond indicated the outcome of interest. Estimates below the dashed
                            line have uncalibrated p < .05. Estimates in the orange area have calibrated p < .05. The red band
                            indicated the 95% credible interval around the boundary of the orange area. ")),
               tabPanel("Kaplan-Meier",
                        plotOutput("kaplanMeierPlot", height = 550),
                        uiOutput("kmPlotCaption"))
               )
          )
            
      )
  )
))
