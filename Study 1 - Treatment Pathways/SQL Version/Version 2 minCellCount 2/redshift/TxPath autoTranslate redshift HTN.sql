/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
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

script to create treatment patterns among patients with a disease

last revised: 29 December 2014

author:  Patrick Ryan

description:

create cohort of patients with index at first treatment.  
patients must have >365d prior observation and >1095d of follow-up. 
patients must have >1 diagnosis during their observation. 
patients must have >1 treatment every 120d from index through 1095d.

for each patient, we summarize the sequence of treatments (active ingredients, ordered by first date of dispensing)

we then count the number of persons with the same sequence of treatments

the results queries allow you to remove small cell counts before producing the final summary tables as needed


--update 29 Dec 2014:
***changed the handling of small cell counts to aggregate treatment sequences until cell count is achieved (rather than removing full sequence)
***changed mincellcount default = 0
***changed to create only 2 output files.   both stratified by year, but overall is set with year = 9999



*************************/

  /*cdmSchema:  cdm_schema*/
  /*resultsSchema:  results_schema*/
 /*studyName:  HTN*/
 /*sourceName:  source_name*/
 /*txlist:  21600381,21601461,21601560,21601664,21601744,21601782*/
 /*dxlist: 316866*/
 /*excludedxlist:  444094*/
 /*smallcellcount:  2*/


--create index population (persons with >1 treatment with >365d observation prior and >1095d observation after)

SET search_path TO  results_schema;

--For Oracle: drop temp tables if they already exist
DROP TABLE IF EXISTS  HTN_indexcohort;

DROP TABLE IF EXISTS  HTN_e0;

DROP TABLE IF EXISTS  HTN_t0;

DROP TABLE IF EXISTS  HTN_t1;

DROP TABLE IF EXISTS  HTN_t2;

DROP TABLE IF EXISTS  HTN_t3;

DROP TABLE IF EXISTS  HTN_t4;

DROP TABLE IF EXISTS  HTN_t5;

DROP TABLE IF EXISTS  HTN_t6;

DROP TABLE IF EXISTS  HTN_t7;

DROP TABLE IF EXISTS  HTN_t8;

DROP TABLE IF EXISTS  HTN_t9;

DROP TABLE IF EXISTS  HTN_matchcohort;

DROP TABLE IF EXISTS  HTN_drug_seq;

DROP TABLE IF EXISTS  HTN_drug_seq_summary;

DROP TABLE IF EXISTS  HTN_person_count;

DROP TABLE IF EXISTS  HTN_person_count_year;

DROP TABLE IF EXISTS  HTN_seq_count;	

DROP TABLE IF EXISTS  HTN_seq_count_year;
	
CREATE TEMP TABLE HTN_IndexCohort
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	COHORT_END_DATE date not null,
	OBSERVATION_PERIOD_START_DATE date not null,
	OBSERVATION_PERIOD_END_DATE date not null
);

INSERT INTO HTN_IndexCohort (PERSON_ID, INDEX_DATE, COHORT_END_DATE, OBSERVATION_PERIOD_START_DATE, OBSERVATION_PERIOD_END_DATE)
select  person_id, INDEX_DATE,COHORT_END_DATE, observation_period_start_date, observation_period_end_date
FROM 
(
	select ot.PERSON_ID, ot.INDEX_DATE, MIN(e.END_DATE) as COHORT_END_DATE, ot.OBSERVATION_PERIOD_START_DATE, ot.OBSERVATION_PERIOD_END_DATE, ROW_NUMBER() OVER (PARTITION BY ot.PERSON_ID ORDER BY ot.INDEX_DATE) as RowNumber
	from 
	(
		select dt.PERSON_ID, dt.DRUG_EXPOSURE_START_DATE as index_date, op.OBSERVATION_PERIOD_START_DATE, op.OBSERVATION_PERIOD_END_DATE
		from  
		(
			select de.PERSON_ID, de.DRUG_CONCEPT_ID, de.DRUG_EXPOSURE_START_DATE
			FROM 
			(
				select d.PERSON_ID, d.DRUG_CONCEPT_ID, d.DRUG_EXPOSURE_START_DATE,
				COALESCE(d.DRUG_EXPOSURE_END_DATE, (d.DRUG_EXPOSURE_START_DATE + d.DAYS_SUPPLY), (d.DRUG_EXPOSURE_START_DATE + 1)) as DRUG_EXPOSURE_END_DATE,
				ROW_NUMBER() OVER (PARTITION BY d.PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE) as RowNumber
				FROM cdm_schema.DRUG_EXPOSURE d
				JOIN cdm_schema.CONCEPT_ANCESTOR ca 
				on d.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
			) de
			JOIN cdm_schema.PERSON p on p.PERSON_ID = de.PERSON_ID
			WHERE de.RowNumber = 1
		) dt
		JOIN cdm_schema.observation_period op 
			on op.PERSON_ID = dt.PERSON_ID and (dt.DRUG_EXPOSURE_START_DATE between op.OBSERVATION_PERIOD_START_DATE and op.OBSERVATION_PERIOD_END_DATE)
		WHERE ( op.OBSERVATION_PERIOD_START_DATE + 365) <= dt.DRUG_EXPOSURE_START_DATE AND ( dt.DRUG_EXPOSURE_START_DATE + 1095) <= op.OBSERVATION_PERIOD_END_DATE

	) ot
	join
	(
		select PERSON_ID, (EVENT_DATE + -31) as END_DATE -- subtract 30 days to end dates to resove back to the 'true' dates
		FROM
		(
			select PERSON_ID, EVENT_DATE, EVENT_TYPE, START_ORDINAL, 
			ROW_NUMBER() OVER (PARTITION BY PERSON_ID ORDER BY EVENT_DATE, EVENT_TYPE) AS EVENT_ORDINAL,
			MAX(START_ORDINAL) OVER (PARTITION BY PERSON_ID ORDER BY EVENT_DATE, EVENT_TYPE ROWS UNBOUNDED PRECEDING) as STARTS
			from
			(
				Select PERSON_ID, DRUG_EXPOSURE_START_DATE AS EVENT_DATE, 1 as EVENT_TYPE, ROW_NUMBER() OVER (PARTITION BY PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE) as START_ORDINAL
				from 
			
				(
					select d.PERSON_ID, d.DRUG_CONCEPT_ID, d.DRUG_EXPOSURE_START_DATE,
					COALESCE(d.DRUG_EXPOSURE_END_DATE, (d.DRUG_EXPOSURE_START_DATE + d.DAYS_SUPPLY), (d.DRUG_EXPOSURE_START_DATE + 1)) as DRUG_EXPOSURE_END_DATE,
					ROW_NUMBER() OVER (PARTITION BY d.PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE) as RowNumber
					FROM cdm_schema.DRUG_EXPOSURE d
					JOIN cdm_schema.CONCEPT_ANCESTOR ca 
						on d.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
				)
				cteExposureData
				UNION ALL
				select PERSON_ID, (DRUG_EXPOSURE_END_DATE + 31), 0 as EVENT_TYPE, NULL
				FROM 
				(
					select d.PERSON_ID, d.DRUG_CONCEPT_ID, d.DRUG_EXPOSURE_START_DATE,
					COALESCE(d.DRUG_EXPOSURE_END_DATE, (d.DRUG_EXPOSURE_START_DATE + d.DAYS_SUPPLY), (d.DRUG_EXPOSURE_START_DATE + 1)) as DRUG_EXPOSURE_END_DATE,
					ROW_NUMBER() OVER (PARTITION BY d.PERSON_ID ORDER BY DRUG_EXPOSURE_START_DATE) as RowNumber
					FROM cdm_schema.DRUG_EXPOSURE d
					JOIN cdm_schema.CONCEPT_ANCESTOR ca 
						on d.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
				) cteExposureData
			) RAWDATA
		) E
		WHERE 2 * E.STARTS - E.EVENT_ORDINAL = 0
	) e on e.PERSON_ID = ot.PERSON_ID and e.END_DATE >= ot.INDEX_DATE
	GROUP BY ot.PERSON_ID, ot.INDEX_DATE, ot.OBSERVATION_PERIOD_START_DATE, ot.OBSERVATION_PERIOD_END_DATE
) r
WHERE r.RowNumber = 1
;




