-- Data Cleaning 

SELECT * 
FROM layoffs; 

-- 1. Remove Duplicates 
-- 2. Standardise Data 
-- 3. Null Values or Blank Values 
-- 4. Remove Unnecessary Columns or Rows 

CREATE TABLE layoffs_staging 
LIKE layoffs; 

INSERT layoffs_staging 
SELECT * 
FROM layoffs; 

SELECT * 
FROM layoffs_staging; 

-- 1. Remove Duplicates 

-- row number restarts with each unique set of rows, unique rows = 1, duplicate rows = 2 and above

SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- CTE, temporary result set, identifies duplicate values 

WITH duplicate_cte AS 
	(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
	)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1; 
    
SELECT * 
FROM layoffs_staging
WHERE company = 'Casper'; 


-- Error Code: 1288. The target table duplicate_cte of the DELETE is not updatable

WITH duplicate_cte AS 
	(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging
	)
DELETE
FROM duplicate_cte 
WHERE row_num > 1; 

-- create new table to delete duplicate values 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2; 

INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging; 

-- delete duplicate values 

DELETE
FROM layoffs_staging2
WHERE row_num > 1; 

SELECT *
FROM layoffs_staging2
WHERE row_num > 1; 

-- 2. Standardising Data 

-- trim removes leading and trailing spaces in strings 

SELECT company, TRIM(company)
FROM layoffs_staging2; 

UPDATE layoffs_staging2
SET company = TRIM(company); 

-- assign similar values to same value 

-- industry 

SELECT DISTINCT industry
FROM layoffs_staging2; 

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; 

-- country 

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1; 

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'; 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

-- change format & data type 

-- date, %m = month, %d = day, %Y = year 

SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;   

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); 

SELECT `date`
FROM layoffs_staging2; 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; 

-- 3. Null Values or Blank Values

-- where total_laid_off = 0 -> NULL in raw data (data type set to int, NULL(string) converted to 0(int))

SELECT *
FROM layoffs_staging2
WHERE total_laid_off = '0'; 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off = '0' AND 
percentage_laid_off = 'NULL'; 

-- update '0' and 'NULL' values as NULL 

UPDATE layoffs_staging2
SET total_laid_off = NULL 
WHERE total_laid_off = '0'; 

UPDATE layoffs_staging2
SET percentage_laid_off = NULL 
WHERE percentage_laid_off = 'NULL'; 

-- industry 

SELECT *
FROM layoffs_staging2
WHERE industry = 'NULL' OR
industry = '' OR 
industry IS NULL;  

UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = 'NULL' OR
industry = ''; 

-- self join to check for companies with blank and non-blank values 
-- join on company & location to avoid confusing companies in different locations who may have same name 

SELECT t1.company, t1.location, t1.industry, t2.industry
FROM layoffs_staging2 AS t1 
JOIN layoffs_staging2 AS t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;  


UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
	ON t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL; 

-- check update was successful 

SELECT * 
FROM layoffs_staging2 
WHERE company = 'Airbnb'; 


-- 4. Remove Unnecessary Columns or Rows 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL  AND
percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL  AND
percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2; 

ALTER TABLE layoffs_staging2 
DROP COLUMN row_num; 