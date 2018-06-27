INSERT INTO #covar_defs
SELECT descendant_concept_id AS concept_id,
	@covariate_id AS covariate_id
FROM @cdm_database_schema.concept atc
INNER JOIN @cdm_database_schema.concept_ancestor
	ON ancestor_concept_id = atc.concept_id
WHERE atc.concept_code = '@atc';