--find persons with no excluding conditions
CREATE TEMP TABLE HTN_E0
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);


INSERT INTO HTN_E0
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select co.PERSON_ID, co.CONDITION_CONCEPT_ID
	FROM cdm_schema.condition_occurrence co
	JOIN HTN_IndexCohort ip on co.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on co.CONDITION_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (444094)
	WHERE (co.CONDITION_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.CONDITION_CONCEPT_ID) <= 0
;




--find persons in indexcohort with no treatments before index
CREATE TEMP TABLE HTN_T0
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);


INSERT INTO HTN_T0
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and (ip.INDEX_DATE + -1)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) <= 0
;

--find persons in indexcohort with diagnosis
CREATE TEMP TABLE HTN_T1
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T1
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN 
(
	select ce.PERSON_ID, ce.CONDITION_CONCEPT_ID
	FROM cdm_schema.CONDITION_ERA ce
	JOIN HTN_IndexCohort ip on ce.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on ce.CONDITION_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (316866)
	WHERE (ce.CONDITION_ERA_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		--cteConditionTargetClause	
) ct on ct.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(ct.CONDITION_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T2
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T2
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 121) and (ip.INDEX_DATE + 240)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T3
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T3
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 241) and (ip.INDEX_DATE + 360)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T4
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T4
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 361) and (ip.INDEX_DATE + 480)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T5
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T5
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 481) and (ip.INDEX_DATE + 600)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T6
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T6
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 601) and (ip.INDEX_DATE + 720)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;


--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T7
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T7
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 721) and (ip.INDEX_DATE + 840)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T8
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T8
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 841) and (ip.INDEX_DATE + 960)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;

--find persons in indexcohort with >1 treatments in 4mo interval after index
CREATE TEMP TABLE HTN_T9
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	OBSERVATION_END_DATE date not null
);

INSERT INTO HTN_T9
select ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
from HTN_IndexCohort ip
LEFT JOIN
(
	select de.PERSON_ID, de.DRUG_CONCEPT_ID
	FROM cdm_schema.DRUG_EXPOSURE de
	JOIN HTN_IndexCohort ip on de.PERSON_ID = ip.PERSON_ID
	JOIN cdm_schema.CONCEPT_ANCESTOR ca on de.DRUG_CONCEPT_ID = ca.DESCENDANT_CONCEPT_ID and ca.ANCESTOR_CONCEPT_ID in (21600381,21601461,21601560,21601664,21601744,21601782)
	WHERE (de.DRUG_EXPOSURE_START_DATE between ip.OBSERVATION_PERIOD_START_DATE and ip.OBSERVATION_PERIOD_END_DATE)
		 AND de.DRUG_EXPOSURE_START_DATE between (ip.INDEX_DATE + 961) and (ip.INDEX_DATE + 1080)	
) dt on dt.PERSON_ID = ip.PERSON_ID
GROUP BY  ip.PERSON_ID, ip.INDEX_DATE, ip.COHORT_END_DATE
HAVING COUNT(dt.DRUG_CONCEPT_ID) >= 1
;


--find persons that qualify for final cohort (meeting all inclusion criteria)
CREATE TEMP TABLE HTN_MatchCohort
 (
	PERSON_ID bigint not null primary key,
	INDEX_DATE date not null,
	COHORT_END_DATE date not null,
	OBSERVATION_PERIOD_START_DATE date not null,
	OBSERVATION_PERIOD_END_DATE date not null
);


INSERT INTO HTN_MatchCohort (PERSON_ID, INDEX_DATE, COHORT_END_DATE, OBSERVATION_PERIOD_START_DATE, OBSERVATION_PERIOD_END_DATE)
select c.person_id, c.index_date, c.cohort_end_date, c.observation_period_start_date, c.observation_period_end_date
FROM HTN_IndexCohort C
INNER JOIN
(
SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID
FROM
(
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_E0
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T0
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T1
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T2
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T3
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T4
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T5
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T6
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T7
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T8
	INTERSECT
	SELECT INDEX_DATE, OBSERVATION_END_DATE, PERSON_ID FROM HTN_T9
) TopGroup
) I 
ON C.PERSON_ID = I.PERSON_ID
and c.index_date = i.INDEX_DATE
;



