{DEFAULT @max_gap = 0}

-- Select APAP exposures, set length to 7/4 times provided length
IF OBJECT_ID('tempdb..#apap_exposure', 'U') IS NOT NULL
	DROP TABLE #apap_exposure;
	
--HINT DISTRIBUTE_ON_KEY(person_id)	
SELECT person_id,
	ancestor_concept_id AS concept_id,
	drug_exposure_start_date AS exposure_start_date,
	--DATEADD(DAY, ROUND(days_supply * 7/4, 0), drug_exposure_start_date) AS exposure_end_date
	--DATEADD(DAY, days_supply, drug_exposure_start_date) AS exposure_end_date
	CASE 
		WHEN DATEADD(DAY, days_supply + 30, drug_exposure_start_date) > DATEADD(DAY, ROUND(days_supply * 7/4, 0), drug_exposure_start_date) 
		THEN DATEADD(DAY, days_supply + 30, drug_exposure_start_date)
		ELSE DATEADD(DAY, ROUND(days_supply * 7/4, 0), drug_exposure_start_date)
		END AS exposure_end_date
INTO #apap_exposure
FROM @cdm_database_schema.drug_exposure
INNER JOIN @cdm_database_schema.concept_ancestor
	ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id = 1125315 -- Acetaminophen
	AND days_supply IS NOT NULL;
	
-- Create eras from exposures:
IF OBJECT_ID('tempdb..#apap_era', 'U') IS NOT NULL
	DROP TABLE #apap_era;

--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT ends.person_id AS subject_id,
	ends.concept_id AS cohort_definition_id,
	MIN(exposure_start_date) AS cohort_start_date,
	ends.era_end_date AS cohort_end_date
INTO #apap_era
FROM (
	SELECT exposure.person_id,
		exposure.concept_id,
		exposure.exposure_start_date,
		MIN(events.end_date) AS era_end_date
	FROM #apap_exposure exposure
	JOIN (
		--cteEndDates
		SELECT person_id,
			concept_id,
			DATEADD(DAY, - 1 * @max_gap, event_date) AS end_date -- unpad the end date by @max_gap
		FROM (
			SELECT person_id,
				concept_id,
				event_date,
				event_type,
				MAX(start_ordinal) OVER (
					PARTITION BY person_id,
					concept_id ORDER BY event_date,
						event_type ROWS UNBOUNDED PRECEDING
					) AS start_ordinal,
				ROW_NUMBER() OVER (
					PARTITION BY person_id,
					concept_id ORDER BY event_date,
						event_type
					) AS overall_ord -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
			FROM (
				-- select the start dates, assigning a row number to each
				SELECT person_id,
					concept_id,
					exposure_start_date AS event_date,
					0 AS event_type,
					ROW_NUMBER() OVER (
						PARTITION BY person_id,
						concept_id ORDER BY exposure_start_date
						) AS start_ordinal
				FROM #apap_exposure
				
				UNION ALL
				
				-- add the end dates with NULL as the row number, padding the end dates by @max_gap to allow a grace period for overlapping ranges.
				SELECT person_id,
					concept_id,
					DATEADD(day, @max_gap, exposure_end_date),
					1 AS event_type,
					NULL
				FROM #apap_exposure
				) rawdata
			) events
		WHERE 2 * events.start_ordinal - events.overall_ord = 0
		) events
		ON exposure.person_id = events.person_id
			AND exposure.concept_id = events.concept_id
			AND events.end_date >= exposure.exposure_end_date
	GROUP BY exposure.person_id,
		exposure.concept_id,
		exposure.exposure_start_date
	) ends
GROUP BY ends.person_id,
	concept_id,
	ends.era_end_date;

-- Select cancer concepts (excluding nonmelanoma skin cancer):
IF OBJECT_ID('tempdb..#cancer', 'U') IS NOT NULL
	DROP TABLE #cancer;
	
SELECT descendant_concept_id AS concept_id
INTO #cancer
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id = 443392 -- Malignant neoplastic disease
	AND descendant_concept_id NOT IN (
		SELECT descendant_concept_id
		FROM @cdm_database_schema.concept_ancestor
		WHERE ancestor_concept_id IN(4111921, 4112752) -- Squamous cell carcinoma of skin, Basal cell carcinoma of skin
	);

-- Create eligible population, requiring washout period and no prior cancer:
IF OBJECT_ID('tempdb..#eligible', 'U') IS NOT NULL
	DROP TABLE #eligible;

SELECT index_date.index_date,
	index_date.person_id,
	observation_period_end_date
INTO #eligible
FROM #index_date index_date
INNER JOIN @cdm_database_schema.observation_period
	ON index_date.person_id = observation_period.person_id
		AND index_date >= DATEADD(DAY, @washout_days, observation_period_start_date)
		AND index_date <= observation_period_end_date
LEFT JOIN @cdm_database_schema.condition_occurrence
	ON index_date.person_id = condition_occurrence.person_id
		AND condition_start_date <= index_date.index_date
		AND condition_concept_id IN (SELECT concept_id FROM #cancer)
WHERE condition_concept_id IS NULL;

-- Target cohort: continuously exposed for past 4 years
INSERT INTO @target_database_schema.@target_cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT CAST(1 AS INT) AS cohort_definition_id,
	eligible.person_id AS subject_id,
	index_date AS cohort_start_date,
	observation_period_end_date AS cohort_end_date
FROM #eligible eligible
INNER JOIN #apap_era apap_era
	ON eligible.person_id = apap_era.subject_id
	AND cohort_end_date >= index_date
	AND cohort_start_date <= DATEADD(DAY, -@washout_days, index_date);
	
-- Comparator cohort: no exposure at all
INSERT INTO @target_database_schema.@target_cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT CAST(2 AS INT) AS cohort_definition_id,
	eligible.person_id AS subject_id,
	index_date AS cohort_start_date,
	observation_period_end_date AS cohort_end_date
FROM #eligible eligible
LEFT JOIN #apap_era apap_era
	ON eligible.person_id = apap_era.subject_id
	AND cohort_start_date <= index_date
WHERE apap_era.subject_id IS NULL;

