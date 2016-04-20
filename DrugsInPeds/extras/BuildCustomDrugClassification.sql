/************************************************************************
@file BuildCustomDrugClassification.sql

Copyright 2016 Observational Health Data Sciences and Informatics

This file is part of DrugsInPeds

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

IF OBJECT_ID('tempdb..#my_drug_classification', 'U') IS NOT NULL
	DROP TABLE #my_drug_classification;

CREATE TABLE #my_drug_classification (
	concept_id INT,
	concept_name VARCHAR(MAX),
	vocabulary_id VARCHAR(6),
	class_id VARCHAR(MAX)
	);

-- Antidiabetic drugs:
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antidiabetic drugs' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'A10'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'A10'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)
	) tmp;

-- Analgesics (inc. NSAIDs)
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Analgesics (inc. NSAIDs)' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code IN ('N02', 'M01A')
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE (
			LEFT(concept_code, 3) = 'N02'
			OR LEFT(concept_code, 4) = 'M01A'
			)
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND (
			ndfrt2.concept_name LIKE '%opioid%'
			OR ndfrt2.concept_name = 'Nonsteroidal Anti-inflammatory Drug'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	WHERE rxnorm.concept_name = 'loxoprofen'
	AND rxnorm.concept_class_id = 'Ingredient'
	AND rxnorm.vocabulary_id = 'RxNorm'
	) tmp;

-- Corticosteroids:
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Corticosteroid' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'C05AA'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 5) = 'C05AA'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name = 'Corticosteroid'
	) tmp;

-- Psychotherapeutic agents
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Psychotherapeutic agents' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code IN ('N05A', 'N06A')
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 4) IN ('N05A', 'N06A')
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name IN ('Atypical Antipsychotic', 'Typical Antipsychotic', 'Serotonin Reuptake Inhibitor', 'Tricyclic Antidepressant', 'Serotonin and Norepinephrine Reuptake Inhibitor', 'Monoamine Oxidase Inhibitor')
	) tmp;

-- Antiinfectives (excluding antibiotics)
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antiinfectives (excluding antibiotics)' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
	    AND LEN(atc.concept_code) = 3
		AND LEFT(atc.concept_code, 1) = 'J'
		AND atc.concept_code != 'J01'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 1) = 'J'
		AND LEFT(concept_code, 3) != 'J01'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND (
			ndfrt2.concept_name LIKE 'Antimicrobial'
			OR ndfrt2.concept_name LIKE '%Vaccine'
			OR ndfrt2.concept_name LIKE '%Antifungal'
			)
	) tmp;
	
-- Antibiotics
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antibiotics' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'J01'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'J01'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name LIKE '%Antibacterial'
	) tmp;

-- Antihistamines
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antihistamines' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'R06'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'R06'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name IN ('Histamine-1 Receptor Antagonist', 'Histamine-1 Receptor Inhibitor')
	) tmp;

-- Contraceptives
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Contraceptives' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'G03A'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 4) = 'G03A'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)
	) tmp;

-- Adrenergics
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Adrenergics' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'R03C'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 4) = 'R03C'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name LIKE '%adrenergic%'
	) tmp;

-- Central nervous system stimulants
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Central nervous system stimulants' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'N06B'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 4) = 'N06B'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name = 'Central Nervous System Stimulant'
	) tmp;

-- Antineoplastic and immunomodulating agents
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antineoplastic and immunomodulating agents' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'L'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'
		AND ingredient.concept_id != 1118084	-- celecoxib

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 1) = 'L'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)
	) tmp;

-- Mucolytics
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Mucolytics' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'R05CB'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 5) = 'R05CB'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name = 'Mucolytic'
	) tmp;

-- Antithrombotic agents
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antithrombotic agents' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'B01'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'B01'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)
	) tmp;

-- Diuretics
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Diuretics' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'C03'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'C03'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name LIKE '%Diuretic'
	) tmp;
	
	
-- Antiepileptics
INSERT INTO #my_drug_classification (
	concept_id,
	concept_name,
	vocabulary_id,
	class_id
	)
SELECT *,
	'Antiepileptics' AS class_id
FROM (
	SELECT ingredient.concept_id,
		ingredient.concept_name,
		ingredient.vocabulary_id
	FROM concept atc
	INNER JOIN concept_ancestor
		ON atc.concept_id = ancestor_concept_id
	INNER JOIN concept ingredient
		ON ingredient.concept_id = descendant_concept_id
	WHERE atc.vocabulary_id = 'ATC'
		AND atc.concept_code = 'N03A'
		AND ingredient.vocabulary_id = 'RxNorm'
		AND ingredient.concept_class_id = 'Ingredient'

	UNION

	SELECT concept_id,
		concept_name,
		vocabulary_id
	FROM concept ingredient
	WHERE LEFT(concept_code, 3) = 'N03A'
		AND LEN(concept_code) = 7
		AND vocabulary_id = 'ATC'
		AND concept_id NOT IN (
			SELECT concept_id_1
			FROM concept_relationship
			WHERE relationship_id = 'ATC - RxNorm'
			)

	UNION

	SELECT rxnorm.concept_id,
		rxnorm.concept_name,
		rxnorm.vocabulary_id
	FROM concept rxnorm
	INNER JOIN concept_relationship rxnorm_to_ndfrt
		ON rxnorm_to_ndfrt.concept_id_1 = rxnorm.concept_id
	INNER JOIN concept ndfrt1
		ON rxnorm_to_ndfrt.concept_id_2 = ndfrt1.concept_id
	INNER JOIN concept_relationship ndfrt_to_class
		ON ndfrt_to_class.concept_id_1 = ndfrt1.concept_id
	INNER JOIN concept ndfrt2
		ON ndfrt_to_class.concept_id_2 = ndfrt2.concept_id
	WHERE rxnorm_to_ndfrt.relationship_id = 'RxNorm - NDFRT eq'
		AND rxnorm_to_ndfrt.invalid_reason IS NULL
		AND ndfrt_to_class.invalid_reason IS NULL
		AND ndfrt1.vocabulary_id = 'NDFRT'
		AND ndfrt1.invalid_reason IS NULL
		AND ndfrt2.vocabulary_id = 'NDFRT'
		AND ndfrt2.invalid_reason IS NULL
		AND ndfrt2.concept_class_id = 'Pharmacologic Class'
		AND ndfrt2.concept_name LIKE 'Anti-epileptic Agent'
	) tmp;
