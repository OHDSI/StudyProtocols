IF OBJECT_ID('@target_database_schema.@target_table') IS NOT NULL
  DROP TABLE @target_database_schema.@target_table;

WITH CTE_CODE_LIST AS (
  /*Bucket code list into dosages of interest*/
	SELECT CODE_LIST_NAME, CODE_LIST_DESCRIPTION, CONCEPT_ID, CONCEPT_NAME,
		CASE
			WHEN AMOUNT_VALUE = 150 THEN 'Other'
			WHEN AMOUNT_VALUE = 50 THEN 'Other'
			WHEN AMOUNT_VALUE = 12.5 THEN 'Other'
			WHEN CODE_LIST_NAME = 'Empagliflozin' AND AMOUNT_VALUE = 5 THEN 'Other'
			WHEN AMOUNT_VALUE IS NOT NULL THEN CONCAT(CAST(AMOUNT_VALUE AS VARCHAR(10)),' mg')
			WHEN CONCEPT_NAME LIKE '% 150 MG%' THEN 'Other'
			WHEN CONCEPT_NAME LIKE '% 50 MG%' THEN 'Other'
			WHEN CONCEPT_NAME LIKE '% 12.5 MG%' THEN 'Other'
			WHEN CONCEPT_NAME LIKE '% 25 MG%' THEN '25 mg'
			WHEN CONCEPT_NAME LIKE '% 10 MG%' THEN '10 mg'
			WHEN CODE_LIST_NAME = 'Empagliflozin' AND CONCEPT_NAME LIKE '% 5 MG%' THEN 'Other'
			WHEN CONCEPT_NAME LIKE '% 5 MG%' THEN '5 mg'
			WHEN AMOUNT_VALUE IS NULL THEN 'Other'
			ELSE 'ERROR'
		END AS AMOUNT_VALUE
	FROM @target_database_schema.@codeList cl
		JOIN @cdm_database_schema.DRUG_STRENGTH ds
			ON ds.DRUG_CONCEPT_ID = cl.CONCEPT_ID
			AND ds.INGREDIENT_CONCEPT_ID IN (
				45774751, /*EMPA*/
				44785829, /*Dapa*/
				43526465  /*Cana*/
			)
	WHERE CODE_LIST_NAME IN (
		'Canagliflozin','Dapagliflozin','Empagliflozin'
	)
),
CTE_SGLT2I AS (
	SELECT COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR
	FROM @target_database_schema.@cohort_universe u
	WHERE u.EXPOSURE_COHORT = 1
	AND u.FU_STRAT_ITT_PP0DAY = 1
	AND u.COHORT_OF_INTEREST IN (
		'Empagliflozin','Dapagliflozin','Canagliflozin'
	)
),
CTE_COHORTS AS (
	SELECT DISTINCT
		cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR, cu.FULL_NAME, cu.SEED_COHORT_DEFINITION_ID,
		c.SUBJECT_ID, c.COHORT_START_DATE, c.COHORT_END_DATE
	FROM @target_database_schema.@db_cohorts c
		JOIN CTE_SGLT2I s
			ON c.COHORT_DEFINITION_ID = s.COHORT_DEFINITION_ID
		JOIN @cdm_database_schema.DRUG_EXPOSURE de
			ON de.PERSON_ID = c.SUBJECT_ID
			AND de.DRUG_EXPOSURE_START_DATE = c.COHORT_START_DATE
		JOIN CTE_CODE_LIST cl
			ON cl.CONCEPT_ID = de.DRUG_CONCEPT_ID
		JOIN @target_database_schema.@cohort_universe_DOSE cu
			ON cu.SEED_COHORT_DEFINITION_ID = c.COHORT_DEFINITION_ID
			AND cl.AMOUNT_VALUE LIKE cu.DOSAGE
			AND cl.CODE_LIST_NAME = s.COHORT_OF_INTEREST
),
CTE_FIND_DUPLICATES AS (
	SELECT SEED_COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE, COUNT(*) AS DUPLICATE
	FROM CTE_COHORTS
	GROUP BY SEED_COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE
	HAVING COUNT(*) > 1
),
CTE_DUPLICATES AS (
	SELECT DISTINCT
		cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR, cu.FULL_NAME, cu.SEED_COHORT_DEFINITION_ID,
		d.SUBJECT_ID, d.COHORT_START_DATE, d.COHORT_END_DATE
	FROM CTE_FIND_DUPLICATES d
		JOIN @target_database_schema.@cohort_universe_DOSE cu
			ON cu.SEED_COHORT_DEFINITION_ID = d.SEED_COHORT_DEFINITION_ID
			AND cu.FULL_NAME LIKE '%Other%'
)
SELECT COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE
INTO @target_database_schema.@target_table
FROM (
	/*Non Duplicates*/
	SELECT c.COHORT_DEFINITION_ID, c.COHORT_OF_INTEREST, c.T2DM, c.CENSOR, c.FULL_NAME, c.SUBJECT_ID, c.COHORT_START_DATE, c.COHORT_END_DATE
	FROM CTE_COHORTS c
		LEFT OUTER JOIN CTE_DUPLICATES d
			ON d.SUBJECT_ID = c.SUBJECT_ID
			AND d.SEED_COHORT_DEFINITION_ID = c.SEED_COHORT_DEFINITION_ID
	WHERE d.SUBJECT_ID IS NULL
	UNION ALL
	/*People in Multi Buckets*/
	SELECT COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR, FULL_NAME, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE
	FROM CTE_DUPLICATES
) z;
