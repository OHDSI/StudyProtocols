-- Place parameterized SQL statements in this file

{DEFAULT @cdmSchema = 'cdmSchema'}
{DEFAULT @resultsSchema = 'resultsSchema'}
{DEFAULT @studyName = 'studyName'}


USE @resultsSchema;

SELECT patient_counts FROM @studyName_patients_t2dm_final_counts;
