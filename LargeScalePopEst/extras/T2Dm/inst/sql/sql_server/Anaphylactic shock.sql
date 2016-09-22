CREATE TABLE #Codesets (
  codeset_id int NOT NULL,
  concept_id bigint NOT NULL
)
;

INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (4302371,441202,4221182,4084168,4084639,4086737,4032658,4084169)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4302371,4084168,4084639,4086737,4032658,4084169)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (442038)and invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (9201,9203)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (9201,9203)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 2 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (9202)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (9202)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (256717)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (256717)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 4 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (253321)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (253321)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 5 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (317002)and invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 6 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (1343916)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (1343916)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 7 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (1129625)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (1129625)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 8 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2313789,2008356)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2313789,2008356)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 9 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (434219,443567,435987,40479204,442010,4084635,437442,443560,40479646,40481793,40479207,4330225,4299299,4292362,4193788,4176292,4086738,4086737,4084634,4084633,4083995,4083866,436863)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (434219,443567,435987,40479204,442010,4084635,437442,443560,40479646,40481793,40479207,4330225,4299299,4292362,4193788,4176292,4086738,4086737,4084634,4084633,4083995,4083866,436863)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 10 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (440905,435140,436585,441191,437754,433735,442794,4206177,433933,433951,433097,440268,439219,4239004,4318502,435444,443526,4149700,437459,433368,4104431,436876)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (440905,435140,436585,441191,437754,433735,442794,4206177,433933,433951,433097,440268,439219,4239004,4318502,435444,443526,4149700,437459,433368,436876)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 11 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (4188027,4250749,4240902,4139681,442116,4239721,4306169,4102123,4303820,4163175)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4188027,4250749,4240902,4139681,442116,4239721,4306169,4102123,4303820,4163175)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 12 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2314074,436298,442038,4066820,4096274,40479204,4240902,4188027,442794,440905,435987,434219)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2314074,436298,442038,4066820,4096274,40479204,4240902,4188027,442794,440905,435987,434219)
  and c.invalid_reason is null

) I
) C;

select row_number() over (order by P.person_id, P.start_date) as event_id, P.person_id, P.start_date, P.end_date, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
INTO #PrimaryCriteriaEvents
FROM
(
  select P.person_id, P.start_date, P.end_date, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date ASC) ordinal
  FROM 
  (
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 0)
) C



  ) P
) P
JOIN @cdm_database_schema.observation_period OP on P.person_id = OP.person_id and P.start_date between OP.observation_period_start_date and op.observation_period_end_date
WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= P.START_DATE AND DATEADD(day,0,P.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
;


SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date
INTO #cohort_candidate
FROM 
(
  select RawEvents.*, row_number() over (partition by RawEvents.person_id order by RawEvents.start_date ASC) as ordinal
  FROM
  (
    select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date
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
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 9)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-1,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


UNION
SELECT 1 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 12)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-1,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


UNION
SELECT 2 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 12)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-1,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


UNION
SELECT 3 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 10)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-1,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


UNION
SELECT 4 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 11)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-1,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


UNION
select 5 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.visit_start_date as start_date, C.visit_end_date as end_date, C.visit_concept_id as TARGET_CONCEPT_ID
from 
(
  select vo.*, ROW_NUMBER() over (PARTITION BY vo.person_id ORDER BY vo.visit_start_date) as ordinal
  FROM @cdm_database_schema.VISIT_OCCURRENCE vo
where vo.visit_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 1)
) C




) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,0,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
select 1 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.visit_start_date as start_date, C.visit_end_date as end_date, C.visit_concept_id as TARGET_CONCEPT_ID
from 
(
  select vo.*, ROW_NUMBER() over (PARTITION BY vo.person_id ORDER BY vo.visit_start_date) as ordinal
  FROM @cdm_database_schema.VISIT_OCCURRENCE vo
where vo.visit_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 2)
) C




) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,0,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
select 1 as index_id, event_id
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
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 3)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 1 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 4)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 2 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 5)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 3 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_EXPOSURE de
where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 6)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 4 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_EXPOSURE de
where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 7)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 5 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 8)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,0,P.START_DATE) and DATEADD(day,1,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) > 0
) G

  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 2
) G

  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) > 0
) G

  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 6
) G
) AC on AC.event_id = pe.event_id

  ) RawEvents
) Results
WHERE Results.ordinal = 1
;

