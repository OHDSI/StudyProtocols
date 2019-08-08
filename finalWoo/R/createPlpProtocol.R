#' Create a protocol template for the study 
#'
#' @details
#' This function will create a template protocol 
#'
#' @param outputLocation    Directory location where you want the protocol written to
#' @export
createPlpProtocol <- function(outputLocation = getwd()){
  
  predictionAnalysisListFile <- system.file("settings",
                                            "predictionAnalysisList.json",
                                            package = "finalWoo")
  
  #figure1 <- 'vignettes/Figure1.png'
  figure1 <- system.file("doc",
              "Figure1.png",
              package = "PatientLevelPrediction")
  
  #============== STYLES =======================================================
  style_title <- officer::shortcuts$fp_bold(font.size = 28)
  style_title_italic <- officer::shortcuts$fp_bold(font.size = 30, italic = TRUE)
  style_toc <- officer::shortcuts$fp_bold(font.size = 16)
  style_helper_text <- officer::shortcuts$fp_italic(color = "#FF8C00")
  style_citation <- officer::shortcuts$fp_italic(shading.color = "grey")
  style_table_title <- officer::shortcuts$fp_bold(font.size = 14, italic = TRUE)
  
  style_hidden_text <- officer::shortcuts$fp_italic(color = "#FFFFFF")
  
  #============== VARIABLES ====================================================
  json <- tryCatch({ParallelLogger::loadSettingsFromJson(file=predictionAnalysisListFile)},
                   error=function(cond) {
                     stop('Issue with json file...')
                   })
  
  #analysis information
  analysisList <- PatientLevelPrediction::loadPredictionAnalysisList(predictionAnalysisListFile)
  
  targetCohortNamesList <- paste(analysisList$cohortNames, collapse = ', ')
  targetCohorts <- as.data.frame(cbind(analysisList$cohortIds,analysisList$cohortNames,rep("TBD",length(analysisList$cohortNames))), stringsAsFactors = FALSE)
  names(targetCohorts) <- c("Cohort ID", "Cohort Name","Description")
  targetCohorts <- targetCohorts[order(as.numeric(targetCohorts$`Cohort ID`)),]
  
  outcomeCohortNamesList <- paste(analysisList$outcomeNames, collapse = ', ')
  outcomeCohorts <- as.data.frame(cbind(analysisList$outcomeIds,analysisList$outcomeNames,rep("TBD",length(analysisList$outcomeNames))), stringsAsFactors = FALSE)
  names(outcomeCohorts) <- c("Cohort ID", "Cohort Name","Description")
  outcomeCohorts <- outcomeCohorts[order(as.numeric(outcomeCohorts$`Cohort ID`)),]
  
  #time at risk
  tar <- unique(
    lapply(json$populationSettings, function(x) 
      paste0("Risk Window Start:  ",x$riskWindowStart,
             ', Add Exposure Days to Start:  ',x$addExposureDaysToStart,
             ', Risk Window End:  ', x$riskWindowEnd,
             ', Add Exposure Days to End:  ', x$addExposureDaysToEnd)))
  tarDF <- as.data.frame(rep(times = length(tar),''), stringsAsFactors = FALSE)
  names(tarDF) <- c("Time at Risk")
  for(i in 1:length(tar)){
    tarDF[i,1] <- paste0("[Time at Risk Settings #", i, '] ', tar[[i]])
  }
  tarList <- paste(tarDF$`Time at Risk`, collapse = ', ')
  tarListDF <- as.data.frame(tarList)
  
  covSettings <- lapply(json$covariateSettings, function(x) cbind(names(x), unlist(lapply(x, function(x2) paste(x2, collapse=', '))))) 
  
  popSettings <- lapply(json$populationSettings, function(x) cbind(names(x), unlist(lapply(x, function(x2) paste(x2, collapse=', '))))) 
  
  
  plpModelSettings <- PatientLevelPrediction::createPlpModelSettings(modelList = analysisList$modelAnalysisList$models,
                                                                     covariateSettingList = json$covariateSettings,
                                                                     populationSettingList = json$populationSettings)
  m1 <-merge(targetCohorts$`Cohort Name`,outcomeCohorts$`Cohort Name`)
  names(m1) <- c("Target Cohort Name","Outcome Cohort Name")
  modelSettings <- unique(data.frame(plpModelSettings$settingLookupTable$modelSettingId,plpModelSettings$settingLookupTable$modelSettingName))
  names(modelSettings) <- c("Model Settings Id", "Model Settings Description")
  m2 <- merge(m1,modelSettings)
  covSet <- unique(data.frame(plpModelSettings$settingLookupTable$covariateSettingId))
  names(covSet) <- "Covariate Settings ID"
  m3 <- merge(m2,covSet)
  popSet <-unique(data.frame( plpModelSettings$settingLookupTable$populationSettingId))
  names(popSet) <- c("Population Settings ID")
  completeAnalysisList <- merge(m3,popSet)
  completeAnalysisList$ID <- seq.int(nrow(completeAnalysisList))
  
  concepts <- formatConcepts(json)
  #-----------------------------------------------------------------------------
  
  #============== CITATIONS =====================================================
  plpCitation <- paste0("Citation:  ", utils::citation("PatientLevelPrediction")$textVersion)
  tripodCitation <- paste0("Citation:  Collins, G., et al. (2017.02.01). 'Transparent reporting of a multivariable prediction model for individual prognosis or diagnosis (TRIPOD): The TRIPOD statement.' from https://www.equator-network.org/reporting-guidelines/tripod-statement/ ")
  progressCitation <- paste0("Citation:  Steyerberg EW, Moons KG, van der Windt DA, Hayden JA, Perel P, Schroter S, Riley RD, Hemingway H, Altman DG; PROGRESS Group. Prognosis Research Strategy (PROGRESS) 3: prognostic model research. PLoS Med. 2013;10(2):e1001381. doi: 10.1371/journal.pmed.1001381. Epub 2013 Feb 5. Review. PubMed PMID: 23393430; PubMed Central PMCID: PMC3564751.")
  rCitation <- paste0("Citation:  R Core Team (2013). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL http://www.R-project.org/.")
  #-----------------------------------------------------------------------------
  
  #============== CREATE DOCUMENT ==============================================
  # create new word document
  doc = officer::read_docx()
  #-----------------------------------------------------------------------------
  
  #============ TITLE PAGE =====================================================
  title <- officer::fpar(
    officer::ftext("Patient-Level Prediction:  ", prop = style_title), 
    officer::ftext(json$packageName, prop = style_title_italic)
  )
  
  doc <- doc %>%
    officer::body_add_par("") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(title) %>%
    officer::body_add_par("") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("Prepared on:  ", Sys.Date()), style = "Normal") %>%
    officer::body_add_par(paste0("Created by:  ", json$createdBy$name, " (", json$createdBy$email,")"), style = "Normal") %>%
    officer::body_add_break() 
  #-----------------------------------------------------------------------------  
  
  #============ TOC ============================================================
  toc <- officer::fpar(
    officer::ftext("Table of Contents", prop = style_toc)
  )
  
  doc <- doc %>%
    officer::body_add_fpar(toc) %>%
    officer::body_add_toc(level = 2) %>%
    officer::body_add_break() 
  #----------------------------------------------------------------------------- 
  
  #============ LIST OF ABBREVIATIONS ==========================================
  abb <- data.frame(rbind(
    c("AUC", "Area Under the Receiver Operating Characteristic Curve"),
    c("CDM","Common Data Model"),
    c("O","Outcome Cohort"),
    c("OHDSI","Observational Health Data Sciences & Informatics"),
    c("OMOP","Observational Medical Outcomes Partnership"),
    c("T", "Target Cohort"),
    c("TAR", "Time at Risk")
  ))
  names(abb) <- c("Abbreviation","Phrase")
  abb <- abb[order(abb$Abbreviation),]
  
  doc <- doc %>%
    officer::body_add_par("List of Abbreviations", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(abb, header = TRUE) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< Rest to be completed outside of ATLAS >>", prop = style_helper_text)
      ))
  #----------------------------------------------------------------------------- 
  
  
  #============ RESPONSIBLE PARTIES ============================================
  doc <- doc %>%
    officer::body_add_par("Responsible Parties", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS ", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Includes author, investigator, and reviewer names and sponsor information. >>", prop = style_helper_text)
      ))
  #----------------------------------------------------------------------------- 
  
  #============ Executive Summary ==============================================
  doc <- doc %>%
    officer::body_add_par("Executive Summary", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< A few statements about the rational and background for this study. >>", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("The objective of this study is to develop and validate patient-level prediction models for patients in ",
                                 length(json$targetIds)," target cohort(s) (",
                                 targetCohortNamesList,") to predict ",
                                 length(json$outcomeIds)," outcome(s) (",
                                 outcomeCohortNamesList,") for ",
                                 length(tar)," time at risk(s) (",
                                 tarList,")."), 
                          style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("The prediction will be implemented using ",
                                 length(json$modelSettings)," algorithms (",
                                 paste(lapply(analysisList$modelAnalysisList$models, function(x) x$name), collapse = ', '),")."),
                          style = "Normal")
  #----------------------------------------------------------------------------- 
  
  #============ RATIONAL & BACKGROUND ==========================================
  doc <- doc %>%
    officer::body_add_par("Rational & Background", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Provide a short description of the reason that led to the initiation of or need for the study and add a short critical review of available published and unpublished data to explain gaps in knowledge that the study is intended to fill. >>", prop = style_helper_text)
      )) 
  #-----------------------------------------------------------------------------
  
  #============ OBJECTIVE ======================================================
  prep_objective <- merge(analysisList$cohortNames, analysisList$outcomeNames)
  objective <- merge(prep_objective, tarListDF )
  names(objective) <-c("Target Cohorts","Outcome Cohorts","Time at Risk") 
  
  doc <- doc %>%
    officer::body_add_par("Objective", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("The objective is to develop and validate patient-level prediction models for the following prediction problems:"),style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(objective, header = TRUE, style = "Table Professional")
  
  #----------------------------------------------------------------------------- 
  
  #============ METHODS ======================================================
  doc <- doc %>%
    officer::body_add_par("Methods", style = "heading 1") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Study Design", style = "heading 2") %>%
    officer::body_add_par("This study will follow a retrospective, observational, patient-level prediction design. We define 'retrospective' to mean the study will be conducted using data already collected prior to the start of the study. We define 'observational' to mean there is no intervention or treatment assignment imposed by the study. We define 'patient-level prediction' as a modeling process wherein an outcome is predicted within a time at risk relative to the target cohort start and/or end date.  Prediction is performed using a set of covariates derived using data prior to the start of the target cohort.",style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Figure 1, illustrates the prediction problem we will address. Among a population at risk, we aim to predict which patients at a defined moment in time (t = 0) will experience some outcome during a time-at-risk. Prediction is done using only information about the patients in an observation window prior to that moment in time.", style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_img(src = figure1, width = 6.5, height = 2.01, style = "centered") %>%
    officer::body_add_par("Figure 1: The prediction problem", style="graphic title") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext(plpCitation, prop = style_citation)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_par("We follow the PROGRESS best practice recommendations for model development and the TRIPOD guidance for transparent reporting of the model results.", style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext(progressCitation, prop = style_citation)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext(tripodCitation, prop = style_citation)
      )) %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Data Source(s)", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("For each database, provide database full name, version information (if applicable), the start and end dates of data capture, and a brief description of the data source.  Also include information on data storage (e.g. software and IT environment, database maintenance and anti-fraud protection, archiving) and data protection.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Important Citations: OMOP Common Data Model:  'OMOP Common Data Model (CDM).' from https://github.com/OHDSI/CommonDataModel.", prop = style_helper_text)
      )) %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Study Populations", style = "heading 2") %>%
    officer::body_add_par("Target Cohort(s) [T]", style = "heading 3") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< Currently cohort definitions need to be grabbed from ATLAS, in a Cohort Definition, Export Tab, from Text View. >>", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_table(targetCohorts, header = TRUE, style = "Table Professional") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Outcome Cohorts(s) [O]", style = "heading 3") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< Currently cohort definitions need to be grabbed from ATLAS, in a Cohort Definition, Export Tab, from Text View. >>", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_table(outcomeCohorts, header = TRUE, style = "Table Professional") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Time at Risk", style = "heading 3") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(tarDF, header = TRUE, style = "Table Professional") %>%
    officer::body_add_par("Additional Population Settings", style = "heading 3") %>%
    officer::body_add_par("")
  
  for(i in 1:length(popSettings)){
    onePopSettings <- as.data.frame(popSettings[i])
    names(onePopSettings) <- c("Item","Settings")
    
    doc <- doc %>% 
      officer::body_add_fpar(
        officer::fpar(
          officer::ftext(paste0("Population Settings #",i), prop = style_table_title)
        )) %>%
      officer::body_add_table(onePopSettings, header = TRUE, style = "Table Professional") %>% 
      officer::body_add_par("")
  }
  
  #```````````````````````````````````````````````````````````````````````````
  algorithms <- data.frame(rbind(
    c("Lasso Logistic Regression", "Lasso logistic regression belongs to the family of generalized linear models, where a linear combination of the variables is learned and finally a logistic function maps the linear combination to a value between 0 and 1.  The lasso regularization adds a cost based on model complexity to the objective function when training the model.  This cost is the sum of the absolute values of the linear combination of the coefficients.  The model automatically performs feature selection by minimizing this cost. We use the Cyclic coordinate descent for logistic, Poisson and survival analysis (Cyclops) package to perform large-scale regularized logistic regression: https://github.com/OHDSI/Cyclops"),
    c("Gradient boosting machine", "Gradient boosting machines is a boosting ensemble technique and in our framework it combines multiple decision trees.  Boosting works by iteratively adding decision trees but adds more weight to the data-points that are misclassified by prior decision trees in the cost function when training the next tree.  We use Extreme Gradient Boosting, which is an efficient implementation of the gradient boosting framework implemented in the xgboost R package available from CRAN."),
    c("Random forest", "Random forest is a bagging ensemble technique that combines multiple decision trees.  The idea behind bagging is to reduce the likelihood of overfitting, by using weak classifiers, but combining multiple diverse weak classifiers into a strong classifier.  Random forest accomplishes this by training multiple decision trees but only using a subset of the variables in each tree and the subset of variables differ between trees. Our packages uses the sklearn learn implementation of Random Forest in python."),
    c("KNN", "K-nearest neighbors (KNN) is an algorithm that uses some metric to find the K closest labelled data-points, given the specified metric, to a new unlabelled data-point.  The prediction of the new data-points is then the most prevalent class of the K-nearest labelled data-points.  There is a sharing limitation of KNN, as the model requires labelled data to perform the prediction on new data, and it is often not possible to share this data across data sites.  We included the BigKnn classifier developed in OHDSI which is a large scale k-nearest neighbor classifier using the Lucene search engine: https://github.com/OHDSI/BigKnn"),
    c("AdaBoost", "AdaBoost is a boosting ensemble technique. Boosting works by iteratively adding decision trees but adds more weight to the data-points that are misclassified by prior decision trees in the cost function when training the next tree.  We use the sklearn 'AdaboostClassifier' implementation in Python."),
    c("DecisionTree", "A decision tree is a classifier that partitions the variable space using individual tests selected using a greedy approach.  It aims to find partitions that have the highest information gain to separate the classes.  The decision tree can easily overfit by enabling a large number of partitions (tree depth) and often needs some regularization (e.g., pruning or specifying hyper-parameters that limit the complexity of the model). We use the sklearn 'DecisionTreeClassifier' implementation in Python."),
    c("Neural network", "Neural networks contain multiple layers that weight their inputs using an non-linear function.  The first layer is the input layer, the last layer is the output layer the between are the hidden layers.  Neural networks are generally trained using feed forward back-propagation.  This is when you go through the network with a data-point and calculate the error between the true label and predicted label, then go backwards through the network and update the linear function weights based on the error.  This can also be performed as a batch, where multiple data-points are feed through the network before being updated.  We use the sklearn 'MLPClassifier' implementation in Python."),
    c("Naive Bayes","The Naive Bayes algorithm applies the Bayes' theorem with the 'naive' assumption of conditional  independence between every pair of features given the value of the class variable. Based on the likelihood of the data belong to a class and the prior distribution of the class, a posterior distribution is obtained.")
  ))
  names(algorithms) <- c("Algorithm","Description")
  algorithms <- algorithms[order(algorithms$Algorithm),]
  
  modelIDs <- as.data.frame(sapply(analysisList$modelAnalysisList$models, function(x) x$name))
  names(modelIDs) <- c("ID")
  algorithmsFiltered <- algorithms[algorithms$Algorithm %in% modelIDs$ID,]
  
  modelEvaluation <- data.frame(rbind(
    c("ROC Plot", "The ROC plot plots the sensitivity against 1-specificity on the test set. The plot shows how well the model is able to discriminate between the people with the outcome and those without. The dashed diagonal line is the performance of a model that randomly assigns predictions. The higher the area under the ROC plot the better the discrimination of the model."),
    c("Calibration Plot", "The calibration plot shows how close the predicted risk is to the observed risk. The diagonal dashed line thus indicates a perfectly calibrated model. The ten (or fewer) dots represent the mean predicted values for each quantile plotted against the observed fraction of people in that quantile who had the outcome (observed fraction). The straight black line is the linear regression using these 10 plotted quantile mean predicted vs observed fraction points. The two blue straight lines represented the 95% lower and upper confidence intervals of the slope of the fitted line."),
    c("Smooth Calibration Plot", "Similar to the traditional calibration shown above the Smooth Calibration plot shows the relationship between predicted and observed risk. the major difference is that the smooth fit allows for a more fine grained examination of this. Whereas the traditional plot will be heavily influenced by the areas with the highest density of data the smooth plot will provide the same information for this region as well as a more accurate interpretation of areas with lower density. the plot also contains information on the distribution of the outcomes relative to predicted risk.  However the increased information game comes at a computational cost. It is recommended to use the traditional plot for examination and then to produce the smooth plot for final versions."),
    c("Prediction Distribution Plots", "The preference distribution plots are the preference score distributions corresponding to i) people in the test set with the outcome (red) and ii) people in the test set without the outcome (blue)."),
    c("Box Plots", "The prediction distribution boxplots are box plots for the predicted risks of the people in the test set with the outcome (class 1: blue) and without the outcome (class 0: red)."),
    c("Test-Train Similarity Plot", "The test-train similarity is presented by plotting the mean covariate values in the train set against those in the test set for people with and without the outcome."),
    c("Variable Scatter Plot", "The variable scatter plot shows the mean covariate value for the people with the outcome against the mean covariate value for the people without the outcome. The size and color of the dots correspond to the importance of the covariates in the trained model (size of beta) and its direction (sign of beta with green meaning positive and red meaning negative), respectively."),
    c("Precision Recall Plot", "The precision-recall curve is valuable for dataset with a high imbalance between the size of the positive and negative class. It shows the tradeoff between precision and recall for different threshold. High precision relates to a low false positive rate, and high recall relates to a low false negative rate. High scores for both show that the classifier is returning accurate results (high precision), as well as returning a majority of all positive results (high recall). A high area under the curve represents both high recall and high precision."),
    c("Demographic Summary Plot", "This plot shows for females and males the expected and observed risk in different age groups together with a confidence area.")
  ))
  names(modelEvaluation) <- c("Evaluation","Description")
  modelEvaluation <- modelEvaluation[order(modelEvaluation$Evaluation),]
  
  doc <- doc %>%
    officer::body_add_par("Statistical Analysis Method(s)", style = "heading 2") %>%
    officer::body_add_par("Algorithms", style = "heading 3") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(algorithmsFiltered, header = TRUE, style = "Table Professional") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Model Evaluation", style = "heading 3") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("The following evaluations will be performed on the model:", style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(modelEvaluation, header = TRUE, style = "Table Professional") %>%
    officer::body_add_par("") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Quality Control", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("The PatientLevelPrediction package itself, as well as other OHDSI packages on which PatientLevelPrediction depends, use unit tests for validation.",style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext(plpCitation, prop = style_citation)
      )) %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Tools", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("This study will be designed using OHDSI tools and run with R.",style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext(rCitation, prop = style_citation)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_par("More information about the tools can be found in the Appendix 'Study Generation Version Information'.", style = "Normal")
  #----------------------------------------------------------------------------- 
  
  #============ DIAGNOSTICS ====================================================
  doc <- doc %>%
    officer::body_add_par("Diagnostics", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Reviewing the incidence rates of the outcomes in the target population prior to performing the analysis will allow us to assess its feasibility.  The full table can be found in the 'Table and Figures' section under 'Incidence Rate of Target & Outcome'.",style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Additionally, reviewing the characteristics of the cohorts provides insight into the cohorts being reviewed.  The full table can be found below in the 'Table and Figures' section under 'Characterization'.",style="Normal")
  #----------------------------------------------------------------------------- 
  
  #============ DATA ANALYSIS PLAN =============================================
  
  doc <- doc %>%
    officer::body_add_par("Data Analysis Plan", style = "heading 1") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Algorithm Settings", style = "heading 2") %>%
    officer::body_add_par("") 
  
  for(i in 1:length(json$modelSettings)){
    
    modelSettingsTitle <- names(json$modelSettings[[i]])
    modelSettings <- lapply(json$modelSettings[[i]], function(x) cbind(names(x), unlist(lapply(x, function(x2) paste(x2, collapse=', '))))) 
    
    oneModelSettings <- as.data.frame(modelSettings)
    names(oneModelSettings) <- c("Covariates","Settings")
    
    doc <- doc %>% 
      officer::body_add_fpar(
        officer::fpar(
          officer::ftext(paste0("Model Settings Settings #",i, " - ",modelSettingsTitle), prop = style_table_title)
        )) %>%
      officer::body_add_table(oneModelSettings, header = TRUE, style = "Table Professional") %>% 
      officer::body_add_par("")
  }
  
  #```````````````````````````````````````````````````````````````````````````
  covStatement1 <- paste0("The covariates (constructed using records on or prior to the target cohort start date) are used within this prediction mode include the following.")
  covStatement2 <- paste0("  Each covariate needs to contain at least ", 
                          json$runPlpArgs$minCovariateFraction, 
                          " subjects to be considered for the model.")
  
  if(json$runPlpArgs$minCovariateFraction == 0){
    covStatement <- covStatement1 
  }else {
    covStatement <- paste0(covStatement1,covStatement2)
  }
  
  doc <- doc %>%
    officer::body_add_par("Covariate Settings", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(covStatement,
                          style="Normal") %>%
    officer::body_add_par("") 
  
  for(i in 1:length(covSettings)){
    oneCovSettings <- as.data.frame(covSettings[i])
    names(oneCovSettings) <- c("Covariates","Settings")
    
    doc <- doc %>% 
      officer::body_add_fpar(
        officer::fpar(
          officer::ftext(paste0("Covariate Settings #",i), prop = style_table_title)
        )) %>%
      officer::body_add_table(oneCovSettings, header = TRUE, style = "Table Professional") %>% 
      officer::body_add_par("")
  }
  #```````````````````````````````````````````````````````````````````````````
  doc <- doc %>%
    officer::body_add_par("Model Development & Evaluation", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("To build and internally validate the models, we will partition the labelled data into a train set (",
                                 (1-analysisList$testFraction)*100,
                                 "%) and a test set (",
                                 analysisList$testFraction*100,
                                 "%)."), 
                          style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("The hyper-parameters for the models will be assessed using ",
                                 analysisList$nfold,
                                 "-fold cross validation on the train set and a final model will be trained using the full train set and optimal hyper-parameters."),
                          style = "Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("The internal validity of the models will be assessed on the test set.  We will use the area under the receiver operating characteristic curve (AUC) to evaluate the discriminative performance of the models and plot the predicted risk against the observed fraction to visualize the calibration.  See 'Model Evaluation' section for more detailed information about additional model evaluation metrics.") %>%
    officer::body_add_par("") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Analysis Execution Settings", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("There are ",
                                 length(json$targetIds),
                                 " target cohorts evaluated for ",
                                 length(json$outcomeIds),
                                 " outcomes over ",
                                 length(json$modelSettings),
                                 " models over ",
                                 length(covSettings),
                                 " covariates settings and over ",
                                 length(popSettings),
                                 " population settings.  In total there are ",
                                 length(json$targetIds) * length(json$outcomeIds) * length(json$modelSettings) * length(covSettings) * length(popSettings),
                                 " analysis performed.  For a full list refer to appendix 'Complete Analysis List'."),
                          style = "Normal") %>%
    officer::body_add_par("")
  #----------------------------------------------------------------------------- 
  
  #============ STRENGTHS & LIMITATIONS ========================================
  doc <- doc %>%
    officer::body_add_par("Strengths & Limitations", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Some limitations to consider:", 
                       prop = style_helper_text), 
        officer::ftext("--It may not be possible to develop prediction models for rare outcomes. ", 
                       prop = style_helper_text),
        officer::ftext("--Not all medical events are recorded into the observational datasets and some recordings can be incorrect.  This could potentially lead to outcome misclassification.", 
                       prop = style_helper_text),
        officer::ftext("--The prediction models are only applicable to the population of patients represented by the data used to train the model and may not be generalizable to the wider population. >>", 
                       prop = style_helper_text)
      ))
  
  #----------------------------------------------------------------------------- 
  
  #============ PROTECTION OF HUMAN SUBJECTS ===================================
  doc <- doc %>%
    officer::body_add_par("Protection of Human Subjects", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Describe any additional safeguards that are appropriate for the data being used.", 
                       prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("Here is an example statement:", prop = style_helper_text),
        officer::ftext("Confidentiality of patient records will be maintained always. All study reports will contain aggregate data only and will not identify individual patients or physicians. At no time during the study will the sponsor receive patient identifying information except when it is required by regulations in case of reporting adverse events.", prop = style_helper_text),
        officer::ftext(">>", prop = style_helper_text)
      ))
  #----------------------------------------------------------------------------- 
  
  #============ DISSEMINATING & COMMUNICATING ==================================
  doc <- doc %>%
    officer::body_add_par("Plans for Disseminating & Communicating Study Results", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS.", prop = style_helper_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("List any plans for submission of progress reports, final reports, and publications.", 
                       prop = style_helper_text),
        officer::ftext(">>", 
                       prop = style_helper_text)
      )) %>%
    officer::body_add_break()
  
  #----------------------------------------------------------------------------- 
  
  #============ TABLES & FIGURES ===============================================
  doc <- doc %>%
    officer::body_add_par("Tables & Figures", style = "heading 1") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Incidence Rate of Target & Outcome", style = "heading 2") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< add incidence here. >>", prop = style_hidden_text)
      )) %>%
    officer::body_add_par("") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Characterization", style = "heading 2") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< add characterization table here. >>", prop = style_hidden_text)
      )) %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< add results here. >>", prop = style_hidden_text)
      )) %>%
    officer::body_add_break() 
  #----------------------------------------------------------------------------- 
  
  #============ APPENDICES =====================================================
  doc <- doc %>%
    officer::body_add_par("Appendices", style = "heading 1") %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Study Generation Version Information", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par(paste0("Skeleton Version:  ",json$skeletonType," - ", json$skeletonVersion),style="Normal") %>%
    officer::body_add_par(paste0("Identifier / Organization: ",json$organizationName),style="Normal") %>%
    officer::body_add_break() %>%
    officer::body_end_section_continuous() %>%
    #```````````````````````````````````````````````````````````````````````````
    officer::body_add_par("Code List", style = "heading 2") %>%
    officer::body_add_par("") 
  
  for(i in 1:length(concepts$uniqueConceptSets)){
    conceptSetId <- paste0("Concept Set #",concepts$uniqueConceptSets[[i]]$conceptId,
                           " - ",concepts$uniqueConceptSets[[i]]$conceptName)
    conceptSetTable <- as.data.frame(concepts$uniqueConceptSets[[i]]$conceptExpressionTable)
    
    id <- as.data.frame(concepts$conceptTableSummary[which(concepts$conceptTableSummary$newConceptId == i),]$cohortDefinitionId)
    names(id) <- c("ID")
    outcomeCohortsForConceptSet <- outcomeCohorts[outcomeCohorts$`Cohort ID` %in% id$ID,]
    targetCohortsForConceptSet <- targetCohorts[targetCohorts$`Cohort ID` %in% id$ID,]
    
    cohortsForConceptSet <- rbind(outcomeCohortsForConceptSet,targetCohortsForConceptSet)
    cohortsForConceptSet <- cohortsForConceptSet[,1:2]
    
    doc <- doc %>% 
      officer::body_add_fpar(
        officer::fpar(
          officer::ftext(conceptSetId, prop = style_table_title)
        )) %>%
      officer::body_add_table(conceptSetTable[,c(1,2,4,6,7,8,9,10,11,12)], header = TRUE, style = "Table Professional") %>% 
      officer::body_add_par("") %>%
      officer::body_add_par("Cohorts that use this Concept Set:", style = "Normal") %>%
      officer::body_add_par("") %>%
      officer::body_add_table(cohortsForConceptSet, header = TRUE, style = "Table Professional") %>%
      officer::body_add_par("")
    
  }
  
  #```````````````````````````````````````````````````````````````````````````
  doc <- doc %>%   
    officer::body_add_break() %>%
    officer::body_end_section_landscape() %>%
    officer::body_add_par("Complete Analysis List", style = "heading 2") %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Below is a complete list of analysis that will be performed.  Definitions for the column 'Covariate Settings ID' can be found above in the 'Covariate Settings' section.  Definitions for the 'Population Settings Id' can be found above in the 'Additional Population Settings' section.",style="Normal") %>%
    officer::body_add_par("") %>%
    officer::body_add_table(completeAnalysisList[,c(7,1,2,3,4,5,6)], header = TRUE, style = "Table Professional") %>% 
    officer::body_add_break() 
  
  
  doc <- doc %>% officer::body_add_fpar(
    officer::fpar(
      officer::ftext("<< add models here >>", prop = style_hidden_text)
    )) %>% officer::body_add_par("")
  #-----------------------------------------------------------------------------
  
  #============ REFERNCES ======================================================
  doc <- doc %>%
    officer::body_add_par("References", style = "heading 1") %>%
    officer::body_add_par("") %>%
    officer::body_add_fpar(
      officer::fpar(
        officer::ftext("<< To be completed outside of ATLAS. >>", prop = style_helper_text)
      ))
  #----------------------------------------------------------------------------- 
  
  if(!dir.exists(outputLocation)){
    dir.create(outputLocation, recursive = T)
  }
  print(doc, target = file.path(outputLocation,'protocol.docx'))
}


