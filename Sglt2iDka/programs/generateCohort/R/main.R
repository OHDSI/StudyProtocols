execute <- function(connectionDetails, study, datasources,
                    createCodeList, createUniverse,
                    createCohortTables, #This drops all cohort data
                    buildTheCohorts,
                    buildOutcomeCohorts,
                    buildNegativeControlCohorts,
                    buildTheCohortsDose,
                    combinedDbData,
                    exportResults,
                    exportPotentialRiskFactors,
                    exportPotentialRiskFactorsScores,
                    exportMeanAge,
                    exportTwoPlusNonSGLT2i,
                    exportReviewDKAEvents,
                    exportInitislSGLT2iDosage,
                    exportDKAFatal,
                    exportRelevantLabs,
                    formatPotentialRiskFactors,
                    formatPaticipantsTxInfo,
                    formatFatalDka){

  # VARIABLES ##################################################################
  ptm <- proc.time()
  numOfDBs <- length(datasources)
  packageName <- "generateCohort"
  tableCodeList <- paste0(study,"_CODE_LIST")
  tableCohorts <- paste0(study,"_COHORTS")
  vocabulary_database_schema <- "VOCABULARY_20171201.dbo"
  tableCohortUniverse <- paste0(study,"_COHORT_UNIVERSE")
  tabelCohortUniverseDose <- paste0(tableCohortUniverse, "_DOSE")
  tableCohortAttrition <- paste0(study,"_TABLE_COHORT_ATTRITION")
  tablePotentialRiskFactors <- paste0(study,"_TABLE_POTENTIAL_RISK_FACTORS")
  tableMeanAge <- paste0(study,"_TABLE_MEAN_AGE")
  tableTwoPlusNonSGLT2i_table1 <- paste0(study,"_TABLE_TWO_PLUS_NON_SGLT2I")
  tableTwoPlusNonSGLT2i_table2 <- paste0(study,"_TABLE_TWO_PLUS_NON_SGLT2I_DETAILS")
  tableReviewDKAEvents <- paste0(study,"_TABLE_REVIEW_DKA_EVENTS")
  tableInitialSGLT2iDosage <- paste0(study,"_TABLE_INITIAL_SGLT2i_DOSAGE")
  tableDSCI <- paste0(study,"_DCSI")
  tableChads2 <- paste0(study,"_CHADS2")
  tableCharlson <- paste0(study,"_CHARLSON")
  tableDKAFatal <- paste0(study,"_DKA_FATAL")
  tableRelevantLabs <- paste0(study,"_RELEVANT_LABS")
  tablePotentialRiskFactorsFormatted <- paste0(tablePotentialRiskFactors,"_FORMATTED")
  tableParticipantsAndTreatmentInfo <- paste0(study,"_TABLE_PARTICIPANTS_AND_TX_INFO_FORMATTED")

  # RUN ########################################################################
  if(createCodeList){
    writeLines("### Create Code List ###########################################")
    codeList(connectionDetails=connectionDetails,
             packageName = packageName,
             target_database_schema = Sys.getenv("writeTo"),
             target_table = tableCodeList,
             vocabulary_schema = Sys.getenv("vocabulary"))
  }

  if(createUniverse){
    writeLines("### Create Cohort Universe #####################################")
    createUniverse(connectionDetails=connectionDetails,
                   packageName = packageName,
                   target_database_schema = Sys.getenv("writeTo"),
                   target_table = tableCohortUniverse,
                   target_table_dose = tabelCohortUniverseDose,
                   codeList = tableCodeList)

    conn <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    sql <- paste0("SELECT * FROM ",Sys.getenv("writeTo"),".",tableCohortUniverse," WHERE TARGET_COHORT = 1 OR COMPARATOR_COHORT = 1 ORDER BY 1;")
    cohortUniverse <- DatabaseConnector::querySql(conn=conn,sql)
  }

  if(combinedDbData){
    writeLines("### Prep to Combo Data #########################################")
    createCohortTable(connectionDetails=connectionDetails,
                      packageName = packageName,
                      target_database_schema = Sys.getenv("writeTo"),
                      target_table = tableCohorts)
  }

  for(i in 1:numOfDBs){
    writeLines("")
    writeLines("")
    writeLines("##################################################################")
    print(paste0(datasources[[i]]$db.name))
    writeLines("##################################################################")

    #VARIABLES ###
    dbCohortTable <- paste0(tableCohorts,"_",datasources[[i]]$db.name)
    dbCohortTableDose <- paste0(dbCohortTable,"_DOSE")

    if(createCohortTables){
      writeLines("### Create DB Centric Table to write in")
      createDBCohortTables(connectionDetails=connectionDetails,
                           packageName = packageName,
                           target_database_schema = Sys.getenv("writeTo"),
                           target_table = dbCohortTable)
    }

    if(buildTheCohorts){
      for(z in 1:nrow(cohortUniverse)){
        writeLines("")
        writeLines("############################################################")
        print(paste0(cohortUniverse[z,]$FULL_NAME))
        writeLines("############################################################")
        writeLines("### Create study Target/Comparator cohorts")
        buildCohorts(connectionDetails=connectionDetails,
                     packageName = packageName,
                     target_database_schema = Sys.getenv("writeTo"),
                     target_table = dbCohortTable,
                     codeList = tableCodeList,
                     cdm_database_schema = datasources[[i]]$schema,
                     target_cohort_id = cohortUniverse[z,]$COHORT_DEFINITION_ID,
                     drugOfInterest = cohortUniverse[z,]$COHORT_OF_INTEREST,
                     t2dm = cohortUniverse[z,]$T2DM,
                     censor = cohortUniverse[z,]$CENSOR)
      }

    }

    if(buildTheCohortsDose){
        writeLines("### Create study Target/Comparator cohorts by Dose")
        buildCohortsDose(
                     connectionDetails=connectionDetails,
                     packageName = packageName,
                     target_database_schema = Sys.getenv("writeTo"),
                     target_table = dbCohortTableDose,
                     codeList = tableCodeList,
                     cdm_database_schema = datasources[[i]]$schema,
                     cohort_universe = tableCohortUniverse,
                     db_cohorts = dbCohortTable)
      }



    if(buildOutcomeCohorts){
      writeLines("### Create Outcomes")
      #DKA (IP & ER)
      buildOutcomeCohorts(connectionDetails=connectionDetails,
                          packageName = packageName,
                          target_database_schema = Sys.getenv("writeTo"),
                          target_table = dbCohortTable,
                          target_cohort_id = 200,
                          codeList = tableCodeList,
                          cdm_database_schema = datasources[[i]]$schema,
                          gap_days = 30)
      #DKA (IP)
      buildOutcomeCohorts(connectionDetails=connectionDetails,
                          packageName = packageName,
                          target_database_schema = Sys.getenv("writeTo"),
                          target_table = dbCohortTable,
                          target_cohort_id = 201,
                          codeList = tableCodeList,
                          cdm_database_schema = datasources[[i]]$schema,
                          gap_days = 30)

      #DKA (IP & ER) w/out gaps
      buildOutcomeCohorts(connectionDetails=connectionDetails,
                          packageName = packageName,
                          target_database_schema = Sys.getenv("writeTo"),
                          target_table = dbCohortTable,
                          target_cohort_id = 900,
                          codeList = tableCodeList,
                          cdm_database_schema = datasources[[i]]$schema,
                          gap_days = 0)

      #DKA (IP) w/out gaps
      buildOutcomeCohorts(connectionDetails=connectionDetails,
                          packageName = packageName,
                          target_database_schema = Sys.getenv("writeTo"),
                          target_table = dbCohortTable,
                          target_cohort_id = 901,
                          codeList = tableCodeList,
                          cdm_database_schema = datasources[[i]]$schema,
                          gap_days = 0)
    }

    if(buildNegativeControlCohorts){
      writeLines("### Create Negative Control cohorts")
      buildNegativeControlCohorts(connectionDetails=connectionDetails,
                                  packageName = packageName,
                                  target_database_schema = Sys.getenv("writeTo"),
                                  target_table = dbCohortTable,
                                  codeList = tableCodeList,
                                  cdm_database_schema = datasources[[i]]$schema)
    }



    if(combinedDbData){
      writeLines("### Combined DB")  #assumes DB tables exist
      combinedDBData(connectionDetails=connectionDetails,
                     packageName = packageName,
                     target_database_schema = Sys.getenv("writeTo"),
                     target_table = tableCohorts,
                     sourceTable = dbCohortTable,
                     dbID = datasources[[i]]$dbID,
                     i =i,
                     lastDb = numOfDBs)
    }
  }

  if(exportResults){
    writeLines("### Export Results #############################################")
    export(connectionDetails=connectionDetails,
           packageName = packageName,
           codeList = tableCodeList,
           target_database_schema = Sys.getenv("writeTo"),
           cohortUniverse = tableCohortUniverse,
           cohortAttrition = tableCohortAttrition,
           datasources = datasources)
  }

  if(exportPotentialRiskFactors){
    writeLines("### Export Results:  Potential Risk Factors ####################")

    if(exportPotentialRiskFactorsScores){
      # Create DCSI For each person
      writeLines("### DCSI Score")
      for(i in 1:length(datasources)){
        aggregatedScore(connectionDetails = connectionDetails,
                        packageName = packageName,
                        sql = 'dcsi.sql',
                        cdm_database_schema = datasources[[i]]$schema,
                        aggregated = FALSE,
                        temporal = FALSE,
                        covariate_table = paste0(Sys.getenv("writeTo"),'.', tableDSCI,"_",datasources[[i]]$db.name),
                        row_id_field = 'SUBJECT_ID',
                        cohort_table = paste0(Sys.getenv("writeTo"),'.', tableCohorts,"_",datasources[[i]]$db.name),
                        end_day = 0,
                        cohort_definition_id = 'COHORT_DEFINITION_ID',
                        analysis_id = 902,
                        included_cov_table = '',
                        analysis_name = 'DCSI',
                        domain_id = 'Condition')
      }

      # Create CHADS2 For each person
      writeLines("### CHADS2 Score")
      for(i in 1:length(datasources)){
        aggregatedScore(connectionDetails = connectionDetails,
                        packageName = packageName,
                        sql = 'chads2.sql',
                        cdm_database_schema = datasources[[i]]$schema,
                        aggregated = FALSE,
                        temporal = FALSE,
                        covariate_table = paste0(Sys.getenv("writeTo"),'.', tableChads2,"_",datasources[[i]]$db.name),
                        row_id_field = 'SUBJECT_ID',
                        cohort_table = paste0(Sys.getenv("writeTo"),'.', tableCohorts,"_",datasources[[i]]$db.name),
                        end_day = 0,
                        cohort_definition_id = 'COHORT_DEFINITION_ID',
                        analysis_id = 903,
                        included_cov_table = '',
                        analysis_name = 'Chads2',
                        domain_id = 'Condition')
      }


      # Create Charlson For each person
      writeLines("### Charlson Score")
      for(i in 1:length(datasources)){
        aggregatedScore(connectionDetails = connectionDetails,
                        packageName = packageName,
                        sql = 'charlsonIndex.sql',
                        cdm_database_schema = datasources[[i]]$schema,
                        aggregated = FALSE,
                        temporal = FALSE,
                        covariate_table = paste0(Sys.getenv("writeTo"),'.', tableCharlson,"_",datasources[[i]]$db.name),
                        row_id_field = 'SUBJECT_ID',
                        cohort_table = paste0(Sys.getenv("writeTo"),'.', tableCohorts,"_",datasources[[i]]$db.name),
                        end_day = 0,
                        cohort_definition_id = 'COHORT_DEFINITION_ID',
                        analysis_id = 901,
                        included_cov_table = '',
                        analysis_name = 'CharlsonIndex',
                        domain_id = 'Condition')
      }
    }

    for(i in 1:length(datasources)){
      exportPotentialRiskFactors(connectionDetails = connectionDetails,
                                 packageName = packageName,
                                 target_database_schema = Sys.getenv("writeTo"),
                                 target_table = tablePotentialRiskFactors,
                                 cdm_database_schema = datasources[[i]]$schema,
                                 dbID = datasources[[i]]$db.name,
                                 cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                                 code_list = tableCodeList,
                                 cohort_universe = tableCohortUniverse,
                                 i = i,
                                 last = length(datasources),
                                 study = study)
    }
  }

  if(exportRelevantLabs){
    writeLines("### Export Results:  Relevant Labs #############################")

    for(i in 1:length(datasources)){
      exportRelevantLabs(connectionDetails = connectionDetails,
                                 packageName = packageName,
                                 target_database_schema = Sys.getenv("writeTo"),
                                 target_table = tableRelevantLabs,
                                 cdm_database_schema = datasources[[i]]$schema,
                                 dbID = datasources[[i]]$db.name,
                                 cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                                 code_list = tableCodeList,
                                 cohort_universe = tableCohortUniverse,
                                 i = i,
                                 last = length(datasources))
    }
  }

  if(exportMeanAge){
    writeLines("### Export Results:  Mean Age ##################################")

    for(i in 1:length(datasources)){
      exportMeanAge(connectionDetails = connectionDetails,
                                 packageName = packageName,
                                 target_database_schema = Sys.getenv("writeTo"),
                                 target_table = tableMeanAge,
                                 cdm_database_schema = datasources[[i]]$schema,
                                 dbID = datasources[[i]]$db.name,
                                 cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                                 cohort_universe = tableCohortUniverse,
                                 i = i,
                                 last = length(datasources))
    }
  }

  if(exportTwoPlusNonSGLT2i){
    writeLines("### Export Results:  Two Plus Non SGLT2is ######################")
    for(i in 1:length(datasources)){
      exportTwoPlusNonSGLT2i(connectionDetails = connectionDetails,
                             packageName = packageName,
                             target_database_schema = Sys.getenv("writeTo"),
                             target_table_1 = tableTwoPlusNonSGLT2i_table1,
                             target_table_2 = tableTwoPlusNonSGLT2i_table2,
                             cdm_database_schema = datasources[[i]]$schema,
                             dbID = datasources[[i]]$db.name,
                             cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                             code_list = tableCodeList,
                             cohort_universe = tableCohortUniverse,
                             i = i,
                             last = length(datasources))
    }
  }

  if(exportReviewDKAEvents){
    writeLines("### Export Results:  Review DKA Events #########################")
    for(i in 1:length(datasources)){
      exportReviewDKAEvents (connectionDetails = connectionDetails,
                             packageName = packageName,
                             target_database_schema = Sys.getenv("writeTo"),
                             target_table = tableReviewDKAEvents,
                             dbID = datasources[[i]]$db.name,
                             cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                             cohort_universe = tableCohortUniverse,
                             i = i,
                             last = length(datasources))
    }
  }

  if(exportInitislSGLT2iDosage){
    writeLines("### Export Results:  Export Initial SGLT2i Dosage ##############")
    for(i in 1:length(datasources)){
      exportInitialSGLT2iDosage(connectionDetails = connectionDetails,
                             packageName = packageName,
                             target_database_schema = Sys.getenv("writeTo"),
                             target_table = tableInitialSGLT2iDosage,
                             cdm_database_schema = datasources[[i]]$schema,
                             dbID = datasources[[i]]$db.name,
                             cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                             code_list = tableCodeList,
                             cohort_universe = tableCohortUniverse,
                             i = i,
                             last = length(datasources))
    }
  }

  if(exportDKAFatal){
    writeLines("### Export Results:  DKA Fatal #################################")
    for(i in 1:length(datasources)){
      exportDKAFatal(connectionDetails = connectionDetails,
                    packageName = packageName,
                    target_database_schema = Sys.getenv("writeTo"),
                    target_table = tableDKAFatal,
                    cdm_database_schema = datasources[[i]]$schema,
                    dbID = datasources[[i]]$db.name,
                    cohort_table = paste0(tableCohorts,"_",datasources[[i]]$db.name),
                    code_list = tableCodeList,
                    cohort_universe = tableCohortUniverse,
                    i = i,
                    last = length(datasources))
    }
  }

  if(formatPotentialRiskFactors){
    writeLines("### Format Results:  Potential Risk Factors ####################")

      formatPotentialRiskFactors(connectionDetails = connectionDetails,
                     packageName = packageName,
                     target_database_schema = Sys.getenv("writeTo"),
                     target_table = tablePotentialRiskFactorsFormatted ,
                     cohort_universe = tableCohortUniverse,
                     tablePotentialRiskFactors = tablePotentialRiskFactors)

  }

  if(formatPaticipantsTxInfo){
    writeLines("### Format Results:  Participants and Treatment Info ###########")

    formatParticipantsAndTxInfo(connectionDetails = connectionDetails,
                               packageName = packageName,
                               target_database_schema = Sys.getenv("writeTo"),
                               target_table = tableParticipantsAndTreatmentInfo,
                               cohort_universe = tableCohortUniverse,
                               tablePotentialRiskFactors = tablePotentialRiskFactors,
                               tableMeanAge = tableMeanAge)
  }

  if(formatFatalDka){
    writeLines("### Format Results:  Fatal DKA #################################")

    formatFatalDka(connectionDetails = connectionDetails,
                                packageName = packageName,
                                target_database_schema = Sys.getenv("writeTo"),
                                target_table = tableParticipantsAndTreatmentInfo,
                                cohort_universe = tableCohortUniverse,
                                tablePotentialRiskFactors = tablePotentialRiskFactors,
                   tableDKAFatal = tableDKAFatal)
  }

  runTime <- proc.time() - ptm
  writeLines("### Program Run Time")
  print(runTime)
}
