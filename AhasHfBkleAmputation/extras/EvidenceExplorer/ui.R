library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1500px;',
                  titlePanel(HTML(paste("<h3>Comparative Effectiveness of Canagliflozin, SGLT2 Inhibitors, and Non-SGLT2 Inhibitors on the Risk of Hospitalization for Heart Failure and Amputation in Patients With Type 2 Diabetes Mellitus:  A Real-world Meta-analysis of 4 Observational Databases</h3>", if(blind){"*Blinded*"}else{""})), windowTitle = "Comparison of Canagliflozin vs. Alternative Antihyperglycemic Treatments"),
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
                                       div(p("The results of this study have been accepted for presentation at American Diabetes Association (ADA), and are under embargo until the conference is held.  A manuscript summarizing the results is currently under review in a peer-review journal, the results of which represent a subset of the top-line summary report shared with the FDA.  This web-based application provides an interactive platform to explore all analysis results generated as part of this study, as a supplement to the top-line summary report and manuscript.  This tool is currently being made available only for the journal peer reviewers and regulatory authorities as part of their review process, and results should not be shared more broadly until the ADA embargo and peer review process is complete."), style="border: 1px solid black; padding: 5px;"),
                                       HTML("<br/>"),
                                       p(HTML("This study has been registered on clinicaltrials.gov (NCT03492580) : <a href=\"https://clinicaltrials.gov/ct2/show/NCT03492580\">https://clinicaltrials.gov/ct2/show/NCT03492580</a><br/>"),
                                         HTML("The full study protocol and statistical analysis plan can be found here: <a href=\"https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation/documents\">https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation/documents</a><br/>"),
                                         HTML("The full source code for the study can be found here: <a href=\"https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation\">https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation</a>")),
                                       HTML("<br/>"),
                                       p("Below is the abstract of the submitted manuscript that summarizes the collective findings:"),
                                       HTML("<br/>"),
                                       p(tags$strong("Aims:"), "Sodium glucose co-transporter 2 inhibitors (SGLT2i) are indicated for treatment of type 2 diabetes mellitus (T2DM); some SGLT2i have reported cardiovascular benefit, and some reported risk of below-knee lower extremity (BKLE) amputation. This study examined the real-world comparative effectiveness within the SGLT2i class and versus non-SGLT2i antihyperglycemic agents."),
                                       p(tags$strong("Materials and Methods:"), "Data from 4 large US administrative claims databases were used to characterize risk and provide population-level estimates of canagliflozin’s effects on hospitalization for heart failure (HHF) and BKLE amputation versus other SGLT2i and non-SGLT2i in T2DM patients. Comparative analyses using a propensity score adjusted new-user cohort design examined relative hazards of outcomes across all new users and a subpopulation with established cardiovascular disease (CVD)."),
                                       p(tags$strong("Results:"), "Across the 4 databases (142,800 canagliflozin, 110,897 other SGLT2i, 460,885 non-SGLT2i), the meta-analytic hazard ratio estimate for HHF with canagliflozin versus non-SGLT2i was 0.39 (0.26-0.60; on-treatment). The estimate for BKLE amputation with canagliflozin versus non-SGLT2i was 0.75 (0.40-1.41) in the on-treatment and 1.01 (0.93-1.10) in the intent-to-treat analyses. Effects in the CVD subgroup were similar for both outcomes. No consistent differences were observed between canagliflozin and other SGLT2i."),
                                       p(tags$strong("Conclusions:"), "In this large comprehensive analysis, canagliflozin and other SGLT2i demonstrated HHF benefits consistent with clinical trial data, but showed no increased risk of BKLE amputation versus non-SGLT2i. HHF and BKLE amputation results were similar in the CVD subgroup. This study helps further characterize the potential benefits and harms of SGLT2i in routine clinical practice to complement evidence from clinical trials and prior observational studies.")
                              ),
                              tabPanel("Explore results",
                                       fluidRow(
                                         column(3,
                                                selectInput("comparison", div("Comparison:", actionLink("comparisonsInfo", "", icon = icon("info-circle"))), comparisons),
                                                selectInput("outcome", div("Outcome:", actionLink("outcomesInfo", "", icon = icon("info-circle"))), outcomes),
                                                checkboxGroupInput("establishedCVd", div("Established cardiovasc. disease (CVD):", actionLink("cvdInfo", "", icon = icon("info-circle"))), establishCvds, selected = "not required"),
                                                checkboxGroupInput("priorExposure", div("Prior exposure:", actionLink("priorExposureInfo", "", icon = icon("info-circle"))), priorExposures, selected = "no restrictions"),
                                                checkboxGroupInput("timeAtRisk", div("Time at risk:", actionLink("tarInfo", "", icon = icon("info-circle"))), timeAtRisks, selected = "On Treatment"),
                                                checkboxGroupInput("evenType", div("Event type:", actionLink("eventInfo", "", icon = icon("info-circle"))), evenTypes, selected = "First Post Index Event"),
                                                checkboxGroupInput("psStrategy", div("Propensity score (PS) strategy:", actionLink("psInfo", "", icon = icon("info-circle"))), psStrategies, selected = "Matching"),
                                                checkboxGroupInput("db", div("Data source:", actionLink("dbInfo", "", icon = icon("info-circle"))), dbs, selected = dbs)
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
                                                                             tabPanel("Parameter sensitivity",
                                                                                      uiOutput("hoverInfoForestPlot"),
                                                                                      plotOutput("forestPlot", height = 2000, hover = hoverOpts("plotHoverForestPlot", delay = 100, delayType = "debounce")),
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