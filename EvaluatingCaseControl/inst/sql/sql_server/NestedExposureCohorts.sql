/************************************************************************
Copyright 2018 Observational Health Data Sciences and Informatics

This file is part of EvaluatingCaseControl

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/
SELECT nested_exposure_id AS cohort_definition_id,
	exposure.subject_id,
	exposure.cohort_start_date,
	exposure.cohort_end_date
INTO #temp_cohorts
FROM @target_database_schema.@target_cohort_table exposure
INNER JOIN @target_database_schema.@target_cohort_table nesting_cohort
ON exposure.subject_id = nesting_cohort.subject_id
AND exposure.cohort_start_date >= nesting_cohort.cohort_start_date
AND DATEADD(DAY, -365, exposure.cohort_start_date) <= nesting_cohort.cohort_start_date
INNER JOIN #nested_exposures nested_exposures
ON exposure.cohort_definition_id = nested_exposures.exposure_id
AND nesting_cohort.cohort_definition_id = nested_exposures.nesting_id;

INSERT INTO  @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
SELECT cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
FROM #temp_cohorts;

TRUNCATE TABLE #temp_cohorts;

DROP TABLE #temp_cohorts;