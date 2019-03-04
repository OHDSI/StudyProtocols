select distinct
  @row_id_field AS row_id,
  @covariate_id_prefix + 998 AS covariate_id,
  1 AS covariate_value
from @cdm_database_schema.drug_era de
inner join @cohort_temp_table c
  on de.person_id = c.subject_id and de.drug_era_start_date < c.cohort_start_date
where de.drug_concept_id in
(
  select
    c.concept_id
  from @code_list_schema.@code_list_table cl
  inner join @vocabulary_database_schema.concept c
    on c.concept_id = cl.concept_id
    and c.concept_class_id = 'INGREDIENT'
  where code_list_name = '@drug'
)
{@cohort_id != -1} ? {AND c.cohort_definition_id = @cohort_id}
;
