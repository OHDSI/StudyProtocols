select codeset_id, concept_id 
INTO #Codesets
FROM
(
 SELECT 0 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (711584) and invalid_reason is null
    UNION 

  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (711584)
  and c.invalid_reason is null

) I
) C
UNION
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (4029498) and invalid_reason is null
    UNION 

  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4029498)
  and c.invalid_reason is null

) I
) C
UNION
SELECT 2 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (432791) and invalid_reason is null
    UNION 

  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (432791)
  and c.invalid_reason is null

) I
) C
UNION
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (740910) and invalid_reason is null
    UNION 

  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (740910)
  and c.invalid_reason is null

) I
) C
) C
;

select row_number() over (order by P.person_id, P.start_date) as event_id, P.person_id, P.start_date, P.end_date, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
INTO #PrimaryCriteriaEvents
FROM
(
  select P.person_id, P.start_date, P.end_date, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date ASC) ordinal
  FROM 
  (
  select C.person_id, C.drug_era_start_date as start_date, C.drug_era_end_date as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_era_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_ERA de
where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 0)
) C

WHERE C.ordinal = 1

  ) P
) P
JOIN @cdm_database_schema.observation_period OP on P.person_id = OP.person_id and P.start_date between OP.observation_period_start_date and op.observation_period_end_date
WHERE DATEADD(day,183,OP.OBSERVATION_PERIOD_START_DATE) <= P.START_DATE AND DATEADD(day,0,P.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE AND P.ordinal = 1
;


DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @cohort_definition_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @cohort_definition_id as cohort_definition_id, person_id as subject_id, start_date as cohort_start_date, end_date as cohort_end_date
FROM 
(
  select RawEvents.*, row_number() over (partition by RawEvents.person_id order by RawEvents.start_date ASC) as ordinal
  FROM
  (
    select pe.person_id, pe.start_date, pe.end_date
    FROM #PrimaryCriteriaEvents pe
    
JOIN (
select 0 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 1)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and DATEADD(day,0,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 1
) G
) AC on AC.event_id = pe.event_id

  ) RawEvents
) Results
WHERE Results.ordinal = 1
;

TRUNCATE TABLE #Codesets;
DROP TABLE #Codesets;

TRUNCATE TABLE #PrimaryCriteriaEvents;
DROP TABLE #PrimaryCriteriaEvents;

