library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1500px;',
                  titlePanel(HTML(paste("<h3>Diabetic Ketoacidosis in Patients With Type 2 Diabetes Treated With Sodium Glucose Co-transporter 2 Inhibitors Versus Other Antihyperglycemic Agents: An Observational Study of Four US Administrative Claims Databases</h3>", if(blind){"*Blinded*"}else{""})), windowTitle = "Comparison of SGLT2is vs. Other AHAs"),
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

                  tabsetPanel(id = "mainTabsetPanel",
                              tabPanel("About",
                                       HTML("<br/>"),
                                       div(p("These research results are from a retrospective, real-world observational study to evaluate the risk of diabetic ketoacidosis among patients with type 2 diabetes mellitus treated with antihyperglycemic agents. This web-based application provides an interactive platform to explore all analysis results generated as part of this study, as a supplement to a full manuscript which has been submitted to peer-reviewed, scientific journal. During the review period, these results are considered under embargo and should not be disclosed without explicit permission and consent from the authors."), style="border: 1px solid black; padding: 5px;"),
                                       HTML("<br/>"),
                                       HTML("<br/>"),
                                       p("Below is the abstract of the submitted manuscript that summarizes the collective findings:"),
                                       HTML("<br/>"),
                                       p(tags$strong("Purpose:"), "To compare the incidence of diabetic ketoacidosis (DKA) among patients with type 2 diabetes mellitus (T2DM) who were new users of sodium glucose co-transporter 2 inhibitors (SGLT2i) versus other classes of antihyperglycemic agents (AHAs)."),
                                       p(tags$strong("Methods:"), "Patients were identified from four large US claims databases using broad (all T2DM patients) and narrow (intended to exclude patients with T1DM or secondary diabetes misclassified as T2DM) definitions of T2DM. New users of SGLT2i and seven groups of comparator AHAs were matched (1:1) on exposure propensity scores to adjust for imbalances in baseline covariates. Cox proportional hazards regression models, conditioned on propensity score-matched pairs, were used to estimate hazard ratios (HRs) of DKA for new users of SGLT2i versus other AHAs. When I2 <40%, a combined HR across the four databases was estimated."),
                                       p(tags$strong("Results:"), "Using the broad definition of T2DM, new users of SGLT2i had an increased risk of DKA versus sulfonylureas (HR[95%CI]: 1.53[1.31-1.79]), DPP-4i (1.28[1.11-1.47]), GLP-1 receptor agonists (1.34[1.12-1.60]), metformin (1.31[1.11-1.54]), and insulinotropic AHAs (1.38[1.15-1.66]). Using the narrow definition of T2DM, new users of SGLT2i had an increased risk of DKA only versus sulfonylureas (1.43[1.01-2.01]). New users of SGLT2i had a lower risk of DKA versus insulin and a similar risk as thiazolidinediones, regardless of T2DM definition."),
                                       p(tags$strong("Conclusions:"), "Increased risk of DKA was observed for new users of SGLT2i versus several non-SGLT2i AHAs when T2DM was defined broadly. When T2DM was defined narrowly to exclude possible misclassified T1DM patients, an increased risk of DKA with SGLT2i was observed compared to sulfonylureas."),
                                       HTML("<br/>"),
                                       HTML("<br/>"),
                                       HTML("<p>Below are links for study-related artifacts that have been made available as part of this study:</p>"),
                                       HTML("<ul>"),
                                       HTML("<li>The study protocol was reviewed and approved by the EMA, and registered at the EU PAS Register (EUPAS23705): <a href=\"http://www.encepp.eu/encepp/viewResource.htm?id=26367\">http://www.encepp.eu/encepp/viewResource.htm?id=26367</a><br/></li>"),
                                       HTML("<li>The full study protocol and statistical analysis plan is available at: <a href=\"https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_535/browse/documents/EPI535_PROTOCOL\">https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_535/browse/documents/EPI535_PROTOCOL</a><br/></li>"),
                                       HTML("<li>The full source code for the study is available at: <a href=\"https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_535/browse/programs\">https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_535/browse/programs</a></li>"),
                                       HTML("</ul>")
                              ),
                              tabPanel("Explore results",
                                       fluidRow(
                                         column(4,
                                                selectInput("comparison", div("Comparison:", actionLink("comparisonsInfo", "", icon = icon("info-circle"))), comparisons, selected = "SGLT2i-BROAD vs. DPP-4i-BROAD", width = '85%'),
                                                selectInput("outcome", div("Outcome:", actionLink("outcomesInfo", "", icon = icon("info-circle"))), outcomes, selected = "DKA (IP or ER)", width = '85%'),
                                                checkboxGroupInput("timeAtRisk", div("Time at risk:", actionLink("tarInfo", "", icon = icon("info-circle"))), timeAtRisks, selected = "Intent-to-Treat", width = '85%'),
                                                checkboxGroupInput("db", div("Data source:", actionLink("dbInfo", "", icon = icon("info-circle"))), dbs, selected = dbs, width = '85%')
                                         ),
                                         column(8,
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
                                                                                      div(strong("Figure 1."),"Preference score distribution. The preference score is a transformation of the propensity score that adjusts for differences in the sizes of the two treatment groups. A higher overlap indicates subjects in the two groups were more similar in terms of their predicted probability of receiving one treatment over the other.")),
                                                                             tabPanel("Covariate balance",
                                                                                      uiOutput("hoverInfoBalanceScatter"),
                                                                                      plotOutput("balancePlot",
                                                                                                 hover = hoverOpts("plotHoverBalanceScatter", delay = 100, delayType = "debounce")),
                                                                                      uiOutput("balancePlotCaption")),
                                                                             tabPanel("Systematic error",
                                                                                      plotOutput("negativeControlPlot"),
                                                                                      div(strong("Figure 3."),"Negative control estimates. Each blue dot represents the estimated hazard ratio and standard error (related to the width of the confidence interval) of each of the negative control outcomes. The yellow diamond indicated the outcome of interest. Estimates below the dashed line have uncalibrated p < .05. Estimates in the orange area have calibrated p < .05. The red band indicated the 95% credible interval around the boundary of the orange area. ")),
                                                                             tabPanel("Sensitivity",
                                                                                      uiOutput("hoverInfoForestPlot"),
                                                                                      plotOutput("forestPlot", height = 500, hover = hoverOpts("plotHoverForestPlot", delay = 100, delayType = "debounce")),
                                                                                      div(strong("Figure 4."),"Forest plot of effect estimates from all sensitivity analyses across databases and time-at-risk periods. Black indicates the estimate selected by the user.")),
                                                                             tabPanel("Kaplan-Meier",
                                                                                      plotOutput("kaplanMeierPlot", height = 550),
                                                                                      uiOutput("kmPlotCaption"))
                                                                 )
                                                )

                                         )
                                       )
                              )
                  )
)
)