create table #inclusionRuleCohorts 
(
  inclusion_rule_id bigint,
  event_id bigint
)
;


DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @target_cohort_id as cohort_definition_id, MG.person_id, MG.start_date, MG.end_date
from
(
  select C.event_id, C.person_id, C.start_date, C.end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
  from #cohort_candidate C
  LEFT JOIN #inclusionRuleCohorts I on I.event_id = C.event_id
  GROUP BY C.event_id, C.person_id, C.start_date, C.end_date
) MG -- matching groups
{0 != 0}?{
-- the matching group with all bits set ( POWER(2,# of inclusion rules) - 1 = inclusion_rule_mask
WHERE (MG.inclusion_rule_mask = POWER(cast(2 as bigint),0)-1)
}
;

{0 != 0}?{
-- calculte matching group counts
delete from @results_database_schema.cohort_inclusion_result where cohort_definition_id = @target_cohort_id;
insert into @results_database_schema.cohort_inclusion_result (cohort_definition_id, inclusion_rule_mask, person_count)
select @target_cohort_id as cohort_definition_id, inclusion_rule_mask, count(*) as person_count
from
(
  select C.event_id, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
  from #cohort_candidate C
  LEFT JOIN #inclusionRuleCohorts I on c.event_id = i.event_id
  GROUP BY C.event_id
) MG -- matching groups
group by inclusion_rule_mask
;

-- calculate gain counts
delete from @results_database_schema.cohort_inclusion_stats where cohort_definition_id = @target_cohort_id;
insert into @results_database_schema.cohort_inclusion_stats (cohort_definition_id, rule_sequence, person_count, gain_count, person_total)
select ir.cohort_definition_id, ir.rule_sequence, coalesce(T.person_count, 0) as person_count, coalesce(SR.person_count, 0) gain_count, EventTotal.total
from @results_database_schema.cohort_inclusion ir
left join
(
  select i.inclusion_rule_id, count(i.event_id) as person_count
  from #cohort_candidate C
  JOIN #inclusionRuleCohorts i on C.event_id = i.event_id
  group by i.inclusion_rule_id
) T on ir.rule_sequence = T.inclusion_rule_id
CROSS JOIN (select count(*) as total_rules from @results_database_schema.cohort_inclusion where cohort_definition_id = @target_cohort_id) RuleTotal
CROSS JOIN (select count(event_id) as total from #cohort_candidate) EventTotal
LEFT JOIN @results_database_schema.cohort_inclusion_result SR on SR.cohort_definition_id = @target_cohort_id AND (POWER(cast(2 as bigint),RuleTotal.total_rules) - POWER(cast(2 as bigint),ir.rule_sequence) - 1) = SR.inclusion_rule_mask -- POWER(2,rule count) - POWER(2,rule sequence) - 1 is the mask for 'all except this rule' 
WHERE ir.cohort_definition_id = @target_cohort_id
;

-- calculate totals
delete from @results_database_schema.cohort_summary_stats where cohort_definition_id = @target_cohort_id;
insert into @results_database_schema.cohort_summary_stats (cohort_definition_id, base_count, final_count)
select @target_cohort_id as cohort_definition_id, 
(select count(event_id) as total from #cohort_candidate) as person_count,
coalesce((
  select sr.person_count 
  from @results_database_schema.cohort_inclusion_result sr
  CROSS JOIN (select count(*) as total_rules from @results_database_schema.cohort_inclusion where cohort_definition_id = @target_cohort_id) RuleTotal
  where cohort_definition_id = @target_cohort_id and sr.inclusion_rule_mask = POWER(cast(2 as bigint),RuleTotal.total_rules)-1
),0) as final_count
;
}

TRUNCATE TABLE #inclusionRuleCohorts;
DROP TABLE #inclusionRuleCohorts;

TRUNCATE TABLE #cohort_candidate;
DROP TABLE #cohort_candidate;

TRUNCATE TABLE #PrimaryCriteriaEvents;
DROP TABLE #PrimaryCriteriaEvents;

TRUNCATE TABLE #Codesets;
DROP TABLE #Codesets;

