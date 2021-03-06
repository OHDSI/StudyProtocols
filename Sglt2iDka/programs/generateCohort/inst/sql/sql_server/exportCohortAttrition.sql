{@z == 1 & @i == 1}?{
    IF OBJECT_ID('@target_database_schema.@target_table') IS NOT NULL
    DROP TABLE @target_database_schema.@target_table;

    CREATE TABLE @target_database_schema.@target_table (
      DB                  CHAR(10),
      COHORT_ID           INT,
      COHORT_OF_INTEREST  VARCHAR(150),
      T2DM                VARCHAR(10),
      STAT_ORDER_NUM      INT,
      STAT_TYPE           VARCHAR(150),
      STAT                BIGINT,
      STAT_PCT            FLOAT,
      CUMM_LOSS           FLOAT
    );
}

IF OBJECT_ID('tempdb..#qualified_events') IS NOT NULL
  DROP TABLE #qualified_events;

IF OBJECT_ID('tempdb..#TEMP_RESULTS ') IS NOT NULL
  DROP TABLE #TEMP_RESULTS;

IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #qualified_events
  WITH (LOCATION = USER_DB, DISTRIBUTION = HASH(person_id)) AS
SELECT i.*,
		(YEAR(INDEX_DATE) - p.YEAR_OF_BIRTH) AS AGE,
		op.OBSERVATION_PERIOD_START_DATE,
		op.OBSERVATION_PERIOD_END_DATE,
		DATEDIFF(dd,OBSERVATION_PERIOD_START_DATE, INDEX_DATE) AS TIME_BEFORE_INDEX
FROM (
	select PERSON_ID, MIN(DRUG_ERA_START_DATE) AS INDEX_DATE
	FROM @cdm_database_schema.DRUG_ERA de
	where de.drug_concept_id in (SELECT concept_id from  @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = '@drugOfInterest')
	GROUP BY PERSON_ID
) i
	JOIN @cdm_database_schema.PERSON p
		ON p.PERSON_ID = i.PERSON_ID
	JOIN @cdm_database_schema.OBSERVATION_PERIOD op
		ON op.PERSON_ID = i.PERSON_ID
		AND i.INDEX_DATE BETWEEN op.OBSERVATION_PERIOD_START_DATE AND op.OBSERVATION_PERIOD_END_DATE;



