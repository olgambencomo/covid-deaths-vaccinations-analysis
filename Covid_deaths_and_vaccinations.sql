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



-- 9. Vaccination coverage speed: days to reach 50% fully vaccinated

WITH vaccination_progress AS (
    SELECT 
        d.continent,
        d.location,
        d.date,
        d.population,
        v.new_vaccinations,
        SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
    FROM covid_deaths AS d
    JOIN covid_vaccinations AS v
      ON v.location = d.location
     AND v.date = d.date
    WHERE  d.continent IS NOT NULL
),
vaccination_percentage  AS(
     SELECT *, (rolling_people_vaccinated/population)*100 as percentage_people_vaccinated
     FROM vaccination_progress
),
first_50_percent AS (
    SELECT location, MIN(date) AS date_50_percent
    FROM vaccination_percentage
    WHERE percentage_people_vaccinated >= 50
    GROUP BY location
),
first_vaccination_day AS (
    SELECT location, MIN(date) AS first_vaccination_date
    FROM vaccination_percentage
    WHERE new_vaccinations > 0
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






