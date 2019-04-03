select
  cohort_definition_id
  , person_id as subject_id
  ,	case when number_of_drugs >= 3 then 500003 else 500000 + number_of_drugs end as covariate_id
  ,	1 as covariate_value
from (
  select
    cohort_definition_id
    , person_id
    , count(*) as number_of_drugs
	from (
    select distinct
      cohort_definition_id
      , cohort_of_interest
      , person_id
      , cohort_start_date
      , drug_concept_id
      , drug_concept_name
      ,	max(case when cl.concept_id is null then 0 else 1 end) as index_drug
    from (
      select distinct
      	c.cohort_definition_id
      	, u.cohort_of_interest
      	,	c.subject_id as person_id
      	, c.cohort_start_date
      	, de.drug_concept_id
      	,	c1.concept_name as drug_concept_name
      from @cohort_database_schema.@cohort_definition_table u
        join @cohort_database_schema.@cohort_table c
      		on c.cohort_definition_id = u.cohort_definition_id
        join @cdm_database_schema.observation_period op
      		on op.person_id = c.subject_id
      		and c.cohort_start_date between op.observation_period_start_date and op.observation_period_end_date
        join @cdm_database_schema.drug_era de
      		on de.person_id = c.subject_id
      		and de.drug_concept_id in (
      			select concept_id
      			from @cohort_database_schema.@code_list_table
      			where code_list_name = 'AHAs'
      		)
      		and c.cohort_start_date between de.drug_era_start_date and de.drug_era_end_date
        join @cdm_database_schema.concept c1
      		on c1.concept_id = de.drug_concept_id
      where u.exposure_cohort = 1
      and u.fu_strat_itt_pp0day = 1
    ) e
    left outer join @cohort_database_schema.@code_list_table cl
    	on code_list_name = cohort_of_interest
    	and e.drug_concept_id = cl.concept_id
    group by
      cohort_definition_id
      , cohort_of_interest
      , person_id
      , cohort_start_date
      , drug_concept_id
      , drug_concept_name
	) y
	group by
  cohort_definition_id
	, person_id
) z
order by 1,3
;
