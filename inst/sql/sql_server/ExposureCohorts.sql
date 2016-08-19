--create exposure cohorts of interest
----current example:
----15 t2dm drugs
----365d washout before first use
----prior diagnosis of T2DM
----but approach would work for any exposures defined as drug_concept_ids at ingredient level (so in drug_era table)
--create exposure pairs
----must not have both drugs
----must restrict to period of overlapping time MAX(min date) - MIN(max date)
{DEFAULT @washout_period = 365}
{DEFAULT @exposure_ids = 1503297, 1580747, 1560171, 1597756, 1525215, 1559684, 43526465, 40170911, 19059796, 40166035, 40239216, 1583722, 45774751, 1516766, 1502826, 1529331, 44785829}
{DEFAULT @indication_ids = 201826, 443732}
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
WHERE de1.rn1 = 1;

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

DELETE FROM @target_database_schema.@target_cohort_table 
WHERE cohort_definition_id IN (
	  SELECT tprime_cohort_definition_id
	  FROM #exposure_cohort_pairs)
  OR cohort_definition_id IN (
	  SELECT cprime_cohort_definition_id
	  FROM #exposure_cohort_pairs);

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