--find all drugs that the matching cohort had taken
CREATE TEMP TABLE HTN_drug_seq
 (
	person_id bigint,
	index_year int,
	drug_concept_id int,
	concept_name varchar(255),
	drug_seq int
);

insert into HTN_drug_seq (person_id, index_year, drug_concept_id, concept_name, drug_seq)
select de1.person_id, de1.index_year, de1.drug_concept_id, c1.concept_name, row_number() over (partition by de1.person_id order by de1.drug_start_date, de1.drug_concept_id) as rn1
from
(select de0.person_id, de0.drug_concept_id, EXTRACT(YEAR FROM c1.index_date) as index_year, min(de0.drug_era_start_date) as drug_start_date
from cdm_schema.drug_era de0
inner join HTN_MatchCohort c1
on de0.person_id = c1.person_id
where drug_concept_id in (select descendant_concept_id from cdm_schema.concept_ancestor where ancestor_concept_id in (21600381,21601461,21601560,21601664,21601744,21601782))
group by de0.person_id, de0.drug_concept_id, EXTRACT(YEAR FROM c1.index_date)
) de1
inner join cdm_schema.concept c1
on de1.drug_concept_id = c1.concept_id
;




--summarize the unique treatment sequences observed
CREATE TEMP TABLE HTN_drug_seq_summary
 (
	index_year int,
	d1_concept_id int,
	d2_concept_id int,
	d3_concept_id int,
	d4_concept_id int,
	d5_concept_id int,
	d6_concept_id int,
	d7_concept_id int,
	d8_concept_id int,
	d9_concept_id int,
	d10_concept_id int,
	d11_concept_id int,
	d12_concept_id int,
	d13_concept_id int,
	d14_concept_id int,
	d15_concept_id int,
	d16_concept_id int,
	d17_concept_id int,
	d18_concept_id int,
	d19_concept_id int,
	d20_concept_id int,
	d1_concept_name varchar(255),
	d2_concept_name varchar(255),
	d3_concept_name varchar(255),
	d4_concept_name varchar(255),
	d5_concept_name varchar(255),
	d6_concept_name varchar(255),
	d7_concept_name varchar(255),
	d8_concept_name varchar(255),
	d9_concept_name varchar(255),
	d10_concept_name varchar(255),
	d11_concept_name varchar(255),
	d12_concept_name varchar(255),
	d13_concept_name varchar(255),
	d14_concept_name varchar(255),
	d15_concept_name varchar(255),
	d16_concept_name varchar(255),
	d17_concept_name varchar(255),
	d18_concept_name varchar(255),
	d19_concept_name varchar(255),
	d20_concept_name varchar(255),
	num_persons int
);

insert into HTN_drug_seq_summary (index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons)
select d1.index_year,
	d1.drug_concept_id as d1_concept_id,
	d2.drug_concept_id as d2_concept_id,
	d3.drug_concept_id as d3_concept_id,
	d4.drug_concept_id as d4_concept_id,
	d5.drug_concept_id as d5_concept_id,
	d6.drug_concept_id as d6_concept_id,
	d7.drug_concept_id as d7_concept_id,
	d8.drug_concept_id as d8_concept_id,
	d9.drug_concept_id as d9_concept_id,
	d10.drug_concept_id as d10_concept_id,
	d11.drug_concept_id as d11_concept_id,
	d12.drug_concept_id as d12_concept_id,
	d13.drug_concept_id as d13_concept_id,
	d14.drug_concept_id as d14_concept_id,
	d15.drug_concept_id as d15_concept_id,
	d16.drug_concept_id as d16_concept_id,
	d17.drug_concept_id as d17_concept_id,
	d18.drug_concept_id as d18_concept_id,
	d19.drug_concept_id as d19_concept_id,
	d20.drug_concept_id as d20_concept_id,
	d1.concept_name as d1_concept_name,
	 d2.concept_name as d2_concept_name,
	 d3.concept_name as d3_concept_name,
	 d4.concept_name as d4_concept_name,
	 d5.concept_name as d5_concept_name,
	 d6.concept_name as d6_concept_name,
	 d7.concept_name as d7_concept_name,
	 d8.concept_name as d8_concept_name,
	 d9.concept_name as d9_concept_name,
	 d10.concept_name as d10_concept_name,
	 d11.concept_name as d11_concept_name,
	 d12.concept_name as d12_concept_name,
	 d13.concept_name as d13_concept_name,
	 d14.concept_name as d14_concept_name,
	 d15.concept_name as d15_concept_name,
	 d16.concept_name as d16_concept_name,
	 d17.concept_name as d17_concept_name,
	 d18.concept_name as d18_concept_name,
	 d19.concept_name as d19_concept_name,
	 d20.concept_name as d20_concept_name,
	count(distinct d1.person_id) as num_persons
