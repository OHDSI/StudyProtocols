select cohort_definition_id
from scratch.dbo.epi534_mdcr
group by cohort_definition_id
having count(distinct subject_id) <= 15

union 

select cohort_definition_id
from scratch.dbo.epi534_optum
group by cohort_definition_id
having count(distinct subject_id) <= 15

union 

select cohort_definition_id
from scratch.dbo.epi534_ccae
group by cohort_definition_id
having count(distinct subject_id) <= 15