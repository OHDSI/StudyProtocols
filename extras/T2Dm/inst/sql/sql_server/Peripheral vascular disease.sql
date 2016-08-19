CREATE TABLE #Codesets (
  codeset_id int NOT NULL,
  concept_id bigint NOT NULL
)
;

INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 5 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2006873,2211596,2211584,2211597)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2006873,2211596,2211584,2211597)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 6 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2002042,2002187,2002191,2002022,2107717,2107733,2107739,2107741,2107752,2107753,2107754,2107755,2107758,2107760,2107761,2107772,2107773,2107774,2107775,2107780,2107798,2107859,2107876,2107879,2107880,2107881,2107882,2107888,2107889,2107902,2107903,2107904,2107906,2107909,2107910,2107911,2107927,2107928,2107945,2107946,2107950,2107951,2107964,2107965,2107966,2107967,2107968,2107969,2107970,2108001,2108014,2108017,2108035,2108036,2108037,2108038,2108039,2108323,2108324,2108325)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2002042,2002187,2002191,2002022,2107717,2107733,2107739,2107741,2107752,2107753,2107754,2107755,2107758,2107760,2107761,2107772,2107773,2107774,2107775,2107780,2107798,2107859,2107876,2107879,2107880,2107881,2107882,2107888,2107889,2107902,2107903,2107904,2107906,2107909,2107910,2107911,2107927,2107928,2107945,2107946,2107950,2107951,2107964,2107965,2107966,2107967,2107968,2107969,2107970,2108001,2108014,2108017,2108035,2108036,2108037,2108038,2108039,2108323,2108324,2108325)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 7 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (76791,80819,79916,432417,434455,75050,81948,81106,74747,444285,433578,198528,73021,76819,74150,77661,78241,75073,440507,441962,81395,441401,79124,436799,74471,81402,437703,436247,435956,440556,437117,432473,444192,4009610,4015981,438887,440856,443113,440237,435951,437401,40481797,80241,81707,75382,73888,74185,74778,442348,444405,75386,443079,80242,77395,78577,77408,73335,442276,75387,78275,80857,442322,437132,133613,432750,140555,198287,443674,197724,81459,444073,4231695,201449,192496,201998,198023,198900,200877,440257,442321,319967,442942,197435,40480077)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (76791,80819,79916,432417,434455,75050,81948,81106,74747,444285,433578,198528,73021,76819,74150,77661,78241,75073,440507,441962,81395,441401,79124,436799,74471,81402,437703,436247,435956,440556,437117,432473,444192,4009610,4015981,438887,440856,443113,440237,435951,437401,40481797,80241,81707,75382,73888,74185,74778,442348,444405,75386,443079,80242,77395,78577,77408,73335,442276,75387,78275,80857,442322,437132,133613,432750,140555,198287,443674,197724,81459,444073,4231695,201449,192496,201998,198023,198900,200877,440257,442321,319967,442942,197435,40480077)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 8 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2002222,2002267,2108323,2108325,2108324)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2002222,2002267,2108323,2108325,2108324)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 9 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2006228,2006229,2006230,2006231,2006242,2006243,2006244,2006245,2006246,2006247,2006372,2105209,2105388,2105210,2105211,2104950,2105446,2105224,2105804,2105462,2105805,2105451)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2006228,2006229,2006230,2006231,2006242,2006243,2006244,2006245,2006246,2006247,2006372,2105209,2105388,2105210,2105211,2104950,2105446,2105224,2105804,2105462,2105805,2105451)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 10 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (2002042,2002187,2002191,2002022,2107717,2107733,2107739,2107741,2107752,2107753,2107754,2107755,2107758,2107760,2107761,2107772,2107773,2107774,2107775,2107780,2107798,2107859,2107876,2107879,2107880,2107881,2107882,2107888,2107889,2107902,2107903,2107904,2107906,2107909,2107910,2107911,2107927,2107928,2107945,2107946,2107950,2107951,2107964,2107965,2107966,2107967,2107968,2107969,2107970,2108001,2108014,2108017,2108035,2108036,2108037,2108038,2108039,2108323,2108324,2108325)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2002042,2002187,2002191,2002022,2107717,2107733,2107739,2107741,2107752,2107753,2107754,2107755,2107758,2107760,2107761,2107772,2107773,2107774,2107775,2107780,2107798,2107859,2107876,2107879,2107880,2107881,2107882,2107888,2107889,2107902,2107903,2107904,2107906,2107909,2107910,2107911,2107927,2107928,2107945,2107946,2107950,2107951,2107964,2107965,2107966,2107967,2107968,2107969,2107970,2108001,2108014,2108017,2108035,2108036,2108037,2108038,2108039,2108323,2108324,2108325)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 11 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (43020432,40483538)and invalid_reason is null
UNION  select c.concept_id
  from @cdm_database_schema.CONCEPT c
  join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (43020432,40483538)
  and c.invalid_reason is null

) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 12 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @cdm_database_schema.CONCEPT where concept_id in (40095503,19077697,1350333,19120717,19071427,1331247,1331274,19079220,40067933,19043593,19035628,40067936,19041816,1331277,40159619,19108056,40019822,19107864,40067905,19111248,19107867,19106733,19111253,19111249,19104095,1331276,19117304,1331249,19024117,19111250,19106732,19065090,19100449,19111251,19067560,19101826,1331275,19103818,19065084,19106731,40067931,40067932,40067934,40067937,40067938,40067939)and invalid_reason is null

) I
) C;

select row_number() over (order by P.person_id, P.start_date) as event_id, P.person_id, P.start_date, P.end_date, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date
INTO #PrimaryCriteriaEvents
FROM
(
  select P.person_id, P.start_date, P.end_date, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date ASC) ordinal
  FROM 
  (
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 5)
) C



UNION
select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 10)
) C



UNION
select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 7)
) C



UNION
select C.person_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID
from 
(
        select co.*, ROW_NUMBER() over (PARTITION BY co.person_id ORDER BY co.condition_start_date) as ordinal
        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 11)
) C



UNION
select C.person_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_EXPOSURE de
where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 12)
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
where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 11)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
SELECT 1 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID
from 
(
  select de.*, ROW_NUMBER() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date) as ordinal
  FROM @cdm_database_schema.DRUG_EXPOSURE de
where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 12)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN DATEADD(day,-7,P.START_DATE) and DATEADD(day,7,P.START_DATE)
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


UNION
select 2 as index_id, event_id
FROM
(
  select event_id FROM
  (
    select 0 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 5)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


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
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 8)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 1


  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 2
) G

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
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 10)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


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
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 6)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


  ) CQ
  GROUP BY event_id
  HAVING COUNT(index_id) = 2
) G

UNION
select 2 as index_id, event_id
FROM
(
  select event_id FROM
  (
    SELECT 0 as index_id, p.event_id
FROM #PrimaryCriteriaEvents P
LEFT JOIN
(
  select C.person_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID
from 
(
  select po.*, ROW_NUMBER() over (PARTITION BY po.person_id ORDER BY po.procedure_date) as ordinal
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 7)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) >= 1


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
where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 9)
) C



) A on A.person_id = P.person_id and A.START_DATE BETWEEN P.OP_START_DATE AND P.OP_END_DATE AND A.START_DATE BETWEEN P.OP_START_DATE and P.OP_END_DATE
GROUP BY p.event_id
HAVING COUNT(A.TARGET_CONCEPT_ID) = 0


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
  HAVING COUNT(index_id) >= 2
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

