-- Place parameterized SQL statements in this file

{DEFAULT @cdmSchema = 'cdmSchema'}
{DEFAULT @resultsSchema = 'resultsSchema'}
{DEFAULT @studyName = 'studyName'}


SELECT patient_counts FROM @resultsSchema.dbo.@studyName_patients_t2dm_final_counts;
