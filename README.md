#  COVID-19 Deaths & Vaccinations Analysis — SQL Project

![SQL](https://img.shields.io/badge/SQL-MySQL%20%7C%20PostgreSQL-blue?logo=postgresql)
![Data Analysis](https://img.shields.io/badge/Data%20Analysis-EDA-orange)
![CTEs](https://img.shields.io/badge/SQL-CTEs-green)
![Window Functions](https://img.shields.io/badge/SQL-Window%20Functions-purple)
![Joins](https://img.shields.io/badge/SQL-Joins-yellow)

---

## Table of Contents

- [📘 About the Project](#-about-the-project)
- [📁 Dataset](#-dataset)
- [🎯 Objectives](#-objectives)
- [🛠️ Skills & Concepts Applied](#-skills-concepts-applied)
- [📑 SQL Queries Overview](#-sql-queries-overview)
- [👤 Author](#-author)

---

## 📘 About the Project

This project explores global COVID-19 data using SQL to understand infection patterns,
mortality rates, vaccination progress, and health risk factors across countries.
It demonstrates analytical SQL skills through real-world questions and advanced transformations
using CTEs, window functions, and multi-table joins.

---

## 📁 Dataset

The data comes from [Our World in Data (OWID)](https://ourworldindata.org/covid-deaths), which includes:

| Table | Description |
|---|---|
| **covid_deaths** | Daily cases, deaths, population, deaths per million, continent |
| **covid_vaccinations** | Vaccinations per day, fully vaccinated %, health-related factors |

---

## 🎯 Objectives

The analysis aims to answer:

- What % of the population was infected in each country?
- What countries and continents had the highest death count?
- What was the global mortality rate?
- How did vaccination progress in each region?
- How long did it take each country to reach 50% full vaccination?

---

## 🛠️ Skills & Concepts Applied

### SQL Techniques
- Common Table Expressions (CTEs) — including chained CTEs
- Window Functions (`SUM() OVER`, `PARTITION BY`)
- Aggregations (`MAX`, `SUM`)
- Joins between multiple datasets
- Null handling & filtering with `IS NOT NULL`
- Calculated metrics and KPIs (death rate, infection rate, vaccination %)

### Analytical Skills
- Exploratory Data Analysis (EDA)
- Comparative country and continent analysis
- Population-based metrics
- Vaccination progress and speed evaluation

---

## 📑 SQL Queries Overview

### Query 1 — All COVID Deaths Data
Basic exploration of the full dataset ordered by location and date.
Shows cases, new cases, total deaths and population per country.

### Query 2 — Total Cases vs Total Deaths
Calculates the **death percentage** per country over time.
Focused on the United States to show the likelihood of dying after contracting COVID.

```sql
(total_deaths / total_cases) * 100 AS death_percentage
```

### Query 3 — Total Cases vs Population
Shows what **percentage of the population got infected** per country over time.

```sql
(total_cases / population) * 100 AS population_infected_percentage
```

### Query 4 — Countries with Highest Infection Rate
Ranks countries by the **maximum infection rate** relative to their population.

```sql
MAX((total_cases / population)) * 100 AS population_infected_percentage
```

### Query 5 — Countries with Highest Death Count
Ranks countries by their **total death count**, filtering out continent-level rows.

### Query 6 — Continents with Highest Death Count
Same analysis aggregated at the **continent level** to identify the most impacted regions.

### Query 7 — Global Numbers
Single-row summary of **total global cases, deaths and mortality rate** across the entire dataset.

```sql
(SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage
```

### Query 8 — Population vs Vaccinations (Rolling Sum)
Uses a **CTE + window function** to calculate a rolling cumulative vaccination count per country,
then derives the percentage of the population vaccinated over time.

```sql
SUM(v.new_vaccinations) OVER (
    PARTITION BY d.location
    ORDER BY d.location, d.date
) AS rolling_people_vaccinated
```

### Query 9 — Days to Reach 50% Vaccination Coverage
The most complex query — uses **4 chained CTEs** to calculate how many days each country
took from their first vaccination to reaching 50% coverage.

```
CTE 1: vaccination_progress   → rolling vaccination sum per country
CTE 2: vaccination_percentage → calculates % of population vaccinated
CTE 3: first_50_percent       → finds the first date each country hit 50%
CTE 4: first_vaccination_day  → finds the first day vaccinations started
Final: JOIN both CTEs to calculate days elapsed
```

---

## 👤 Author

**olgambencomo** — [github.com/olgambencomo](https://github.com/olgambencomo)
