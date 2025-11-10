-- =========================================
-- DATABASE SELECTION
-- =========================================
use world_layoffs;


-- =========================================
-- STAGING TABLE CREATION AND DUPLICATE REMOVAL
-- =========================================

-- Create a staging table like the original
create table layoffs_staging like layoffs;

-- Insert all records into staging table
insert into layoffs_staging
select * 
from layoffs;

-- Check for potential duplicates (basic)
select *,
       row_number() over(partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;

-- Identify duplicates using all relevant columns
with duplicates_CTE as (
    select *,
           row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
    from layoffs_staging
)
select * 
from duplicates_CTE
where row_num > 1;

-- Create a second staging table for clean-up
create table layoffs_staging2 like layoffs_staging;

-- Add row_num column for duplicate removal
alter table layoffs_staging2
add column row_num int;

-- Insert records with row number assigned
insert into layoffs_staging2  
select *,
       row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- Delete duplicates (keeping first occurrence)
delete from layoffs_staging2
where row_num > 1;

-- Confirm duplicates are removed
select * from layoffs_staging2
where row_num > 1;


-- =========================================
-- DATA STANDARDIZATION
-- =========================================

-- Trim company names
update layoffs_staging2
set company = trim(company);

-- Standardize industry names (Crypto)
update layoffs_staging2
set industry = "Crypto"
where industry like "Crypto%";

-- Standardize country names by removing trailing dots
update layoffs_staging2
set country = trim(trailing "." from country)
where country like "United States%";

-- Convert date column to DATE type
update layoffs_staging2
set `date` = str_to_date(`date`, "%m/%d/%Y");

alter table layoffs_staging2
modify column `date` date;

-- Replace empty industry values with NULL
update layoffs_staging2
set industry = null
where industry = '';

-- Fill NULL industry values using same company info
update layoffs_staging2 t1
join layoffs_staging2 t2
    on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null 
  and t2.industry is not null;

-- Remove records with both total_laid_off and percentage_laid_off as NULL
delete from layoffs_staging2
where total_laid_off is null
  and percentage_laid_off is null;

-- Drop temporary row_num column
alter table layoffs_staging2
drop column row_num;


-- =========================================
-- EXPLORATORY DATA ANALYSIS (EDA)
-- =========================================

-- Maximum layoffs
select max(total_laid_off)
from layoffs_staging2;

-- Full layoffs (100% of employees) ordered by funds raised
select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- Total layoffs per company
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- Date range in dataset
select min(`date`), max(`date`)
from layoffs_staging2;

-- Total layoffs per industry
select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- Total layoffs per country
select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

-- Total layoffs per year
select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 1 desc;

-- Total layoffs per stage
select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

-- Total percentage layoffs per company
select company, sum(percentage_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- =========================================
-- ROLLING TOTAL OF LAYOFFS BY MONTH
-- =========================================
with rolling_total as (
    select substring(`date`,1,7) as `MONTH`, sum(total_laid_off) as total_off
    from layoffs_staging2
    where substring(`date`,1,7) is not null
    group by `MONTH`
    order by 1 asc
)
select `MONTH`, total_off,
       sum(total_off) over(order by `MONTH`) as Rolling_Total
from rolling_total;

-- Total percentage layoffs per company per year
select company, year(`date`), sum(percentage_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

-- Top 5 companies with most layoffs per year
with company_year(company, years, total_laid_offs) as (
    select company, year(`date`), sum(total_laid_off)
    from layoffs_staging2
    group by company, year(`date`)
), company_year_rank as (
    select *,
           dense_rank() over(partition by years order by total_laid_offs desc) as ranking
    from company_year
    where years is not null
)
select *
from company_year_rank
where ranking <= 5;
