SELECT DISTINCT row_id,
	outcome.cohort_definition_id AS outcome_id,
	DATEDIFF(DAY, exposure_cohorts.cohort_start_date, outcome.cohort_start_date) AS days_to_event
FROM #exposure_cohorts exposure_cohorts
INNER JOIN @outcome_database_schema.@outcome_table outcome
	ON exposure_cohorts.subject_id = outcome.subject_id
INNER JOIN @cdm_database_schema.observation_period op
	ON op.person_id = exposure_cohorts.subject_id
		AND op.observation_period_start_date <= exposure_cohorts.cohort_start_date
		AND op.observation_period_end_date >= exposure_cohorts.cohort_start_date
WHERE exposure_cohorts.cohort_start_date >= observation_period_start_date
	AND outcome.cohort_start_date <= observation_period_end_date
	AND outcome.cohort_definition_id IN (@outcome_ids);
