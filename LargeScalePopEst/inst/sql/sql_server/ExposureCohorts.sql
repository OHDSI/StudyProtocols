-- Create depression exposure cohorts. Cohorts are created in temp table #exposure_cohorts
--
-- Important: make sure the cohort IDs generated here are the same as in ExposuresOfInterest.csv
--
--- Depression cohorts:
---- 15 antidepressant drugs + 2 antidepressant procedures
---- 365d washout before first use
---- prior diagnosis of MDD
---- no prior diagnosis of bipolar or schizophrenia
{DEFAULT @washout_period = 365 } 
{DEFAULT @cdm_database_schema = 'cdm.dbo' }

IF OBJECT_ID('tempdb..#exposure_cohorts', 'U') IS NOT NULL
	DROP TABLE #exposure_cohorts;

-- Antidepressant drugs
SELECT de1.person_id AS subject_id,
	de1.drug_concept_id AS cohort_definition_id,
	de1.drug_era_start_date AS cohort_start_date,
	de1.drug_era_end_date AS cohort_end_date
INTO #exposure_cohorts
FROM (
	SELECT person_id,
		drug_concept_id,
		drug_era_start_date,
		drug_era_end_date,
		ROW_NUMBER() OVER (
			PARTITION BY person_id,
			drug_concept_id ORDER BY drug_era_start_date ASC
			) AS rn1
	FROM @cdm_database_schema.drug_era
	WHERE drug_concept_id IN (739138, 750982, 797617, 755695, 715939, 703547, 715259, 743670, 710062, 725131, 722031, 721724, 717607, 738156, 40234834)
	AND drug_era_end_date > drug_era_start_date
	) de1
INNER JOIN @cdm_database_schema.observation_period op1
	ON de1.person_id = op1.person_id
		AND de1.drug_era_start_date BETWEEN DATEADD(dd, @washout_period, op1.observation_period_start_date)
			AND op1.observation_period_end_date
INNER JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (4152280) -- Major depressive disorder
			)
	GROUP BY person_id
	) co1
	ON de1.person_id = co1.person_id
		AND de1.drug_era_start_date >= co1.condition_start_date
LEFT JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (435783, 436665) -- Schizophrenia, Bipolar disorder
			)
	GROUP BY person_id
	) co2
	ON de1.person_id = co2.person_id
		AND de1.drug_era_start_date >= co2.condition_start_date
WHERE de1.rn1 = 1
	AND co2.person_id IS NULL;

-- 4327941 Psychotherapy 
SELECT po1.person_id,
	po2.procedure_date AS drug_exposure_start_date,
	po2.procedure_date AS drug_exposure_end_date
INTO #de
FROM (
	SELECT person_id,
		procedure_concept_id,
		MIN(procedure_date) AS procedure_date
	FROM @cdm_database_schema.procedure_occurrence
	WHERE procedure_concept_id IN (2007748, 4088889, 4151904, 43527989, 4118797, 4199042, 4262582, 2617478, 2007749, 2213547, 4118801, 4148398, 4196062, 4208314, 4234402, 43527904, 43527986, 45888237, 4143316, 43527905, 4119335, 4258834, 40482841, 45765516, 45887951, 2213554, 4079938, 4079939, 4128268, 44792695, 2007731, 4035812, 4083133, 4173581, 4242119, 4268909, 4080044, 4083706, 4117915, 4121662, 4225728, 44808677, 2007750, 2213546, 4103512, 44791916, 44808259, 46286330, 2213544, 4012488, 4079608, 4084195, 4119334, 4132436, 4299728, 4263758, 45887728, 2007730, 2007746, 2617477, 4128406, 4164790, 4219683, 4226276, 2213555, 4048385, 4083130, 4234476, 4249602, 4265313, 4295027, 2007763, 2108571, 4080048, 4221997, 4226275, 4278094, 45763911, 45889353, 2213548, 4114491, 4136352, 4137086, 4233181, 4327941, 43527987, 4048387, 4148765, 4202234, 4311943, 43527988, 43527990, 4028920, 4084202, 4100341, 4118798, 4118800, 4296166, 43527991, 4083129, 4083131, 4084201, 4179241, 46286403, 2007747, 4079500, 4126653, 4272803)
		OR procedure_source_concept_id IN (
			SELECT concept_id
			FROM @cdm_database_schema.concept
			WHERE vocabulary_id = 'CPT4'
				AND concept_name LIKE '%psychotherap%'
				AND concept_name NOT LIKE '%without the patient%'
				AND invalid_reason = 'D'
			)
	GROUP BY person_id,
		procedure_concept_id
	) po1
