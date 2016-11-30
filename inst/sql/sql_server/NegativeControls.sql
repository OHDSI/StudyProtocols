INSERT INTO  @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT ancestor_concept_id AS cohort_definition_id,
	condition_occurrence.person_id AS subject_id,
	MIN(condition_start_date) AS cohort_start_date,
	MIN(condition_start_date) AS cohort_end_date
FROM @cdm_database_schema.condition_occurrence
INNER JOIN @cdm_database_schema.concept_ancestor
	ON condition_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (@outcome_ids)
GROUP BY ancestor_concept_id,
	person_id;
