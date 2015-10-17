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
WHERE ancestor_concept_id IN (77650, 81250, 133327, 134118, 134765, 137054, 140362, 193874, 195212, 195501, 198075, 261326, 317895, 378160, 378256, 433163, 434319, 435140, 437222, 437986, 438134, 438407, 439237, 440389, 440424, 440695, 440814, 441267, 441788, 442274, 443605, 444130, 444191, 4029582, 4047269, 4052648, 4095288, 4112853, 4147672, 4153877, 4164337, 4186392, 4209011, 4223947, 4262178, 4285569, 4286201, 4297984, 4307254)
	AND visit_occurrence.visit_concept_id IN (9201, 9203);