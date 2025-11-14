-- 1. Show all Covid deaths data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY location, date;


-- 2. Total cases vs total deaths
-- Shows the likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, 
       (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE '%States%' AND continent IS NOT NULL
ORDER BY location, date;


-- 3. Total cases vs population
-- Shows what percentage of the population got Covid
SELECT location, date, population, total_cases, 
       (total_cases/population)*100 AS population_infected_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;


-- 4. Countries with highest infection rate compared to population
SELECT location, population, 
       MAX(total_cases) AS highest_infection_count,
       MAX((total_cases/population))*100 AS population_infected_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage DESC NULLS LAST;


-- 5. Countries with highest death count
SELECT location, MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC NULLS LAST;


-- 6. Continents with highest death count
SELECT continent, MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC NULLS LAST;


-- 7. Global numbers
SELECT SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths, 
       (SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY total_cases;


-- 8. Population vs vaccinations (rolling sum)
WITH pop_vs_vac AS (
    SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
           SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
    FROM covid_deaths AS d
    JOIN covid_vaccinations AS v
      ON d.location = v.location
     AND d.date = v.date
    WHERE d.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 AS vaccinated_percentage
FROM pop_vs_vac;


-- 9. Health risk index by country (normalized factors 0-1)
WITH covid_risk_data AS (
    SELECT 
        d.location, 
        d.date, 
        d.total_deaths_per_million, 
        v.male_smokers, 
        v.female_smokers, 
        v.diabetes_prevalence, 
        v.cardiovasc_death_rate
    FROM covid_deaths AS d
    JOIN covid_vaccinations AS v
      ON d.location = v.location AND d.date = v.date
    WHERE d.continent IS NOT NULL
      AND v.male_smokers IS NOT NULL
      AND v.female_smokers IS NOT NULL
      AND v.diabetes_prevalence IS NOT NULL
      AND v.cardiovasc_death_rate IS NOT NULL
      AND d.total_deaths_per_million IS NOT NULL
),


latest_risk_data AS (
    SELECT 
        location, 
        MAX(date) AS latest_date
    FROM covid_risk_data
    GROUP BY location
),


normalized_data AS (
    SELECT 
        d.*,
        
        (d.male_smokers - MIN(d.male_smokers) OVER()) /
        NULLIF(MAX(d.male_smokers) OVER() - MIN(d.male_smokers) OVER(), 0)
        AS male_smokers_norm,
        
        (d.female_smokers - MIN(d.female_smokers) OVER()) /
        NULLIF(MAX(d.female_smokers) OVER() - MIN(d.female_smokers) OVER(), 0)
        AS female_smokers_norm,
        
        (d.diabetes_prevalence - MIN(d.diabetes_prevalence) OVER()) /
        NULLIF(MAX(d.diabetes_prevalence) OVER() - MIN(d.diabetes_prevalence) OVER(), 0)
        AS diabetes_norm,
        
        (d.cardiovasc_death_rate - MIN(d.cardiovasc_death_rate) OVER()) /
        NULLIF(MAX(d.cardiovasc_death_rate) OVER() - MIN(d.cardiovasc_death_rate) OVER(), 0)
        AS cardio_norm
        
    FROM covid_risk_data d
),


final_risk_data AS (
    SELECT 
        n.location,
        l.latest_date,
        n.male_smokers AS male_smokers_percent,
        n.female_smokers AS female_smokers_percent,
        n.diabetes_prevalence AS diabetes_prevalence_percent,
        n.cardiovasc_death_rate AS cardiovasc_death_rate_percent,
        n.total_deaths_per_million,
        
        ROUND((
            n.male_smokers_norm +
            n.female_smokers_norm +
            n.diabetes_norm +
            n.cardio_norm
        ) / 4, 3) AS health_risk_index
        
    FROM normalized_data n
    JOIN latest_risk_data l
      ON n.location = l.location AND n.date = l.latest_date
)


SELECT 
    ROW_NUMBER() OVER (ORDER BY health_risk_index DESC) AS risk_rank,
    location,
    latest_date,
    male_smokers_percent,
    female_smokers_percent,
    diabetes_prevalence_percent,
    cardiovasc_death_rate_percent,
    total_deaths_per_million,
    health_risk_index
FROM final_risk_data
ORDER BY risk_rank;


-- 10. Vaccination coverage speed: days to reach 50% fully vaccinated
WITH vaccination_progress AS (
    SELECT 
        v.location,
        v.date,
        v.people_fully_vaccinated_per_hundred,
        ROW_NUMBER() OVER (PARTITION BY v.location ORDER BY v.date) AS day_number
    FROM covid_vaccinations v
    JOIN covid_deaths d
      ON v.location = d.location
     AND v.date = d.date
    WHERE v.people_fully_vaccinated_per_hundred IS NOT NULL
      AND d.continent IS NOT NULL
),
first_50_percent AS (
    SELECT location, MIN(date) AS date_50_percent
    FROM vaccination_progress
    WHERE people_fully_vaccinated_per_hundred >= 50
    GROUP BY location
),
first_vaccination_day AS (
    SELECT location, MIN(date) AS first_vaccination_date
    FROM vaccination_progress
    WHERE people_fully_vaccinated_per_hundred > 0
    GROUP BY location
)
SELECT f.location,
       f.first_vaccination_date,
       t.date_50_percent,
       (t.date_50_percent - f.first_vaccination_date) AS days_to_50_percent
FROM first_vaccination_day f
JOIN first_50_percent t
  ON f.location = t.location
ORDER BY days_to_50_percent;






