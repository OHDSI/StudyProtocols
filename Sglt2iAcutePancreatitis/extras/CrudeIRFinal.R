studyFolder <- "D:/Studies/EPI534"
reportFolder = file.path(studyFolder, "report")

drugsOfInterest <- c(
  " GLP-1 inhibitors",
  " DPP-4 inhibitors",
  "Sulfonylurea",
  "TZD",
  "Insulin new users",
  "Other AHA"
)

#Read in the results tables

optumResults <- readRDS( "D:/Studies/EPI534/optum/results/shinyData/resultsHois_optum.rds")
mdcrResults <- readRDS( "D:/Studies/EPI534/mdcr/results/shinyData/resultsHois_mdcr.rds")
ccaeResults <- readRDS( "D:/Studies/EPI534/ccae/results/shinyData/resultsHois_ccae.rds")


###############################################################################
# ccae Incidence table
###############################################################################

##For the Comparator

ccaeResultsIRSubsetITTComparator <-subset(ccaeResults, ccaeResults$outcomeName == " Acute Pancreatitis" &
                                            ccaeResults$timeAtRisk == "Intent to Treat"  &
                                            ccaeResults$canaRestricted == "TRUE" &
                                            ccaeResults$eventType == "First Post Index Event" &
                                            ccaeResults$psStrategy == "Stratification" &
                                            ccaeResults$targetName == "Canagliflozin new users" &
                                            ccaeResults$comparatorDrug %in% drugsOfInterest,
                                          select=c(timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

ccaeResultsIRSubsetITTComparator<-plyr::rename(ccaeResultsIRSubsetITTComparator,  replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                        "comparatorDays"="personDays","eventsComparator"="Events"))

ccaeResultsIRSubsetOTComparator <-subset(ccaeResults, ccaeResults$outcomeName == " Acute Pancreatitis" &
                                           ccaeResults$timeAtRisk == "On Treatment"  &
                                           ccaeResults$canaRestricted == "TRUE" &
                                           ccaeResults$eventType == "First Post Index Event" &
                                           ccaeResults$psStrategy == "Stratification" &
                                           ccaeResults$targetName == "Canagliflozin new users" &
                                           ccaeResults$comparatorDrug %in% drugsOfInterest,
                                         select=c( timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

ccaeResultsIRSubsetOTComparator<-plyr::rename(ccaeResultsIRSubsetOTComparator, replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                     "comparatorDays"="personDays","eventsComparator"="Events"))



ccaeResultsIRSubsetComparator<-rbind(ccaeResultsIRSubsetITTComparator, ccaeResultsIRSubsetOTComparator)



###For the Target

#Intent to treat

ccaeResultsIRSubsetITTTarget <-subset(ccaeResults, ccaeResults$outcomeName == " Acute Pancreatitis" &
                                        ccaeResults$timeAtRisk == "Intent to Treat"  &
                                        ccaeResults$canaRestricted == "TRUE" &
                                        ccaeResults$eventType == "First Post Index Event" &
                                        ccaeResults$psStrategy == "Stratification" &
                                        ccaeResults$targetName == "Canagliflozin new users" &
                                        ccaeResults$comparatorDrug ==" GLP-1 inhibitors",
                                      select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))


ccaeResultsIRSubsetITTTarget<-plyr::rename(ccaeResultsIRSubsetITTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                               "treatedDays"="personDays","eventsTreated"="Events"))

#On treatment

ccaeResultsIRSubsetOTTarget <-subset(ccaeResults, ccaeResults$outcomeName == " Acute Pancreatitis" &
                                       ccaeResults$timeAtRisk == "On Treatment"  &
                                       ccaeResults$canaRestricted == "TRUE" &
                                       ccaeResults$eventType == "First Post Index Event" &
                                       ccaeResults$psStrategy == "Stratification" &
                                       ccaeResults$targetName == "Canagliflozin new users" &
                                       ccaeResults$comparatorDrug ==" GLP-1 inhibitors",
                                     select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))

ccaeResultsIRSubsetOTTarget<-plyr::rename(ccaeResultsIRSubsetOTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                             "treatedDays"="personDays","eventsTreated"="Events"))

ccaeResultsIRSubsetTreated<-rbind(ccaeResultsIRSubsetITTTarget, ccaeResultsIRSubsetOTTarget)


#Combining Target and Comparator IRs

ccaeResultsIRSubset<-rbind(ccaeResultsIRSubsetTreated, ccaeResultsIRSubsetComparator)

