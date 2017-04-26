IF OBJECT_ID('@target_database_schema.@target_cohort_table', 'U') IS NOT NULL
  DROP TABLE @target_database_schema.@target_cohort_table;
  
CREATE TABLE @target_database_schema.@target_cohort_table (
	subject_id BIGINT, 
	cohort_definition_id BIGINT,
	cohort_start_date DATE,
	cohort_end_date DATE
);
