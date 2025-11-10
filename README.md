# SQL_EDA

## Skills Demonstrated
- Duplicate detection/removal using `ROW_NUMBER()` with partitions.  
- Data standardization: trimming, normalizing industry & country values, date conversion.  
- Handling missing values and propagating non-null data.  
- Exploratory data analysis: aggregates (`SUM`, `MAX`), rolling totals, ranking top companies per year.  
- Structured workflow with staging tables for clean and reproducible analysis.

## Project Steps
This project analyzes company layoffs in MySQL:

1. **Staging Tables:**  
   - `layoffs_staging` — raw copy  
   - `layoffs_staging2` — cleaned & deduplicated  

2. **Data Cleaning:**  
   - Remove duplicates, trim strings, standardize industries/countries, convert dates.  
   - Handle missing values and propagate industry info by company.  

3. **EDA - Here are the questions I was interested in answering:**  
   - Which company laid off the most employees overall?  
   - Which layoffs involved 100% of a workforce?  
   - How many employees were laid off per company, per industry, and per country?  
   - What are the trends of layoffs over time (monthly and yearly)?  
   - Which companies had the highest layoffs per year?  
   - How does the percentage of workforce reductions vary across companies and years?  

## Why It Matters
Provides a reproducible, clean SQL pipeline for analyzing layoffs, showcasing strong SQL analytical and data hygiene skills.

## Usage
1. Load the `layoffs` table.  
2. Run the staging, cleaning, and analysis scripts sequentially.  
3. Use `layoffs_staging2` for all EDA queries.