ccaeResultsIRSubset$PersonYears<-round(ccaeResultsIRSubset$personDays/365.25, digits=2)
ccaeResultsIRSubset$IR_per_1000<-round((ccaeResultsIRSubset$Events/ccaeResultsIRSubset$PersonYears)*1000, digits=2)


database<-c("ccae")
ccaeResultsIRSubset <- rbind(database,ccaeResultsIRSubset) 

###############################################################################
#MDCR Incidence table

##For the Comparator

mdcrResultsIRSubsetITTComparator <-subset(mdcrResults, mdcrResults$outcomeName == " Acute Pancreatitis" &
                                            mdcrResults$timeAtRisk == "Intent to Treat"  &
                                            mdcrResults$canaRestricted == "TRUE" &
                                            mdcrResults$eventType == "First Post Index Event" &
                                            mdcrResults$psStrategy == "Stratification" &
                                            mdcrResults$targetName == "Canagliflozin new users" &
                                            mdcrResults$comparatorDrug %in% drugsOfInterest,
                                          select=c(timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

mdcrResultsIRSubsetITTComparator<-plyr::rename(mdcrResultsIRSubsetITTComparator,  replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                        "comparatorDays"="personDays","eventsComparator"="Events"))

mdcrResultsIRSubsetOTComparator <-subset(mdcrResults, mdcrResults$outcomeName == " Acute Pancreatitis" &
                                           mdcrResults$timeAtRisk == "On Treatment"  &
                                           mdcrResults$canaRestricted == "TRUE" &
                                           mdcrResults$eventType == "First Post Index Event" &
                                           mdcrResults$psStrategy == "Stratification" &
                                           mdcrResults$targetName == "Canagliflozin new users" &
                                           mdcrResults$comparatorDrug %in% drugsOfInterest,
                                         select=c( timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

mdcrResultsIRSubsetOTComparator<-plyr::rename(mdcrResultsIRSubsetOTComparator, replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                     "comparatorDays"="personDays","eventsComparator"="Events"))



mdcrResultsIRSubsetComparator<-rbind(mdcrResultsIRSubsetITTComparator, mdcrResultsIRSubsetOTComparator)



###For the Target

#Intent to treat

mdcrResultsIRSubsetITTTarget <-subset(mdcrResults, mdcrResults$outcomeName == " Acute Pancreatitis" &
                                        mdcrResults$timeAtRisk == "Intent to Treat"  &
                                        mdcrResults$canaRestricted == "TRUE" &
                                        mdcrResults$eventType == "First Post Index Event" &
                                        mdcrResults$psStrategy == "Stratification" &
                                        mdcrResults$targetName == "Canagliflozin new users" &
                                        mdcrResults$comparatorDrug ==" GLP-1 inhibitors",
                                      select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))


mdcrResultsIRSubsetITTTarget<-plyr::rename(mdcrResultsIRSubsetITTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                               "treatedDays"="personDays","eventsTreated"="Events"))

#On treatment

mdcrResultsIRSubsetOTTarget <-subset(mdcrResults, mdcrResults$outcomeName == " Acute Pancreatitis" &
                                       mdcrResults$timeAtRisk == "On Treatment"  &
                                       mdcrResults$canaRestricted == "TRUE" &
                                       mdcrResults$eventType == "First Post Index Event" &
                                       mdcrResults$psStrategy == "Stratification" &
                                       mdcrResults$targetName == "Canagliflozin new users" &
                                       mdcrResults$comparatorDrug ==" GLP-1 inhibitors",
                                     select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))

mdcrResultsIRSubsetOTTarget<-plyr::rename(mdcrResultsIRSubsetOTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                             "treatedDays"="personDays","eventsTreated"="Events"))

mdcrResultsIRSubsetTreated<-rbind(mdcrResultsIRSubsetITTTarget, mdcrResultsIRSubsetOTTarget)


#Combining Target and Comparator IRs

mdcrResultsIRSubset<-rbind(mdcrResultsIRSubsetTreated, mdcrResultsIRSubsetComparator)

mdcrResultsIRSubset$PersonYears<-round(mdcrResultsIRSubset$personDays/365.25, digits=2)
mdcrResultsIRSubset$IR_per_1000<-round((mdcrResultsIRSubset$Events/mdcrResultsIRSubset$PersonYears)*1000, digits=2)


database<-c("mdcr")
mdcrResultsIRSubset <- rbind(database,mdcrResultsIRSubset) 

