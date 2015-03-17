PROPOSED : Incidence of exposure to drugs for which pre-emptive pharmacogenomic testing is available
===============

The goal of this PROPOSED study is to derive data that large
healthcare organizations can combine data on risks of adverse events
and cost data to conduct cost-effectiveness / cost-benefit analyses
for pre-emptive pharmacogenomics testing.  Detailed information and
protocol is available on the [OHDSI
Wiki](http://www.ohdsi.org/web/wiki/doku.php?id=research:project_proposal_template).

To execute protocol in `R`

```R
library(devtools)
install_github(c("OHDSI/SqlRender","OHDSI/DatabaseConnector","OHDSI/StudyProtocols/PGcDrugStudy"))
library(PGxDrugStudy)
?execute # To get extended help

# Run study
execute(dbms = "postgresql",
        user = "joebruin",
        password = "supersecret",
        server = "myserver",
        cdmSchema = "cdm_schema")
        
# Email result file        
email(from = "collaborator@ohdsi.org",
      dataDescription = "CDM4 Simulated Data")        
```

To reload saved results in `R`

```R
# Load (or reload) study results
results <- loadOhdsiStudy(verbose = TRUE)
```
