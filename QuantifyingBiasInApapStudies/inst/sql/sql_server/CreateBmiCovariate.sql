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
SELECT row_id,
	CASE 
		WHEN bmi < 25 THEN CAST(1000 AS BIGINT) + @analysis_id 
		WHEN bmi >= 25 AND bmi < 30 THEN CAST(2000 AS BIGINT) + @analysis_id
		ELSE CAST(3000 AS BIGINT) + @analysis_id
	END AS covariate_id,
	CAST(1 AS INT) AS covariate_value
FROM (
	SELECT c.@row_id_field AS row_id,
		bmi,
		ROW_NUMBER() OVER (PARTITION BY c.@row_id_field ORDER BY bmi_date DESC, bmi_date_2 DESC) AS nr
	FROM @cohort_temp_table c
	INNER JOIN (
		SELECT person_id,
			value_as_number AS bmi,
			measurement_date AS bmi_date,
			measurement_date AS bmi_date_2
		FROM @cdm_database_schema.measurement
		WHERE measurement_concept_id = 3038553 -- Body mass index (BMI) [Ratio]
		
		UNION ALL
		
		SELECT body_height.person_id,
			body_weight.value_as_number / (body_height.value_as_number * body_height.value_as_number) AS bmi,
			CASE 
				WHEN body_height.measurement_date <= body_weight.measurement_date THEN body_weight.measurement_date
				ELSE body_height.measurement_date
			END as bmi_date,
			CASE 
				WHEN body_height.measurement_date <= body_weight.measurement_date THEN body_height.measurement_date
				ELSE body_weight.measurement_date
			END as bmi_date_2
		FROM @cdm_database_schema.measurement body_height
		INNER JOIN @cdm_database_schema.measurement body_weight
			ON body_height.person_id = body_weight.person_id
				AND ABS(DATEDIFF(DAY, body_height.measurement_date, body_weight.measurement_date)) <= 365
		WHERE body_height.measurement_concept_id = 3036277 -- Body height
			AND body_weight.measurement_concept_id = 3013762 -- Body weight Measured
			AND body_height.value_as_number != 0
	) bmi
	ON c.subject_id = bmi.person_id
	WHERE c.cohort_start_date >= bmi_date
{@cohort_id != -1} ? {	AND c.cohort_definition_id = @cohort_id}		
) ordered_bmi
WHERE nr = 1;
