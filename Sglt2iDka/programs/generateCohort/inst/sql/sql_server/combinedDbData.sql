INSERT INTO @target_database_schema.@target_cohort_table (COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE)
SELECT @dbID + COHORT_DEFINITION_ID, SUBJECT_ID, COHORT_START_DATE, COHORT_END_DATE
FROM @target_database_schema.@sourceTable;

{@i == @lastDb}?{
  CREATE INDEX IDX_EPI535_COHORT ON @target_database_schema.@target_cohort_table (COHORT_DEFINITION_ID, SUBJECT_ID);
}
