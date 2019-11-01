/************************************************************************
Copyright 2019 Observational Health Data Sciences and Informatics

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
SELECT DISTINCT c.@row_id_field AS row_id,
	CAST(1000 AS BIGINT) + @analysis_id AS covariate_id,
	CAST(1 AS INT) AS covariate_value
FROM @cohort_temp_table c
INNER JOIN @cdm_database_schema.drug_exposure
	ON c.subject_id = drug_exposure.person_id
		AND c.cohort_start_date >= drug_exposure_start_date
INNER JOIN @cdm_database_schema.concept_ancestor
	ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id = 21600712 -- ATC class A10
{@cohort_id != -1} ? {	AND c.cohort_definition_id = @cohort_id}			
;
