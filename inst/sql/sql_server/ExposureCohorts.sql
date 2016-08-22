--create exposure cohorts of interest
----current example:
----15 antidepressant drugs
----365d washout before first use
----prior diagnosis of MDD
----no prior diagnosis of bipolar or schizophrenia
----but approach would work for any exposures defined as drug_concept_ids at ingredient level (so in drug_era table)
--create exposure pairs
----must not have both drugs
----must restrict to period of overlapping time MAX(min date) - MIN(max date)
{DEFAULT @washout_period = 365}
{DEFAULT @exposure_ids = 739138,750982,797617,755695,715939,703547,715259,743670,710062,725131,722031,721724,717607,738156,40234834}
{DEFAULT @indication_ids = 440383}
{DEFAULT @exclusion_ids = 435783, 36665}
{DEFAULT @cdm_database_schema = 'cdm.dbo'}
{DEFAULT @target_database_schema = 'scratch.dbo'}
{DEFAULT @target_cohort_table = 'cohort'}
{DEFAULT @target_cohort_summary_table = 'exposure_cohort_summary'}

IF OBJECT_ID('tempdb..#exposure_cohorts', 'U') IS NOT NULL
	DROP TABLE #exposure_cohorts;

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
	WHERE drug_concept_id IN (@exposure_ids)
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
			WHERE ancestor_concept_id IN (@indication_ids)
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
			WHERE ancestor_concept_id IN (@exclusion_ids)
			)
	GROUP BY person_id
	) co2
	ON de1.person_id = co2.person_id
		AND de1.drug_era_start_date >= co2.condition_start_date
WHERE de1.rn1 = 1
	AND co2.person_id IS NULL;

--4327941 Psychotherapy 
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
			WHERE ancestor_concept_id IN (@indication_ids)
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
			WHERE ancestor_concept_id IN (@exclusion_ids)
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
	) po2
	ON po1.person_id = po2.person_id
WHERE co2.person_id IS NULL;

INSERT INTO #exposure_cohorts (
	subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT person_id AS subject_id,
	4327941 AS cohort_definition_id,
	min(drug_exposure_start_date) AS cohort_start_date,
	min(era_end_date) AS cohort_end_date
FROM (
	SELECT *
	FROM #de
	) de
INNER JOIN (
	--cteEndDates
	SELECT PERSON_ID,
		DATEADD(day, - 1 * 30, EVENT_DATE) AS END_DATE -- unpad the end date by 30
	FROM (
		SELECT E1.PERSON_ID,
			E1.EVENT_DATE,
			COALESCE(E1.START_ORDINAL, MAX(E2.START_ORDINAL)) START_ORDINAL,
			E1.OVERALL_ORD
		FROM (
			SELECT PERSON_ID,
				EVENT_DATE,
				EVENT_TYPE,
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
				FROM (
					-- cteDrugTarget
					SELECT *
					FROM #de
					) D
				
				UNION ALL
				
				-- add the end dates with NULL as the row number, padding the end dates by 30 to allow a grace period for overlapping ranges.
				SELECT PERSON_ID,
					DATEADD(day, 30, DRUG_EXPOSURE_END_DATE),
					1 AS EVENT_TYPE,
					NULL
				FROM (
					-- cteDrugTarget
					SELECT *
					FROM #de
					) D
				) E2
				ON E1.PERSON_ID = E2.PERSON_ID
					AND E2.EVENT_DATE <= E1.EVENT_DATE
			GROUP BY E1.PERSON_ID,
				E1.EVENT_DATE,
				E1.START_ORDINAL,
				E1.OVERALL_ORD
			) E
		WHERE 2 * E.START_ORDINAL - E.OVERALL_ORD = 0
		) E
		ON de.PERSON_ID = E.PERSON_ID
			AND E.END_DATE >= de.DRUG_EXPOSURE_START_DATE
	GROUP BY de.person_id,
		de.drug_exposure_start_date
	) t1
GROUP BY person_id;

TRUNCATE TABLE #de;
DROP TABLE #de;

--4030840 Electroconvulsive therapy 
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
			WHERE ancestor_concept_id IN (@indication_ids)
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
			WHERE ancestor_concept_id IN (@exclusion_ids)
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

