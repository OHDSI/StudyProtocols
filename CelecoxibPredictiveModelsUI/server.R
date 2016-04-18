shiny::shinyServer(function(input, output, session) {

    # add cluster plot here:
    output$image1 <- shiny::renderImage({
        return(list(
            src = "www/predict2.png",
            width = "100%",
            height = 300,
            contentType = "image/png",
            alt = "Prediction"
        ))
    }, deleteFile = FALSE)

    output$packageList <- DT::renderDataTable({
        packageList <- installed.packages()[,c('Package','Version')]
        deps <- data.frame(Package=c("devtools", "OhdsiRTools","SqlRender",
                                     "DatabaseConnector","Cyclops",
                                     "OhdsiSharing",
                                     "FeatureExtraction",
                                     "CelecoxibPredictiveModels",
                                     "PatientLevelPrediction"),
                           requiredVersion = c('Any','Any','>= 1.1.3','>= 1.3.0','>= 1.2.0','Any',
                                               'Any',
                                               '>= 0.2','>= 1.1.1'))
        packageList <- merge(packageList, deps, all.y=T)

        data.frame(packageList)
    },     escape = FALSE, selection = 'none',
                                                  options = list(
                                                      pageLength = 25
                                                      #,initComplete = I("function(settings, json) {alert('Done.');}")
                                                  ))
    # add install setiings reactive value
    shiny::observeEvent(input$install, {

        # UNSET JAVA_HOME AS TRHIS CAUSES ISSUES WITH RJAVA:
        jh <- Sys.getenv('JAVA_HOME')
        Sys.unsetenv('JAVA_HOME')

        progress <- shiny::Progress$new()
        progress$set(message = "Installing Packages...", value = 0)
        # Close the progress when this reactive exits (even if there's an error)
        on.exit(progress$close())

        updateProgress <- function(value = NULL, detail = NULL) {
            if (is.null(value)) {
                value <- progress$getValue()
                value <- value + (progress$getMax() - value) / 10
            }
            progress$set(value = value, detail = detail)
        }
        updateProgress(detail='Intalling required packages if missing')
        packageList <-installed.packages()
        if (ifelse(!'devtools'%in%packageList[,'Package'],
                   TRUE,
                   as.character(packageList[as.character(packageList[,'Package'])=="devtools",'Version'])< '0' )) { install.packages("devtools") }
        library(devtools)
        pkgs <- c("OhdsiRTools","SqlRender","DatabaseConnector","Cyclops", "OhdsiSharing", "FeatureExtraction")
        version <- data.frame(pkg=pkgs,
                              min=c('0','1.1.3','1.3.0','1.2.0', '0', '0'))
        for (pkg in pkgs) {
            if (ifelse(!pkg%in%packageList[,'Package'],
                       TRUE,
                       as.character(packageList[as.character(packageList[,'Package'])==pkg,'Version'])< as.character(version[version[,'pkg']==pkg,'min'])) )
                       {devtools::install_github(paste0('ohdsi/',pkg)) }
        }

        if (ifelse(!'PatientLevelPrediction'%in%packageList[,'Package'],
                               TRUE,
                               as.character(packageList[as.character(packageList[,'Package'])=="PatientLevelPrediction",'Version'])<'1.1.1' ))
            {
        updateProgress(detail='Intalling PatientLevelPrediction develop branch...')
        devtools::install_github("ohdsi/PatientLevelPrediction", ref='develop')
        }

        if (ifelse(!'CelecoxibPredictiveModels'%in%packageList[,'Package'],
                   TRUE,
                   as.character(packageList[as.character(packageList[,'Package'])=="CelecoxibPredictiveModels",'Version'])<'0.2' ))
        {
            updateProgress(detail='Intalling CelecoxibPredictiveModels new_plp branch...')
        devtools::install_github("ohdsi/StudyProtocols/CelecoxibPredictiveModels", ref='new_plp')
        }

        # reset jave home:
        Sys.setenv(JAVA_HOME= jh)

    })
#===========================================================================
    # add stugy settings
    settingList <- shiny::reactiveValues(password =NULL, dbms=NULL, domain=NULL,
                                  port=NULL, user=NULL, server=NULL,
                                  cdmDatabaseSchema=NULL,
                                  workDatabaseSchema = NULL,
                                  studyCohortTable = "ohdsi_celecoxib_prediction",
                                  oracleTempSchema = NULL,
                                  cdmVersion = 5,
                                  outputFolder = NULL,
                                  gap=NULL
    )

    # the reactive value containing the sumamry data:
    summary <- shiny::reactiveValues( data=NULL, choice=NULL
    )


    shiny::observeEvent(input$runStudy, {
        settingList$dbms=input$dbms
        settingList$domain = input$domain
        settingList$password= input$password
        settingList$server = input$server
        settingList$port = input$port
        settingList$cdmDatabaseSchema = input$cdmDatabaseSchema
        settingList$workDatabaseSchema = input$workDatabaseSchema
        settingList$oracleTempSchema = input$oracleTempSchema
        settingList$cdmVersion = input$cdmVersion
        settingList$outputFolder = input$outputFolder
        settingList$gap = input$gap
        priorResult$dataFolder <- input$outputFolder


        connectionSettings <- DatabaseConnector::createConnectionDetails(dbms = input$dbms,
                                                   user= NULL,#input$user,
                                                   password = NULL,#input$password,
                                                   server= input$server,
                                                   port=input$port,
                                                   domain=input$domain)


        # initialise progressbar:
        progress <- shiny::Progress$new()
        progress$set(message = "Running prediction analysis...", value = 0)
        # Close the progress when this reactive exits (even if there's an error)
        on.exit(progress$close())

        updateProgress <- function(value = NULL, detail = NULL) {
            if (is.null(value)) {
                value <- progress$getValue()
                value <- value + (progress$getMax() - value) / 10
            }
            progress$set(value = value, detail = detail)
        }

        if(!dir.exists(file.path(input$outputFolder,'fftemp')))
            dir.create(file.path(input$outputFolder,'fftemp'))
        options(fftempdir = file.path(input$outputFolder,'fftemp'))

        CelecoxibPredictiveModels::execute(connectionDetails = connectionSettings,
                cdmDatabaseSchema = input$cdmDatabaseSchema,
                workDatabaseSchema = input$workDatabaseSchema,
                studyCohortTable = "ohdsi_celecoxib_prediction",
                oracleTempSchema = input$oracleTempSchema,
                gap=input$gap,
                cdmVersion = input$cdmVersion,
                outputFolder = input$outputFolder,
                updateProgress = updateProgress)

        if (is.function(updateProgress)) {
            updateProgress(detail = "\n Prediction complete...")
        }
        # LOAD summary results into table to view in summary
        # add gap to outputFolder when including it
        summary$data <- PatientLevelPrediction::createAnalysisSummary(input$outputFolder, save=F)

        summary$choice <- as.list(1:nrow(summary$data))
        names(summary$choice) <- paste(rep('Cohort: ', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('COHORT_ID','COHORT_DEFINITION_ID')],
                                       rep('(', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('COHORT_NAME')], rep(')', nrow(summary$data)),

                                       rep(' Outcome: ', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('OUTCOME_ID','outcomeID')],
                                       rep('(', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('OUTCOME_NAME')], rep(')', nrow(summary$data)),

                                       sep='')

    })




    # The topic clustering
    output$runAnalysis <-
        shiny::renderUI(
            shiny::wellPanel(
                shiny::h4("Run analysis"),
                shiny::helpText("Add the study setting and then the ",
                         "the results will be returned to the 'Results View' tab",
                         'where the user can explore the various performance metrics',
                         #dbconnection,
                         shiny::textInput("password", "Password:",NULL),
                         shiny::textInput("user", "Username:",NULL),
                         shiny::selectInput("dbms", label = "dbms:",
                                     choices = list("Microsoft SQL Server" = 'sql server',
                                                    "MySQL" = 'mysql',
                                                    "Oracle" = "oracle",
                                                    "PostgreSQL" = "postgresql",
                                                    "Amazon Redshift" = "redshift", 
                                                    "Microsoft Parallel Data Warehouse (PDW)" = 'pdw',
                                                    "IBM Netezza" = 'netezza' ),
                                     selected = 'pdw'),
                         shiny::textInput("server", "Server:",'JRDUSAPSCTL01'),
                         shiny::textInput("port", "Port:",17001),
                         shiny::textInput("domain", "Domain:",NULL),


                         shiny::textInput('cdmDatabaseSchema', 'cdmDatabaseSchema:', 'CDM_JMDC_V5.dbo'),
                         shiny::textInput('workDatabaseSchema', 'workDatabaseSchema:', 'Scratch.dbo'),
                         shiny::textInput('oracleTempSchema', 'oracleTempSchema:', NULL),

                         shiny::selectInput("cdmVersion", label = "cdmVersion",
                                     choices = list("version 5" = '5',
                                                    "version 4" = '4' ),
                                     selected = '5'),

                         shiny::sliderInput("gap", "Gap between cohort start and prediction interval start:",
                                     min = 1, max = 365, value = 1, step = 1),

                         shiny::textInput('outputFolder', 'Directory to save results:', 'C:/CelecoxibPredictions'),

                         shiny::actionButton("runStudy", "Run the analysis")

                ))

        )

    output$selectData <-
        shiny::renderUI(
            shiny::wellPanel(
                shiny::h4("Load exisitng results"),
                shiny::helpText("Select the folder containing existing results ",
                                #dbconnection,
                                shiny::textInput("dataFolder", "Folder path:",NULL),
                                shiny::actionButton("loadData", "Load existing results")
                ))

        )

    priorResult <- shiny::reactiveValues( dataFolder=NULL
    )

    shiny::observeEvent(input$loadData, {
        priorResult$dataFolder <- input$dataFolder

        summary$data <- PatientLevelPrediction::createAnalysisSummary(input$dataFolder, save=F)
        summary$choice <- as.list(1:nrow(summary$data))
        names(summary$choice) <- paste(rep('Cohort: ', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('COHORT_ID','COHORT_DEFINITION_ID')],
                                       rep('(', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('COHORT_NAME')], rep(')', nrow(summary$data)),

                                       rep(' Outcome: ', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('OUTCOME_ID','outcomeID')],
                                       rep('(', nrow(summary$data)),summary$data[,colnames(summary$data)%in%c('OUTCOME_NAME')], rep(')', nrow(summary$data)),

                               sep='')
    })


    # summary output:
    output$summary <- DT::renderDataTable({
        if (is.null(summary$data)) return()

        colnames(summary$data) <- gsub('_DEFINITION','',colnames(summary$data))
        data.frame(summary$data[,colnames(summary$data)%in%c('COHORT_ID', 'COHORT_NAME','OUTCOME_ID','outcomeId','OUTCOME_NAME','trainDatabase','testDatabase','auc')])
    },     escape = FALSE, selection = 'none',
    options = list(
        pageLength = 25
        #,initComplete = I("function(settings, json) {alert('Done.');}")
    ))

    #==================================
    # add the summary$data cohortId and outcomeId columns into a slection form
    # on the

    output$visSel <- shiny::renderUI(
        shiny::wellPanel(
            shiny::selectInput("explorerIds", label = "Select model:",
                               choices = summary$choice,
                               selected = 1),
            shiny::actionButton("explore", "Select")
                        )
        )


    #=========================================================
    # PLOTS
    output$performance <- DT::renderDataTable({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
                id <- input$explorerIds
                }
        data.frame(summary$data[id,colnames(summary$data)%in%c('auc', 'auc_lb95ci',
                                                                          'auc_lb95ci.1', 'Brier',
                                                                          'BrierScaled','Xsquared',
                                                                          'df',	'pvalue',
                                                                          'calibrationIntercept',
                                                                          'calibrationGradient')])
    },     escape = FALSE, selection = 'none',
    options = list(
        pageLength = 25
        #,initComplete = I("function(settings, json) {alert('Done.');}")
    ))

    output$varImp <- DT::renderDataTable({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        model <- PatientLevelPrediction::loadPlpModel(file.path(priorResult$dataFolder, id, 'savedModel' ))
    data.frame(model$varImp)
    },     escape = FALSE, selection = 'none',
    options = list(
        pageLength = 25
        #,initComplete = I("function(settings, json) {alert('Done.');}")
    ))

    output$attrition <- DT::renderDataTable({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        model <- PatientLevelPrediction::loadPlpModel(file.path(priorResult$dataFolder, id, 'savedModel' ))
        data.frame(model$metaData$attrition)
    },     escape = FALSE, selection = 'none',
    options = list(
        pageLength = 25
        #,initComplete = I("function(settings, json) {alert('Done.');}")
    ))

    output$rocPlot <- shiny::renderPlot({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        rocData <- read.table(file.path(priorResult$dataFolder, id, 'rocRawSparse.txt' ), header=T)
        sensitivity <- rocData$TP/(rocData$TP+rocData$FN)
        one_minus_specificity <- 1-rocData$TN/(rocData$TN+rocData$FP)
        data <- data.frame(sensitivity=sensitivity,
                           one_minus_specificity=one_minus_specificity)
        #plot(1-specificity, sensitivity)
        steps <- data.frame(sensitivity = sensitivity[1:(length(sensitivity) - 1)],
                            one_minus_specificity = one_minus_specificity[2:length(one_minus_specificity)] - 1e-09)
        data <- rbind(data, steps)
        data <- data[order(data$sensitivity, data$one_minus_specificity), ]
        ggplot2::ggplot(data, ggplot2::aes(x = one_minus_specificity, y = sensitivity)) +
        ggplot2::geom_abline(intercept = 0, slope = 1) +
        ggplot2::geom_area(color = rgb(0, 0, 0.8, alpha = 0.8),
                           fill = rgb(0, 0, 0.8, alpha = 0.4)) +
        ggplot2::scale_x_continuous("1 - specificity") +
        ggplot2::scale_y_continuous("Sensitivity")
    })

    output$boxPlot <- shiny::renderPlot({
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        boxData <- read.table(file.path(priorResult$dataFolder, id, 'quantiles.txt' ), header=T)

        #"Group.1" "x.0%" "x.25%" "x.50%" "x.75%" "x.100%"
        colnames(boxData) <- c('Outcome', 'y0', 'y25', 'y50', 'y75', 'y100')
        ggplot2::ggplot(boxData, ggplot2::aes(as.factor(Outcome))) +
            ggplot2::geom_boxplot(
                ggplot2::aes(ymin = y0, lower = y25, middle = y50, upper = y75, ymax = y100),
                stat = "identity"
            ) +
            ggplot2::coord_flip()

    })

    output$calPlot <- shiny::renderPlot({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        calData <- read.table(file.path(priorResult$dataFolder, id, 'calSparse.txt' ), header=T)

        ggplot2::ggplot(calData,
                                ggplot2::aes(xmin = minx, xmax = maxx, ymin = 0, ymax = fraction)) +
            ggplot2::geom_abline() +
            ggplot2::geom_rect(color = rgb(0, 0, 0.8, alpha = 0.8),
                               fill = rgb(0, 0, 0.8, alpha = 0.5)) +
            ggplot2::scale_x_continuous("Predicted probability") +
            ggplot2::coord_cartesian(xlim = c(0, min(1,max(calData[,'minx'])*1.5)  )) +
            ggplot2::scale_y_continuous("Observed fraction")

    })

    output$prefPlot <- shiny::renderPlot({
        if (is.null(summary$data)) return()
        if(is.null(input$explorerIds)){
            id <- 1
        } else{
            id <- input$explorerIds
        }
        id <- gsub(' ','',gsub('-','',gsub(':','', summary$data[id, colnames(summary$data)=='datetime'])))
        prefData <- read.table(file.path(priorResult$dataFolder, id, 'preferenceScoresSparse.txt' ), header=T)
        ggplot2::ggplot(prefData, ggplot2::aes(x=groupVal, y=density,
                                                  group=as.factor(outcomeCount), col=as.factor(outcomeCount),
                                                  fill=as.factor(outcomeCount))) +
            ggplot2::geom_line() + ggplot2::xlab("Preference") + ggplot2::ylab("Density") +
            ggplot2::scale_x_continuous(limits = c(0, 1)) +
            ggplot2::geom_vline(xintercept = 0.3) + ggplot2::geom_vline(xintercept = 0.7)

    })

})
