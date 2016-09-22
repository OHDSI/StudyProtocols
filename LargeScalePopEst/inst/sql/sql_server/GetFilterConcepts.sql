SELECT concept_id AS filter_concept_id,
	concept_name AS filter_concept_name,
	descendant_concept_id AS exposure_concept_id
FROM @cdm_database_schema.concept
INNER JOIN @cdm_database_schema.concept_ancestor
	ON concept_id = ancestor_concept_id
WHERE descendant_concept_id IN (@exposure_concept_ids)
	AND (
		vocabulary_id = 'ATC'
		OR ancestor_concept_id = descendant_concept_id
		OR concept_class_id = 'Procedure'
		)

UNION ALL

SELECT concept_id AS filter_concept_id,
	concept_name AS filter_concept_name,
	ancestor_concept_id AS exposure_concept_id
FROM @cdm_database_schema.concept
INNER JOIN @cdm_database_schema.concept_ancestor
	ON concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (@exposure_concept_ids)