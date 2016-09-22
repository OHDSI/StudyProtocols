SELECT ROW_NUMBER() OVER (
		ORDER BY subject_id,
			cohort_start_date
		) AS row_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
INTO #exposure_cohorts
FROM (
	SELECT DISTINCT subject_id,
		cohort_start_date,
		cohort_end_date
	FROM @target_database_schema.@target_cohort_table
	WHERE cohort_definition_id IN (@exposure_ids)
	) tmp;
