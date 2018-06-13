/************************************************************************
Copyright 2018 Observational Health Data Sciences and Informatics

This file is part of SkeletonCompartiveEffectStudy

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
INSERT INTO @target_database_schema.@target_cohort_table (
	subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT person_id AS subject_id,
	ancestor_concept_id AS cohort_definition_id,
	condition_era_start_date AS cohort_start_date,
	condition_era_end_date AS cohort_end_date
FROM @cdm_database_schema.condition_era
INNER JOIN @cdm_database_schema.concept_ancestor
	ON condition_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (@outcome_ids);

