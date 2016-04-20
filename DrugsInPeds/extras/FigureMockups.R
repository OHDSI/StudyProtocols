# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of DrugsInPeds
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

createMockupsForProtocol <- function(){
    library(ggplot2)

    #data <- expand.grid(c("CDARS","JMDC","NHIRD", "AUSOM","CCAE"), c("<2","2-11","12-18"), c("A","B","C","D","G","H","J","L","M","N","P"))
    data <- expand.grid(c("CDARS","JMDC","NHIRD", "AUSOM","CCAE"), c("<2","2-11","12-18"), c("Adrenergics", "Analgesics (inc. NSAIDs)", "Antibiotics", "Antidiabetic drugs", "Antiepileptics", "Antihistamines", "Antiinfectives (excluding antibiotics)", "Antineoplastic and immunomodulating agents", "Antithrombotic agents", "Central nervous system stimulants", "Contraceptives", "Corticosteroid", "Diuretics", "Mucolytics", "Psychotherapeutic agents"))
    colnames(data) <- c("Database","Age","Class")
    data$Prevalence <- runif(nrow(data),0,100)

    ggplot(data, aes(x = Age, y = Prevalence, group = Database, fill = Database)) +
        geom_bar(stat = "identity") +
        facet_grid(.~ Class) +
        theme(axis.text.x = element_text(angle=-90),
              strip.text.x = element_text(angle=-90))

    ggsave("extras/mockup1.png", width = 9, height = 5, dpi= 200)

    data <- expand.grid(c("CDARS","JMDC","NHIRD", "AUSOM","CCAE"), c("Male","Female"), c("Adrenergics", "Analgesics (inc. NSAIDs)", "Antibiotics", "Antidiabetic drugs", "Antiepileptics", "Antihistamines", "Antiinfectives (excluding antibiotics)", "Antineoplastic and immunomodulating agents", "Antithrombotic agents", "Central nervous system stimulants", "Contraceptives", "Corticosteroid", "Diuretics", "Mucolytics", "Psychotherapeutic agents"))
    colnames(data) <- c("Database","Gender","Class")
    data$Prevalence <- runif(nrow(data),0,100)

    ggplot(data, aes(x = Gender, y = Prevalence, group = Database, fill = Database)) +
        geom_bar(stat = "identity") +
        facet_grid(.~ Class) +
        theme(axis.text.x = element_text(angle=-90),
              strip.text.x = element_text(angle=-90))

    ggsave("extras/mockup2.png", width = 9, height = 5, dpi= 200)


    data <- expand.grid(c("CDARS","JMDC","NHIRD", "AUSOM","CCAE"), c("<2","2-11","12-18"), c("Adrenergics", "Analgesics (inc. NSAIDs)", "Antibiotics", "Antidiabetic drugs", "Antiepileptics", "Antihistamines", "Antiinfectives (excluding antibiotics)", "Antineoplastic and immunomodulating agents", "Antithrombotic agents", "Central nervous system stimulants", "Contraceptives", "Corticosteroid", "Diuretics", "Mucolytics", "Psychotherapeutic agents"), 2008:2014)
    colnames(data) <- c("Database","Age","Class", "Year")
    data$Prevalence <- runif(nrow(data),0,100)

    ggplot(data, aes(x = Year, y = Prevalence, group = Database, color = Database)) +
        geom_line() +
        facet_grid(Class ~ Age) +
        theme(axis.text.x = element_text(angle=-90),
              strip.text.y = element_text(angle=0))

    ggsave("extras/mockup3.png", width = 7, height = 8, dpi= 200)
}
