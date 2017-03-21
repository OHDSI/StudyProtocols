--create exposure pairs
----must not have both drugs
----must restrict to period of overlapping time MAX(min date) - MIN(max date)
{DEFAULT @cdm_database_schema = 'cdm.dbo'}
{DEFAULT @target_database_schema = 'scratch.dbo'}
{DEFAULT @target_cohort_table = 'cohort'}
{DEFAULT @target_cohort_summary_table = 'exposure_cohort_summary'}

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
		CAST(s1.cohort_definition_id AS BIGINT) AS t_cohort_definition_id,
	    CAST(s2.cohort_definition_id AS BIGINT) AS c_cohort_definition_id,
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
LEFT JOIN #exposure_cohorts ec2
	ON cp1.c_cohort_definition_id = ec2.cohort_definition_id
		AND ec1.subject_id = ec2.subject_id
WHERE ec2.subject_id IS NULL;

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
LEFT JOIN #exposure_cohorts ec2
	ON cp1.t_cohort_definition_id = ec2.cohort_definition_id
		AND ec1.subject_id = ec2.subject_id
WHERE ec2.subject_id IS NULL;

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

TRUNCATE TABLE #exposure_cohorts;
DROP TABLE #exposure_cohorts;

TRUNCATE TABLE #exposure_cohort_summary;
DROP TABLE #exposure_cohort_summary;

TRUNCATE TABLE #exposure_cohort_pairs;
DROP TABLE #exposure_cohort_pairs;

TRUNCATE TABLE #exposure_pair_cohort_summary;
DROP TABLE #exposure_pair_cohort_summary;
