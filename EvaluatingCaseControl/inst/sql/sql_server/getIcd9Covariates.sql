SELECT DISTINCT @row_id_field AS row_id,
	covariate_id,
	1 AS covariate_value
FROM @cohort_table c
INNER JOIN @cdm_database_schema.condition_occurrence
	ON condition_occurrence.person_id = c.subject_id
INNER JOIN #covar_defs
	ON condition_concept_id = concept_id
WHERE condition_start_date <= DATEADD(DAY, @window_end, cohort_start_date)
	AND condition_start_date >= DATEADD(DAY, @window_start, cohort_start_date)
{@cohort_id	!= -1} ? {	AND cohort_definition_id = @cohort_id}
