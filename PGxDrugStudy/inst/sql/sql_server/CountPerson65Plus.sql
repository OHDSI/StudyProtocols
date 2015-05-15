-- query-to-get-count-of-persons-being-prescribed-any-drug-using-age-at-exposure.sql

WITH persons_and_their_age AS (
		SELECT DISTINCT(DRUG_EXPOSURE.person_id), MIN((YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth)) AS person_age_first_prescription
		FROM DRUG_EXPOSURE,  PERSON
		WHERE DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE >= DATE '2009-01-01'
		AND   DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE <= DATE '2012-12-31'
		AND   DRUG_EXPOSURE.person_id = PERSON.person_id 
		AND   (YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth >= 65)
		AND   (YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth <= 110)
		GROUP BY DRUG_EXPOSURE.person_id
)
-- SELECT COUNT(person_id), min(person_age_at_first_prescription) as min_age, MAX(person_age_at_first_prescription) AS max_age, MIN(median_age_temp) AS median_age FROM 
--   (SELECT person_id, person_age_at_first_prescription, MEDIAN(person_age_at_first_prescription) OVER() AS median_age_temp
--     FROM persons_and_their_age)
SELECT person_age_first_prescription FROM persons_and_their_age
