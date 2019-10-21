SELECT person.person_id
FROM @cdm_database_schema.person
INNER JOIN @cdm_database_schema.observation_period
	ON person.person_id = observation_period.person_id
WHERE observation_period_start_date <= DATEADD(DAY, -@washout_days, CAST('@period_end_date' AS DATE))
	AND observation_period_end_date >= CAST('@period_start_date' AS DATE)
	AND YEAR(CAST('@period_end_date' AS DATE)) - year_of_birth >= @min_age
	AND YEAR(CAST('@period_start_date' AS DATE)) - year_of_birth >= @max_age;
