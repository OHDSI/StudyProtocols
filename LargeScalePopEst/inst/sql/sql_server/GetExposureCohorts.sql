SELECT row_id,
	e1.subject_id,
    e1.cohort_definition_id,
	e1.cohort_start_date,
	DATEDIFF(DAY, observation_period_start_date, e1.cohort_start_date) AS days_from_obs_start,
	DATEDIFF(DAY, e1.cohort_start_date, e1.cohort_end_date) AS days_to_cohort_end,
	DATEDIFF(DAY, e1.cohort_start_date, observation_period_end_date) AS days_to_obs_end
FROM @target_database_schema.@target_cohort_table e1
INNER JOIN #exposure_cohorts e2
ON e1.subject_id = e2.subject_id
AND e1.cohort_start_date = e2.cohort_start_date
AND e1.cohort_end_date = e2.cohort_end_date
INNER JOIN @cdm_database_schema.observation_period op
ON op.person_id = e1.subject_id
AND op.observation_period_start_date <= e1.cohort_start_date
AND op.observation_period_end_date >= e1.cohort_start_date
ORDER BY e1.subject_id