from
(select *
from HTN_drug_seq
where drug_seq = 1) d1
left join
(select *
from HTN_drug_seq
where drug_seq = 2) d2
on d1.person_id = d2.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 3) d3
on d1.person_id = d3.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 4) d4
on d1.person_id = d4.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 5) d5
on d1.person_id = d5.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 6) d6
on d1.person_id = d6.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 7) d7
on d1.person_id = d7.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 8) d8
on d1.person_id = d8.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 9) d9
on d1.person_id = d9.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 10) d10
on d1.person_id = d10.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 11) d11
on d1.person_id = d11.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 12) d12
on d1.person_id = d12.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 13) d13
on d1.person_id = d13.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 14) d14
on d1.person_id = d14.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 15) d15
on d1.person_id = d15.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 16) d16
on d1.person_id = d16.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 17) d17
on d1.person_id = d17.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 18) d18
on d1.person_id = d18.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 19) d19
on d1.person_id = d19.person_id
left join
(select *
from HTN_drug_seq
where drug_seq = 20) d20
on d1.person_id = d20.person_id
group by 
	d1.index_year,
	d1.drug_concept_id,
	d2.drug_concept_id,
	d3.drug_concept_id,
	d4.drug_concept_id,
	d5.drug_concept_id,
	d6.drug_concept_id,
	d7.drug_concept_id,
	d8.drug_concept_id,
	d9.drug_concept_id,
	d10.drug_concept_id,
	d11.drug_concept_id,
	d12.drug_concept_id,
	d13.drug_concept_id,
	d14.drug_concept_id,
	d15.drug_concept_id,
	d16.drug_concept_id,
	d17.drug_concept_id,
	d18.drug_concept_id,
	d19.drug_concept_id,
	d20.drug_concept_id,
	d1.concept_name,
	 d2.concept_name,
	 d3.concept_name,
	 d4.concept_name,
	 d5.concept_name,
	 d6.concept_name,
	 d7.concept_name,
	 d8.concept_name,
	 d9.concept_name,
	 d10.concept_name,
	 d11.concept_name,
	 d12.concept_name,
	 d13.concept_name,
	 d14.concept_name,
	 d15.concept_name,
	 d16.concept_name,
	 d17.concept_name,
	 d18.concept_name,
	 d19.concept_name,
	 d20.concept_name;