INNER JOIN @cdm_database_schema.observation_period op1
	ON po1.person_id = op1.person_id
		AND po1.procedure_date BETWEEN DATEADD(dd, @washout_period, op1.observation_period_start_date)
			AND op1.observation_period_end_date
INNER JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (4152280) -- Major depressive disorder
			)
	GROUP BY person_id
	) co1
	ON po1.person_id = co1.person_id
		AND po1.procedure_date >= co1.condition_start_date
LEFT JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (435783, 436665) -- Schizophrenia, Bipolar disorder
			)
	GROUP BY person_id
	) co2
	ON po1.person_id = co2.person_id
		AND po1.procedure_date >= co2.condition_start_date
INNER JOIN (
	SELECT person_id,
		procedure_concept_id,
		procedure_date
	FROM @cdm_database_schema.procedure_occurrence
	WHERE procedure_concept_id IN (2007748, 4088889, 4151904, 43527989, 4118797, 4199042, 4262582, 2617478, 2007749, 2213547, 4118801, 4148398, 4196062, 4208314, 4234402, 43527904, 43527986, 45888237, 4143316, 43527905, 4119335, 4258834, 40482841, 45765516, 45887951, 2213554, 4079938, 4079939, 4128268, 44792695, 2007731, 4035812, 4083133, 4173581, 4242119, 4268909, 4080044, 4083706, 4117915, 4121662, 4225728, 44808677, 2007750, 2213546, 4103512, 44791916, 44808259, 46286330, 2213544, 4012488, 4079608, 4084195, 4119334, 4132436, 4299728, 4263758, 45887728, 2007730, 2007746, 2617477, 4128406, 4164790, 4219683, 4226276, 2213555, 4048385, 4083130, 4234476, 4249602, 4265313, 4295027, 2007763, 2108571, 4080048, 4221997, 4226275, 4278094, 45763911, 45889353, 2213548, 4114491, 4136352, 4137086, 4233181, 4327941, 43527987, 4048387, 4148765, 4202234, 4311943, 43527988, 43527990, 4028920, 4084202, 4100341, 4118798, 4118800, 4296166, 43527991, 4083129, 4083131, 4084201, 4179241, 46286403, 2007747, 4079500, 4126653, 4272803)
		OR procedure_source_concept_id IN (
			SELECT concept_id
			FROM @cdm_database_schema.concept
			WHERE vocabulary_id = 'CPT4'
				AND concept_name LIKE '%psychotherap%'
				AND concept_name NOT LIKE '%without the patient%'
				AND invalid_reason = 'D'
			)
	) po2
	ON po1.person_id = po2.person_id
WHERE co2.person_id IS NULL;

-- Create eras, adapted from https://gist.github.com/chrisknoll/8d3c6744bae4f060aec1 
INSERT INTO #exposure_cohorts (
	subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT d.PERSON_ID,
	4327941,
	MIN(d.DRUG_EXPOSURE_START_DATE),
	MIN(e.END_DATE) AS ERA_END_DATE
