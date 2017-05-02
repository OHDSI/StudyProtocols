SELECT concept_id AS filter_concept_id,
	concept_name AS filter_concept_name,
	descendant_concept_id AS exposure_concept_id
FROM @cdm_database_schema.concept
INNER JOIN @cdm_database_schema.concept_ancestor
	ON concept_id = ancestor_concept_id
WHERE descendant_concept_id IN (@exposure_concept_ids)
	AND (
		vocabulary_id = 'ATC'
		OR ancestor_concept_id = descendant_concept_id
		OR concept_class_id = 'Procedure'
		)

UNION

SELECT concept_id AS filter_concept_id,
	concept_name AS filter_concept_name,
	ancestor_concept_id AS exposure_concept_id
FROM @cdm_database_schema.concept
INNER JOIN @cdm_database_schema.concept_ancestor
	ON concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (@exposure_concept_ids)

UNION

SELECT concept_id AS filter_concept_id,
  concept_name AS filter_concept_name,
  4327941 AS exposure_concept_id
FROM @cdm_database_schema.concept
WHERE concept_id IN (2007748, 4088889, 4151904, 43527989, 4118797, 4199042, 4262582, 2617478, 2007749, 2213547, 4118801, 4148398, 4196062, 4208314, 4234402, 43527904, 43527986, 45888237, 4143316, 43527905, 4119335, 4258834, 40482841, 45765516, 45887951, 2213554, 4079938, 4079939, 4128268, 44792695, 2007731, 4035812, 4083133, 4173581, 4242119, 4268909, 4080044, 4083706, 4117915, 4121662, 4225728, 44808677, 2007750, 2213546, 4103512, 44791916, 44808259, 46286330, 2213544, 4012488, 4079608, 4084195, 4119334, 4132436, 4299728, 4263758, 45887728, 2007730, 2007746, 2617477, 4128406, 4164790, 4219683, 4226276, 2213555, 4048385, 4083130, 4234476, 4249602, 4265313, 4295027, 2007763, 2108571, 4080048, 4221997, 4226275, 4278094, 45763911, 45889353, 2213548, 4114491, 4136352, 4137086, 4233181, 4327941, 43527987, 4048387, 4148765, 4202234, 4311943, 43527988, 43527990, 4028920, 4084202, 4100341, 4118798, 4118800, 4296166, 43527991, 4083129, 4083131, 4084201, 4179241, 46286403, 2007747, 4079500, 4126653, 4272803)

UNION

SELECT concept_id  AS filter_concept_id,
  concept_name AS filter_concept_name,
  4030840 AS exposure_concept_id
FROM @cdm_database_schema.concept
WHERE concept_id IN (2007727, 2007728, 2108578, 2108579, 2213552, 4004830, 4020981, 4030840, 4111663, 4210144, 4210145, 4332436, 4336318, 44508134)
