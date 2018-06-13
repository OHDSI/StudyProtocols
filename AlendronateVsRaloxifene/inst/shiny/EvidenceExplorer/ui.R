library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1500px;',
                  titlePanel(paste("Evidence Explorer", if(blind){"*Blinded*"}else{""})),
                  tags$head(tags$style(type="text/css", "
             #loadmessage {
               position: fixed;
               top: 0px;
               left: 0px;
               width: 100%;
               padding: 5px 0px 5px 0px;
               text-align: center;
               font-weight: bold;
               font-size: 100%;
               color: #000000;
               background-color: #ADD8E6;
               z-index: 105;
             }
          ")),
                  conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                   tags$div("Procesing...",id="loadmessage")),
                  
                  fluidRow(
                    column(3,
                           selectInput("comparison", "Comparison:", comparisons),
                           selectInput("outcome", "Outcome:", outcomes),
                           checkboxGroupInput("analysis", "Analysis", analyses, selected = analyses),
                           checkboxGroupInput("db", "Database:", databases, selected = databases)
                    ),
                    column(9,
                           dataTableOutput("mainTable"),
                           conditionalPanel("output.rowIsSelected == true",
                                            tabsetPanel(id = "tabsetPanel",
                                                        tabPanel("Power",
                                                                 uiOutput("powerTableCaption"),
                                                                 tableOutput("powerTable")),
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
                                                        tabPanel("Parameter sensitivity",
                                                                 uiOutput("hoverInfoForestPlot"),
                                                                 plotOutput("forestPlot", hover = hoverOpts("plotHoverForestPlot", delay = 100, delayType = "debounce")),
                                                                 div(strong("Figure 4."),"Forest plot of effect estimates from all sensitivity analyses across databases and time-at-risk periods. Black indicates the estimate selected by the user.")),
                                                        tabPanel("Kaplan-Meier",
                                                                 imageOutput("kaplanMeierPlot", height = 550),
                                                                 uiOutput("kmPlotCaption"))
                                            )
                           )
                           
                    )
                  )
)
)
