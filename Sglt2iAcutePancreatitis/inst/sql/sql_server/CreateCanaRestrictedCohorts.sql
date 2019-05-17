insert into @cohortDatabaseSchema.@cohortTable
select cohort_definition_id + 100000 cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
from (
  select *
	from @cohortDatabaseSchema.@cohortTable
	where cohort_definition_id in (
    6493, 6494, 6495, 6499, 6500, 6502, 6503, 6504, 6505, 6506, 6507, 6508, 6509, 6510, 6511, 6512, 6513, 6514, 6515, 6516, 6517, 6518, 6519, 6520, 6521, 6523, 6524, 6525, 6526, 6527, 6528, 6529, 6706, 
    16493, 16494, 16495, 16499, 16500, 16502, 16503, 16504, 16505, 16506, 16507, 16508, 16509, 16510, 16511, 16512, 16513, 16514, 16515, 16516, 16517, 16518, 16519, 16520, 16521, 16523, 16524, 16525, 16526, 16527, 16528, 16529, 16706 
	)
) cs
left join @cdmDatabaseSchema.drug_exposure de on de.person_id = cs.subject_id and drug_concept_id in (
	select descendant_concept_id from @cdmDatabaseSchema.concept_ancestor where ancestor_concept_id = 43526465
)
where de.drug_exposure_start_date is NULL