FROM #de d
INNER JOIN (
	SELECT PERSON_ID,
		DATEADD(day, - 30, EVENT_DATE) AS END_DATE -- unpad the end date
	FROM (
		SELECT E1.PERSON_ID,
			E1.EVENT_DATE,
			COALESCE(E1.START_ORDINAL, MAX(E2.START_ORDINAL)) START_ORDINAL,
			E1.OVERALL_ORD
		FROM (
			SELECT PERSON_ID,
				EVENT_DATE,
				EVENT_TYPE,
				--MAX(START_ORDINAL) OVER (PARTITION BY PERSON_ID ORDER BY EVENT_DATE, EVENT_TYPE ROWS UNBOUNDED PRECEDING) as START_ORDINAL, -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with 
				START_ORDINAL,
				ROW_NUMBER() OVER (
					PARTITION BY PERSON_ID ORDER BY EVENT_DATE,
						EVENT_TYPE
					) AS OVERALL_ORD -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
			FROM (
				-- select the start dates, assigning a row number to each
				SELECT PERSON_ID,
					DRUG_EXPOSURE_START_DATE AS EVENT_DATE,
					0 AS EVENT_TYPE,
					ROW_NUMBER() OVER (
						PARTITION BY PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE
						) AS START_ORDINAL
				FROM #de
				
				UNION ALL
				
				-- add the end dates with NULL as the row number, padding the end dates by 30 to allow a grace period for overlapping ranges.
				SELECT PERSON_ID,
					DATEADD(day, 30, DRUG_EXPOSURE_END_DATE),
					1 AS EVENT_TYPE,
					NULL
				FROM #de
				) RAWDATA
			) E1
		LEFT JOIN (
			SELECT PERSON_ID,
				DRUG_EXPOSURE_START_DATE AS EVENT_DATE,
				ROW_NUMBER() OVER (
					PARTITION BY PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE
					) AS START_ORDINAL
			FROM #de
			) E2
			ON E1.PERSON_ID = E2.PERSON_ID
				AND E2.EVENT_DATE < E1.EVENT_DATE
		GROUP BY E1.PERSON_ID,
			E1.EVENT_DATE,
			E1.START_ORDINAL,
			E1.OVERALL_ORD
		) E
	WHERE 2 * E.START_ORDINAL - E.OVERALL_ORD = 0
	) e
	ON d.PERSON_ID = e.PERSON_ID
		AND e.END_DATE >= d.DRUG_EXPOSURE_START_DATE
GROUP BY d.PERSON_ID
-- Require at least 1 day in era, so single session doesn't count:
HAVING DATEDIFF(DAY, MIN(d.DRUG_EXPOSURE_START_DATE), MIN(e.END_DATE)) > 0;

TRUNCATE TABLE #de;

DROP TABLE #de;

-- 4030840 Electroconvulsive therapy 
SELECT po1.person_id,
	po2.procedure_date AS drug_exposure_start_date,
	po2.procedure_date AS drug_exposure_end_date
INTO #de
FROM (
	SELECT person_id,
		procedure_concept_id,
		min(procedure_date) AS procedure_date
	FROM @cdm_database_schema.procedure_occurrence
	WHERE procedure_concept_id IN (2007727, 2007728, 2108578, 2108579, 2213552, 4004830, 4020981, 4030840, 4111663, 4210144, 4210145, 4332436, 4336318, 44508134)
	GROUP BY person_id,
		procedure_concept_id
	) po1
INNER JOIN @cdm_database_schema.observation_period op1
	ON po1.person_id = op1.person_id
		AND po1.procedure_date BETWEEN DATEADD(dd, @washout_period, op1.observation_period_start_date)
			AND op1.observation_period_end_date
INNER JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (4152280) -- Major depressive disorder
			)
	GROUP BY person_id
	) co1
	ON po1.person_id = co1.person_id
		AND po1.procedure_date >= co1.condition_start_date
