IF OBJECT_ID('@target_database_schema.@target_table') IS NOT NULL
  DROP TABLE @target_database_schema.@target_table;

CREATE TABLE @target_database_schema.@target_table (
  CODE_LIST_NAME          VARCHAR(500),
  CODE_LIST_DESCRIPTION   VARCHAR(500),
  CONCEPT_ID              BIGINT,
  CONCEPT_NAME            VARCHAR(500)
);

INSERT INTO @target_database_schema.@target_table (CODE_LIST_NAME, CODE_LIST_DESCRIPTION, CONCEPT_ID, CONCEPT_NAME)
SELECT *
FROM (

   SELECT  DISTINCT
  	'DKA' AS CODE_LIST_NAME,
  	'Diabetic Ketoacidosis' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	443727,   /*Diabetic ketoacidosis*/
    4009303,  /*Diabetic ketoacidosis without coma*/
    439770,   /*Ketoacidosis in type 1 diabetes mellitus*/
    443734   /*Ketoacidosis in type 2 diabetes mellitus*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'SGLT2i' AS CODE_LIST_NAME,
  	'Sodium-Glucose Co-Transporter 2 Inhibitors' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	45774751, /*empagliflozin*/
  	44785829, /*dapagliflozin*/
  	43526465  /*canagliflozin*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'DPP-4i' AS CODE_LIST_NAME,
  	'Dipeptidyl Peptidase-4 Inhibitors' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1580747,	/*sitagliptin*/
  	43013884,	/*alogliptin*/
  	19122137,	/*vildagliptin*/
  	40239216,	/*Linagliptin*/
  	40166035	/*saxagliptin*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'GLP-1a' AS CODE_LIST_NAME,
  	'Glucagon-Like Peptide-1 Agonists' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	44816332,	/*albiglutide*/
  	45774435,	/*dulaglutide*/
  	1583722,	/*exenatide*/
  	40170911,	/*liraglutide*/
  	44506754	/*Lixisenatide*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'SU' AS CODE_LIST_NAME,
  	'Sulfonylureas' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1530014,	/*Acetohexamide*/
  	19033498,	/*Carbutamide*/
  	1594973,	/*Chlorpropamide*/
  	19001409,	/*glibornuride*/
  	19059796,	/*Gliclazide*/
  	1597756,	/*glimepiride*/
  	1560171,	/*Glipizide*/
  	19097821,	/*gliquidone*/
  	1559684,	/*Glyburide*/
  	19001441,	/*glymidine*/
  	1502809,	/*Tolazamide*/
  	1502855		/*Tolbutamide*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'TZDs' AS CODE_LIST_NAME,
  	'Thiazolidinedione' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1525215,	/*pioglitazone*/
  	1547504,	/*rosiglitazone*/
  	1515249		/*troglitazone*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'Insulin' AS CODE_LIST_NAME,
  	'Insulin' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	21600713 /*INSULINS AND ANALOGUES*/
  )

  UNION ALL

  SELECT DISTINCT
  	'T1DM' AS CODE_LIST_NAME,
  	'Type 1 Diabetes Mellitus' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	435216,	/*Disorder due to type 1 diabetes mellitus*/
  	377821,	/*Neurological disorder associated with type 1 diabetes mellitus*/
  	318712,	/*Peripheral circulatory disorder associated with type 1 diabetes mellitu*/
  	200687,	/*Renal disorder associated with type 1 diabetes mellitus*/
  	201254	/*Type 1 diabetes mellitus*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'T2DM' AS CODE_LIST_NAME,
  	'Type 2 Diabetes Mellitus' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT c1
  WHERE c1.CONCEPT_ID IN (
  	192279,201530,201826,376065,376114,376683,376979,377552,378743,380096,380097,443729,443731,443732,443733,443734,443735,443767,4007943,4027121,4030664,4063043,4095288,4099216,4099217,4099651,4101478,4102176,4105172,4105173,4128221,4129519,4130162,4137220,4140466,4142579,4147577,4151946,4161670,4161671,4162095,4164174,4164175,4164176,4164632,4174977,4177050,4181588,4186542,4193704,4195043,4195044,4195045,4195498,4196141,4198296,4199039,4200875,4206115,4209538,4210128,4210129,4210872,4210874,4212435,4212441,4215961,4218499,4221487,4221495,4221933,4221962,4222415,4223463,4223734,4223739,4224419,4226121,4226238,4226798,4228443,4230254,4235260,4235261,4243625,4247107,4252356,4255399,4255400,4255401,4255402,4266041,4266042,4266637,4269870,4269871,4270049,4290822,4290823,4304377,4321756,4334884,4336000,4338900,4338901,36712670,36712686,36712687,36714116,36717156,37016163,37016349,37016354,37016356,37016357,37016358,37016768,37017221,37017432,37018728,37018912,40482458,43530656,43530685,43530689,43530690,43531010,43531559,43531562,43531564,43531566,43531577,43531578,43531588,43531597,43531608,43531616,43531651,43531653,44805628,45757065,45757075,45757255,45757277,45757278,45757280,45757363,45757392,45757435,45757444,45757445,45757446,45757447,45757449,45757450,45757474,45757499,45757798,45763582,45766052,45769828,45769835,45769836,45769872,45769875,45769888,45769889,45769890,45769894,45769905,45769906,45770830,45770831,45770832,45770880,45770881,45770883,45770928,45771064,45771072,45772019,45772060,45772914,45773064,46274058
  )
  AND c1.STANDARD_CONCEPT = 'S'

  UNION ALL

  SELECT DISTINCT
  	'Secondary Diabetes' AS CODE_LIST_NAME,
  	'Secondary Diabetes' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	195771 /*Secondary diabetes mellitus*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Other AHAs' AS CODE_LIST_NAME,
  	'Other Antihyperglycemic Agents' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1529331,	/*Acarbose*/
  	40164159,	/*Bromocriptine 0.8 MG*/
  	1510202,	/*miglitol*/
  	1502826,	/*nateglinide*/
  	1516766		/*repaglinide*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Canagliflozin' AS CODE_LIST_NAME,
  	'Canagliflozin' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	43526465	/*Canagliflozin*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Dapagliflozin' AS CODE_LIST_NAME,
  	'Dapagliflozin' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	44785829	/*dapagliflozin*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Empagliflozin' AS CODE_LIST_NAME,
  	'Empagliflozin' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	45774751	/*empagliflozin*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Metformin' AS CODE_LIST_NAME,
  	'Metformin' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1503297	/*metformin*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Nateglinide' AS CODE_LIST_NAME,
  	'Nateglinide' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1502826	/*Nateglinide*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Repaglinide' AS CODE_LIST_NAME,
  	'Repaglinide' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	1516766	/*Repaglinide*/
  )

  UNION ALL

  SELECT DISTINCT
  	'Non-Insulin T2DM Drug' AS CODE_LIST_NAME,
  	'Non-Insulin T2DM Drug' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	21600744,	/*BLOOD GLUCOSE LOWERING DRUGS, EXCL. INSULINS*/
	21500154	/*Oral Antidiabetic Agents*/
  )
  AND c1.CONCEPT_ID NOT IN (
    SELECT DESCENDANT_CONCEPT_ID
    FROM @vocabulary_schema.CONCEPT_ANCESTOR
    WHERE ANCESTOR_CONCEPT_ID IN (
    	730548,		/*Bromocriptine*/
    	1000979,	/*guar gum*/
    	1508439,	/*Mifepristone*/
    	1510202,	/*miglitol*/
    	19033909	/*Phenformin*/
    )
  )

  UNION ALL

  /*Based on 534*/
  /*https://sourcecode.jnj.com/projects/ITX-ASJ/repos/epi_534/browse/inst/settings/NegativeControls.csv*/
  SELECT  DISTINCT
  'Negative Control' AS CODE_LIST_NAME,
  'Negative Control' AS CODE_LIST_DESCRIPTION,
  c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT c1
  WHERE c1.CONCEPT_ID IN (
  	376707,	/*Acute conjunctivitis,Outcome*/
  	433753,	/*Alcohol abuse,Outcome*/
  	257007,	/*Allergic rhinitis,Outcome*/
  	442077,	/*Anxiety disorder,Outcome*/
  	436665,	/*Bipolar disorder,Outcome*/
  	380094,	/*Carpal tunnel syndrome,Outcome*/
  	255573,	/*Chronic obstructive lung disease,Outcome*/
  	257012,	/*Chronic sinusitis,Outcome*/
  	443617,	/*Conduct disorder,Outcome*/
  	134438,	/*Contact dermatitis,Outcome*/
  	78619,	/*Contusion of knee,Outcome*/
  	378752,	/*Corneal opacity,Outcome*/
  	--137063,	/*Corns and callus,Outcome*/  /*NO LONGER VALID*/
  	133228,	/*Dental caries,Outcome*/
  	134681,	/*Diffuse spasm of esophagus,Outcome*/
  	432251,	/*Disease caused by parasite,Outcome*/
  	378161,	/*Disorder of ear,Outcome*/
  	139057,	/*Disorder of oral soft tissues,Outcome*/
  	31057,	/*Disorder of pharynx,Outcome*/
  	138225,	/*Disorder of sebaceous gland,Outcome*/
  	440329,	/*Herpes zoster without complication,Outcome*/
  	441788,	/*Human papilloma virus infection,Outcome*/
  	140673,	/*Hypothyroidism,Outcome*/
  	374375,	/*Impacted cerumen,Outcome*/
  	139099,	/*Ingrowing nail,Outcome*/
  	436962,	/*Insomnia,Outcome*/
  	201322,	/*Internal hemorrhoids without complication,Outcome*/
  	132466,	/*Lumbar sprain,Outcome*/
  	255891,	/*Lupus erythematosus,Outcome*/
  	444100,	/*Mood disorder,Outcome*/
  	440374,	/*Obsessive-compulsive disorder,Outcome*/
  	380733,	/*Otalgia,Outcome*/
  	372328,	/*Otitis media,Outcome*/
  	4002650,	/*Plantar fasciitis,Outcome*/
  	373478,	/*Presbyopia,Outcome*/
  	436073,	/*Psychotic disorder,Outcome*/
  	438688,	/*Sarcoidosis,Outcome*/
  	432597,	/*Schizoaffective schizophrenia,Outcome*/
  	435783,	/*Schizophrenia,Outcome*/
  	372409,	/*Sciatica,Outcome*/
  	73562,	/*Solitary sacroiliitis,Outcome*/
  	133141,	/*Tinea pedis,Outcome*/
  	436070,	/*Vitamin D deficiency,Outcome*/
  	434008	/*White blood cell disorder,Outcome*/
  )
  AND c1.STANDARD_CONCEPT = 'S'

  UNION ALL

  SELECT  DISTINCT
  	'AHAs' AS CODE_LIST_NAME,
  	'AHAs' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	21600712 /*	DRUGS USED IN DIABETES*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'UTI' AS CODE_LIST_NAME,
  	'Urinary Tract Infections' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	81902 /*Urinary Tract Infectious Disease*/
  )

  UNION ALL

  SELECT  DISTINCT
  	'URI' AS CODE_LIST_NAME,
  	'Upper Respiratory Infections' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	257011,4181583
  )

  UNION ALL

  SELECT DISTINCT
  	'Surgery' AS CODE_LIST_NAME,
  	'Surgery' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT_ANCESTOR ca
  	JOIN @vocabulary_schema.CONCEPT c1
  		ON c1.CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID
  		AND c1.STANDARD_CONCEPT = 'S'
  WHERE ca.ANCESTOR_CONCEPT_ID IN (
  	2779047,2779014,2779020,2779026,2779052,2779029,2779011,4101626,44804816,2758572,2758573,2758574,2744552,2744558,2744554,2744560,2746493,2746495,2779569,2779571,2746502,2746504,2744543,2744549,2744545,2744551,2759841,2759843,2759845,2780336,2780543,2760583,2760584,2760585,2780332,2760574,2760575,2760576,2760580,2760581,2760582,2760586,44805396,2780803,2780806,2780809,2723360,2781596,2777853,2777863,2726370,2749127,2777818,2749133,2777834,2777828,2749336,2777831,2749121,2749115,4314251,3051281,44804737,4073393,45766037,2778116,2778101,2778106,2778111,2723963,2723962
  )
  AND c1.CONCEPT_ID NOT IN (
    SELECT DESCENDANT_CONCEPT_ID
    FROM @vocabulary_schema.CONCEPT_ANCESTOR
    WHERE ANCESTOR_CONCEPT_ID IN (
    	3004798,3038602,40757123
    )
  )

  UNION ALL

  SELECT  DISTINCT
  	'Glucose' AS CODE_LIST_NAME,
  	'Glucose Measurements' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT c1
  WHERE c1.CONCEPT_ID IN (
    2212367,3004077,3004501,3021737,3034962,3035250,3037110,3037187,44816672
  )
  AND c1.STANDARD_CONCEPT = 'S'

  UNION ALL

  SELECT  DISTINCT
  	'Bicarbonate' AS CODE_LIST_NAME,
  	'Bicarbonate Measurements' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT c1
  WHERE c1.CONCEPT_ID IN (
    3006576,3008152,3015473,3016293,3027273
  )
  AND c1.STANDARD_CONCEPT = 'S'

  UNION ALL

  SELECT  DISTINCT
  	'Ketone' AS CODE_LIST_NAME,
  	'Ketone Measurements' AS CODE_LIST_DESCRIPTION,
  	c1.CONCEPT_ID, c1.CONCEPT_NAME
  FROM @vocabulary_schema.CONCEPT c1
  WHERE c1.CONCEPT_ID IN (
		2212180,3023539,3035350
  )
  AND c1.STANDARD_CONCEPT = 'S'

) z;

