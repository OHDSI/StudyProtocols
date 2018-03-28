SELECT DISTINCT subject_id,
  cohort_start_date,
  (CAST(drug_concept_id AS BIGINT) * 1000) + 998 AS covariate_id,
  1 AS covariate_value
FROM @cdm_database_schema.drug_era
INNER JOIN @cdm_database_schema.concept_ancestor
ON drug_concept_id = descendant_concept_id
INNER JOIN @cohort_database_schema.@cohort_table
ON person_id = subject_id
	AND drug_era_start_date < cohort_start_date
WHERE cohort_definition_id IN (@cohort_ids)
	AND ancestor_concept_id = 21600712;
