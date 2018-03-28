/************************************************************************
Copyright 2018 Observational Health Data Sciences and Informatics

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
SELECT DISTINCT @row_id_field AS row_id,
	CAST(outcome_table.cohort_definition_id AS BIGINT) * 1000 + 999 AS covariate_id,
	1 AS covariate_value
FROM @cohort_temp_table c
INNER JOIN @outcome_database_schema.@outcome_table outcome_table
	ON outcome_table.subject_id = c.subject_id
WHERE outcome_table.cohort_start_date <= DATEADD(DAY, @window_end, c.cohort_start_date)
	AND outcome_table.cohort_start_date >= DATEADD(DAY, @window_start, c.cohort_start_date)
	AND outcome_table.cohort_definition_id IN (@outcome_ids)
{@cohort_id != -1} ? {	AND cohort_definition_id = @cohort_id}	
;