INSERT INTO @target_database_schema.@target_table (CODE_LIST_NAME, CODE_LIST_DESCRIPTION, CONCEPT_ID, CONCEPT_NAME)
SELECT 'Insulinotropic AHAs' AS CODE_LIST_NAME,
  CODE_LIST_NAME AS CONCEPT_LIST_DESCRIPTION,
  CONCEPT_ID, CONCEPT_NAME
FROM @target_database_schema.@target_table
WHERE CODE_LIST_NAME IN (
  'DPP-4i','GLP-1a','SU','Nateglinide','Repaglinide'
);

INSERT INTO @target_database_schema.@target_table (CODE_LIST_NAME, CODE_LIST_DESCRIPTION, CONCEPT_ID, CONCEPT_NAME)
SELECT 'High-Dose SGLT2i' AS CODE_LIST_NAME,
	z.CODE_LIST_DESCRIPTION,
	z.CONCEPT_ID, z.CONCEPT_NAME
FROM (
	SELECT *
	FROM @target_database_schema.@target_table cl
		JOIN @vocabulary_schema.DRUG_STRENGTH ds
			ON ds.DRUG_CONCEPT_ID = cl.CONCEPT_ID
			AND ds.INGREDIENT_CONCEPT_ID = 43526465 /*Cana*/
			AND ds.AMOUNT_VALUE = 300
	WHERE CODE_LIST_NAME = 'Canagliflozin'
	UNION ALL
	SELECT *
	FROM @target_database_schema.@target_table cl
		JOIN @vocabulary_schema.DRUG_STRENGTH ds
			ON ds.DRUG_CONCEPT_ID = cl.CONCEPT_ID
			AND ds.INGREDIENT_CONCEPT_ID = 44785829 /*Dapa*/
			AND ds.AMOUNT_VALUE = 10
	WHERE CODE_LIST_NAME = 'Dapagliflozin'
	UNION ALL
	SELECT *
	FROM @target_database_schema.@target_table cl
		JOIN @vocabulary_schema.DRUG_STRENGTH ds
			ON ds.DRUG_CONCEPT_ID = cl.CONCEPT_ID
			AND ds.INGREDIENT_CONCEPT_ID = 45774751 /*EMPA*/
			AND ds.AMOUNT_VALUE = 25
	WHERE CODE_LIST_NAME = 'Empagliflozin'
) z;


CREATE INDEX IDX_CONCEPT_LIST ON @target_database_schema.@target_table
 (CODE_LIST_NAME, CONCEPT_ID);
