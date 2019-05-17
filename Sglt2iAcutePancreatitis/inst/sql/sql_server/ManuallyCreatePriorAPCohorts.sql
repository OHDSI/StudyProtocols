-- create the cohorts that require prior AP
insert into @cohortDatabaseSchema.@cohortTable
select cohort_definition_id + 2000000 cohort_definition_id, subject_id, min(cohort_start_date) cohort_start_date, min(cohort_end_date) cohort_end_date-- restrict to single record per person
from (
	select *
	from @cohortDatabaseSchema.@cohortTable
	where cohort_definition_id in (
		6492, 106493, 106494, 106495, 106500, 106706, 106521 -- primary analyses (excluding cana, with censoring for pp) and 6492 for cana with prior metformin
	)
) cs
left join @cdmDatabaseSchema.condition_occurrence co 
	on co.person_id = cs.subject_id and condition_concept_id in (
	select descendant_concept_id 
	from @cdmDatabaseSchema.concept_ancestor 
	where ancestor_concept_id = 199074 -- acute pancreatitis
)
join @cdmDatabaseSchema.visit_occurrence vo on vo.visit_occurrence_id = co.visit_occurrence_id and visit_concept_id = 9201
where co.condition_start_date is NOT NULL
and co.condition_type_concept_id  in (38000183,38000199,44786627,45756843,45756835,38000184,38000200,38000215,38000230)
and co.condition_start_date < cohort_start_date
group by cohort_definition_id, subject_id