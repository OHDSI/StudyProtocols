SELECT (CAST(concept_id AS BIGINT) * 1000) + 998 AS covariate_id,
  CONCAT('Prior exposure to: ', concept_name) AS covariate_name,
  998 AS analysis_id,
  concept_id
FROM @cdm_database_schema.concept_ancestor
INNER JOIN @cdm_database_schema.concept
ON concept_id = descendant_concept_id
WHERE ancestor_concept_id = 21600712
  AND concept_class_id = 'Ingredient';
