library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1500px;',
                  titlePanel(paste("Acute Pancreatitis Risk in Type 2 Diabetes with Canagliflozin versus Other Antihyperglycemic Agents: Retrospective Cohort Study of US Claims Databases", if(blind){"*Blinded*"}else{""})),
  
                  tabsetPanel(id = "mainTabsetPanel",
                              tabPanel("About",
                                       HTML("<br/>"),
                                       div(p("These research results are from a retrospective, real-world observational study to evaluate the risk of acute pancreatitis among patients with type 2 diabetes mellitus treated with antihyperglycemic agents. This web-based application provides an interactive platform to explore all analysis results generated as part of this study, as a supplement to a full manuscript which has been submitted to peer-reviewed, scientific journal. During the review period, these results are considered under embargo and should not be disclosed without explicit permission and consent from the authors."), style="border: 1px solid black; padding: 5px;"),
                                       HTML("<br/>"),
                                       HTML("<br/>"),
                                       p("Below is the abstract of the submitted manuscript that summarizes the collective findings:"),
                                       HTML("<br/>"),
                                       p(tags$strong("Background:"), "Observational evidence suggests that patients with type 2 diabetes mellitus (T2DM) are at increased risk for acute pancreatitis (AP) versus those without T2DM. A small number of AP events were reported in clinical trials of the sodium glucose co-transporter 2 inhibitor canagliflozin, though no imbalances were observed between treatment groups. This observational study evaluated risk of AP among new users of canagliflozin compared with new users of six classes of other antihyperglycemic agents (AHAs)."),
                                       p(tags$strong("Methods:"), "Three US claims databases were analyzed based on a prespecified protocol approved by the European Medicines Agency. Propensity score adjustment controlled for imbalances in baseline covariates. Cox regression models estimated the hazard ratio of AP with canagliflozin compared with other AHAs using on-treatment (primary) and intent-to-treat approaches. Sensitivity analyses assessed robustness of findings."),
                                       p(tags$strong("Results:"), "Across the three databases, there were between 12,023-80,986 new users of canagliflozin; the unadjusted incidence rates of AP (per 1000 person-years) were between 1.5-2.2 for canagliflozin and 1.1-6.6 for other AHAs. The risk of AP was generally similar for new users of canagliflozin compared with new users of glucagon-like peptide-1 receptor agonists, dipeptidyl peptidase-4 inhibitors, sulfonylureas, thiazolidinediones, insulin, and other AHAs, with no consistent between-treatment differences observed across databases. Intent-to-treat and sensitivity analysis findings were qualitatively consistent with on-treatment findings."),
                                       p(tags$strong("Conclusions:"), "In this large observational study, incidence rates of AP in patients with T2DM treated with canagliflozin or other AHAs were generally similar, with no evidence suggesting that canagliflozin is associated with increased risk of AP compared with other AHAs."),
                                       HTML("<br/>"),
                                       HTML("<br/>"),
                                       HTML("<p>Below are links for study-related artifacts that have been made available as part of this study:</p>"),
                                       HTML("<ul>"),
                                       HTML("<li>The study protocol was reviewed and approved by the EMA, and registered at the EU PAS Register (EUPAS23531): <a href=\"http://www.encepp.eu/encepp/viewResource.htm?id=26370\">http://www.encepp.eu/encepp/viewResource.htm?id=26370</a><br/></li>"),
                                       HTML("<li>The full study protocol and statistical analysis plan is available at: <a href=\"https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_534/browse/documents\">https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_534/browse/documents</a><br/></li>"),
                                       HTML("<li>The full source code for the study is available at: <a href=\"https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_534/browse\">https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_534/browse</a></li>"),
                                       HTML("</ul>")
                              ),
                              tabPanel("Explore results", 
                                       fluidRow(
                                         column(3,
                                                selectInput("comparison", "Comparison:", comparisons),
                                                selectInput("outcome", "Outcome:", outcomes),
                                                checkboxGroupInput("eventType", "Event type:", eventTypes, selected = eventTypes[1]),
                                                checkboxGroupInput("timeAtRisk", "Time at risk:", timeAtRisks, selected = timeAtRisks[1]),
                                                checkboxGroupInput("psStrategy", "Propensity score (PS) strategy:", psStrategies, selected = psStrategies[1]),
                                                checkboxGroupInput("noCana", "Canagliflozin exposure history:", canaFilters, selected = canaFilters[1]),
                                                checkboxGroupInput("metforminAddOn", "Metformin add-on:", metforminAddOns, selected = "Not required"),
                                                checkboxGroupInput("db", "Database (DB):", dbs, selected = dbs)
                                                #checkboxGroupInput("noCensor", "Remove Censoring:", censorFilters, selected = censorFilters),
                                                #checkboxGroupInput("priorAP", "Prior acute pancreatitis (AP):", priorAPs, selected = priorAPs),
                                         ),
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
                              )
                  )
))
