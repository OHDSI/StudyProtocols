/************************************************************************
Copyright 2017 Observational Health Data Sciences and Informatics

This file is part of AlendronateVsRaloxifene

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
{DEFAULT @cdm_database_schema = "cdm"}
{DEFAULT @work_database_schema = "cdm"}
{DEFAULT @study_cohort_table = "cohort"}
{DEFAULT @cohort_definition_ids = 1}

SELECT cohort_definition_id,
	COUNT(*) AS code_count,
	COUNT(DISTINCT subject_id) AS person_count,
	- 1 AS gender_concept_id,
	- 1 AS age_decile
FROM @work_database_schema.@study_cohort_table
WHERE cohort_definition_id IN (@cohort_definition_ids)
GROUP BY cohort_definition_id

UNION

SELECT cohort_definition_id,
	COUNT(*) AS code_count,
	COUNT(DISTINCT subject_id) AS person_count,
	gender_concept_id,
	FLOOR((YEAR(cohort_start_date) - year_of_birth) / 10) AS age_decile
FROM @work_database_schema.@study_cohort_table
INNER JOIN @cdm_database_schema.person
	ON subject_id = person_id
WHERE cohort_definition_id IN (@cohort_definition_ids)
GROUP BY cohort_definition_id,
	gender_concept_id,
	FLOOR((YEAR(cohort_start_date) - year_of_birth) / 10);