/****

added 29Dec2014:
modify table to remove small cell counts

*****/



  CREATE TEMP TABLE HTN_drug_seq_summary_temp
   (
    index_year int,
  	d1_concept_id int,
  	d2_concept_id int,
  	d3_concept_id int,
  	d4_concept_id int,
  	d5_concept_id int,
  	d6_concept_id int,
  	d7_concept_id int,
  	d8_concept_id int,
  	d9_concept_id int,
  	d10_concept_id int,
  	d11_concept_id int,
  	d12_concept_id int,
  	d13_concept_id int,
  	d14_concept_id int,
  	d15_concept_id int,
  	d16_concept_id int,
  	d17_concept_id int,
  	d18_concept_id int,
  	d19_concept_id int,
  	d20_concept_id int,
  	d1_concept_name varchar(255),
  	d2_concept_name varchar(255),
  	d3_concept_name varchar(255),
  	d4_concept_name varchar(255),
  	d5_concept_name varchar(255),
  	d6_concept_name varchar(255),
  	d7_concept_name varchar(255),
  	d8_concept_name varchar(255),
  	d9_concept_name varchar(255),
  	d10_concept_name varchar(255),
  	d11_concept_name varchar(255),
  	d12_concept_name varchar(255),
  	d13_concept_name varchar(255),
  	d14_concept_name varchar(255),
  	d15_concept_name varchar(255),
  	d16_concept_name varchar(255),
  	d17_concept_name varchar(255),
  	d18_concept_name varchar(255),
  	d19_concept_name varchar(255),
  	d20_concept_name varchar(255),
  	num_persons int
  );
  
  
  insert into HTN_drug_seq_summary_temp (index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons)
  select index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons
  from
  HTN_drug_seq_summary;
  
  delete from HTN_drug_seq_summary;
  
  
  insert into HTN_drug_seq_summary (index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons)
  select index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons
  from
  (
  select index_year,  
    case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  	case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  	case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  	sum(num_persons) as num_persons
  from
  	(
  	select index_year,  
  		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  		case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  		case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  		sum(num_persons) as num_persons
  	from
  		(
  		select index_year,  
  			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  			case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  			case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  			sum(num_persons) as num_persons
  		from
  			(
  			select index_year,  
  				case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  				case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  				case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  				case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  				case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  				case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  				case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  				case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  				case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  				case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  				case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  				case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  				case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  				case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  				case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  				case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  				case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  				case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  				case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  				case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  				case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  				case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  				case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  				case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  				case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  				case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  				case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  				case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  				case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  				case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  				case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  				case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  				case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  				case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  				case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  				case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  				case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  				case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  				case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  				case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  				sum(num_persons) as num_persons
  			from
  				(
  				select index_year,  
  					case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  					case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  					case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  					case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  					case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  					case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  					case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  					case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  					case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  					case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  					case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  					case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  					case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  					case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  					case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  					case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  					case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  					case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  					case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  					case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  					case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  					case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  					case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  					case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  					case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  					case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  					case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  					case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  					case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  					case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  					case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  					case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  					case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  					case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  					case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  					case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  					case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  					case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  					case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  					case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  					sum(num_persons) as num_persons
  				from
  					(
  					select index_year,  
  						case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  						case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  						case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  						case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  						case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  						case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  						case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  						case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  						case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  						case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  						case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  						case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  						case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  						case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  						case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  						case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  						case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  						case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  						case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  						case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  						case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  						case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  						case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  						case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  						case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  						case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  						case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  						case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  						case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  						case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  						case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  						case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  						case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  						case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  						case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  						case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  						case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  						case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  						case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  						case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  						sum(num_persons) as num_persons
  					from
  						(
  						select index_year,  
  							case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  							case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  							case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  							case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  							case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  							case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  							case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  							case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  							case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  							case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  							case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  							case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  							case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  							case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  							case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  							case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  							case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  							case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  							case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  							case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  							case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  							case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  							case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  							case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  							case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  							case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  							case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  							case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  							case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  							case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  							case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  							case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  							case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  							case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  							case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  							case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  							case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  							case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  							case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  							case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  							sum(num_persons) as num_persons
  						from
  							(
  							select index_year,  
  								case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  								case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  								case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  								case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  								case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  								case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  								case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  								case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  								case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  								case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  								case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  								case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  								case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  								case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  								case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  								case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  								case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  								case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  								case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  								case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  								case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  								case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  								case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  								case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  								case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  								case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  								case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  								case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  								case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  								case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  								case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  								case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  								case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  								case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  								case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  								case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  								case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  								case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  								case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  								case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  								sum(num_persons) as num_persons
  							from
  								(
  								select index_year,  
  									case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  									case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  									case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  									case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  									case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  									case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  									case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  									case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  									case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  									case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  									case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  									case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  									case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  									case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  									case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  									case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  									case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  									case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  									case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  									case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  									case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  									case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  									case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  									case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  									case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  									case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  									case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  									case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  									case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  									case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  									case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  									case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  									case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  									case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  									case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  									case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  									case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  									case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  									case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  									case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  									sum(num_persons) as num_persons
  								from
  								(
  									select index_year,  
  										case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  										case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  										case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  										case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  										case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  										case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  										case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  										case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  										case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  										case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  										case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  										case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  										case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  										case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  										case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  										case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  										case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  										case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  										case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  										case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  										case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  										case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  										case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  										case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  										case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  										case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  										case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  										case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  										case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  										case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  										case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  										case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  										case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  										case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  										case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  										case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  										case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  										case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  										case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  										case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  										sum(num_persons) as num_persons
  									from
  										(
  										select index_year,  
  											case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  											case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  											case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  											case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  											case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  											case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  											case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  											case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  											case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  											case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  											case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  											case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  											case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  											case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  											case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  											case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  											case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  											case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  											case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  											case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  											case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  											case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  											case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  											case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  											case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  											case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  											case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  											case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  											case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  											case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  											case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  											case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  											case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  											case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  											case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  											case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  											case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  											case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  											case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  											case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  											sum(num_persons) as num_persons
  										from
  											(
  											select index_year,  
  												case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  												case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  												case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  												case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  												case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  												case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  												case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  												case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  												case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  												case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  												case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  												case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  												case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  												case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  												case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  												case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  												case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  												case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  												case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  												case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  												case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  												case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  												case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  												case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  												case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  												case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  												case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  												case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  												case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  												case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  												case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  												case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  												case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  												case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  												case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  												case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  												case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  												case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  												case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  												case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  												sum(num_persons) as num_persons
  											from
  												(
  												select index_year,  
  													case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  													case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  													case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  													case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  													case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  													case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  													case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  													case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  													case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  													case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  													case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  													case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  													case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  													case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  													case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  													case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  													case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  													case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  													case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  													case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  													case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  													case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  													case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  													case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  													case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  													case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  													case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  													case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  													case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  													case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  													case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  													case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  													case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  													case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  													case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  													case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  													case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  													case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  													case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  													case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  													sum(num_persons) as num_persons
  												from
  													(
  													select index_year,  
  														case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  														case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  														case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  														case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  														case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  														case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  														case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  														case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  														case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  														case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  														case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  														case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  														case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  														case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  														case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  														case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  														case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  														case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  														case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  														case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  														case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  														case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  														case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  														case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  														case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  														case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  														case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  														case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  														case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  														case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  														case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  														case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  														case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  														case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  														case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  														case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  														case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  														case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  														case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  														case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  														sum(num_persons) as num_persons
  													from
  														(
  														select index_year,  
  															case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  															case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  															case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  															case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  															case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  															case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  															case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  															case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  															case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  															case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  															case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  															case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  															case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  															case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  															case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  															case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  															case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  															case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  															case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  															case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  															case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  															case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  															case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  															case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  															case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  															case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  															case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  															case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  															case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  															case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  															case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  															case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  															case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  															case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  															case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  															case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  															case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  															case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  															case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  															case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  															sum(num_persons) as num_persons
  														from
  															(
  															select index_year,  
  																case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  																case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  																case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  																case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  																case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  																case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  																case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  																case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  																case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  																case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  																case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  																case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  																case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  																case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  																case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  																case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  																case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  																case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  																case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  																case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  																case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  																case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  																case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  																case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  																case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  																case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  																case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  																case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  																case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  																case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  																case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  																case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  																case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  																case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  																case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  																case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  																case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  																case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  																case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  																case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  																sum(num_persons) as num_persons
  															from
  																(
  																select index_year,  
  																	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  																	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  																	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  																	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  																	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  																	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  																	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  																	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  																	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  																	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  																	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  																	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  																	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  																	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  																	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  																	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  																	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  																	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  																	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  																	case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  																	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  																	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  																	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  																	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  																	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  																	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  																	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  																	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  																	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  																	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  																	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  																	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  																	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  																	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  																	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  																	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  																	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  																	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  																	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  																	case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  																	sum(num_persons) as num_persons
  																from
  																(
  																	select index_year,  
  																		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  																		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  																		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  																		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  																		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  																		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  																		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  																		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  																		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  																		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  																		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  																		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  																		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  																		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  																		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  																		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  																		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  																		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  																		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  																		case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  																		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  																		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  																		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  																		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  																		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  																		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  																		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  																		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  																		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  																		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  																		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  																		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  																		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  																		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  																		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  																		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  																		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  																		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  																		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  																		case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  																		sum(num_persons) as num_persons
  																	from
  																		(
  																		select index_year,  
  																			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end as d1_concept_id, 
  																			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end as d2_concept_id,
  																			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end as d3_concept_id,
  																			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end as d4_concept_id,
  																			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end as d5_concept_id,
  																			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end as d6_concept_id,
  																			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end as d7_concept_id,
  																			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end as d8_concept_id,
  																			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end as d9_concept_id,
  																			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end as d10_concept_id,
  																			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end as d11_concept_id,
  																			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end as d12_concept_id,
  																			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end as d13_concept_id,
  																			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end as d14_concept_id,
  																			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end as d15_concept_id,
  																			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end as d16_concept_id,
  																			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end as d17_concept_id,
  																			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end as d18_concept_id,
  																			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end as d19_concept_id,
  																			case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end as d20_concept_id,
  																			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end as d1_concept_name, 
  																			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end as d2_concept_name,
  																			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end as d3_concept_name,
  																			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end as d4_concept_name,
  																			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end as d5_concept_name,
  																			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end as d6_concept_name,
  																			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end as d7_concept_name,
  																			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end as d8_concept_name,
  																			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end as d9_concept_name,
  																			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end as d10_concept_name,
  																			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end as d11_concept_name,
  																			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end as d12_concept_name,
  																			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end as d13_concept_name,
  																			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end as d14_concept_name,
  																			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end as d15_concept_name,
  																			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end as d16_concept_name,
  																			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end as d17_concept_name,
  																			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end as d18_concept_name,
  																			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end as d19_concept_name,
  																			case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end as d20_concept_name,
  																			sum(num_persons) as num_persons
  																		from HTN_drug_seq_summary_temp
  																		group by index_year,  
  																			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  																			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  																			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  																			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  																			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  																			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  																			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  																			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  																			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  																			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  																			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  																			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  																			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  																			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  																			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  																			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  																			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  																			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  																			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  																			case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  																			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  																			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  																			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  																			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  																			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  																			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  																			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  																			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  																			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  																			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  																			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  																			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  																			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  																			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  																			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  																			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  																			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  																			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  																			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  																			case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  																		) t1
  																	group by index_year,  
  																		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  																		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  																		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  																		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  																		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  																		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  																		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  																		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  																		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  																		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  																		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  																		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  																		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  																		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  																		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  																		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  																		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  																		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  																		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  																		case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  																		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  																		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  																		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  																		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  																		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  																		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  																		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  																		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  																		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  																		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  																		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  																		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  																		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  																		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  																		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  																		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  																		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  																		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  																		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  																		case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  																	) t2
  																group by index_year,  
  																	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  																	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  																	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  																	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  																	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  																	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  																	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  																	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  																	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  																	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  																	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  																	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  																	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  																	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  																	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  																	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  																	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  																	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  																	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  																	case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  																	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  																	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  																	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  																	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  																	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  																	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  																	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  																	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  																	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  																	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  																	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  																	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  																	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  																	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  																	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  																	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  																	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  																	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  																	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  																	case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  																) t3
  															group by index_year,  
  																case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  																case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  																case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  																case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  																case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  																case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  																case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  																case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  																case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  																case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  																case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  																case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  																case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  																case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  																case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  																case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  																case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  																case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  																case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  																case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  																case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  																case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  																case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  																case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  																case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  																case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  																case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  																case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  																case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  																case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  																case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  																case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  																case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  																case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  																case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  																case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  																case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  																case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  																case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  																case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  															) t4
  														group by index_year,  
  															case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  															case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  															case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  															case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  															case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  															case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  															case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  															case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  															case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  															case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  															case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  															case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  															case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  															case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  															case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  															case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  															case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  															case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  															case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  															case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  															case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  															case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  															case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  															case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  															case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  															case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  															case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  															case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  															case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  															case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  															case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  															case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  															case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  															case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  															case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  															case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  															case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  															case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  															case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  															case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  														) t5
  													group by index_year,  
  														case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  														case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  														case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  														case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  														case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  														case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  														case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  														case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  														case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  														case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  														case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  														case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  														case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  														case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  														case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  														case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  														case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  														case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  														case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  														case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  														case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  														case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  														case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  														case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  														case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  														case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  														case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  														case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  														case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  														case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  														case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  														case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  														case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  														case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  														case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  														case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  														case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  														case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  														case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  														case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  													) t6
  												group by index_year,  
  													case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  													case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  													case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  													case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  													case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  													case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  													case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  													case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  													case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  													case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  													case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  													case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  													case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  													case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  													case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  													case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  													case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  													case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  													case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  													case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  													case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  													case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  													case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  													case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  													case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  													case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  													case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  													case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  													case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  													case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  													case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  													case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  													case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  													case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  													case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  													case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  													case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  													case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  													case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  													case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  												) t7
  											group by index_year,  
  												case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  												case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  												case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  												case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  												case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  												case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  												case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  												case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  												case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  												case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  												case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  												case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  												case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  												case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  												case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  												case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  												case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  												case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  												case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  												case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  												case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  												case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  												case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  												case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  												case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  												case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  												case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  												case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  												case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  												case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  												case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  												case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  												case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  												case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  												case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  												case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  												case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  												case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  												case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  												case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  											) t8
  										group by index_year,  
  											case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  											case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  											case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  											case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  											case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  											case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  											case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  											case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  											case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  											case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  											case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  											case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  											case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  											case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  											case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  											case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  											case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  											case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  											case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  											case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  											case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  											case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  											case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  											case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  											case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  											case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  											case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  											case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  											case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  											case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  											case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  											case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  											case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  											case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  											case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  											case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  											case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  											case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  											case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  											case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  										) t9
  									group by index_year,  
  										case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  										case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  										case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  										case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  										case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  										case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  										case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  										case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  										case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  										case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  										case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  										case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  										case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  										case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  										case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  										case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  										case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  										case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  										case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  										case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  										case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  										case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  										case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  										case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  										case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  										case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  										case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  										case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  										case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  										case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  										case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  										case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  										case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  										case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  										case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  										case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  										case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  										case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  										case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  										case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  									) t10
  								group by index_year,  
  									case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  									case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  									case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  									case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  									case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  									case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  									case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  									case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  									case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  									case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  									case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  									case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  									case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  									case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  									case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  									case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  									case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  									case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  									case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  									case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  									case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  									case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  									case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  									case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  									case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  									case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  									case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  									case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  									case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  									case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  									case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  									case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  									case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  									case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  									case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  									case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  									case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  									case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  									case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  									case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  								) t11
  							group by index_year,  
  								case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  								case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  								case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  								case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  								case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  								case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  								case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  								case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  								case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  								case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  								case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  								case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  								case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  								case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  								case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  								case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  								case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  								case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  								case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  								case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  								case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  								case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  								case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  								case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  								case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  								case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  								case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  								case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  								case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  								case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  								case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  								case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  								case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  								case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  								case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  								case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  								case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  								case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  								case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  								case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  							) t12
  						group by index_year,  
  							case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  							case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  							case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  							case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  							case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  							case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  							case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  							case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  							case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  							case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  							case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  							case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  							case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  							case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  							case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  							case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  							case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  							case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  							case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  							case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  							case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  							case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  							case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  							case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  							case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  							case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  							case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  							case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  							case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  							case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  							case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  							case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  							case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  							case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  							case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  							case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  							case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  							case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  							case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  							case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  						) t13
  					group by index_year,  
  						case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  						case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  						case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  						case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  						case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  						case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  						case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  						case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  						case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  						case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  						case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  						case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  						case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  						case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  						case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  						case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  						case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  						case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  						case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  						case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  						case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  						case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  						case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  						case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  						case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  						case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  						case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  						case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  						case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  						case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  						case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  						case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  						case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  						case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  						case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  						case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  						case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  						case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  						case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  						case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  					) t14
  				group by index_year,  
  					case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  					case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  					case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  					case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  					case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  					case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  					case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  					case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  					case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  					case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  					case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  					case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  					case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  					case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  					case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  					case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  					case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  					case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  					case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  					case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  					case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  					case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  					case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  					case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  					case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  					case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  					case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  					case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  					case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  					case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  					case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  					case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  					case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  					case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  					case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  					case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  					case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  					case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  					case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  					case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  				) t15
  			group by index_year,  
  				case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  				case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  				case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  				case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  				case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  				case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  				case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  				case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  				case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  				case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  				case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  				case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  				case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  				case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  				case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  				case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  				case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  				case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  				case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  				case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  				case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  				case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  				case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  				case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  				case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  				case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  				case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  				case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  				case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  				case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  				case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  				case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  				case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  				case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  				case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  				case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  				case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  				case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  				case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  				case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  			) t16
  		group by index_year,  
  			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  			case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  			case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  			case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  			case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  			case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  			case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  			case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  			case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  			case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  			case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  			case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  			case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  			case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  			case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  			case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  			case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  			case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  			case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  			case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  			case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  			case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  		) t17
  	group by index_year,  
  		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  		case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  		case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  		case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  		case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  		case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  		case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  		case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  		case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  		case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  		case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  		case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  		case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  		case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  		case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  		case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  		case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  		case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  		case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  		case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  		case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  		case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  	) t18
  group by index_year,  
  	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then -1 else d1_concept_id end, 
  	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then -1 when d1_concept_id = -1 then null else d2_concept_id end,
  	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then -1 when d2_concept_id = -1 then null else d3_concept_id end,
  	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then -1 when d3_concept_id = -1 then null else d4_concept_id end,
  	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then -1 when d4_concept_id = -1 then null else d5_concept_id end,
  	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then -1 when d5_concept_id = -1 then null else d6_concept_id end,
  	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then -1 when d6_concept_id = -1 then null else d7_concept_id end,
  	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then -1 when d7_concept_id = -1 then null else d8_concept_id end,
  	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then -1 when d8_concept_id = -1 then null else d9_concept_id end,
  	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then -1 when d9_concept_id = -1 then null else d10_concept_id end,
  	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then -1 when d10_concept_id = -1 then null else d11_concept_id end,
  	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then -1 when d11_concept_id = -1 then null else d12_concept_id end,
  	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then -1 when d12_concept_id = -1 then null else d13_concept_id end,
  	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then -1 when d13_concept_id = -1 then null else d14_concept_id end,
  	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then -1 when d14_concept_id = -1 then null else d15_concept_id end,
  	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then -1 when d15_concept_id = -1 then null else d16_concept_id end,
  	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then -1 when d16_concept_id = -1 then null else d17_concept_id end,
  	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then -1 when d17_concept_id = -1 then null else d18_concept_id end,
  	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then -1 when d18_concept_id = -1 then null else d19_concept_id end,
  	case when d20_concept_id > 0 and num_persons < 2 then -1 when d19_concept_id = -1 then null else d20_concept_id end,
  	case when d1_concept_id > 0 and (d2_concept_id is null or d2_concept_id = -1) and num_persons < 2 then 'Other' else d1_concept_name end, 
  	case when d2_concept_id > 0 and (d3_concept_id is null or d3_concept_id = -1) and num_persons < 2 then 'Other' when d1_concept_id = -1 then null else d2_concept_name end,
  	case when d3_concept_id > 0 and (d4_concept_id is null or d4_concept_id = -1) and num_persons < 2 then 'Other' when d2_concept_id = -1 then null else d3_concept_name end,
  	case when d4_concept_id > 0 and (d5_concept_id is null or d5_concept_id = -1) and num_persons < 2 then 'Other' when d3_concept_id = -1 then null else d4_concept_name end,
  	case when d5_concept_id > 0 and (d6_concept_id is null or d6_concept_id = -1) and num_persons < 2 then 'Other' when d4_concept_id = -1 then null else d5_concept_name end,
  	case when d6_concept_id > 0 and (d7_concept_id is null or d7_concept_id = -1) and num_persons < 2 then 'Other' when d5_concept_id = -1 then null else d6_concept_name end,
  	case when d7_concept_id > 0 and (d8_concept_id is null or d8_concept_id = -1) and num_persons < 2 then 'Other' when d6_concept_id = -1 then null else d7_concept_name end,
  	case when d8_concept_id > 0 and (d9_concept_id is null or d9_concept_id = -1) and num_persons < 2 then 'Other' when d7_concept_id = -1 then null else d8_concept_name end,
  	case when d9_concept_id > 0 and (d10_concept_id is null or d10_concept_id = -1) and num_persons < 2 then 'Other' when d8_concept_id = -1 then null else d9_concept_name end,
  	case when d10_concept_id > 0 and (d11_concept_id is null or d11_concept_id = -1) and num_persons < 2 then 'Other' when d9_concept_id = -1 then null else d10_concept_name end,
  	case when d11_concept_id > 0 and (d12_concept_id is null or d12_concept_id = -1) and num_persons < 2 then 'Other' when d10_concept_id = -1 then null else d11_concept_name end,
  	case when d12_concept_id > 0 and (d13_concept_id is null or d13_concept_id = -1) and num_persons < 2 then 'Other' when d11_concept_id = -1 then null else d12_concept_name end,
  	case when d13_concept_id > 0 and (d14_concept_id is null or d14_concept_id = -1) and num_persons < 2 then 'Other' when d12_concept_id = -1 then null else d13_concept_name end,
  	case when d14_concept_id > 0 and (d15_concept_id is null or d15_concept_id = -1) and num_persons < 2 then 'Other' when d13_concept_id = -1 then null else d14_concept_name end,
  	case when d15_concept_id > 0 and (d16_concept_id is null or d16_concept_id = -1) and num_persons < 2 then 'Other' when d14_concept_id = -1 then null else d15_concept_name end,
  	case when d16_concept_id > 0 and (d17_concept_id is null or d17_concept_id = -1) and num_persons < 2 then 'Other' when d15_concept_id = -1 then null else d16_concept_name end,
  	case when d17_concept_id > 0 and (d18_concept_id is null or d18_concept_id = -1) and num_persons < 2 then 'Other' when d16_concept_id = -1 then null else d17_concept_name end,
  	case when d18_concept_id > 0 and (d19_concept_id is null or d19_concept_id = -1) and num_persons < 2 then 'Other' when d17_concept_id = -1 then null else d18_concept_name end,
  	case when d19_concept_id > 0 and (d20_concept_id is null or d20_concept_id = -1) and num_persons < 2 then 'Other' when d18_concept_id = -1 then null else d19_concept_name end,
  	case when d20_concept_id > 0 and num_persons < 2 then 'Other' when d19_concept_id = -1 then null else d20_concept_name end
  ) t19
  ;