INSERT INTO #exposure_cohorts (
	subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT person_id AS subject_id,
	4030840 AS cohort_definition_id,
	min(drug_exposure_start_date) AS cohort_start_date,
	min(era_end_date) AS cohort_end_date
FROM (
	SELECT *
	FROM #de
	) de
INNER JOIN (
	--cteEndDates
	SELECT PERSON_ID,
		DATEADD(day, - 1 * 30, EVENT_DATE) AS END_DATE -- unpad the end date by 30
	FROM (
		SELECT E1.PERSON_ID,
			E1.EVENT_DATE,
			COALESCE(E1.START_ORDINAL, MAX(E2.START_ORDINAL)) START_ORDINAL,
			E1.OVERALL_ORD
		FROM (
			SELECT PERSON_ID,
				EVENT_DATE,
				EVENT_TYPE,
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
				FROM (
					-- cteDrugTarget
					SELECT *
					FROM #de
					) D
				
				UNION ALL
				
				-- add the end dates with NULL as the row number, padding the end dates by 30 to allow a grace period for overlapping ranges.
				SELECT PERSON_ID,
					DATEADD(day, 30, DRUG_EXPOSURE_END_DATE),
					1 AS EVENT_TYPE,
					NULL
				FROM (
					-- cteDrugTarget
					SELECT *
					FROM #de
					) D
				) E2
				ON E1.PERSON_ID = E2.PERSON_ID
					AND E2.EVENT_DATE <= E1.EVENT_DATE
			GROUP BY E1.PERSON_ID,
				E1.EVENT_DATE,
				E1.START_ORDINAL,
				E1.OVERALL_ORD
			) E
		WHERE 2 * E.START_ORDINAL - E.OVERALL_ORD = 0
		) E
		ON de.PERSON_ID = E.PERSON_ID
			AND E.END_DATE >= de.DRUG_EXPOSURE_START_DATE
	GROUP BY de.person_id,
		de.drug_exposure_start_date
	) t1
GROUP BY person_id;

TRUNCATE TABLE #de;
DROP TABLE #de;


IF OBJECT_ID('tempdb..#exposure_cohort_summary', 'U') IS NOT NULL
	DROP TABLE #exposure_cohort_summary;

SELECT cohort_definition_id,
	c1.concept_name AS cohort_definition_name,
	COUNT(subject_id) AS num_persons,
	MIN(cohort_start_date) AS min_cohort_date,
	MAX(cohort_start_date) AS max_cohort_date
INTO #exposure_cohort_summary
FROM #exposure_cohorts tec1
INNER JOIN @cdm_database_schema.concept c1
	ON tec1.cohort_definition_id = c1.concept_id
GROUP BY cohort_definition_id,
	c1.concept_name;

IF OBJECT_ID('tempdb..#exposure_cohort_pairs', 'U') IS NOT NULL
	DROP TABLE #exposure_cohort_pairs;

SELECT pair_id,
	t_cohort_definition_id,
	c_cohort_definition_id,
	t_cohort_definition_id * 1000 + pair_id AS tprime_cohort_definition_id,
	c_cohort_definition_id * 1000 + pair_id AS cprime_cohort_definition_id,
	min_cohort_date,
	max_cohort_date
INTO #exposure_cohort_pairs
FROM (
	SELECT ROW_NUMBER() OVER (
			ORDER BY s1.cohort_definition_id,
				s2.cohort_definition_id
			) AS pair_id,
		s1.cohort_definition_id AS t_cohort_definition_id,
		s2.cohort_definition_id AS c_cohort_definition_id,
		CASE 
			WHEN s1.min_cohort_date > s2.min_cohort_date
				THEN s1.min_cohort_date
			ELSE s2.min_cohort_date
			END AS min_cohort_date,
		CASE 
			WHEN s1.max_cohort_date < s2.max_cohort_date
				THEN s1.max_cohort_date
			ELSE s2.max_cohort_date
			END AS max_cohort_date
	FROM #exposure_cohort_summary s1,
		#exposure_cohort_summary s2
	WHERE s1.cohort_definition_id < s2.cohort_definition_id
	) t1;

