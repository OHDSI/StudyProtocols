library(shiny)
library(DT)

shinyUI(fluidPage(style = 'width:1500px;',
                  titlePanel(HTML(paste("<h3>Comparative effectiveness of canagliflozin, SGLT2 inhibitors and non-SGLT2 inhibitors on the risk of hospitalization for heart failure and amputation in patients with type 2 diabetes mellitus: A real-world meta-analysis of 4 observational databases (OBSERVE-4D)</h3>", if(blind){"*Blinded*"}else{""})), windowTitle = "Comparison of Canagliflozin vs. Alternative Antihyperglycemic Treatments"),
                  tags$head(tags$style(type = "text/css", "
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
                                       HTML("<p>OBSERVE-4D is a retrospective real-world observational study to evaluate the risk of below-knee lower extremity (BKLE) amputation and hospitalization for heart failure (HHF) with canagliflozin versus other sodium glucose co-transporter 2 inhibitor (SGLT2i) and non-SGLT2i antihyperglycemic agents (AHAs).</p>"),
                                       HTML("<p>This web-based application provides an interactive platform to explore all analysis results generated as part of this study, as a supplement to the manuscript published in Diabetes, Metabolism, and Obesity (the full manuscript is available at: <a href = \"https://onlinelibrary.wiley.com/doi/full/10.1111/dom.13424\">https://onlinelibrary.wiley.com/doi/full/10.1111/dom.13424</a>).</p>"),
                                       HTML("<br/>"),
                                       HTML("<p>Below is the abstract of the manuscript that summarizes the collective findings:</p>"),
                                       HTML("<p><strong>Aims:</strong> Sodium glucose co-transporter 2 inhibitors (SGLT2i) are indicated for treatment of type 2 diabetes mellitus (T2DM); some SGLT2i have reported cardiovascular benefit, and some have reported risk of below-knee lower extremity (BKLE) amputation. This study examined the real-world comparative effectiveness within the SGLT2i class and compared with non-SGLT2i antihyperglycaemic agents. </p>"),
                                       HTML("<p><strong>Materials and methods:</strong> Data from 4 large US administrative claims databases were used to characterize risk and provide population-level estimates of canagliflozin's effects on hospitalization for heart failure (HHF) and BKLE amputation vs other SGLT2i and non-SGLT2i in T2DM patients. Comparative analyses using a propensity score–adjusted new-user cohort design examined relative hazards of outcomes across all new users and a subpopulation with established cardiovascular disease. </p>"),
                                       HTML("<p><strong>Results:</strong> Across the 4 databases (142 800 new users of canagliflozin, 110 897 new users of other SGLT2i, 460 885 new users of non-SGLT2i), the meta-analytic hazard ratio estimate for HHF with canagliflozin vs non-SGLT2i was 0.39 (95% CI, 0.26-0.60) in the on-treatment analysis. The estimate for BKLE amputation with canagliflozin vs non-SGLT2i was 0.75 (95% CI, 0.40-1.41) in the on-treatment analysis and 1.01 (95% CI, 0.93-1.10) in the intent-to-treat analysis. Effects in the subpopulation with established cardiovascular disease were similar for both outcomes. No consistent differences were observed between canagliflozin and other SGLT2i. </p>"),
                                       HTML("<p><strong>Conclusions:</strong> In this large comprehensive analysis, canagliflozin and other SGLT2i demonstrated HHF benefits consistent with clinical trial data, but showed no increased risk of BKLE amputation vs non-SGLT2i. HHF and BKLE amputation results were similar in the subpopulation with established cardiovascular disease. This study helps further characterize the potential benefits and harms of SGLT2i in routine clinical practice to complement evidence from clinical trials and prior observational studies.</p>"),
                                       HTML("<br/>"),
                                       HTML("<p>Below are links for study-related artifacts that have been made available as part of this study:</p>"),
                                       HTML("<ul>"),
                                       HTML("<li>This study has been registered on clinicaltrials.gov (NCT03492580) : <a href=\"https://clinicaltrials.gov/ct2/show/NCT03492580\">https://clinicaltrials.gov/ct2/show/NCT03492580</a></li>"),
                                       HTML("<li>The full study protocol and statistical analysis plan can be found here: <a href=\"https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation/documents\">https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation/documents</a></li>"),
                                       HTML("<li>The full source code for the study can be found here: <a href=\"https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation\">https://github.com/OHDSI/StudyProtocols/tree/master/AhasHfBkleAmputation</a></li>"),
                                       HTML("<li>A poster presentation was delivered at the American Diabetes Association, 24-25 June 2018.  The poster is available at: <a href=\"http://ada.apprisor.org/index.cfm?k=buexduvq4u\">http://ada.apprisor.org/index.cfm?k=buexduvq4u</a></li>"),
                                       HTML("<li>The results were published in the journal, \"Diabetes, Obesity, and Metabolism\": <a href=\"https://onlinelibrary.wiley.com/doi/full/10.1111/dom.13424\">https://onlinelibrary.wiley.com/doi/full/10.1111/dom.13424</a></li>"),
                                       HTML("</ul>")
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