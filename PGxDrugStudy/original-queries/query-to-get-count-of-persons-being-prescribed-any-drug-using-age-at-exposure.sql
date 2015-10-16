WITH persons_and_their_age_at_first_prescription_in_time_window AS (
		SELECT DISTINCT(DRUG_EXPOSURE.person_id), MIN((DATE_PART_YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth)) AS person_age_at_first_prescription_in_time_window
		FROM DRUG_EXPOSURE,  PERSON
		WHERE DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE >= DATE '2009-01-01'
		AND   DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE <= DATE '2012-12-31'
		AND   DRUG_EXPOSURE.person_id = PERSON.person_id 
		AND   (DATE_PART_YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth >= 0)
		AND   (DATE_PART_YEAR(DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE) - PERSON.year_of_birth < 14)
		GROUP BY DRUG_EXPOSURE.person_id
)
SELECT COUNT(person_id), min(person_age_at_first_prescription_in_time_window) as min_age, max(person_age_at_first_prescription_in_time_window) as max_age, min(median_age_temp) as median_age from 
  (SELECT person_id, person_age_at_first_prescription_in_time_window, median(person_age_at_first_prescription_in_time_window) over() as median_age_temp
    FROM persons_and_their_age_at_first_prescription_in_time_window)

