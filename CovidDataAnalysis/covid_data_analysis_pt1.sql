use CovidDataAnalysis;

UPDATE [dbo].[CovidVaccinations] -- UPDATE VALUE IN MY TABLES BASED OFF CONDITIONAL STATEMENTS
SET 
    median_age =  CASE WHEN 
                  median_age = 'na' 
                  THEN NULL 
                  ELSE median_age -- value already in the median age 
                  
                  END, --[NULL, 18.6.18.6, NULL. 20.9]
    gdp_per_capita = CASE WHEN gdp_per_capita = 'na' THEN NULL ELSE gdp_per_capita END,
    diabetes_prevalence = CASE WHEN diabetes_prevalence = 'na' THEN NULL ELSE diabetes_prevalence END,
    hospital_beds_per_thousand = CASE WHEN hospital_beds_per_thousand = 'na' THEN NULL ELSE hospital_beds_per_thousand END,
    life_expectancy = CASE WHEN life_expectancy = 'na' THEN NULL ELSE life_expectancy END;

GO; 

ALTER TABLE [dbo].[CovidDeaths] 
ALTER COLUMN total_cases FLOAT;

ALTER TABLE [dbo].[CovidVaccinations] 
ALTER COLUMN median_age FLOAT;

ALTER TABLE [dbo].[CovidVaccinations] 
ALTER COLUMN gdp_per_capita FLOAT;

ALTER TABLE [dbo].[CovidVaccinations] 
ALTER COLUMN diabetes_prevalence FLOAT;

ALTER TABLE [dbo].[CovidVaccinations] 
ALTER COLUMN hospital_beds_per_thousand FLOAT;

ALTER TABLE [dbo].[CovidVaccinations] 
ALTER COLUMN life_expectancy FLOAT;

GO;-- batch breaker



-- mock ---
select
median_age,
(CASE WHEN median_age > 20 then 1 else 0 end) as is_above_20
from CovidVaccinations

-- count of data points above 40 X - dont use
select
sum ((CASE WHEN median_age > 40 then 1 else 0 end)) 
from CovidVaccinations

-- count of data points for median age above 40
select
count(median_age)
from CovidVaccinations
where median_age > 40


-- EXPLORATION
-- visualize raw data

select top(5) *
from CovidDeaths

select top(5) *
from CovidVaccinations

-- UNIQUE DIMENSION
select 
distinct location
from CovidDeaths

-- extract out unusual locations
select top(5) *
from CovidDeaths
where location in ('World', 'Asia', 'Africa', 'North America')

--
select top(5) *
from CovidDeaths
where location not in ('World', 'Asia', 'Africa', 'North America')

-- hypothesis, where continent is Null, location serves as continent instead
-- OWID
select DISTINCT iso_code
from CovidDeaths
where iso_code like 'OWID%'-- '%OWID'
order by iso_code

/* 11 distinct OWID characters
OWID_KOS, OWID_ASI, OWID_SAM
OWID_CYN, OWID_AFR, OWID_M, OWID_OCE
OWID_EUN, OWID_EUR, OWID_INT, OWID_WRL

OWID_WRL: World. The sum total of all data for the entire planet.
OWID_AFR: Africa.
OWID_ASI: Asia.
OWID_EUR: Europe.
OWID_SAM: South America.
OWID_OCE: Oceania (Australia, New Zealand, etc.)

OWID_EUN: European Union. This is specifically the 27 EU member states, not the whole continent of Europe.
OWID_INT: International. Used for special cases like the Diamond Princess cruise ship where data didn't belong to a specific country.

unknowns kos,m, cyn
OWID_M : North America
*/

select top(5) *
from CovidDeaths
where iso_code = 'OWID_M'


select top(5) *
from CovidDeaths
where iso_code = 'OWID_KOS'

select top(5) *
from CovidDeaths
where iso_code = 'OWID_CYN'

-- if i need country based aggregations, I will filter where continent is Null
select *
from CovidDeaths
where 
iso_code = 'OWID_EUR' -- OWID_AFR, OWID_M, OWID_ASI, OWID_EUR
and
continent is not null


-- PHASE 1: RAW IMPACT
select
location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null

-- LIKELIHOOD OF DYING IN A PARTICULAR COUNTRY
-- death percentage, within the last 30 days
select top(30)
    location,
    date,
    total_deaths,
    total_cases,
    (total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
where 
continent is not null
-- filter based off country
and
location = 'Afghanistan'
order by date desc

select top(30)
    location,
    date,
    total_deaths,
    total_cases,
    (total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
where 
continent is not null
-- filter based off country
and
location = 'United states'
order by date desc

-- is the united states regaining sanity within the last 30 days
select 
    location,
    date,
    population,
    total_deaths,
    total_cases,
    (total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
where 
continent is not null
-- filter based off country
and
location = 'United states'

-- Nigerias
select distinct location
from CovidDeaths
where location like 'N%'


select 
    location,
    date,
    population,
    total_deaths,
    total_cases,
    (total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
where 
continent is not null
-- filter based off country
and
location = 'Nigeria'


-- Fatality rate by country
select
location,
sum(new_cases) as TotalCases,
sum(new_deaths) as TotalDeaths,
(sum(new_deaths)/sum(new_cases)) * 100 as DeathPercentage
from CovidDeaths
where continent is not null
group by location, population -- any dimensions used in the select statement must always have been included in the groupby clause
order by 
DeathPercentage desc;

select
location,
max(total_cases) as TotalCases,
max(total_deaths) as TotalDeaths,
(max(total_deaths)/max(total_cases)) * 100 as DeathPercentage
from CovidDeaths
where continent is not null
group by location, population -- any dimensions used in the select statement must always have been included in the groupby clause
order by 
DeathPercentage desc;

-- Severity rate, infection rate
select
location,
(sum(cast(new_cases as float))/population) * 100 as Severity,
max(population) as Population
from CovidDeaths
where continent is not null
group by location, population -- any dimensions used in the select statement must always have been included in the groupby clause
order by 
Severity desc

select *
from CovidDeaths
where location = 'Andorra'

-- infection rate
SELECT 
    location,  
    MAX(total_cases) as HighestInfectionCount,  
    Max((cast(total_cases as float)/population))*100 as PercentPopulationInfected
FROM dbo.CovidDeaths
where continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;

-- COMPARE CONTINENT TOTAL DEATH
SELECT
location,
MAX(total_deaths) AS TotalDeathCount
from CovidDeaths
where continent is null
and 
location in ('North America', 'Asia', 'Africa','Europe', 'South America', 'Oceania')
group by location
order by TotalDeathCount desc

-- Lockdown Severity vs. Vaccine Rollout
-- Did spending more days in severe lockdown correlate with a better daily vaccination rollout?
/*
This utilizes conditional aggregation (CASE inside SUM) 
to count how many days a country spent under severe lockdown, 
paired with their average daily vaccination rollout.

Severity level of the lockdown
> 75 severe
else not severe
*/
select *
from CovidVaccinations

--
select
   location,
   sum(case when stringency_index > 75 then 1 else 0 end) as severe_lockdown_days,
   avg(new_vaccinations_smoothed) as avg_daily_vaxes,
   max(people_fully_vaccited_per_hundred) as final_vax_coverage
from CovidVaccinations as v
where continent is not Null
group by location
order by severe_lockdown_days desc

