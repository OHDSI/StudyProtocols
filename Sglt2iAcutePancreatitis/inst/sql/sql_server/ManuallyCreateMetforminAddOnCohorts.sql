
-- create the cohorts that require prior metformin 
insert into @cohortDatabaseSchema.@cohortTable
select cohort_definition_id + 1000000 cohort_definition_id, subject_id, min(cohort_start_date) cohort_start_date, min(cohort_end_date) cohort_end_date-- restrict to single record per person
from (
	select *
	from @cohortDatabaseSchema.@cohortTable
	where cohort_definition_id in (
		6492, 106493, 106494, 106495, 106500, 106706, 106521 -- primary analyses (excluding cana, with censoring for pp) and 6492 for cana with prior metformin
	)
) cs
left join @cdmDatabaseSchema.drug_exposure de 
	on de.person_id = cs.subject_id and drug_concept_id in (
	select descendant_concept_id 
	from @cdmDatabaseSchema.concept_ancestor 
	where ancestor_concept_id = 1503297 -- metformin
)
where de.drug_exposure_start_date is NOT NULL
and de.drug_exposure_start_date < cohort_start_date
group by cohort_definition_id, subject_id
