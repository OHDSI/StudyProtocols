/************************************************************************
Copyright 2016 Observational Health Data Sciences and Informatics

This file is part of KeppraAngioedema

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
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT concepts.ancestor_concept_id AS cohort_definition_id,
	condition_occurrence.person_id AS subject_id,
	MIN(condition_start_date) AS cohort_start_date,
	MIN(condition_start_date) AS cohort_end_date
FROM @cdm_database_schema.condition_occurrence
INNER JOIN (
	SELECT ancestor_concept_id,
		descendant_concept_id
	FROM @cdm_database_schema.concept_ancestor
	WHERE ancestor_concept_id IN (75344, 312437, 4324765, 318800, 197684, 437409, 434056, 261880, 380731, 433516, 437833, 319843, 195562, 195588, 432851, 378425, 433440, 43531027, 139099, 79903, 435459, 197320, 433163, 4002650, 197032, 141932, 372409, 137057, 80665, 200588, 316993, 80951, 134453, 133228, 133834, 80217, 442013, 313792, 75576, 314054, 195873, 198199, 134898, 140480, 200528, 193016, 321596, 29735, 138387, 4193869, 73842, 193326, 4205509, 78804, 141663, 376103, 4311499, 136773, 4291005, 440358, 134461, 192367, 261326, 74396, 78786, 374914, 260134, 196162, 253796, 133141, 136937, 192964, 194997, 440328, 258180, 441284, 440448, 80494, 199876, 376415, 317585, 441589, 140949, 432436, 256722, 378160, 373478, 436027, 443344, 192606, 434926, 439080, 29056, 199067, 77650, 440814, 198075, 79072, 317109, 378424)
	) concepts
	ON condition_occurrence.condition_concept_id = concepts.descendant_concept_id
INNER JOIN (
	SELECT DISTINCT subject_id
	FROM @target_database_schema.@target_cohort_table
	WHERE cohort_definition_id IN (1, 2)
	) study_pop
	ON condition_occurrence.person_id = study_pop.subject_id
GROUP BY concepts.ancestor_concept_id,
	condition_occurrence.person_id;