#' createMultiPlpReport
#'
#' @description
#' Creates a word document report of the prediction
#' @details
#' The function creates a word document containing the analysis details, data summary and prediction model results.
#' @param analysisLocation    The location of the multiple patient-level prediction study
#' @param protocolLocation    The location of the auto generated patient-level prediction protocol
#' @param includeModels       Whether to include the models into the results document
#'
#' @return
#' A work document containing the results of the study is saved into the doc directory in the analysisLocation
#' @export
createMultiPlpReport <- function(analysisLocation,
                                 protocolLocation = file.path(analysisLocation,'doc','protocol.docx'),
                                 includeModels = F){
  
  if(!dir.exists(analysisLocation)){
    stop('Directory input for analysisLocation does not exists')
  }
  
  # this fucntion creates a lsit for analysis with 
  #    internal validation table, internal validation plots
  #    external validation table, external validation plots
  modelsExtraction <- getModelInfo(analysisLocation) 
  
  # add checks for suitable files expected - protocol/summary
  if(!file.exists(protocolLocation)){
    stop('Protocol location invalid')
  }
  
  #================ Check for protocol =========================
  # if exists load it and add results section - else return error
  doc = tryCatch(officer::read_docx(path=protocolLocation),
                 error = function(e) stop(e))
  
  heading1 <- 'heading 1'
  heading2 <- 'heading 2'
  heading3 <- 'heading 3'
  tableStyle <- "Table Professional"
  
  # Find the sections to add the results to (results + appendix)
  
  doc  %>% 
    officer::cursor_reach(keyword = "<< add results here. >>") %>% officer::cursor_forward() %>%
    officer::body_add_par("Results", style = heading1)
  
  for(model in modelsExtraction){
    if(!is.null(model$internalPerformance)){
      doc  %>%  officer::body_add_par(paste('Analysis',model$analysisId), style = heading2) %>%
        officer::body_add_par('Description', style = heading3) %>%
        officer::body_add_par(paste0("The predicton model within ", model$T, 
                                     " predict ", model$O, " during ", model$tar,
                                     " developed using database ", model$D),
                              style = "Normal") %>%
        officer::body_add_par("") %>%
        officer::body_add_par("Internal Performance", style = heading3) %>%
        officer::body_add_table(model$internalPerformance, style = tableStyle) %>%
        officer::body_add_gg(model$scatterPlot) 
      if(!is.null(model$internalPlots[[7]])){
        doc %>% rvg::body_add_vg(code = do.call(gridExtra::grid.arrange, c(model$internalPlots, list(layout_matrix=rbind(c(1,2),
                                                                                                                         c(3,4),
                                                                                                                         c(5,6),
                                                                                                                         c(7,7),
                                                                                                                         c(7,7),
                                                                                                                         c(8,8),
                                                                                                                         c(9,9)
        )))))} else{
          model$internalPlots[[7]] <- NULL
          doc %>% rvg::body_add_vg(code = do.call(gridExtra::grid.arrange, c(model$internalPlots, list(layout_matrix=rbind(c(1,2),
                                                                                                                           c(3,4),
                                                                                                                           c(5,6),
                                                                                                                           c(7,7),
                                                                                                                           c(8,8)
          )))))   
        }
    }
    
    if(!is.null(model$externalPerformance)){
      doc  %>%  officer::body_add_par("") %>%
        officer::body_add_par("External Performance", style = heading3) %>%
        officer::body_add_table(model$externalPerformance, style = tableStyle) %>%
        rvg::body_add_vg(code = do.call(gridExtra::grid.arrange, model$externalRocPlots)) %>%
        rvg::body_add_vg(code = do.call(gridExtra::grid.arrange, model$externalCalPlots))
    }
    
    doc  %>%  officer::body_add_break() 
    
  }
  
  
  
  if(includeModels){
    # move the cursor at the end of the document
    doc  %>% 
      officer::cursor_reach(keyword = "<< add models here >>") %>%  officer::cursor_forward() %>%
      officer::body_add_par("Developed Models", style = heading2)
    
    for(model in modelsExtraction){
      if(!is.null(model$modelTable)){
        doc  %>% officer::body_add_par(paste('Analysis',model$analysisId), style = heading3) %>%
          officer::body_add_table(model$modelTable, style = tableStyle) %>%
          officer::body_add_break() 
      }
    }
  }
  
  # print the document to the doc directory:
  if(!dir.exists(file.path(analysisLocation,'doc'))){
    dir.create(file.path(analysisLocation,'doc'), recursive = T)
  }
  print(doc, target = file.path(analysisLocation,'doc','plpMultiReport.docx'))
  return(TRUE)
}

