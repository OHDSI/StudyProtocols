/*********************************************************************************
# Copyright 2014-2015 Observational Health Data Sciences and Informatics
#
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


/************************
script to count the number of stable diabetes mellitus type II patients.
last revised: April 10th, 2015
author:  Assaf Gottlieb / Converted to OHDSI by: Juan M. Banda
description:
1) Find diabetic patients.
2) Find patients on diabetes drugs where the drug_era > 60.
3) Find diabetic patients which have > 1 year of visits and > 5 visits all together.
4) Find diabetic patients with at least 5 relevant tests.
5) Lastly, count the intersection of all three tables.

*************************/

{DEFAULT @cdmSchema = 'cdmSchema'}  /*cdmSchema:  @cdmSchema*/
{DEFAULT @resultsSchema = 'resultsSchema'}  /*resultsSchema:  @resultsSchema*/
{DEFAULT @studyName = 'studyName'}



USE @resultsSchema;

--For Oracle: drop temp tables if they already exist
IF OBJECT_ID('#@studyName_patients_t2dm', 'U') IS NOT NULL
  DROP TABLE #@studyName_patients_t2dm;

IF OBJECT_ID('#@studyName_patients_t2dm_drug_era', 'U') IS NOT NULL
  DROP TABLE #@studyName_patients_t2dm_drug_era;

IF OBJECT_ID('#@studyName_patients_t2dm_visits', 'U') IS NOT NULL
  DROP TABLE #@studyName_patients_t2dm_visits;

IF OBJECT_ID('#@studyName_patients_t2dm_labs', 'U') IS NOT NULL
  DROP TABLE #@studyName_patients_t2dm_labs;

IF OBJECT_ID('@studyName_patients_t2dm_final_counts', 'U') IS NOT NULL
  DROP TABLE @studyName_patients_t2dm_final_counts;

-- select diabetic patient

create table #@studyName_patients_t2dm
(
        PERSON_ID bigint not null primary key
);

INSERT INTO #@studyName_patients_t2dm
SELECT DISTINCT(PERSON_ID) FROM @cdmSchema.dbo.condition_occurrence WHERE CONDITION_CONCEPT_ID IN (192279,201530,201820,201826,321822,376065,442793,443727,443729,443730,443731,443732,443733,443734,443735,443767,4096666,4232212,40482801);

-- select patients on diabetes drugs where the drug era>60
create table #@studyName_patients_t2dm_drug_era
(
        PERSON_ID bigint not null primary key
);
INSERT INTO #@studyName_patients_t2dm_drug_era
SELECT DISTINCT(PERSON_ID) FROM (SELECT person_id,drug_era_end_date,drug_era_start_date,DATEDIFF(dd,drug_era_start_date,drug_era_end_date) AS diff FROM @cdmSchema.dbo.drug_era AS d WHERE d.drug_concept_id IN (730548,1502809,1502826,1502855,1502905,1503297,1510202,1513849,1513876,1516766,1516976,1517998,1518148,1525215,1529331,1531601,1544838,1547504,1550023,1559684,1560171,1567198,1580747,1583722,1594973,1596914,1596977,1597756,2101744,3002156,3003887,3005951,3008238,3008898,3013407,3024004,3026756,3028116,3029288,3036979,3037202,3043693,19122121,21001760,21002404,21505856,40170911,40239216,40763602,43076942,43081327,43534218,45409536,45411491,45412549,45413106,45458578,45478868,45525124,45525125,45527176,45528159,45660034,45708536,45708808,45725291,45729478)) AS drug_eras WHERE drug_eras.diff >=60;

-- select diabetic patient which have > year of visits and >5 visits all together
create table #@studyName_patients_t2dm_visits
(
        PERSON_ID bigint not null primary key
);

INSERT INTO #@studyName_patients_t2dm_visits
SELECT DISTINCT(visits.PERSON_ID) FROM (SELECT co.person_id, COUNT(co.person_id) AS cnt,(MAX(condition_start_date)-MIN(condition_start_date)) AS diff FROM @cdmSchema.dbo.condition_occurrence AS co, #@studyName_patients_t2dm AS pd WHERE pd.PERSON_ID=co.person_id GROUP BY co.person_id) AS visits WHERE visits.cnt>5 AND visits.diff>=365;

-- select diabetic patients with at least 5 relevant tests;
create table #@studyName_patients_t2dm_labs
(
        PERSON_ID bigint not null primary key
);
INSERT INTO #@studyName_patients_t2dm_labs
SELECT labs.PERSON_ID FROM (SELECT pd.person_id, COUNT(pd.person_id) cnt FROM @cdmSchema.dbo.measurement AS me, #@studyName_patients_t2dm AS pd WHERE pd.PERSON_ID=me.person_id AND me.measurement_concept_id IN (4184637,4197971,40478875,2212393,42869630,3003309,40765129,40758583,3005673,3007263,40762352,3004410,3034639,40775446,40789263,4036846,4017760,4017758,4017759,4018318,4018315,4018316,4018317,4012477,4055970,4020705,4041723,4041724,4041725,4041726,4041697,4042759,4042760,4027514,4017078,4017083,4097900,4182052,4209254,4258832,4262447,4131376,4120298,4116187,4135437,4218282,4289453,4135545,4193853,4193854,4193855,4195213,4230393,4144235,4143633,4149386,4193852,4229586,4147408,4147409,4146454,4078281,4149883,4149519,4152669,4197835,4234879,4234906,4151548,4151414,4153111,4156660,4198718,4198719,4198731,4198732,4198733,4198742,4198743,4094447,4249006,4176733,4209122,4331286,40479799,40479401,40479425,40478875,40481341,40482666,40482677,40481772,40484114,40483659,40483205,40483242,40484115,40484139,40485034,40485039,40485040,40484575,40484576,44783612,4286945,43527958,42742308,2212367,2212366,2212365,2212364,2212363,2212362,2212361,2212360,2212359,2212357,40780315,40794531,43055733,43055732,43055731,43055730,40779918,40791680,40788043,40798340,40774146,40774132,40790800,40776789,40776788,40776787,40784303,40797623,40777227,40777130,40776614,40776580,40772354,40772353,40785880,40784079,40787440,40778494,40783462,40773846,40787210,40794213,40789172,40782598,40773470,40795740,40773453,40783312,40783311,40775129,40794942,44817325,40774498,40791243,40774707,40777686,40775314,40796577,40783867,40783863) GROUP BY pd.person_id) AS labs WHERE labs.cnt>5;

-- count the intersection of all three tables
create table @studyName_patients_t2dm_final_counts
(
        patient_counts bigint not null
);
INSERT INTO @studyName_patients_t2dm_final_counts
SELECT COUNT(de.PERSON_ID) FROM #@studyName_patients_t2dm_drug_era de, #@studyName_patients_t2dm_visits v, #@studyName_patients_t2dm_labs l WHERE l.PERSON_ID=v.PERSON_ID and v.PERSON_ID=de.PERSON_ID;


--For Oracle: cleanup temp tables:
TRUNCATE TABLE #@studyName_patients_t2dm;
DROP TABLE #@studyName_patients_t2dm;
TRUNCATE TABLE #@studyName_patients_t2dm_drug_era;
DROP TABLE #@studyName_patients_t2dm_drug_era;
TRUNCATE TABLE #@studyName_patients_t2dm_visits;
DROP TABLE #@studyName_patients_t2dm_visits;
TRUNCATE TABLE #@studyName_patients_t2dm_labs;
DROP TABLE #@studyName_patients_t2dm_labs;

SELECT patient_counts FROM @studyName_patients_t2dm_final_counts;
