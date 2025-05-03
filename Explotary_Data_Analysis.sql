-- Exploratory Data Analysis

-- Select all columns from the layoffs_staging2 table
SELECT *
FROM layoffs_staging2;

-- Find the maximum number of total layoffs and percentage of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Select records where the percentage of layoffs is 100% and order them by funds raised in descending order
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Group the layoffs by company and sum up the total number of layoffs, order by the total layoffs in descending order
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Find the minimum and maximum date in the layoffs_staging2 table
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Group the layoffs by industry and sum up the total number of layoffs, order by the total layoffs in descending order
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Group the layoffs by country and sum up the total number of layoffs, order by the total layoffs in descending order
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Group the layoffs by the year of the date and sum up the total number of layoffs, order by year in descending order
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Select all records from the layoffs_staging2 table
SELECT *
FROM layoffs_staging2;

-- Group the layoffs by stage and sum up the total number of layoffs, order by the total layoffs in descending order
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Group the layoffs by month (extracted from the date), sum up the total number of layoffs, and order by the month in ascending order
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Calculate a rolling total of layoffs by month
WITH Rolling_Total AS
(
    -- Select the month and sum of layoffs by month
    SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
-- Select the month, total layoffs, and rolling total of layoffs
SELECT `MONTH`, total_off,
    SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Group the layoffs by company and sum up the total number of layoffs, order by the total layoffs in descending order
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Group the layoffs by company and year, sum up the total number of layoffs, order by the total layoffs in descending order
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, `year`
ORDER BY 3 DESC;

-- Using CTE (Common Table Expression) to find the top 5 companies with the most layoffs per year
WITH Company_Year (company, years, total_laid_off) AS
(
    -- Summing total layoffs per company and year
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`) 
), 
Company_Year_Rank AS
(
    -- Ranking companies by total layoffs per year
    SELECT *,
    DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
-- Select the top 5 companies with the most layoffs per year
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
