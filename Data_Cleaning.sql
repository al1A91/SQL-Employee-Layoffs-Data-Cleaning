# Alternatives commented out, used while able data wizard being buggy.

-- CREATE TABLE layoffs (
--     #id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
--     company VARCHAR(100),
--     location VARCHAR(100),
--     industry VARCHAR(100),
--     total_laid_off INT,
--     percentage_laid_off DECIMAL(5, 2) NULL,
--     date VARCHAR(20) NULL,  -- Store the date as a string (VARCHAR)
--     stage VARCHAR(50),
--     country VARCHAR(50),
--     funds_raised_millions INT NULL
-- );



-- LOAD DATA LOCAL INFILE '/Users/alialnaimi/Data_Analyst_Bootcamp/MySQL/Data_Cleaning_project/layoffs.csv'
-- INTO TABLE layoffs
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (company, location, industry, total_laid_off, percentage_laid_off, @date, stage, country, @funds_raised_millions)
-- SET
--     date = @date,
--     funds_raised_millions = CASE 
--         WHEN @funds_raised_millions = '' THEN NULL
--         ELSE @funds_raised_millions
--     END;


# View staging data
SELECT *
FROM layoffs_staging;


# Create a copy of layoffs _staging table
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

# ------------------------------------------
# Step 1: Duplicate removal
# Create a copy of original table for staging
# ------------------------------------------
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte as 
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

WITH duplicate_cte as 
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

# ------------------------------------------
# Step 2: Create new table for cleaned data
# with row numbers for duplicate removal
# ------------------------------------------
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

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

# ------------------------------------------
# Step 3: Standardize company names (trim spaces)
# ------------------------------------------
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT *
FROM layoffs_staging2;

# ------------------------------------------
# Step 4: Clean industry names (e.g., Crypto vs CRYPTO)
# ------------------------------------------
SELECT * 
from layoffs_staging2
WHERE industry LIKE 'CRYPTO%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry 
from layoffs_staging2
ORDER BY 1;

# ------------------------------------------
# Step 5: Standardize country names
# ------------------------------------------
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# ------------------------------------------
# Step 6: Convert `date` from string to DATE format
# ------------------------------------------
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

# ------------------------------------------
# Step 7: Handle NULLs and blanks
# ------------------------------------------
# Check rows with missing layoffs data
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Check for missing or empty industries
SELECT DISTINCT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

# Convert empty strings to NULL
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

# Fill in missing industry using known values from same company/location
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# ------------------------------------------
# Step 8: Remove records with no valid layoff data
# ------------------------------------------
SELECT COUNT(*)
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# ------------------------------------------
# Step 9: Final cleanup
# Drop row_num column used for duplicate checks
# ------------------------------------------
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

# Final cleaned data output
SELECT *
FROM layoffs_staging2;


