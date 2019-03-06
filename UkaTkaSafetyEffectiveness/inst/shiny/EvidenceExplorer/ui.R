library(shiny)
library(DT)

shinyUI(
  fluidPage(style = "width:1500px;",
            titlePanel(paste("Prospective validation of a randomised trial of unicompartmental and total knee replacement: real-world evidence from the OHDSI network", if(blind) "***Blinded***" else "")),
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
            conditionalPanel(condition = "$('html').hasClass('shiny-busy')",
                             tags$div("Procesing...",id = "loadmessage")),
            
            tabsetPanel(id = "mainTabsetPanel",
                        tabPanel("About",
                                 HTML("<br/>"),
                                 div(p("These research results are from a retrospective, real-world observational study to evaluate the risk of post-operative complications, opioid use, and revision with unicompartmental versus total knee replacement. The results have been reported in advance of results from an ongoing clinical trial comparing the same procedures for the risk of the same outcomes. This web-based application provides an interactive platform to explore all analysis results generated as part of this study. A full manuscript has been submitted for peer review publication."), style="border: 1px solid black; padding: 5px;"),
                                 HTML("<br/>"),
                                 HTML("<p>Below is the abstract of the manuscript that summarizes the findings:</p>"),
                                 HTML("<p><strong>Backgroud: </strong>In this network cohort study we aimed to predict the results of an ongoing surgical randomised controlled trial of unicompartmental and total knee replacement, the Total or Partial Knee Arthroplasty Trial (TOPKAT).</p>"),
                                 HTML("<p><strong>Methods: </strong>Five US and UK healthcare databases part of the Observational Health Data Sciences and Informatics (OHDSI) network were analysed. As with the target trial, post-operative complications (venous thromboembolism, infection, readmission, and mortality) were considered over 60 days following surgery and implant survival (revision procedures) over five years following surgery. Clinical effectiveness was assessed using opioid use, as a proxy measure for persistent pain, from 91 to 365 days after surgery. Propensity score matched Cox proportional hazards models were fitted for each outcome. Hazard Ratios (HRs) were calibrated using negative and positive control outcomes to minimise residual confounding.</p>"),
                                 HTML("<p><strong>Findings: </strong>In total, 32,376 and 250,295 individuals who received unicompartmental and total knee replacement respectively were matched based on propensity scores and included in the analysis. Unicompartmental knee replacement was consistently associated with a reduced risk of venous thromboembolism (calibrated HRs: 0.47 (0.31 - 0.73) to 0.76 (0.60 to 0.99)) and opioid use (calibrated HRs: 0.72 (0.63 to 0.84) to 0.86 (0.77 to 0.96)), but an increased risk of revision (calibrated HRs: 1.48 (1.25 to 1.83) to 1.76 (1.42 to 2.32)). Unicompartmental knee replacement was also associated with either a protective or no effect on risk of infection and readmission, and there was little evidence of a difference in risk of mortality in the one database for which calibrated HRs could be estimated.</p>"),
                                 HTML("<p><strong>Interpretation: </strong>Based on our results, we predict TOPKAT will find a significantly increased risk of revision but improved patient reported outcomes for unicompartmental knee replacement. While the trial is not powered to assess complications, we find unicompartmental knee replacement to be a safer procedure with, in particular, a reduced risk of venous thromboembolism. These findings, along with those from the trial when they emerge, will improve the understanding of the relative merits of unicompartmental and total knee replacement.</p>"),
                                 HTML("<br/>"),
                                 HTML("<p>Below are links for study-related artifacts that have been made available as part of this study:</p>"),
                                 HTML("<ul>"),
                                 HTML("<li>The full study protocol is available at: <a href=\"https://github.com/OHDSI/StudyProtocolSandbox/tree/master/ukatkasafety/documents\">https://github.com/OHDSI/StudyProtocolSandbox/tree/master/ukatkasafety/documents</a></li>"),
                                 HTML("<li>The full source code for the study is available at: <a href=\"https://github.com/OHDSI/StudyProtocolSandbox/tree/master/ukatkasafety\">https://github.com/OHDSI/StudyProtocolSandbox/tree/master/ukatkasafety</a></li>"),
                                 HTML("</ul>")
                        ),
                        tabPanel("Explore results",
                                fluidRow(
                                  column(4,
                                         selectInput("target", div("Target cohort:", actionLink("targetCohortsInfo", "", icon("info-circle"))), unique(exposureOfInterest$exposureName), selected = unique(exposureOfInterest$exposureName)[1], width = '100%'),
                                         selectInput("comparator", div("Comparator cohort:", actionLink("comparatorCohortsInfo", "", icon("info-circle"))), unique(exposureOfInterest$exposureName), selected = unique(exposureOfInterest$exposureName)[2], width = '100%'),
                                         selectInput("outcome", div("Outcome:", actionLink("outcomesInfo", "", icon("info-circle"))), unique(outcomeOfInterest$outcomeName), width = '100%'),
                                         checkboxGroupInput("database", div("Data source:", actionLink("dbInfo", "", icon("info-circle"))), database$databaseId, selected = database$databaseId[1], width = '100%'),
                                         checkboxGroupInput("analysis", div("Analysis specification:", actionLink("analysesInfo", "", icon("info-circle"))), cohortMethodAnalysis$description,  selected = cohortMethodAnalysis$description, width = '100%')
                                  ),
                                  
                                  column(8,
                                         dataTableOutput("mainTable"),
                                         conditionalPanel("output.rowIsSelected == true",
                                                          tabsetPanel(id = "detailsTabsetPanel",
                                                                      tabPanel("Power",
                                                                               uiOutput("powerTableCaption"),
                                                                               tableOutput("powerTable"),
                                                                               uiOutput("timeAtRiskTableCaption"),
                                                                               tableOutput("timeAtRiskTable")
                                                                      ),
                                                                      tabPanel("Attrition",
                                                                               plotOutput("attritionPlot", width = 600, height = 600),
                                                                               uiOutput("attritionPlotCaption"),
                                                                               downloadButton("downloadAttritionPlot", label = "Download diagram")
                                                                      ),
                                                                      tabPanel("Population characteristics",
                                                                               uiOutput("table1Caption"),
                                                                               dataTableOutput("table1Table")),
                                                                      tabPanel("Propensity scores",
                                                                               plotOutput("psDistPlot"),
                                                                               div(strong("Figure 2."),"Preference score distribution. The preference score is a transformation of the propensity score
                                                                                                                             that adjusts for differences in the sizes of the two treatment groups. A higher overlap indicates subjects in the
                                                                                                                             two groups were more similar in terms of their predicted probability of receiving one treatment over the other."),
                                                                               downloadButton("downloadPsDistPlot", label = "Download plot")),
                                                                      tabPanel("Covariate balance",
                                                                               uiOutput("hoverInfoBalanceScatter"),
                                                                               plotOutput("balancePlot",
                                                                                          hover = hoverOpts("plotHoverBalanceScatter", delay = 100, delayType = "debounce")),
                                                                               uiOutput("balancePlotCaption"),
                                                                               downloadButton("downloadBalancePlot", label = "Download plot")),
                                                                      tabPanel("Systematic error",
                                                                               plotOutput("systematicErrorPlot"),
                                                                               div(strong("Figure 4."),"Systematic error. Effect size estimates for the negative controls (true hazard ratio = 1)
                                                                                                        and positive controls (true hazard ratio > 1), before and after calibration. Estimates below the diagonal dashed
                                                                                                        lines are statistically significant (alpha = 0.05) different from the true effect size. A well-calibrated
                                                                                                        estimator should have the true effect size within the 95 percent confidence interval 95 percent of times."),
                                                                               downloadButton("downloadSystematicErrorPlot", label = "Download plot")),
                                                                      tabPanel("Kaplan-Meier",
                                                                               plotOutput("kaplanMeierPlot", height = 550),
                                                                               uiOutput("kaplanMeierPlotPlotCaption"),
                                                                               downloadButton("downloadKaplanMeierPlot", label = "Download plot")) #,
                                                                      # tabPanel("Subgroups",
                                                                      #          uiOutput("subgroupTableCaption"),
                                                                      #          dataTableOutput("subgroupTable")) 
                                                          )
                                         )
                                  )
                                )
                        )
            )
  )
)
