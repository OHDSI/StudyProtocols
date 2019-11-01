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
SELECT DISTINCT row_id,
	CAST(1000 AS BIGINT) + @analysis_id AS covariate_id,
	CAST(1 AS INT) AS covariate_value
FROM (
	SELECT DISTINCT c.@row_id_field AS row_id
	FROM @cohort_temp_table c
	INNER JOIN @cdm_database_schema.observation
		ON c.subject_id = observation.person_id
			AND c.cohort_start_date >= observation_date
	WHERE observation_concept_id = 40766929 -- How many cigarettes do you smoke per day now
		AND value_as_number >= 1
{@cohort_id != -1} ? {		AND c.cohort_definition_id = @cohort_id}			
		
	UNION ALL 

	SELECT DISTINCT c.@row_id_field AS row_id
	FROM @cohort_temp_table c
	INNER JOIN @cdm_database_schema.observation
		ON c.subject_id = observation.person_id
			AND c.cohort_start_date >= observation_date
	WHERE observation_concept_id IN (4144271, 4052030, 4052029, 4052947, 4217594, 37395605, 4058137, 4295004, 4199818, 44802474, 4085459, 4144273, 4193014, 44806696, 44802794, 4086132, 4058136, 4190573, 4215409, 4052948, 44810930, 4204653)
{@cohort_id != -1} ? {		AND c.cohort_definition_id = @cohort_id}					
	) alcohol;
