CREATE TABLE #Codesets (
codeset_id int NOT NULL,
concept_id bigint NOT NULL
)
;

INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (21604254,1174888,21604255)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (21604254,1174888,21604255)
                                             and c.invalid_reason is null

                                           ) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 2 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (438130)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (438130)
                                             and c.invalid_reason is null

                                           ) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (438120)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (438120)
                                             and c.invalid_reason is null

                                           ) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 4 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (40225987,40178660,40178661,40015150,40225988,42898501,42898500,40178663,19034635,40225992,40225990,40178662,19098471,40225991,42898505,42898504,40178689,19034636,40225996,40225994,40178688,1133264,40225995,19034634,40180758,40180759,36232564,36246046,36232565,36244939)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (40225987,40178660,40178661,40015150,40225988,42898501,42898500,40178663,19034635,40225992,40225990,40178662,19098471,40225991,42898505,42898504,40178689,19034636,40225996,40225994,40178688,1133264,40225995,19034634,40180758,40180759,36232564,36246046,36232565,36244939)
                                             and c.invalid_reason is null

                                           ) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 5 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (44789201,44789202,4149607,2796047,2796058,2889405,2900296,2854466,2876003,2801512,2900298)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (44789201,44789202,4149607,2796047,2796058,2889405,2900296,2854466,2876003,2801512,2900298)
                                             and c.invalid_reason is null

                                           ) I
) C;
INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 6 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
                                           (
                                             select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (436954,440069,439312,4103426,436097,440694,4279309,4102817,4099809,440693,438120,432301,440379,4100520)and invalid_reason is null
                                             UNION  select c.concept_id
                                             from @vocabulary_database_schema.CONCEPT c
                                             join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
                                             and ca.ancestor_concept_id in (4102817,4099809,440693,4100520)
                                             and c.invalid_reason is null

                                           ) I
) C;


