INSERT INTO #covar_defs
SELECT descendant_concept_id AS concept_id,
	@covariate_id AS covariate_id
FROM (
	SELECT concept_id
	FROM @cdm_database_schema.concept standard
	WHERE standard.standard_concept = 'S'
		AND EXISTS (
			SELECT *
			FROM @cdm_database_schema.concept_relationship
			INNER JOIN @cdm_database_schema.concept
				ON concept_id_1 = concept_id
			WHERE concept_id_2 = standard.concept_id
				AND concept_id_1 IN (
					SELECT concept_id
					FROM @cdm_database_schema.concept
					WHERE concept_code LIKE '@icd9'
					)
				AND relationship_id = 'Maps to'
				AND vocabulary_id = 'ICD9CM'
			)
		AND NOT EXISTS (
			SELECT *
			FROM @cdm_database_schema.concept_relationship
			INNER JOIN @cdm_database_schema.concept
				ON concept_id_1 = concept_id
			WHERE concept_id_2 = standard.concept_id
				AND concept_id_1 NOT IN (
					SELECT concept_id
					FROM @cdm_database_schema.concept
					WHERE concept_code LIKE '@icd9'
					)
				AND relationship_id = 'Maps to'
				AND vocabulary_id = 'ICD9CM'
			)
	) standard
INNER JOIN @cdm_database_schema.concept_ancestor
	ON ancestor_concept_id = standard.concept_id;