LEFT JOIN (
	SELECT person_id,
		MIN(condition_start_date) AS condition_start_date
	FROM @cdm_database_schema.condition_occurrence
	WHERE condition_concept_id IN (
			SELECT descendant_concept_id
			FROM @cdm_database_schema.concept_ancestor
			WHERE ancestor_concept_id IN (435783, 436665) -- Schizophrenia, Bipolar disorder
			)
	GROUP BY person_id
	) co2
	ON po1.person_id = co2.person_id
		AND po1.procedure_date >= co2.condition_start_date
INNER JOIN (
	SELECT person_id,
		procedure_concept_id,
		procedure_date
	FROM @cdm_database_schema.procedure_occurrence
	WHERE procedure_concept_id IN (2007727, 2007728, 2108578, 2108579, 2213552, 4004830, 4020981, 4030840, 4111663, 4210144, 4210145, 4332436, 4336318, 44508134)
	) po2
	ON po1.person_id = po2.person_id
WHERE co2.person_id IS NULL;

-- Create eras, adapted from https://gist.github.com/chrisknoll/8d3c6744bae4f060aec1 
INSERT INTO #exposure_cohorts (
	subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT d.PERSON_ID,
	4030840,
	MIN(d.DRUG_EXPOSURE_START_DATE),
	MIN(e.END_DATE) AS ERA_END_DATE
FROM #de d
INNER JOIN (
	SELECT PERSON_ID,
		DATEADD(day, - 30, EVENT_DATE) AS END_DATE -- unpad the end date
	FROM (
		SELECT E1.PERSON_ID,
			E1.EVENT_DATE,
			COALESCE(E1.START_ORDINAL, MAX(E2.START_ORDINAL)) START_ORDINAL,
			E1.OVERALL_ORD
		FROM (
			SELECT PERSON_ID,
				EVENT_DATE,
				EVENT_TYPE,
				--MAX(START_ORDINAL) OVER (PARTITION BY PERSON_ID ORDER BY EVENT_DATE, EVENT_TYPE ROWS UNBOUNDED PRECEDING) as START_ORDINAL, -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with 
				START_ORDINAL,
				ROW_NUMBER() OVER (
					PARTITION BY PERSON_ID ORDER BY EVENT_DATE,
						EVENT_TYPE
					) AS OVERALL_ORD -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
			FROM (
				-- select the start dates, assigning a row number to each
				SELECT PERSON_ID,
					DRUG_EXPOSURE_START_DATE AS EVENT_DATE,
					0 AS EVENT_TYPE,
					ROW_NUMBER() OVER (
						PARTITION BY PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE
						) AS START_ORDINAL
				FROM #de
				
				UNION ALL
				
				-- add the end dates with NULL as the row number, padding the end dates by 30 to allow a grace period for overlapping ranges.
				SELECT PERSON_ID,
					DATEADD(day, 30, DRUG_EXPOSURE_END_DATE),
					1 AS EVENT_TYPE,
					NULL
				FROM #de
				) RAWDATA
			) E1
		LEFT JOIN (
			SELECT PERSON_ID,
				DRUG_EXPOSURE_START_DATE AS EVENT_DATE,
				ROW_NUMBER() OVER (
					PARTITION BY PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE
					) AS START_ORDINAL
			FROM #de
			) E2
			ON E1.PERSON_ID = E2.PERSON_ID
				AND E2.EVENT_DATE < E1.EVENT_DATE
		GROUP BY E1.PERSON_ID,
			E1.EVENT_DATE,
			E1.START_ORDINAL,
			E1.OVERALL_ORD
		) E
	WHERE 2 * E.START_ORDINAL - E.OVERALL_ORD = 0
	) e
	ON d.PERSON_ID = e.PERSON_ID
		AND e.END_DATE >= d.DRUG_EXPOSURE_START_DATE
GROUP BY d.PERSON_ID
-- Require at least 1 day in era, so single session doesn't count:
HAVING DATEDIFF(DAY, MIN(d.DRUG_EXPOSURE_START_DATE), MIN(e.END_DATE)) > 0;

TRUNCATE TABLE #de;

DROP TABLE #de;