DELETE
FROM @target_database_schema.@target_cohort_table
WHERE cohort_definition_id IN (
		SELECT tprime_cohort_definition_id
		FROM #exposure_cohort_pairs
		)
	OR cohort_definition_id IN (
		SELECT cprime_cohort_definition_id
		FROM #exposure_cohort_pairs
		);

--get tprime	  
INSERT INTO @target_database_schema.@target_cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT cp1.tprime_cohort_definition_id AS cohort_definition_id,
	ec1.subject_id,
	ec1.cohort_start_date,
	ec1.cohort_end_date
FROM #exposure_cohort_pairs cp1
INNER JOIN #exposure_cohorts ec1
	ON cp1.t_cohort_definition_id = ec1.cohort_definition_id
		AND ec1.cohort_start_date BETWEEN cp1.min_cohort_date
			AND cp1.max_cohort_date
LEFT JOIN @cdm_database_schema.drug_era de1
	ON cp1.c_cohort_definition_id = de1.drug_concept_id
		AND ec1.subject_id = de1.person_id
WHERE de1.person_id IS NULL;

--get cprime
INSERT INTO @target_database_schema.@target_cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT cp1.cprime_cohort_definition_id AS cohort_definition_id,
	ec1.subject_id,
	ec1.cohort_start_date,
	ec1.cohort_end_date
FROM #exposure_cohort_pairs cp1
INNER JOIN #exposure_cohorts ec1
	ON cp1.c_cohort_definition_id = ec1.cohort_definition_id
		AND ec1.cohort_start_date BETWEEN cp1.min_cohort_date
			AND cp1.max_cohort_date
LEFT JOIN @cdm_database_schema.drug_era de1
	ON cp1.t_cohort_definition_id = de1.drug_concept_id
		AND ec1.subject_id = de1.person_id
WHERE de1.person_id IS NULL;

IF OBJECT_ID('tempdb..#exposure_pair_cohort_summary', 'U') IS NOT NULL
	DROP TABLE #exposure_pair_cohort_summary;

SELECT cohort_definition_id,
	COUNT(subject_id) AS num_persons,
	MIN(cohort_start_date) AS min_cohort_date,
	MAX(cohort_start_date) AS max_cohort_date
INTO #exposure_pair_cohort_summary
FROM @target_database_schema.@target_cohort_table tec1
GROUP BY cohort_definition_id;

IF OBJECT_ID('@target_database_schema.@target_cohort_summary_table', 'U') IS NOT NULL
	DROP TABLE @target_database_schema.@target_cohort_summary_table;

SELECT cp1.pair_id,
	cp1.t_cohort_definition_id,
	ecs1.cohort_definition_name AS t_cohort_definition_name,
	ecs1.num_persons AS t_num_persons,
	ecs1.min_cohort_date AS t_min_cohort_date,
	ecs1.max_cohort_date AS t_max_cohort_date,
	cp1.tprime_cohort_definition_id,
	epcs1.num_persons AS tprime_num_persons,
	epcs1.min_cohort_date AS tprime_min_cohort_date,
	epcs1.max_cohort_date AS tprime_max_cohort_date,
	cp1.c_cohort_definition_id,
	ecs2.cohort_definition_name AS c_cohort_definition_name,
	ecs2.num_persons AS c_num_persons,
	ecs2.min_cohort_date AS c_min_cohort_date,
	ecs2.max_cohort_date AS c_max_cohort_date,
	cp1.cprime_cohort_definition_id,
	epcs2.num_persons AS cprime_num_persons,
	epcs2.min_cohort_date AS cprime_min_cohort_date,
	epcs2.max_cohort_date AS cprime_max_cohort_date
INTO @target_database_schema.@target_cohort_summary_table
FROM #exposure_cohort_pairs cp1
INNER JOIN #exposure_cohort_summary ecs1
	ON cp1.t_cohort_definition_id = ecs1.cohort_definition_id
INNER JOIN #exposure_pair_cohort_summary epcs1
	ON cp1.tprime_cohort_definition_id = epcs1.cohort_definition_id
INNER JOIN #exposure_cohort_summary ecs2
	ON cp1.c_cohort_definition_id = ecs2.cohort_definition_id
INNER JOIN #exposure_pair_cohort_summary epcs2
	ON cp1.cprime_cohort_definition_id = epcs2.cohort_definition_id;