WITH CTE_EXPOSURE_OF_INTEREST AS (
	SELECT *
	FROM #qualified_events
),
CTE_AFTER_APRIL AS (
	SELECT *
	FROM #qualified_events
	WHERE INDEX_DATE >= '04/01/2013'
),
CTE_GT_365_OBS_TIME AS (
	SELECT *
	FROM CTE_AFTER_APRIL
	WHERE TIME_BEFORE_INDEX >= 365
),
CTE_T2DM AS (
	SELECT DISTINCT a.*
	FROM CTE_GT_365_OBS_TIME a
		JOIN  @cdm_database_schema.CONDITION_OCCURRENCE co
			ON co.PERSON_ID = a.PERSON_ID
			AND co.CONDITION_START_DATE BETWEEN a.OBSERVATION_PERIOD_START_DATE AND a.OBSERVATION_PERIOD_END_DATE
			AND co.CONDITION_START_DATE <= a.INDEX_DATE
			AND co.CONDITION_CONCEPT_ID IN (SELECT concept_id from @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'T2DM')
),
CTE_T2DM_BROAD_NARROW AS (
	SELECT *
	FROM CTE_T2DM
	WHERE PERSON_ID NOT IN (
			SELECT a.PERSON_ID
			FROM CTE_T2DM a
				JOIN  @cdm_database_schema.CONDITION_OCCURRENCE co
					ON co.PERSON_ID = a.PERSON_ID
					AND co.CONDITION_START_DATE BETWEEN a.OBSERVATION_PERIOD_START_DATE AND a.OBSERVATION_PERIOD_END_DATE
					{@t2dm == "BROAD"}?{AND co.CONDITION_START_DATE <= a.INDEX_DATE}
					AND co.CONDITION_CONCEPT_ID IN (SELECT concept_id from  @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'T1DM')
			UNION ALL
			SELECT a.PERSON_ID
			FROM CTE_T2DM a
				JOIN  @cdm_database_schema.CONDITION_OCCURRENCE co
					ON co.PERSON_ID = a.PERSON_ID
					AND co.CONDITION_START_DATE BETWEEN a.OBSERVATION_PERIOD_START_DATE AND a.OBSERVATION_PERIOD_END_DATE
					{@t2dm == "BROAD"}?{AND co.CONDITION_START_DATE <= a.INDEX_DATE}
					AND co.CONDITION_CONCEPT_ID IN (SELECT concept_id from  @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'Secondary Diabetes')
	)
),
{@t2dm == "NARROW"}?{
  CTE_INSULIN_PRIOR_1 AS (
  	SELECT *
  	FROM CTE_T2DM_BROAD_NARROW
  	WHERE PERSON_ID NOT IN (
  		SELECT b.PERSON_ID
  		FROM CTE_T2DM_BROAD_NARROW b
  			JOIN @cdm_database_schema.DRUG_ERA e
  				ON e.PERSON_ID = b.PERSON_ID
  				AND e.DRUG_ERA_START_DATE BETWEEN b.OBSERVATION_PERIOD_START_DATE AND b.OBSERVATION_PERIOD_END_DATE
  				AND e.DRUG_ERA_START_DATE < b.INDEX_DATE
  				AND e.DRUG_CONCEPT_ID IN (SELECT CONCEPT_ID FROM @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'Insulin')
  	)
  ),
  CTE_INSULIN_PRIOR_2 AS (
  	SELECT *
  	FROM CTE_T2DM_BROAD_NARROW
  	WHERE PERSON_ID IN (
  		SELECT PERSON_ID
  		FROM (
  			SELECT DISTINCT b.PERSON_ID
  			FROM CTE_T2DM_BROAD_NARROW b
  				JOIN @cdm_database_schema.DRUG_EXPOSURE e
  					ON e.PERSON_ID = b.PERSON_ID
  					AND e.DRUG_CONCEPT_ID IN (SELECT CONCEPT_ID FROM @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'Insulin')
  					AND e.DRUG_EXPOSURE_START_DATE <= DATEADD(dd,-1,b.INDEX_DATE)
  					AND e.DRUG_EXPOSURE_START_DATE BETWEEN b.OBSERVATION_PERIOD_START_DATE AND b.OBSERVATION_PERIOD_END_DATE
  			UNION ALL
  			SELECT DISTINCT b.PERSON_ID
  			FROM CTE_T2DM_BROAD_NARROW b
  				JOIN @cdm_database_schema.DRUG_EXPOSURE e
  					ON e.PERSON_ID = b.PERSON_ID
  					AND e.DRUG_EXPOSURE_START_DATE <= DATEADD(dd,-1,b.INDEX_DATE)
  					AND e.DRUG_EXPOSURE_START_DATE BETWEEN b.OBSERVATION_PERIOD_START_DATE AND b.OBSERVATION_PERIOD_END_DATE
  					AND e.DRUG_CONCEPT_ID IN (SELECT CONCEPT_ID FROM @target_database_schema.EPI535_CODE_LIST WHERE CODE_LIST_NAME = 'Non-Insulin T2DM Drug')
  		) z
  		GROUP BY PERSON_ID
  		HAVING COUNT(*) > 1
  	)
  ),
}
CTE_INSULIN_PRIOR AS (
	{@t2dm == "NARROW"}?{
  	SELECT *
  	FROM CTE_INSULIN_PRIOR_1
  	UNION
  	SELECT *
  	FROM CTE_INSULIN_PRIOR_2
  }
  {@t2dm == "BROAD"}?{
    SELECT *
    FROM CTE_T2DM_BROAD_NARROW
  }
),
CTE_AGE AS (
	SELECT *
	FROM CTE_INSULIN_PRIOR
	{@t2dm == "NARROW"}?{WHERE AGE >= 40}
),
CTE_COUNT_EXPOSURE_OF_INTEREST AS (
	select
		'@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		1 AS STAT_ORDER_NUM,
		'Drug of Interest' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		1.00 AS STAT_PCT,
		0.00 AS CUMM_LOSS
	FROM CTE_EXPOSURE_OF_INTEREST de
),
CTE_COUNT_AFTER_APRIL AS (
	select '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		2 AS STAT_ORDER_NUM,
		'Index >= April 1, 2013' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS CUMM_LOSS
	FROM CTE_AFTER_APRIL de
),
CTE_COUNT_GT_365_OBS_TIME AS (
	select '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		3 AS STAT_ORDER_NUM,
		'At least 365 days of prior observable time' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_AFTER_APRIL)) AS CUMM_LOSS
	FROM CTE_GT_365_OBS_TIME de
),
CTE_COUNT_T2DM AS (
	SELECT '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		4 AS STAT_ORDER_NUM,
		'1+ Dx of T2DM <= Index' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_GT_365_OBS_TIME)) AS CUMM_LOSS
	FROM CTE_T2DM
),
CTE_COUNT_T2DM_BROAD_NARROW  AS (
	SELECT '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		5 AS STAT_ORDER_NUM,
		'No T1DM and Secondary Diabetes (Broad: <= Index,  Narrow: <= End of Observable Time)' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_T2DM)) AS CUMM_LOSS
	FROM CTE_T2DM_BROAD_NARROW
),
CTE_COUNT_INSULIN_PRIOR AS (
	SELECT '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		6 AS STAT_ORDER_NUM,
		'No Insulin Monotherapy (Broad: N/A, Narrow: Exclude)' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_T2DM_BROAD_NARROW)) AS CUMM_LOSS
	FROM CTE_INSULIN_PRIOR
),
CTE_COUNT_AGE AS (
	SELECT '@db.name' AS DB,
		@cohortID AS COHORT_ID,
		'@drugOfInterest' AS COHORT_OF_INTEREST,
		'@t2dm' AS T2DM,
		7 AS STAT_ORDER_NUM,
		'Age (Broad: >=0, Narrow: >=40)' AS STAT_TYPE,
		COUNT_BIG(DISTINCT PERSON_ID) AS STAT,
		(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_EXPOSURE_OF_INTEREST)) AS STAT_PCT,
		1-(COUNT_BIG(DISTINCT PERSON_ID)*1.00 / (SELECT STAT FROM CTE_COUNT_INSULIN_PRIOR)) AS CUMM_LOSS
	FROM CTE_AGE
)
SELECT *
INTO #TEMP_RESULTS
FROM (
  SELECT *
  FROM CTE_COUNT_EXPOSURE_OF_INTEREST
  UNION ALL
  SELECT *
  FROM CTE_COUNT_AFTER_APRIL
  UNION ALL
  SELECT *
  FROM CTE_COUNT_GT_365_OBS_TIME
  UNION ALL
  SELECT *
  FROM CTE_COUNT_T2DM
  UNION ALL
  SELECT *
  FROM CTE_COUNT_T2DM_BROAD_NARROW
  UNION ALL
  SELECT *
  FROM CTE_COUNT_INSULIN_PRIOR
  UNION ALL
  SELECT *
  FROM CTE_COUNT_AGE
) z;

INSERT INTO @target_database_schema.@target_table
SELECT *
FROM #TEMP_RESULTS;
