SELECT ancestor_concept_id AS nc_concept_id,
	descendant_concept_id AS concept_id
INTO #negative_controls
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (@outcome_ids);

INSERT INTO @target_database_schema.@target_cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT nc_visits.nc_concept_id AS cohort_definition_id,
	nc_visits.person_id AS subject_id,
	nc_visits.visit_start_date AS cohort_start_date,
	nc_visits.visit_end_date AS cohort_end_date
FROM (
	SELECT DISTINCT nc1.nc_concept_id,
		vo1.person_id,
		vo1.visit_start_date,
		vo1.visit_end_date
	FROM @cdm_database_schema.visit_occurrence vo1
	INNER JOIN @cdm_database_schema.condition_occurrence co1
		ON vo1.visit_occurrence_id = co1.visit_occurrence_id
	INNER JOIN #negative_controls nc1
		ON co1.condition_concept_id = nc1.concept_id
	) nc_visits
LEFT JOIN (
	SELECT nc_concept_id,
		person_id,
		condition_start_date
	FROM @cdm_database_schema.condition_occurrence co0
	INNER JOIN #negative_controls nc0
		ON co0.condition_concept_id = nc0.concept_id
	) co1
	ON nc_visits.person_id = co1.person_id
		AND nc_visits.nc_concept_id = co1.nc_concept_id
		AND co1.condition_start_date < nc_visits.visit_start_date
		AND co1.condition_start_date >= DATEADD(DAY, - 30, nc_visits.visit_start_date)
WHERE co1.nc_concept_id IS NULL;

TRUNCATE TABLE #negative_controls;

DROP TABLE #negative_controls;