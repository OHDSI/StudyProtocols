{DEFAULT @cdm_database_schema = "cdm"}
{DEFAULT @cohort_database_schema = "cdm"}
{DEFAULT @cohort_table = "cohort"}

SELECT cohort_definition_id,
	COUNT(*) AS cohort_count,
	COUNT(DISTINCT subject_id) AS person_count
FROM @cohort_database_schema.@cohort_table
GROUP BY cohort_definition_id;


