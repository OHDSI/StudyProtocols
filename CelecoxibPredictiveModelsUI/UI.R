shiny::shinyUI(
    shiny::fluidPage(
        list(shiny::tags$head(shiny::HTML('<link rel="icon", href="www/predict2.jpg",
                            type="image/png" />'))),
        shiny::div(style="padding: 0px 0px; width: '100%'",
                   shiny::titlePanel(title="", windowTitle="Celecoxib Predictive Models")
        ),

        shiny::navbarPage(
            title=shiny::div("Celecoxib Predictive Models Study"),

            shiny::tabPanel("Home",
                            shiny::column(width=5,
                                          shiny::imageOutput("image1")
                     ),

                     shiny::column(width=6,
                                   shiny::p(shiny::h3("OHDSI Research Study- evaluating models across a network of databases"),
                                            shiny::p("This study aims to investigate the robustness and transferablity of prediction models built for the same problem and using the same classifier (logistic regression with lasso regularisation) but across different datasets within the OHDSi community.")),
                                   shiny::p(shiny::a(href="...", "More Information"))
                     )

            ),

            #==============================================
            # Check plp develop installed
            #==============================================
            # the data tab should have 3 conditional tabs - data loader/data extractor/data viewer
            shiny::tabPanel("Install",
                     shiny::mainPanel("Install study R packages:",
                                      'Before running this package installer, please shut down any other R connections.',
                                      DT::dataTableOutput("packageList"),

                                      shiny::p('Click to install CelecoxibPredictionModels R Package and missing dependancies',
                     shiny::actionButton('install', 'Install'))
                         )




                     ),

            #========================================================
            #  Study settings
            #========================================================
            shiny::tabPanel("Analysis",

                            shiny::wellPanel(
                                shiny::uiOutput("runAnalysis")

                            )

                      ),

            shiny::tabPanel("Summary",
                            shiny::uiOutput("selectData"),

                            shiny::wellPanel(shiny::h4("Result Summary:"),
                                DT::dataTableOutput("summary")
                            )
            ),

            #========================================================
            #  Send results
            #========================================================
            shiny::tabPanel("Explorer",
                            shiny::uiOutput("visSel"),
                            shiny::tabsetPanel(id ="analysisTabs",
                                               shiny::tabPanel(title = "Performance", value="panel_permform",
                                                               shiny::h4("Performance Metrics"),
                                                               DT::dataTableOutput("performance")),
                                               shiny::tabPanel(title = "Options", value="panel_options",
                                                               shiny::h4("Options"),
                                                               DT::dataTableOutput("options")),
                                               shiny::tabPanel(title = "Variables", value="panel_varimp",
                                                               shiny::h4("Variable Importance"),
                                                               DT::dataTableOutput("varImp")),
                                               shiny::tabPanel(title = "Attrition", value="panel_attrition",
                                                               shiny::h4("Attrition"),
                                                               DT::dataTableOutput("attrition")),
                                               shiny:: tabPanel(title = "ROC", value="panel_roc",
                                                                shiny::h4("Test"),
                                                                shiny::plotOutput("rocPlot"),
                                                                shiny::h4("Train"),
                                                                shiny::plotOutput("rocPlotTrain")),
                                               shiny::tabPanel(title = "Box Plot", value="panel_box",
                                                               shiny::h4("Test"),
                                                               shiny::plotOutput("boxPlot"),
                                                               shiny::h4("Train"),
                                                               shiny::plotOutput("boxPlotTrain")
                                                               ),
                                               shiny::tabPanel(title = "Calibration", value="panel_cal",
                                                               shiny::h4("Test"),
                                                               shiny::plotOutput("calPlot"),
                                                               shiny::h4("Train"),
                                                               shiny::plotOutput("calPlotTrain")),
                                               shiny::tabPanel(title = "Preference", value="panel_pref",
                                                               shiny::h4("Test"),
                                                               shiny::plotOutput("prefPlot"),
                                                               shiny::h4("Train"),
                                                               shiny::plotOutput("prefPlotTrain"))
                            )

            ),
            
            shiny::tabPanel("Apply Models",
                            shiny::mainPanel("Here you can select a model and apply it to",
                                             "predict the outcome using data extracted from a",
                                             "new database (e.g. apply model trained on CDM_JMDC_V5",
                                             "to data extracted from CDM_OPTUM_V5",
                            shiny::wellPanel(shiny::h4("Pick model: "),
                                             shiny::h4("Pick Data: ")
                              
                              
                            )
                            )
                            
            )


        )
        )
    )
