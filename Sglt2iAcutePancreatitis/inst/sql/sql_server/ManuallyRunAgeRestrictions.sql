delete from scratch.dbo.epi534_mdcr 
where subject_id in (
	select subject_id
	from scratch.dbo.epi534_mdcr c
	join cdm_truven_mdcr_v698.dbo.person p on c.subject_id = p.person_id
	where year(cohort_start_date) - year_of_birth < 65
)

delete from scratch.dbo.epi534_ccae
where subject_id in (
	select subject_id 
	from scratch.dbo.epi534_ccae c
	join cdm_truven_ccae_v697.dbo.person p on c.subject_id = p.person_id
	where year(cohort_start_date) - year_of_birth >= 65
)