TRUNCATE TABLE HTN_drug_seq_summary_temp;
DROP TABLE HTN_drug_seq_summary_temp;






/*****

Final tables for export:  

save these results and report back with the central coordinating center

*****/


SET search_path TO  results_schema;


--1.  count total persons with a treatment, by year
DROP TABLE IF EXISTS  HTN_source_name_person_count_year;

create table results_schema.HTN_source_name_person_count_year
(
	index_year int,
	num_persons int
);

insert into results_schema.HTN_source_name_person_count_year (index_year, num_persons)
select index_year, num_persons
from
(
select index_year, sum(num_persons) as num_persons
from HTN_drug_seq_summary
group by index_year
) t1
;


--2.  count total persons with a treatment, overall (29Dec2014:  now add to year summary table)

insert into results_schema.HTN_source_name_person_count_year (index_year, num_persons)
select 9999 as index_year, num_persons
from
(
select sum(num_persons) as num_persons
from HTN_drug_seq_summary
) t1
;






--3.  summary by year:   edit the where clause if you need to remove cell counts < minimum number
DROP TABLE IF EXISTS  HTN_source_name_seq_count_year;


create table results_schema.HTN_source_name_seq_count_year
(
	index_year int,
	d1_concept_id int, 
	d2_concept_id int, 
	d3_concept_id int, 
	d4_concept_id int, 
	d5_concept_id int, 
	d6_concept_id int, 
	d7_concept_id int, 
	d8_concept_id int, 
	d9_concept_id int, 
	d10_concept_id int, 
	d11_concept_id int, 
	d12_concept_id int, 
	d13_concept_id int, 
	d14_concept_id int, 
	d15_concept_id int, 
	d16_concept_id int, 
	d17_concept_id int, 
	d18_concept_id int, 
	d19_concept_id int, 
	d20_concept_id int, 
	d1_concept_name varchar(255), 
	d2_concept_name varchar(255), 
	d3_concept_name varchar(255), 
	d4_concept_name varchar(255), 
	d5_concept_name varchar(255), 
	d6_concept_name varchar(255), 
	d7_concept_name varchar(255), 
	d8_concept_name varchar(255), 
	d9_concept_name varchar(255), 
	d10_concept_name varchar(255), 
	d11_concept_name varchar(255), 
	d12_concept_name varchar(255), 
	d13_concept_name varchar(255), 
	d14_concept_name varchar(255), 
	d15_concept_name varchar(255), 
	d16_concept_name varchar(255), 
	d17_concept_name varchar(255), 
	d18_concept_name varchar(255), 
	d19_concept_name varchar(255), 
	d20_concept_name varchar(255),
	num_persons int
);

