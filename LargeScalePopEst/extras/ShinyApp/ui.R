library(shiny)

shinyUI(fluidPage(style = 'width:1000px;',
  titlePanel("Supplementary data for 'Improving reproducibility using high-throughput observational studies with empirical calibration'"),
  tabsetPanel(
    tabPanel("Systematically generated evidence",
             fluidRow(
               column(3,
                      checkboxGroupInput("db", "Database:", dbs, selected = dbs),
                      selectInput("targetName", "Target:", c("All", treatments), selected = "All"),
                      selectInput("comparatorName", "Comparator:", c("All", treatments), selected = "All"),
                      selectInput("outcomeName", "Outcome:", c("All", outcomes), selected = "All")),
               column(9,
                      plotOutput("distPlot", 
                                 hover = hoverOpts("plotHover", delay = 100, delayType = "debounce"),
                                 click = "plotClick"),
                      div(strong("Figure S1."),"Systematically generated evidence from observational data. 
                          Each dot represents a calibrated hazard ratio and confidence interval for a comparison of two 
                          depression treatments with respect to an outcome of interest in one of the four databases. Use 
                          the controls on the left to filter the result set. After selecting an estimate, details will be shown below."), 
                      uiOutput("hoverInfo"))
             ),
             fluidRow(h4(textOutput("tco"))
             ), 
             conditionalPanel(condition = "output.tco",
             tabsetPanel(
               tabPanel("Estimates",
                        fluidRow(
                          column(8, 
                                 uiOutput("estimatesText"),
                                 tableOutput("estimatesTable"),
                                 div(strong("Table S1.1."),"Counts of subjects, person-days and outcomes in the target and comparator population.")),
                          column(4, 
                                 plotOutput("estimatesPlot", height = "200px"),
                                 div(strong("Figure S1.1."),"Hazard ratios and confidence intervals (CI) across the databases, both
                                     calibrated (top) and uncalibrated (bottom). Blue indicates the CI includes one, orange indicates
                                     the CI does not include one."))
                        )
               ),
               tabPanel("Diagnostics",
                        fluidRow(
                          column(7, 
                                 plotOutput("psPlot"),
                                 div(strong("Figure S1.2."),"Preference score distribution. The preference score is a transformation of the propensity score 
                                     that adjusts for differences in the sizes of the two treatment groups. A higher overlap indicates subjects in the 
                                     two groups were more similar in terms of their predicted probability of receivind one treatment over the other.")),
                          column(5, 
                                 plotOutput("balanceScatterPlot",
                                            hover = hoverOpts("plotHoverBalanceScatter", delay = 100, delayType = "debounce")),
                                 div(strong("Figure S1.3."),"Covariate balance before and after stratification. 
                                     Each dot represents the standardizes difference in means for a single covariate before and after stratifying on the propensity score.
                                     Move the mouse arrow over a dot for more details."),
                                 uiOutput("hoverInfoBalanceScatter"))
                        )
               ),
               tabPanel("Empirical evaluation & calibration",
                        fluidRow(
                          column(12, 
                                 plotOutput("evaluation", height = "200px"),
                                 div(strong("Figure S1.4."),"Hazard ratios and corresponding standard errors for our negative and positive controls. The estimates are stratified by the true hazard ratio"),
                                 plotOutput("calibration", height = "200px"),
                                 div(strong("Figure S1.5."),"Hazard ratios and corresponding standard errors after empirical calibration for our negative and positive controls. The estimates are stratified by the true hazard ratio"))
                        )
               ),
               tabPanel("Sensitivity analysis",
                        fluidRow(
                          column(8, 
                                 uiOutput("sensitivityAnalysisText"),
                                 tableOutput("sensitivityAnalysisTable"),
                                 div(strong("Table S1.2."),"Counts of subjects, person-days and outcomes in the target and comparator population.")),
                          column(4, 
                                 plotOutput("sensitivityAnalysisPlot", height = "200px"),
                                 div(strong("Figure S1.6."),"Hazard ratios and confidence intervals (CI) across the databases. Blue indicates the CI includes one, orange indicates
                                     the CI does not include one."))
                        )
               )
             )
             )
    ),
    tabPanel("Literature",
             fluidRow(
               column(3,
                      sliderInput("yearSlider", label = "Years", min = min(years), max = max(years), value = c(min(years), max(years)), step = 1, sep=""),
                      checkboxInput("depressionCheckBox", label = "Restrict to depression treatments", value = FALSE)
                      ),
               column(9,
                      plotOutput("distPlotLit",
                                 hover = hoverOpts("plotHoverLit", delay = 100, delayType = "debounce"),
                                 click = "plotClickLit"),
                      div(strong("Figure S2"),": Evidence in literature. 
                          Each dot represents an effect size and confidence interval or p-value as extracted from the scientific
                          literature. Use the controls on the left to filter the result set. After selecting an estimate, the 
                          abstract will be shown below with the location of the estimate highlighted."), 
                      uiOutput("hoverInfoLit"))
             ),
             fluidRow(
               column(12,
                      uiOutput("abstract")
                      )
               )
    ),
    tabPanel("About",
             br(),
             p("Supplementary data for:"),
             p("Schuemie MJ, Ryan PB, Hripcsak G, Madigan D, Suchard MA,", 
               em("Improving reproducibility using high-throughput observational studies with empirical calibration."), 
               ", Phil. Trans. R. Soc. A, 2018")
    )
  )
)
)