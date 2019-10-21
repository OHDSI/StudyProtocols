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
	WHERE observation_concept_id = 40770351 -- Do you drink alcohol regularly, every week 
		AND value_as_string = 'Yes'
{@cohort_id != -1} ? {		AND c.cohort_definition_id = @cohort_id}			
		
	UNION ALL 

	SELECT DISTINCT c.@row_id_field AS row_id
	FROM @cohort_temp_table c
	INNER JOIN @cdm_database_schema.observation
		ON c.subject_id = observation.person_id
			AND c.cohort_start_date >= observation_date
	WHERE observation_concept_id = 3043872 -- Alcoholic drinks per week - Reported 
		AND value_as_number > 2
{@cohort_id != -1} ? {		AND c.cohort_definition_id = @cohort_id}					
	) alcohol;
