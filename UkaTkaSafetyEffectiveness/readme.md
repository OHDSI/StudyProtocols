Prospective validation of a randomised trial of unicompartmental and total knee replacement
========================================================================
**real-world evidence from the OHDSI network**

This study package performs a retrospective, real-world observational study to evaluate the risk of post-operative complications, opioid use, and revision with unicompartmental versus total knee replacement.

Package overview
================

Location | Content 
-------- | ------- 
documents/ | The study protocol.
inst/cohorts | Cohort definitions.
inst/sql | SQL queries for cohort construction.
inst/settings | Analytic specifications of the study. 
root folder | The R package for executing the study. Needs to be built before executing.
extras/CodeToRun.R | The code used to execute the study.
inst/shiny/EvidenceExplorer | The source code for the Shiny app for exploring the study results. Requires all files from the `shinyData` folders created when running the package to be placed in a `data` subfolder of the app.

License
=======
The UkaTkaSafetyFull package is licensed under Apache License 2.0

Development
===========
UkaTkaSafetyFull was developed in R Studio.

### Development status

Study has been executed