insert into results_schema.HTN_source_name_seq_count_year (index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons)
select index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons
from HTN_drug_seq_summary
;




--4.  overall summary (group by year):   edit the where clause if you need to remove cell counts < minimum number (here 1 as example)
insert into results_schema.HTN_source_name_seq_count_year (index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, num_persons)
select *
from
(
select 9999 as index_year, d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name, 
	sum(num_persons) as num_persons
from HTN_drug_seq_summary
group by d1_concept_id, d2_concept_id, d3_concept_id, d4_concept_id, d5_concept_id, d6_concept_id, d7_concept_id, d8_concept_id, d9_concept_id, d10_concept_id, d11_concept_id, d12_concept_id, d13_concept_id, d14_concept_id, d15_concept_id, d16_concept_id, d17_concept_id, d18_concept_id, d19_concept_id, d20_concept_id, d1_concept_name, d2_concept_name, d3_concept_name, d4_concept_name, d5_concept_name, d6_concept_name, d7_concept_name, d8_concept_name, d9_concept_name, d10_concept_name, d11_concept_name, d12_concept_name, d13_concept_name, d14_concept_name, d15_concept_name, d16_concept_name, d17_concept_name, d18_concept_name, d19_concept_name, d20_concept_name
) t1
;


--For Oracle: cleanup temp tables:
TRUNCATE TABLE HTN_indexcohort;
DROP TABLE HTN_indexcohort;
TRUNCATE TABLE HTN_e0;
DROP TABLE HTN_e0;
TRUNCATE TABLE HTN_t0;
DROP TABLE HTN_t0;
TRUNCATE TABLE HTN_t1;
DROP TABLE HTN_t1;
TRUNCATE TABLE HTN_t2;
DROP TABLE HTN_t2;
TRUNCATE TABLE HTN_t3;
DROP TABLE HTN_t3;
TRUNCATE TABLE HTN_t4;
DROP TABLE HTN_t4;
TRUNCATE TABLE HTN_t5;
DROP TABLE HTN_t5;
TRUNCATE TABLE HTN_t6;
DROP TABLE HTN_t6;
TRUNCATE TABLE HTN_t7;
DROP TABLE HTN_t7;
TRUNCATE TABLE HTN_t8;
DROP TABLE HTN_t8;
TRUNCATE TABLE HTN_t9;
DROP TABLE HTN_t9;
TRUNCATE TABLE HTN_matchcohort;
DROP TABLE HTN_matchcohort;
TRUNCATE TABLE HTN_drug_seq;
DROP TABLE HTN_drug_seq;
TRUNCATE TABLE HTN_drug_seq_summary;
DROP TABLE HTN_drug_seq_summary;
