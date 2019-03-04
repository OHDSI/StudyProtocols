select c.concept_id
from @code_list_schema.@code_list_table cl
inner join @vocabulary_database_schema.concept c
  on c.concept_id = cl.concept_id
  and c.concept_class_id = 'Ingredient'
where code_list_name = '@drug'
