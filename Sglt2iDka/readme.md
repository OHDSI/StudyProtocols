Diabetic Ketoacidosis in Patients With Type 2 Diabetes Treated With Sodium Glucose Co-transporter 2 Inhibitors Versus Other Antihyperglycemic Agents: An Observational Study of Four US Administrative Claims Databases
========================================================================

This study package performs a retrospective, real-world observational study to evaluate the risk of diabetic ketoacidosis among patients with type 2 diabetes mellitus treated with antihyperglycemic agents.

Package overview
================

Location | Content 
-------- | ------- 
documents/ | The study protocol
programs/generateCohort | R package for executing cohort construction
programs/generateCohort/inst/sql/sql_server | SQL queries for cohort construction
programs/generateCohort/R | R scripts for cohort construction
programs/generateCohort/extras/CodeToRun.R | The code used to execute cohort construction
programs/sglt2iDka | R package for executing full comparitive study
programs/sglt2iDka/inst/settings | Analytic specifications for the study 
programs/sglt2iDka/R | R scripts for full comparitive study
programs/sglt2iDka/extras/CodeToRun.R | The code used to execute full comparitive study
programs/sglt2iDka/extras/EvidenceExplorer | The source code for the Shiny app for exploring the study results

License
=======
The generateCohort and sglt2iDka packages are licensed under Apache License 2.0

Development
===========
generateCohort and sglt2iDka packages were developed in R Studio.

### Development status

Study has been executed