###############################################################################
#Optum Incidence table

##For the Comparator

optumResultsIRSubsetITTComparator <-subset(optumResults, optumResults$outcomeName == " Acute Pancreatitis" &
                                             optumResults$timeAtRisk == "Intent to Treat"  &
                                             optumResults$canaRestricted == "TRUE" &
                                             optumResults$eventType == "First Post Index Event" &
                                             optumResults$psStrategy == "Stratification" &
                                             optumResults$targetName == "Canagliflozin new users" &
                                             optumResults$comparatorDrug %in% drugsOfInterest,
                                           select=c(timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

optumResultsIRSubsetITTComparator<-plyr::rename(optumResultsIRSubsetITTComparator,  replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                          "comparatorDays"="personDays","eventsComparator"="Events"))

optumResultsIRSubsetOTComparator <-subset(optumResults, optumResults$outcomeName == " Acute Pancreatitis" &
                                            optumResults$timeAtRisk == "On Treatment"  &
                                            optumResults$canaRestricted == "TRUE" &
                                            optumResults$eventType == "First Post Index Event" &
                                            optumResults$psStrategy == "Stratification" &
                                            optumResults$targetName == "Canagliflozin new users" &
                                            optumResults$comparatorDrug %in% drugsOfInterest,
                                          select=c( timeAtRisk,comparatorDrug,comparator, comparatorDays, eventsComparator))

optumResultsIRSubsetOTComparator<-plyr::rename(optumResultsIRSubsetOTComparator, replace = c("timeAtRisk"="Time At Risk", "comparatorDrug" = "Drug","comparator" = "Persons",
                                                                                       "comparatorDays"="personDays","eventsComparator"="Events"))



optumResultsIRSubsetComparator<-rbind(optumResultsIRSubsetITTComparator, optumResultsIRSubsetOTComparator)



###For the Target

#Intent to treat

optumResultsIRSubsetITTTarget <-subset(optumResults, optumResults$outcomeName == " Acute Pancreatitis" &
                                         optumResults$timeAtRisk == "Intent to Treat"  &
                                         optumResults$canaRestricted == "TRUE" &
                                         optumResults$eventType == "First Post Index Event" &
                                         optumResults$psStrategy == "Stratification" &
                                         optumResults$targetName == "Canagliflozin new users" &
                                         optumResults$comparatorDrug ==" GLP-1 inhibitors",
                                       select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))


optumResultsIRSubsetITTTarget<-plyr::rename(optumResultsIRSubsetITTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                                 "treatedDays"="personDays","eventsTreated"="Events"))

#On treatment

optumResultsIRSubsetOTTarget <-subset(optumResults, optumResults$outcomeName == " Acute Pancreatitis" &
                                        optumResults$timeAtRisk == "On Treatment"  &
                                        optumResults$canaRestricted == "TRUE" &
                                        optumResults$eventType == "First Post Index Event" &
                                        optumResults$psStrategy == "Stratification" &
                                        optumResults$targetName == "Canagliflozin new users" &
                                        optumResults$comparatorDrug ==" GLP-1 inhibitors",
                                      select=c(timeAtRisk, targetDrug, treated, treatedDays, eventsTreated))

optumResultsIRSubsetOTTarget<-plyr::rename(optumResultsIRSubsetOTTarget, replace = c("timeAtRisk"="Time At Risk", "targetDrug" = "Drug","treated" = "Persons",
                                                                               "treatedDays"="personDays","eventsTreated"="Events"))

optumResultsIRSubsetTreated<-rbind(optumResultsIRSubsetITTTarget, optumResultsIRSubsetOTTarget)


#Combining Target and Comparator IRs

optumResultsIRSubset<-rbind(optumResultsIRSubsetTreated, optumResultsIRSubsetComparator)

optumResultsIRSubset$PersonYears<-round(optumResultsIRSubset$personDays/365.25, digits=2)
optumResultsIRSubset$IR_per_1000<-round((optumResultsIRSubset$Events/optumResultsIRSubset$PersonYears)*1000, digits=2)


database<-c("optum")
optumResultsIRSubset <- rbind(database,optumResultsIRSubset) 
###########################################################################
#Merge the three tables together

epi534_IR<-cbind(ccaeResultsIRSubset,mdcrResultsIRSubset,optumResultsIRSubset)

setwd(reportFolder)
write.csv(epi534_IR, file='D:/Studies/EPI534/report/epi534_Table1_IR.csv', row.names = F)