with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
  -- Begin Primary Events
  select row_number() over (PARTITION BY P.person_id order by P.start_date) as event_id, P.person_id, P.start_date, P.end_date, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM
  (
    select P.person_id, P.start_date, P.end_date, row_number() OVER (PARTITION BY person_id ORDER BY start_date ASC) ordinal, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
    FROM
    (
      -- Begin Drug Era Criteria
      select C.person_id, C.drug_era_id as event_id, C.drug_era_start_date as start_date, C.drug_era_end_date as end_date, C.drug_concept_id as TARGET_CONCEPT_ID, CAST(NULL as bigint) as visit_occurrence_id
      from
      (
        select de.*, row_number() over (PARTITION BY de.person_id ORDER BY de.drug_era_start_date, de.drug_era_id) as ordinal
        FROM @cdm_database_schema.DRUG_ERA de
        where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 1)
        ) C

        WHERE C.ordinal = 1
        -- End Drug Era Criteria

      ) P
    ) P
    JOIN @cdm_database_schema.observation_period OP on P.person_id = OP.person_id and P.start_date >=  OP.observation_period_start_date and P.start_date <= op.observation_period_end_date
    WHERE DATEADD(day,1095,OP.OBSERVATION_PERIOD_START_DATE) <= P.START_DATE AND DATEADD(day,0,P.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE AND P.ordinal = 1
    -- End Primary Events

  )
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
  INTO #qualified_events
  FROM
  (
    select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
    FROM primary_events pe

    JOIN (
      -- Begin Criteria Group
      select 0 as index_id, person_id, event_id
      FROM
      (
        select E.person_id, E.event_id
        FROM primary_events E
        LEFT JOIN
        (
          -- Begin Correlated Criteria
          SELECT 0 as index_id, p.person_id, p.event_id
          FROM primary_events P
          LEFT JOIN
          (
            -- Begin Condition Occurrence Criteria
            SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id
            FROM
            (
              SELECT co.*, row_number() over (PARTITION BY co.person_id ORDER BY co.condition_start_date, co.condition_occurrence_id) as ordinal
              FROM @cdm_database_schema.CONDITION_OCCURRENCE co
              where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 2)
              ) C


              -- End Condition Occurrence Criteria

            ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,0,P.START_DATE)
            GROUP BY p.person_id, p.event_id
            HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
            -- End Correlated Criteria

            UNION ALL
            -- Begin Correlated Criteria
            SELECT 1 as index_id, p.person_id, p.event_id
            FROM primary_events P
            LEFT JOIN
            (
              -- Begin Condition Occurrence Criteria
              SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id
              FROM
              (
                SELECT co.*, row_number() over (PARTITION BY co.person_id ORDER BY co.condition_start_date, co.condition_occurrence_id) as ordinal
                FROM @cdm_database_schema.CONDITION_OCCURRENCE co
                where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 3)
                ) C


                -- End Condition Occurrence Criteria

              ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,0,P.START_DATE)
              GROUP BY p.person_id, p.event_id
              HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
              -- End Correlated Criteria

              UNION ALL
              -- Begin Correlated Criteria
              SELECT 2 as index_id, p.person_id, p.event_id
              FROM primary_events P
              LEFT JOIN
              (
                -- Begin Drug Exposure Criteria
                select C.person_id, C.drug_exposure_id as event_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id
                from
                (
                  select de.*, row_number() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date, de.drug_exposure_id) as ordinal
                  FROM @cdm_database_schema.DRUG_EXPOSURE de
                  where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 4)
                  ) C


                  -- End Drug Exposure Criteria

                ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,0,P.START_DATE)
                GROUP BY p.person_id, p.event_id
                HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
                -- End Correlated Criteria

                UNION ALL
                -- Begin Correlated Criteria
                SELECT 3 as index_id, p.person_id, p.event_id
                FROM primary_events P
                LEFT JOIN
                (
                  -- Begin Procedure Occurrence Criteria
                  select C.person_id, C.procedure_occurrence_id as event_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE, C.procedure_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id
                  from
                  (
                    select po.*, row_number() over (PARTITION BY po.person_id ORDER BY po.procedure_date, po.procedure_occurrence_id) as ordinal
                    FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
                    where po.procedure_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 5)
                    ) C


                    -- End Procedure Occurrence Criteria

                  ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,0,P.START_DATE)
                  GROUP BY p.person_id, p.event_id
                  HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
                  -- End Correlated Criteria

                  UNION ALL
                  -- Begin Correlated Criteria
                  SELECT 4 as index_id, p.person_id, p.event_id
                  FROM primary_events P
                  LEFT JOIN
                  (
                    -- Begin Drug Exposure Criteria
                    select C.person_id, C.drug_exposure_id as event_id, C.drug_exposure_start_date as start_date, COALESCE(C.drug_exposure_end_date, DATEADD(day, 1, C.drug_exposure_start_date)) as end_date, C.drug_concept_id as TARGET_CONCEPT_ID, C.visit_occurrence_id
                    from
                    (
                      select de.*, row_number() over (PARTITION BY de.person_id ORDER BY de.drug_exposure_start_date, de.drug_exposure_id) as ordinal
                      FROM @cdm_database_schema.DRUG_EXPOSURE de
                      where de.drug_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 6)
                      ) C


                      -- End Drug Exposure Criteria

                    ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,1,P.START_DATE)
                    GROUP BY p.person_id, p.event_id
                    HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
                    -- End Correlated Criteria

                    UNION ALL
                    -- Begin Correlated Criteria
                    SELECT 5 as index_id, p.person_id, p.event_id
                    FROM primary_events P
                    LEFT JOIN
                    (
                      -- Begin Condition Occurrence Criteria
                      SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date, C.CONDITION_CONCEPT_ID as TARGET_CONCEPT_ID, C.visit_occurrence_id
                      FROM
                      (
                        SELECT co.*, row_number() over (PARTITION BY co.person_id ORDER BY co.condition_start_date, co.condition_occurrence_id) as ordinal
                        FROM @cdm_database_schema.CONDITION_OCCURRENCE co
                        where co.condition_concept_id in (SELECT concept_id from  #Codesets where codeset_id = 6)
                        ) C


                        -- End Condition Occurrence Criteria

                      ) A on A.person_id = P.person_id and A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE and A.START_DATE <= DATEADD(day,1,P.START_DATE)
                      GROUP BY p.person_id, p.event_id
                      HAVING COUNT(A.TARGET_CONCEPT_ID) = 0
                      -- End Correlated Criteria

                    ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
                    GROUP BY E.person_id, E.event_id
                    HAVING COUNT(index_id) = 6
                  ) G
                  -- End Criteria Group
                ) AC on AC.person_id = pe.person_id and AC.event_id = pe.event_id

              ) QE
              WHERE QE.ordinal = 1
              ;

              --- Inclusion Rule Inserts

              create table #inclusion_events (inclusion_rule_id bigint,
              person_id bigint,
              event_id bigint
            );

            with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
            (
              SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
              from
              (
                select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
                from #qualified_events Q
                LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
                GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
              ) MG -- matching groups

            )
            select event_id, person_id, start_date, end_date, op_start_date, op_end_date
            into #included_events
            FROM cteIncludedEvents Results
            WHERE Results.ordinal = 1
            ;



            -- generate cohort periods into #final_cohort
            with cohort_ends (event_id, person_id, end_date) as
            (
              -- cohort exit dates
              -- By default, cohort exit at the event's op end date
              select event_id, person_id, op_end_date as end_date from #included_events
            ),
              first_ends (person_id, start_date, end_date) as
              (
              select F.person_id, F.start_date, F.end_date
              FROM (
              select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal
              from #included_events I
              join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
              ) F
              WHERE F.ordinal = 1
              )
              select person_id, start_date, end_date
              INTO #cohort_rows
              from first_ends;

              with cteEndDates (person_id, end_date) AS -- the magic
              (
              SELECT
              person_id
              , DATEADD(day,-1 * 0, event_date)  as end_date
              FROM
              (
              SELECT
              person_id
              , event_date
              , event_type
              , MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal
              , ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
              FROM
              (
              SELECT
              person_id
              , start_date AS event_date
              , -1 AS event_type
              , ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
              FROM #cohort_rows

              UNION ALL


              SELECT
              person_id
              , DATEADD(day,0,end_date) as end_date
              , 1 AS event_type
              , NULL
              FROM #cohort_rows
              ) RAWDATA
              ) e
              WHERE (2 * e.start_ordinal) - e.overall_ord = 0
              ),
              cteEnds (person_id, start_date, end_date) AS
              (
              SELECT
              c.person_id
              , c.start_date
              , MIN(e.end_date) AS era_end_date
              FROM #cohort_rows c
              JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
              GROUP BY c.person_id, c.start_date
              )
              select person_id, min(start_date) as start_date, end_date
              into #final_cohort
              from cteEnds
              group by person_id, end_date
              ;

              DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
              INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
              select @target_cohort_id as cohort_definition_id, person_id, start_date, end_date
              FROM #final_cohort CO
              ;





              TRUNCATE TABLE #cohort_rows;
              DROP TABLE #cohort_rows;

              TRUNCATE TABLE #final_cohort;
              DROP TABLE #final_cohort;

              TRUNCATE TABLE #inclusion_events;
              DROP TABLE #inclusion_events;

              TRUNCATE TABLE #qualified_events;
              DROP TABLE #qualified_events;

              TRUNCATE TABLE #included_events;
              DROP TABLE #included_events;

              TRUNCATE TABLE #Codesets;
              DROP TABLE #Codesets;
