INSERT INTO  @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT ancestor_concept_id AS cohort_definition_id,
	condition_occurrence.person_id AS subject_id,
	condition_start_date AS cohort_start_date,
	condition_end_date AS cohort_end_date
FROM @cdm_database_schema.condition_occurrence
INNER JOIN @cdm_database_schema.visit_occurrence
	ON condition_occurrence.visit_occurrence_id = visit_occurrence.visit_occurrence_id
INNER JOIN @cdm_database_schema.concept_ancestor
	ON condition_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (4246127, 440695, 440424, 440389, 439727, 439237, 438123, 437222, 435140, 434319, 434033, 380688, 379782, 378419, 320835, 317895, 316429, 314665, 312938, 201826, 198571, 198075, 197921, 196528, 195501, 195212, 193807, 77650)
	AND visit_occurrence.visit_concept_id IN (9201, 9203);