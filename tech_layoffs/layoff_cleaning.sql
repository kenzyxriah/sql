USE Tech_Layoffs
GO

select top 10 
	*
from layoffs

-- create a staging table to store outputs
-- CTAS - Create Table As Select

-- copy only the schema and not the data
SELECT *
INTO layoffs_staging
from layoffs
WHERE 1 = 0

-- insert data into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs
GO


select top 2
	*
from layoffs_staging

-- ============================================================
--  DATA CLEANING ROADMAP
-- ------------------------------------------------------------
--  1. Remove duplicate rows
--  2. Standardise data & fix inconsistencies
--  3. Review and handle NULL values
--  4. Drop unnecessary columns and rows
-- ============================================================

-- 1. Identify duplicate rows: using Ranking
with PotentialDuplicates as (
	select
	  *,
	  ROW_NUMBER() OVER (
			-- PARTITION BY company, total_laid_off, [date]
			-- more nuanced approach to identify duplicates
			PARTITION BY 
			company, [location], industry, total_laid_off,
			percentage_laid_off, [date], stage, country, funds_raised_millions

			ORDER BY (SELECT NULL)) AS row_num
	from layoffs_staging
)
select *
from PotentialDuplicates
where row_num > 1

-- spot check on Oda
select *
from layoffs_staging
where company = 'Oda'


-- Problem: We only identified the duplicates, how can we actually remove/clean them?
-- we create a ctas table to store the a ranked staging data, and we delete the duplicates from the new staging table
DROP TABLE IF EXISTS layoffs_staging_ranked

select
	*,
	ROW_NUMBER() OVER (
			PARTITION BY 
			company, [location], industry, total_laid_off,
			percentage_laid_off, [date], stage, country, funds_raised_millions

			ORDER BY (SELECT NULL)) 
			AS row_num
INTO layoffs_staging_ranked
from layoffs_staging

-- PREVIEW
SELECT TOP 3 
* FROM layoffs_staging_ranked

--  Delete duplicates from the staging table
DELETE FROM layoffs_staging_ranked
WHERE row_num > 1
GO

-- CONFIRMATION CHECK
SELECT * FROM layoffs_staging_ranked
WHERE row_num > 1

-- 2: Standardise data & fix inconsistencies in Dimensions

-- A: Find the error and issues to fix
select top 1
* from layoffs_staging_ranked

-- company, location, industry, stage, country are all dimensions that we can standardise
-- spot check empty and NULL values

select distinct company
from layoffs_staging_ranked
order by company
-- CLEAR


select distinct industry
from layoffs_staging_ranked
order by industry
-- ACTUAL NULL INDUSTRY; CHECK IF WE CAN FILL FORWARD
-- Spurious Crypto entries, consolidate to "Crypto"
-- NULL AS A STRING, DELETE IN FUTURE

select * 
from  layoffs_staging_ranked
where industry = ''
order by industry
-- clear


select distinct stage
from layoffs_staging_ranked
-- NULL AS A STRING, DELETE IN FUTURE

select * 
from  layoffs_staging_ranked
where stage = ''
-- clear


select distinct country
from layoffs_staging_ranked
ORDER BY country
-- SPURIOUS ENTRY ON UNITED STATES, HAS "." AT THE END OF THE SECOND ONE

select * 
from  layoffs_staging_ranked
where country = ''
-- clear

-- B1: Managing the Industry column
-- ACTUAL NULL INDUSTRY; CHECK IF WE CAN FILL FORWARD
-- Spurious Crypto entries, consolidate to "Crypto"
-- NULL AS A STRING, DELETE IN FUTURE

-- consolidate
UPDATE layoffs_staging_ranked
SET industry = 'Crypto'
where industry like 'Crypto%'
	and industry <> 'Crypto' -- skipping already correct rows


-- NULL AS A STRING
UPDATE layoffs_staging_ranked
SET industry = NULL
where industry = 'NULL'

select distinct industry
from layoffs_staging_ranked
order by industry

-- Fix null as a string in stage column
UPDATE layoffs_staging_ranked
SET stage = NULL
where stage like 'NULL%'

select distinct stage
from layoffs_staging_ranked
order by stage

-- COUNTRY : SPURIOUS ENTRY ON UNITED STATES, HAS "." AT THE END OF THE SECOND ONE
SELECT TRIM('.' FROM 'United States.') AS TrimTest;

UPDATE layoffs_staging_ranked
SET country = TRIM('.' FROM country)

select distinct country
from layoffs_staging_ranked
ORDER BY country

-- fixing Null strings in the numerical columns
select distinct top 2
--total_laid_off
-- percentage_laid_off
funds_raised_millions
from layoffs_staging_ranked
ORDER BY funds_raised_millions

select distinct top 2
[date]
from layoffs_staging_ranked
ORDER BY [date]
-- null values are in date


-- check for null strings
select * 
from layoffs_staging_ranked
where total_laid_off like 'NULL%'
	or percentage_laid_off like 'NULL%'
	or funds_raised_millions like 'NULL%'

UPDATE layoffs_staging_ranked
SET total_laid_off = NULL
where total_laid_off like 'NULL%'

UPDATE layoffs_staging_ranked
SET percentage_laid_off = NULL
where percentage_laid_off like 'NULL%'

UPDATE layoffs_staging_ranked
SET funds_raised_millions = NULL
where funds_raised_millions like 'NULL%'

-- alter my colums
-- confirm if i could convert without issues
SELECT
    CAST(total_laid_off  AS INT)   AS total_laid_off_check,
    CAST(percentage_laid_off  AS FLOAT) AS pct_check,
    CAST(funds_raised_millions AS INT)   AS funds_check

from layoffs_staging_ranked
go
-- confirmed that no issues will occur upon type conversion
-- actually alter the staging table

alter table layoffs_staging_ranked
alter column total_laid_off INT
go

alter table layoffs_staging_ranked
alter column percentage_laid_off FLOAT
go

alter table layoffs_staging_ranked
alter column funds_raised_millions FLOAT
go

select distinct
funds_raised_millions
from layoffs_staging_ranked


-- 3: MANAGE THE NULL VALUES BY POSSIBLE FILL FORWARD FOR CATEGORY
-- STAGE: FUTURE YOU, FIX THIS

-- INDUSTRY: SELF JOIN
UPDATE l1
SET l1.industry = l2.industry

FROM layoffs_staging_ranked as l1
INNER JOIN layoffs_staging_ranked AS L2
	ON l2.company = l1.company 
WHERE
l1.industry is NULL
and l2.industry is not NULL

-- CHECK THOSE WITH NO FILL FORWARD
SELECT * 
FROM layoffs_staging_ranked
WHERE INDUSTRY IS NULL

SELECT * 
FROM layoffs_staging_ranked
WHERE company like 'Bally%'


-- STEP 4 : Remove Unnecessary Rows & Columns
delete from layoffs_staging_ranked
where total_laid_off is NULL
and percentage_laid_off is NULL


alter table layoffs_staging_ranked
drop column row_num;
go


-- ============================================================
--  FINAL : Cleaned Dataset
-- ============================================================

select *
from layoffs_staging_ranked