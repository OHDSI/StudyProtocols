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
{DEFAULT @cdm_database_schema = 'cdm_data'}
{DEFAULT @top_n = 5}
{DEFAULT @cdm_version = '4'}

SELECT *
FROM (
	SELECT concept_code, 
	    concept_name, 
		person_count,
		inpatient,
		ROW_NUMBER() OVER (
			PARTITION BY concept_code, inpatient ORDER BY - person_count
			) AS row_num
	FROM (
		SELECT numerator.*,
			drug_class.concept_code
		FROM #numerator numerator
		INNER JOIN @cdm_database_schema.concept_ancestor
			ON numerator.concept_id = descendant_concept_id
		INNER JOIN @cdm_database_schema.concept drug_class
			ON ancestor_concept_id = drug_class.concept_id
{@cdm_version == 4} ? {
	    WHERE drug_class.vocabulary_id = 21
} : {
	    WHERE drug_class.vocabulary_id = 'ATC'
}
			AND LEN(drug_class.concept_code) = 1
		) temp1
	) temp2
WHERE row_num <= @top_n
