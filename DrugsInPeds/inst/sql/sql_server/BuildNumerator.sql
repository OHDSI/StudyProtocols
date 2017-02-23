/*********************************************************************************
# Copyright 2016 Observational Health Data Sciences and Informatics
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
{DEFAULT @study_start_date = '19000101'}
{DEFAULT @study_end_date = '21000101'}
{DEFAULT @split_by_age_group = TRUE} 
{DEFAULT @split_by_year = TRUE} 
{DEFAULT @split_by_drug_level = 'ingredient'} /* 'ingredient', 'class', or 'none' */
{DEFAULT @cdm_database_schema = 'cdm_data'}
{DEFAULT @restict_to_persons_with_data = FALSE}
{DEFAULT @cdm_version = '4'}

{@split_by_drug_level == 'ingredient'} ? {
SELECT DISTINCT drug_concept_id,
	concept_id,
	concept_name
INTO #drug_mapping
FROM (
	SELECT drug.concept_id AS drug_concept_id,
		ingredient.concept_id AS concept_id,
		ingredient.concept_name AS concept_name
	FROM @cdm_database_schema.concept_ancestor
	INNER JOIN @cdm_database_schema.concept drug
		ON concept_ancestor.descendant_concept_id = drug.concept_id
	INNER JOIN @cdm_database_schema.concept ingredient
		ON concept_ancestor.ancestor_concept_id = ingredient.concept_id
{@cdm_version == 4} ? {
	WHERE ingredient.concept_class = 'Ingredient'
		AND ingredient.vocabulary_id = 8
} : {
	WHERE ingredient.concept_class_id = 'Ingredient'
		AND ingredient.vocabulary_id = 'RxNorm'
}
	UNION
	
	SELECT concept_id AS drug_concept_id,
		concept_id AS concept_id,
		concept_name AS concept_name
	FROM @cdm_database_schema.concept
{@cdm_version == 4} ? {
	WHERE vocabulary_id = 21
} : {
	WHERE vocabulary_id = 'ATC'
}
		AND LEN(concept_code) = 7
	) temp;
} 

{@split_by_drug_level == 'class'} ? {
SELECT DISTINCT drug_concept_id,
	0 AS concept_id,
	concept_name
INTO #drug_mapping
FROM (
	SELECT drug.concept_id AS drug_concept_id,
		drug_classes.class_id AS concept_name
	FROM #drug_classes drug_classes
	INNER JOIN @cdm_database_schema.concept_ancestor
		ON concept_ancestor.ancestor_concept_id = drug_classes.concept_id
	INNER JOIN @cdm_database_schema.concept drug
		ON concept_ancestor.descendant_concept_id = drug.concept_id
	
	UNION
	
	SELECT drug_classes.concept_id AS drug_concept_id,
		drug_classes.class_id AS concept_name
	FROM #drug_classes drug_classes
	) TEMP;
} 

{@split_by_drug_level == 'none'} ? {
SELECT DISTINCT drug.concept_id AS drug_concept_id,
	0 AS concept_id,
	CAST('drug' AS VARCHAR) AS concept_name
INTO #drug_mapping
FROM @cdm_database_schema.concept drug
{@cdm_version == 4} ? {
WHERE (vocabulary_id = 21
	OR vocabulary_id = 8);
} : {
WHERE (vocabulary_id = 'ATC'
	OR vocabulary_id = 'RxNorm');
}
} 

SELECT concept_id,
	concept_name,
	COUNT_BIG(*) AS prescription_count,
	COUNT_BIG(DISTINCT person_id) AS person_count,
	inpatient
{@split_by_age_group} ? {	,age_group} 
{@split_by_year} ? {	,YEAR(drug_exposure_start_date) AS calendar_year}
{@split_by_gender} ? {	,gender_concept_id}
INTO #drug_counts
FROM (
	SELECT concept_id,
		concept_name,
		drug_exposure.person_id,
		drug_exposure_start_date,
		DATEDIFF(DAY, DATEFROMPARTS(year_of_birth, ISNULL(month_of_birth, 7), ISNULL(day_of_birth, 1)), drug_exposure_start_date) / 365.25 AS age,
		CASE 
		  WHEN {@cdm_version == 4} ? {place_of_service_concept_id} : {visit_concept_id} = 9201 THEN 1 ELSE 0 END AS inpatient,
		gender_concept_id
	FROM @cdm_database_schema.drug_exposure
{@restict_to_persons_with_data} ? {
	INNER JOIN #study_population study_population
	    ON drug_exposure.person_id = study_population.person_id
}
	INNER JOIN #drug_mapping drug_mapping
		ON drug_exposure.drug_concept_id = drug_mapping.drug_concept_id
	INNER JOIN @cdm_database_schema.person
		ON drug_exposure.person_id = person.person_id
    LEFT JOIN @cdm_database_schema.visit_occurrence
		ON drug_exposure.visit_occurrence_id = visit_occurrence.visit_occurrence_id
	WHERE drug_exposure_start_date > CAST('@study_start_date' AS DATE)
		AND drug_exposure_start_date < CAST('@study_end_date' AS DATE)	
	) filtered
INNER JOIN #age_group age_group
	ON age >= start_age
		AND age < end_age
GROUP BY concept_id,
	concept_name,
	inpatient
{@split_by_age_group} ? {	,age_group} 
{@split_by_year} ? {	,YEAR(drug_exposure_start_date)}
{@split_by_gender} ? {	,gender_concept_id}	
;

TRUNCATE TABLE #drug_mapping;
DROP TABLE #drug_mapping;
