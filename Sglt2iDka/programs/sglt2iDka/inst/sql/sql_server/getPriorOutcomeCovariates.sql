SELECT DISTINCT @row_id_field AS row_id,
	CAST(outcome_table.cohort_definition_id AS BIGINT) * 1000 + 999 AS covariate_id,
	1 AS covariate_value
FROM @cohort_temp_table c
INNER JOIN @outcome_database_schema.@outcome_table outcome_table
	ON outcome_table.subject_id = c.subject_id
WHERE outcome_table.cohort_start_date <= DATEADD(DAY, @window_end, c.cohort_start_date)
	AND outcome_table.cohort_start_date >= DATEADD(DAY, @window_start, c.cohort_start_date)
	AND outcome_table.cohort_definition_id IN (@outcome_ids)
{@cohort_id != -1} ? {AND cohort_definition_id = @cohort_id}
;
