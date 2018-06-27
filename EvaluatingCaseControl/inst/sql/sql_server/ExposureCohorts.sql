/************************************************************************
Copyright 2018 Observational Health Data Sciences and Informatics

This file is part of EvaluatingCaseControl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/
INSERT INTO  @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT drug_concept_id AS cohort_definition_id,
	person_id AS subject_id,
	drug_era_start_date AS cohort_start_date,
	drug_era_end_date AS cohort_end_date
FROM @cdm_database_schema.drug_era
WHERE drug_concept_id IN (@exposure_ids);
