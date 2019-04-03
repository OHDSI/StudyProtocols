{@i == 1}?{
  IF OBJECT_ID('@target_database_schema.@target_table') IS NOT NULL
    DROP TABLE @target_database_schema.@target_table;

  CREATE TABLE @target_database_schema.@target_table (
    DB                    VARCHAR(10),
    COHORT_DEFINITION_ID  INT,
    COHORT_OF_INTEREST    VARCHAR(500),
    T2DM                  VARCHAR(10),
    CENSOR                INT,
    STAT_TYPE             VARCHAR(150),
    STAT_OTHER            VARCHAR(50)
  );
}

IF OBJECT_ID('tempdb..#qualified_events') IS NOT NULL
  DROP TABLE tempdb..#qualified_events;

IF OBJECT_ID('tempdb..#temp_results') IS NOT NULL
  DROP TABLE tempdb..#temp_results;


/******************************************************************************/
/*COLLECTING DATA WE DON'T ALREADY HAVE ON EXPOSURE COHORTS*/
/******************************************************************************/
/****Find people's age, gender, and observation period*/

--HINT DISTRIBUTE_ON_KEY(person_id)
SELECT 	'@dbID' AS DB,
		c.COHORT_DEFINITION_ID,
		u.COHORT_OF_INTEREST,
		u.T2DM,
		u.CENSOR,
		c.SUBJECT_ID AS PERSON_ID,
		c.COHORT_START_DATE,
		c.COHORT_END_DATE,
		p.GENDER_CONCEPT_ID AS GENDER_CONCEPT_ID,
		YEAR(COHORT_START_DATE) - p.YEAR_OF_BIRTH AS AGE,
		op.OBSERVATION_PERIOD_START_DATE,
		op.OBSERVATION_PERIOD_END_DATE
INTO #qualified_events
FROM @target_database_schema.@cohort_universe u
	JOIN @target_database_schema.@cohort_table c
		ON c.COHORT_DEFINITION_ID = u.COHORT_DEFINITION_ID
	JOIN @cdm_database_schema.PERSON p
		ON p.PERSON_ID = c.SUBJECT_ID
	JOIN @cdm_database_schema.OBSERVATION_PERIOD op
		ON op.PERSON_ID = c.SUBJECT_ID
		AND c.COHORT_START_DATE BETWEEN op.OBSERVATION_PERIOD_START_DATE AND op.OBSERVATION_PERIOD_END_DATE
WHERE u.EXPOSURE_COHORT = 1
AND u.FU_STRAT_ITT_PP0DAY = 1;

/*******************************************************************************/
/****BUILD TABLE****************************************************************/
/*******************************************************************************/

WITH CTE_COHORT AS (
	SELECT *
	FROM #qualified_events
)
/*AVG Age and SD*/
SELECT u.DB, u.COHORT_DEFINITION_ID,
  u.COHORT_OF_INTEREST, u.T2DM, u.CENSOR,
  'Age, mean (SD)' AS STAT_TYPE,
	CONCAT(
		CAST(CAST(AVG(u.AGE*1.0) AS DECIMAL(6,2)) AS VARCHAR(10)),
		' (',
		CAST(CAST(STDEV(u.AGE*1.0) AS DECIMAL(6,2)) AS VARCHAR(10)),
		')'
	) AS STAT_OTHER
INTO #TEMP_RESULTS
FROM CTE_COHORT u
GROUP BY u.DB, u.COHORT_DEFINITION_ID, u.COHORT_OF_INTEREST, u.T2DM, u.CENSOR;

INSERT INTO @target_database_schema.@target_table (DB, COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR, STAT_TYPE, STAT_OTHER)
SELECT DB, COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR, STAT_TYPE, STAT_OTHER
FROM #TEMP_RESULTS;
