IF OBJECT_ID('@target_database_schema.@target_cohort_table') IS NOT NULL
  DROP TABLE @target_database_schema.@target_cohort_table;

CREATE TABLE @target_database_schema.@target_cohort_table (
  cohort_definition_id INT,
  subject_id  BIGINT,
  cohort_start_date DATE,
  cohort_end_date DATE
);
