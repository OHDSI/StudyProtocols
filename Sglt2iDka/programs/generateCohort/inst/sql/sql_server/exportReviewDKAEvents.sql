{@i == 1}?{
  IF OBJECT_ID('@target_database_schema.@target_table') IS NOT NULL
    DROP TABLE @target_database_schema.@target_table;

  CREATE TABLE @target_database_schema.@target_table (
    DB  VARCHAR(10),
    COHORT_DEFINITION_ID  INT,
    COHORT_OF_INTEREST  VARCHAR(500),
    T2DM  VARCHAR(10),
    CENSOR  INT,
    STAT_ORDER_NUMBER INT,
    STAT_TYPE   VARCHAR(200),
    STAT  INT,
    STAT_PCT  FLOAT,
    CUMM_LOSS FLOAT
  );

}

IF OBJECT_ID('tempdb..#TEMP_DATA') IS NOT NULL
  DROP TABLE tempdb..#TEMP_DATA;

WITH CTE_COHORT_UNIVERSE AS (
  /*Find People and their Index Date*/
	SELECT c.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR,
		c.SUBJECT_ID, c.COHORT_START_DATE AS INDEX_DATE
	FROM @target_database_schema.@cohort_universe cu
		JOIN @target_database_schema.@cohort_table c
			ON c.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
	WHERE EXPOSURE_COHORT = 1
	AND FU_STRAT_ITT_PP0DAY = 1
),
CTE_DKA_30_PRIOR_INDEX AS (
  /*Look for the DKA just prior*/
	SELECT
		cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR, cu.SUBJECT_ID, cu.INDEX_DATE,
		c.COHORT_DEFINITION_ID AS DKA_PRE_COHORT_DEFINITION_ID,
		MAX(c.COHORT_START_DATE) AS DKA_30_PRIOR_INDEX_DATE
	FROM CTE_COHORT_UNIVERSE cu
		JOIN @target_database_schema.@cohort_table c
			ON c.SUBJECT_ID = cu.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID IN (
				200, /*DKA IP/ER*/
				201 /*DKA IP*/
			)
			AND c.COHORT_START_DATE BETWEEN DATEADD(dd,-30,cu.INDEX_DATE) AND cu.INDEX_DATE
	GROUP BY cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR, cu.SUBJECT_ID, cu.INDEX_DATE, c.COHORT_DEFINITION_ID
),
CTE_DKA_WITHIN_30_DAYS AS (
  /*Now look for the DKA just after index, but within 30 days of prior DKA*/
	SELECT d.*,
		c.COHORT_DEFINITION_ID AS DKA_POST_COHORT_DEFINITION_ID,
		MIN(c.COHORT_START_DATE) AS DKA_POST_INDEX_DATE
	FROM CTE_DKA_30_PRIOR_INDEX d
		JOIN @target_database_schema.@cohort_table c
			ON c.SUBJECT_ID = d.SUBJECT_ID
			AND c.COHORT_DEFINITION_ID IN (
				900, /*ALL DKA IP/ER*/
				901 /*ALL DKA IP*/
			)
			AND c.COHORT_START_DATE > d.INDEX_DATE /*After index*/
			AND c.COHORT_START_DATE BETWEEN DATEADD(dd,1,d.DKA_30_PRIOR_INDEX_DATE) AND DATEADD(dd,30,d.DKA_30_PRIOR_INDEX_DATE) /*within 30 days of index prior DKA*/
	GROUP BY d.COHORT_DEFINITION_ID, d.COHORT_OF_INTEREST, d.T2DM, d.CENSOR, d.SUBJECT_ID, d.INDEX_DATE,
		d.DKA_PRE_COHORT_DEFINITION_ID, d.DKA_30_PRIOR_INDEX_DATE, c.COHORT_DEFINITION_ID
)
SELECT *
INTO #TEMP_DATA
FROM (

  SELECT '@dbID' AS DB,
  	COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR,
  	1 AS STAT_ORDER_NUMBER,
  	'Total N' AS STAT_TYPE,
  	COUNT(DISTINCT SUBJECT_ID) AS STAT,
  	1.00 AS STAT_PCT,
  	0.00 AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE
  GROUP BY COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR

  UNION ALL

  SELECT '@dbID' AS DB,
  	cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR,
  	2 AS STAT_ORDER_NUMBER,
  	'DKA IP/ER 30 days prior to index' AS STAT_TYPE,
  	CASE WHEN COUNT(DISTINCT i.SUBJECT_ID) IS NULL THEN 0 ELSE COUNT(DISTINCT i.SUBJECT_ID) END AS STAT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE COUNT(DISTINCT i.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS STAT_PCT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE 1 - COUNT(DISTINCT i.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE cu
  	LEFT OUTER JOIN CTE_DKA_30_PRIOR_INDEX i
  		ON i.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i.SUBJECT_ID = cu.SUBJECT_ID
  		AND i.DKA_PRE_COHORT_DEFINITION_ID = 200
  GROUP BY cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR

  UNION ALL

  SELECT '@dbID' AS DB,
  	cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR,
  	3 AS STAT_ORDER_NUMBER,
  	'DKA IP/ER cases post-index but within 30 days after a pre-index event' AS STAT_TYPE,
  	CASE WHEN COUNT(DISTINCT i2.SUBJECT_ID) IS NULL THEN 0 ELSE COUNT(DISTINCT i2.SUBJECT_ID) END AS STAT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE COUNT(DISTINCT i2.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS STAT_PCT,
  	CASE WHEN COUNT(DISTINCT i.SUBJECT_ID) = 0 THEN 0 ELSE 1 - COUNT(DISTINCT i2.SUBJECT_ID)*1.0 / COUNT(DISTINCT i.SUBJECT_ID) END AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE cu
  	LEFT OUTER JOIN CTE_DKA_30_PRIOR_INDEX i
  		ON i.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i.SUBJECT_ID = cu.SUBJECT_ID
  		AND i.DKA_PRE_COHORT_DEFINITION_ID = 200
  	LEFT OUTER JOIN CTE_DKA_WITHIN_30_DAYS i2
  		ON i2.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i2.SUBJECT_ID = cu.SUBJECT_ID
  		AND i2.DKA_PRE_COHORT_DEFINITION_ID = 200
  		AND i2.DKA_POST_COHORT_DEFINITION_ID = 900
  GROUP BY cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR

  UNION ALL

  SELECT '@dbID' AS DB,
  	COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR,
  	4 AS STAT_ORDER_NUMBER,
  	'Total N' AS STAT_TYPE,
  	COUNT(DISTINCT SUBJECT_ID) AS STAT,
  	1.00 AS STAT_PCT,
  	0.00 AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE
  GROUP BY COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR

  UNION ALL

  SELECT '@dbID' AS DB,
  	cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR,
  	5 AS STAT_ORDER_NUMBER,
  	'DKA IP 30 days prior to index' AS STAT_TYPE,
  	CASE WHEN COUNT(DISTINCT i.SUBJECT_ID) IS NULL THEN 0 ELSE COUNT(DISTINCT i.SUBJECT_ID) END AS STAT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE COUNT(DISTINCT i.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS STAT_PCT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE 1 - COUNT(DISTINCT i.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE cu
  	LEFT OUTER JOIN CTE_DKA_30_PRIOR_INDEX i
  		ON i.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i.SUBJECT_ID = cu.SUBJECT_ID
  		AND i.DKA_PRE_COHORT_DEFINITION_ID = 201
  GROUP BY cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR

  UNION ALL

  SELECT '@dbID' AS DB,
  	cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR,
  	6 AS STAT_ORDER_NUMBER,
  	'DKA IP cases post-index but within 30 days after a pre-index event' AS STAT_TYPE,
  	CASE WHEN COUNT(DISTINCT i2.SUBJECT_ID) IS NULL THEN 0 ELSE COUNT(DISTINCT i2.SUBJECT_ID) END AS STAT,
  	CASE WHEN COUNT(DISTINCT cu.SUBJECT_ID) = 0 THEN 0 ELSE COUNT(DISTINCT i2.SUBJECT_ID)*1.0 / COUNT(DISTINCT cu.SUBJECT_ID) END AS STAT_PCT,
  	CASE WHEN COUNT(DISTINCT i.SUBJECT_ID) = 0 THEN 0 ELSE 1 - COUNT(DISTINCT i2.SUBJECT_ID)*1.0 / COUNT(DISTINCT i.SUBJECT_ID) END AS CUMM_LOSS
  FROM CTE_COHORT_UNIVERSE cu
  	LEFT OUTER JOIN CTE_DKA_30_PRIOR_INDEX i
  		ON i.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i.SUBJECT_ID = cu.SUBJECT_ID
  		AND i.DKA_PRE_COHORT_DEFINITION_ID = 201
  	LEFT OUTER JOIN CTE_DKA_WITHIN_30_DAYS i2
  		ON i2.COHORT_DEFINITION_ID = cu.COHORT_DEFINITION_ID
  		AND i2.SUBJECT_ID = cu.SUBJECT_ID
  		AND i2.DKA_PRE_COHORT_DEFINITION_ID = 201
  		AND i2.DKA_POST_COHORT_DEFINITION_ID = 901
  GROUP BY cu.COHORT_DEFINITION_ID, cu.COHORT_OF_INTEREST, cu.T2DM, cu.CENSOR
) z;

INSERT INTO @target_database_schema.@target_table (DB, COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR, STAT_ORDER_NUMBER, STAT_TYPE, STAT, STAT_PCT, CUMM_LOSS)
SELECT DB, COHORT_DEFINITION_ID, COHORT_OF_INTEREST, T2DM, CENSOR, STAT_ORDER_NUMBER, STAT_TYPE, STAT, STAT_PCT, CUMM_LOSS
FROM #TEMP_DATA;