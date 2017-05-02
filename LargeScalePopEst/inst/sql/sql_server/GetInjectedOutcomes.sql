SELECT o.subject_id, cohort_definition_id, cohort_start_date, cohort_end_date
FROM @output_database_schema.@output_table o
INNER JOIN #subjects subjects
ON o.subject_id = subjects.subject_id
WHERE cohort_definition_id >= @min_id 
	AND cohort_definition_id <= @max_id
