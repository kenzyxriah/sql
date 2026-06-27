Use CovidDataAnalysis
Go

alter table CovidDeaths
alter column total_cases float

alter table CovidDeaths
alter column total_deaths float;

select top(5) *
from CovidDeaths

select  *
from CovidVaccinations

select top(5) *
from CovidVaccinations


select * from CovidDeaths where continent is null
-- TEST

-- Daily Positivity Rate
-- On any given day globally, what percentage of tests came back positive?

select
date,
coalesce(avg(positive_rate), 0) * 100 as global_avg_positive_rate
from CovidVaccinations
-- where location = 'World'
where continent is not null
group by date
order by date

select * from CovidVaccinations where location = 'World'

-- Total Infection Footprint
-- What percentage of a country's total population actually contracted the virus?
select
location,
(count(cast(total_cases as float))/cast(population as float)) * 100 "PercentPopulationInfected"
from CovidDeaths
where continent is not null
group by location, population

select count(total_cases)
from CovidDeaths


-- Daily Global Death Scale
-- Worldwide, what did the daily death toll look like?
select 
date,
(total_deaths/total_cases) * 100 as DeathToll
from CovidDeaths
where 
location = 'World'
and
(total_deaths > 0 or total_cases > 0) -- filters out

select 
date,
coalesce((total_deaths/total_cases), 0) * 100 as DeathToll -- includes all data points
from CovidDeaths
where 
location = 'World'


-- Peak Vaccination Coverage
-- What was the absolute maximum vaccination coverage achieved by each country?
select *
from CovidVaccinations

select 
location,
max(total_vaccitions) as max_vaccinations
from CovidVaccinations
where continent is not null
group by location
order by max_vaccinations desc


-- Poverty as a Co-Morbidity
-- How do underlying health conditions differ across extreme poverty brackets?
select *
from CovidVaccinations
-- no group bys
select
	count(distinct location) as no_of_country_in_bracket, -- 1 value
	avg(gdp_per_capita) as mean_gdp,
	avg(cardiovasc_death_rate) as mean_cardio_deaths,-- has no relation to socio economic factor of the countries
	avg(diabetes_prevalence) as mean_diabetes_rate
from CovidVaccinations
where continent is not null
 and extreme_poverty is not null

select
	extreme_poverty as poverty_bracket
from CovidVaccinations
where continent is not null
 and extreme_poverty is not null

select
	extreme_poverty as poverty_bracket,
	count(distinct location) as no_of_country_in_bracket, -- 1 value
	avg(gdp_per_capita) as mean_gdp,
	avg(cardiovasc_death_rate) as mean_cardio_deaths,-- has no relation to socio economic factor of the countries
	avg(diabetes_prevalence) as mean_diabetes_rate
from CovidVaccinations
where continent is not null
 and extreme_poverty is not null
group by extreme_poverty
order by poverty_bracket desc

-- lets create our own unique brackets, reduce the cardinality using casewhen
select
	case 
		when extreme_poverty < 11 then 0
		when extreme_poverty > 10 and extreme_poverty < 31 then 1  --I use and over between, because between values are not inclusive
		when extreme_poverty > 30 and extreme_poverty < 50 then 2
		else 3
	end as poverty_bracket,
	count(distinct location) as no_of_country_in_bracket, -- 1 value
	avg(gdp_per_capita) as mean_gdp,
	avg(cardiovasc_death_rate) as mean_cardio_deaths,-- has no relation to socio economic factor of the countries
	avg(diabetes_prevalence) as mean_diabetes_rate
from CovidVaccinations
where continent is not null
 and extreme_poverty is not null
group by 
	case 
		when extreme_poverty < 11 then 0
		when extreme_poverty > 10 and extreme_poverty < 31 then 1  --I use and over between, because between values are not inclusive
		when extreme_poverty > 30 and extreme_poverty < 50 then 2
		else 3
	end 
order by poverty_bracket

-- use cte/subquery to avoid repeating the case when statement
WITH poverty_groups AS (
    SELECT
        location,
        gdp_per_capita,
        cardiovasc_death_rate,
        diabetes_prevalence,
        CASE
            WHEN extreme_poverty < 11 THEN 0
            WHEN extreme_poverty BETWEEN 11 AND 30 THEN 1
            WHEN extreme_poverty BETWEEN 31 AND 49 THEN 2
            ELSE 3
        END AS poverty_bracket
    FROM CovidVaccinations
    WHERE continent IS NOT NULL
      AND extreme_poverty IS NOT NULL
)

SELECT
    poverty_bracket,
    COUNT(DISTINCT location) AS no_of_country_in_bracket,
    AVG(gdp_per_capita) AS mean_gdp,
    AVG(cardiovasc_death_rate) AS mean_cardio_deaths,
    AVG(diabetes_prevalence) AS mean_diabetes_rate
FROM poverty_groups
GROUP BY poverty_bracket
ORDER BY poverty_bracket;

-- JOINS
-- total population continent/country vs vaccination daily
select
death.location,
death.date,
death.population,
death.new_cases,
vac.new_vaccinations

from CovidDeaths as death
JOIN CovidVaccinations as vac
on death.location = vac.location
    and death.date = vac.date
where death.continent is not null
      and vac.continent is not null
	  and death.location = 'United states' -- drilling down


--Wealth vs. Viral Suppression
-- Did having a higher GDP genuinely allow a country to suppress the viral reproduction ratebetter?
SELECT 
    d.location, 
    AVG(v.new_tests_smoothed_per_thousand) AS avg_daily_tests_per_k, 
    AVG(d.reproduction_rate) AS avg_reproduction_rate,
    MAX(v.gdp_per_capita) AS national_gdp
FROM CovidDeaths AS d
JOIN CovidVaccinations AS  v 
    ON d.iso_code = v.iso_code 
    AND d.date = v.date
WHERE d.continent IS NOT NULL 
GROUP BY d.location
HAVING AVG(v.new_tests_smoothed_per_thousand) IS NOT NULL 
   AND AVG(d.reproduction_rate) IS NOT NULL
ORDER BY national_gdp DESC;

-- EXTRA QUESTIONS
-- DATE FUNCTIONS
--The Monthly Waves
-- Can we see the "waves" of the pandemic by looking at monthly aggregations?

-- Infrastructure Growth Over Time
-- Did testing capacity scale up alongside existing health infrastructure across different quarters?


-- Testing Volatility
-- The Question: Which countries had the most erratic, unstable testing programs?