/*********************************************************************************
# Copyright 2015 Observational Health Data Sciences and Informatics
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/
{DEFAULT @study_start_date = '19000101' } 
{DEFAULT @study_end_date = '21000101' } 
{DEFAULT @cdm_database_schema = 'dcm4' }
{DEFAULT @min_days_per_person = 180}

IF OBJECT_ID('tempdb..#study_population', 'U') IS NOT NULL
	DROP TABLE #study_population;
	
SELECT person_id
INTO #study_population
FROM (
	SELECT person_id,
		CASE 
			WHEN start_date < DATEADD(DAY, CAST(start_age * 365.25 AS INT), date_of_birth)
				THEN DATEADD(DAY, CAST(start_age * 365.25 AS INT), date_of_birth)
			ELSE start_date
			END AS start_date,
		CASE 
			WHEN end_date > DATEADD(DAY, CAST(end_age * 365.25 AS INT) - 1, date_of_birth)
				THEN DATEADD(DAY, CAST(end_age * 365.25 AS INT) - 1, date_of_birth)
			ELSE end_date
			END AS end_date
	FROM (
		SELECT person.person_id,
			DATEFROMPARTS(year_of_birth, ISNULL(month_of_birth, 7), ISNULL(day_of_birth, 1)) AS date_of_birth,
			CASE 
				WHEN CAST('@study_start_date' AS DATE) > observation_period_start_date
					THEN CAST('@study_start_date' AS DATE)
				ELSE observation_period_start_date
				END AS start_date,
			CASE 
				WHEN CAST('@study_end_date' AS DATE) < observation_period_end_date
					THEN CAST('@study_end_date' AS DATE)
				ELSE observation_period_end_date
				END AS end_date
		FROM @cdm_database_schema.person
		INNER JOIN @cdm_database_schema.observation_period
			ON person.person_id = observation_period.person_id
		WHERE CAST('@study_start_date' AS DATE) <= observation_period_end_date
			AND CAST('@study_end_date' AS DATE) >= observation_period_start_date
		) temp1
	INNER JOIN (
		SELECT MIN(start_age) AS start_age,
			MAX(end_age) AS end_age
		FROM #age_group
		) age_group
		ON start_date < DATEADD(DAY, CAST(end_age * 365.25 AS INT), date_of_birth)
			AND end_date >= DATEADD(DAY, CAST(start_age * 365.25 AS INT), date_of_birth)
	) temp2
WHERE DATEDIFF(DAY, start_date, end_date) >= @min_days_per_person;