getModelInfo <- function(analysisLocation){
  settings <- utils::read.csv(file.path(analysisLocation, "settings.csv"))
  
  modelSettings <- lapply((1:nrow(settings))[order(settings$analysisId)], function(i) {getModelFromSettings(analysisLocation,settings[i,])})
  return(modelSettings)
}

getModelFromSettings <- function(analysisLocation,x){
  result <- list(analysisId = x$analysisId, T = x$cohortName, 
                 D = x$devDatabase, O = x$outcomeName, 
                 tar = paste0(x$riskWindowStart, ' days after ', 
                              ifelse(x$addExposureDaysToStart==1, 'cohort end','cohort start'),
                              ' to ', x$riskWindowEnd, ' days after ',
                              ifelse(x$addExposureDaysToEnd==1, 'cohort end','cohort start')),
                 model = x$modelSettingName)
  
  if(!dir.exists(file.path(as.character(x$plpResultFolder),'plpResult'))){
    return(NULL)
  }
  
  plpResult <- PatientLevelPrediction::loadPlpResult(file.path(as.character(x$plpResultFolder),'plpResult'))
  modelTable <- plpResult$model$varImp
  result$modelTable <- modelTable[modelTable$covariateValue!=0,]
  
  if(!is.null(plpResult$performanceEvaluation)){
    internalPerformance <- plpResult$performanceEvaluation$evaluationStatistics
    internalPerformance <- as.data.frame(internalPerformance)
    internalPerformance$Value <- format(as.double(as.character(internalPerformance$Value)), digits = 2, nsmall = 0, scientific = F)
    class(internalPerformance$Value) <- 'double'
    result$internalPerformance <- reshape2::dcast(internalPerformance, Metric ~ Eval, value.var = 'Value', fun.aggregate = mean)
    
    result$internalPlots <- list(
      PatientLevelPrediction::plotSparseRoc(plpResult$performanceEvaluation),
      PatientLevelPrediction::plotPrecisionRecall(plpResult$performanceEvaluation),
      PatientLevelPrediction::plotF1Measure(plpResult$performanceEvaluation),
      PatientLevelPrediction::plotPredictionDistribution(plpResult$performanceEvaluation),
      
      PatientLevelPrediction::plotSparseCalibration( plpResult$performanceEvaluation),
      PatientLevelPrediction::plotSparseCalibration2( plpResult$performanceEvaluation),
      
      PatientLevelPrediction::plotDemographicSummary( plpResult$performanceEvaluation),
      PatientLevelPrediction::plotPreferencePDF(plpResult$performanceEvaluation),
      PatientLevelPrediction::plotPredictedPDF(plpResult$performanceEvaluation)
      
    )} else{
      result$internalPlots <- NULL  
    }
  
  result$scatterPlot <- PatientLevelPrediction::plotVariableScatterplot(plpResult$covariateSummary)
  
  # get external results if they exist
  externalPerformance <- c()  
  ind <- grep(paste0('Analysis_', x$analysisId,'/'), 
              dir(file.path(analysisLocation,'Validation'), recursive = T))
  if(length(ind)>0){
    vals <- dir(file.path(analysisLocation,'Validation'), recursive = T)[ind]
    externalRocPlots <- list() 
    externalCalPlots <- list() 
    length(externalRocPlots) <- length(vals)
    length(externalCalPlots) <- length(vals)
    for(k in 1:length(vals)){
      val <- vals[k]
      nameDat <- strsplit(val, '\\/')[[1]][1]
      val <- readRDS(file.path(analysisLocation,'Validation',val))
      sum <- as.data.frame(val[[1]]$performanceEvaluation$evaluationStatistics)
      sum$database <- nameDat
      externalPerformance <- rbind(externalPerformance, sum)
      externalCalPlots[[k]] <- PatientLevelPrediction::plotSparseCalibration2(val[[1]]$performanceEvaluation, type='validation') + ggplot2::labs(title=paste(nameDat))
      externalRocPlots[[k]] <- PatientLevelPrediction::plotSparseRoc(val[[1]]$performanceEvaluation, type='validation')+ ggplot2::labs(title=paste(nameDat))
    }
    externalPerformance <- as.data.frame(externalPerformance)
    externalPerformance$Value <- format(as.double(as.character(externalPerformance$Value)), digits = 2, nsmall = 0, scientific = F)
    class(externalPerformance$Value) <- 'double'
    result$externalPerformance <- reshape2::dcast(externalPerformance, Metric ~ database, value.var = 'Value', fun.aggregate = mean)
    result$externalCalPlots <- externalCalPlots
    result$externalRocPlots <- externalRocPlots
  }
  
  
  return(result)
}