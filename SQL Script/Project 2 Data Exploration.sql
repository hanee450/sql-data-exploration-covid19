
/*
===========================================================
Exploratory Data Analysis
Question 1:
Preview the COVID Deaths dataset
===========================================================

Purpose:
- Explore the dataset before analysis.
- Verify the data has been imported correctly.
- Understand the available columns.

Note:
- ORDER BY 3,4 sorts the data by the 3rd column (location)
  and then by the 4th column (date).
- This shorthand is useful for quick exploration, but using
  explicit column names is generally recommended for production
  queries because it improves readability and maintainability.
===========================================================
*/

SELECT *
from portfolioproject2.coviddeaths
Order by 3,4;                


/*
===========================================================
Exploratory Data Analysis
Question 2:
Preview the COVID Vaccinations dataset
===========================================================

Purpose:
- Explore the vaccination dataset before analysis.
- Verify the data has been imported correctly.
- Understand the available columns.

Note:
- ORDER BY 3 sorts the data by the 3rd column (location).
- Positional ordering is useful for quick exploration,
  but explicit column names are generally preferred in
  production code for better readability.
===========================================================
*/

SELECT *
from portfolioproject2.covidvaccinations
Order by 3;

-- Select data that we are going to use.

/*
===========================================================
Exploratory Data Analysis
Question 3:
Select the relevant columns required for COVID-19 analysis
===========================================================

Purpose:
- Retrieve only the columns needed for analysis.
- Exclude summary rows (e.g., World, Asia, Europe) to
  focus only on country-level data.

Selected Columns:
- location      : Country name
- date          : Date of record
- total_cases   : Total confirmed COVID-19 cases
- new_cases     : Daily new confirmed cases
- total_deaths  : Total reported deaths
- population    : Country population

Note:
- WHERE continent IS NOT NULL removes aggregated regions
  and retains only country-level records.
- ORDER BY 1,2 sorts the data by the 1st column (location)
  and then the 2nd column (date).
===========================================================
*/

SELECT
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM portfolioproject2.coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at the total cases VS total deaths

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS deathpercentage
from portfolioproject2.coviddeaths
Where continent is not null
Order by 1,2;

-- Shows likeliood of dying if you contract covid in your country

/*
===========================================================
Exploratory Data Analysis
Question 4:
What was the likelihood of death after contracting COVID-19
in the United States over time?
===========================================================

Purpose:
- Calculate the Case Fatality Percentage (CFR) for the
  United States.
- Compare total confirmed cases with total reported deaths
  over time.

Formula:
Death Percentage =
(Total Deaths / Total Cases) × 100

Note:
- LIKE '%states%' filters records for the United States.
- ORDER BY 1,2 sorts by location and date.
===========================================================
*/

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS deathpercentage
from portfolioproject2.coviddeaths
Where location like '%states%'
and continent is not null
Order by 1,2;

/*
===========================================================
Exploratory Data Analysis
Question 5:
What percentage of the United States population was infected
with COVID-19 over time?
===========================================================

Purpose:
- Compare confirmed COVID-19 cases relative to the total
  population of the United States.
- Measure how widely COVID-19 spread across the country over time.

Formula:
Percentage of Population Infected =
(Total Cases / Population) × 100

Note:
- WHERE location LIKE '%states%' filters the data for
  the United States.
- WHERE continent IS NOT NULL excludes aggregate regions
  (e.g., World, Asia, Europe) and keeps only country-level data.
- ORDER BY 1,2 sorts the results by the 1st column (location)
  and then the 2nd column (date).
===========================================================
*/

-- Looking at Total cases VS population
-- Show percentage pf population got COVID
Select location, date, population, total_cases, (total_cases / population)*100 AS PercentPopulationInfection
from portfolioproject2.coviddeaths
Where location like '%states%'
and continent is not null
Order by 1,2;

/*
===========================================================
Exploratory Data Analysis
Question 6:
Which countries had the highest COVID-19 infection rate
relative to their population?
===========================================================

Purpose:
- Identify countries with the highest percentage of confirmed
  COVID-19 cases relative to their population.
- Compare infection rates across countries regardless of
  population size.

Formula:
Percentage of Population Infected =
(Total Cases / Population) × 100

Note:
- MAX(total_cases) returns the highest cumulative number of
  confirmed cases for each country.
- GROUP BY location, population returns one record per country.
- WHERE continent IS NOT NULL excludes aggregate regions
  (e.g., World, Asia, Europe).
- ORDER BY PercentPopulationInfection DESC ranks countries
  from the highest to the lowest infection percentage.
===========================================================
*/

-- Looking at countries with High Infection Rate compared to population

Select location, population, MAX(total_cases) AS HighInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfection
from portfolioproject2.coviddeaths
Where continent is not null
Group by location, population
Order by PercentPopulationInfection desc;

/*
===========================================================
Exploratory Data Analysis
Question 7:
Which countries recorded the highest total number of
COVID-19 deaths?
===========================================================

Purpose:
- Identify countries with the highest cumulative COVID-19
  death count.
- Compare the overall impact of the pandemic across countries.

Note:
- MAX(total_deaths) returns the highest cumulative death
  count recorded for each country.
- CAST(total_deaths AS UNSIGNED) converts the death count
  from text to a numeric data type before comparison.
- WHERE continent IS NOT NULL excludes aggregate regions
  (e.g., World, Asia, Europe).
- GROUP BY location returns one record per country.
- ORDER BY TotalDeathCount DESC ranks countries from the
  highest to the lowest total deaths.
===========================================================
*/
-- Which countries recorded the highest total number of COVID-19 deaths?

Select location, MAX(cast(total_deaths AS unsigned)) as TotalDeathCount
from portfolioproject2.coviddeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc;

-- LET'S BREAK THINGS DOWN BY CONTINENT

/*
===========================================================
Exploratory Data Analysis
Question 8:
Which continents recorded the highest total number of
COVID-19 deaths?
===========================================================

Purpose:
- Compare cumulative COVID-19 death counts across continents.
- Identify which continent experienced the highest reported
  number of deaths.

Note:
- GROUP BY continent returns one record for each continent.
- MAX(total_deaths) retrieves the highest cumulative death
  count for each continent.
- CAST(total_deaths AS UNSIGNED) converts text values into
  numeric values for accurate comparison.
- WHERE continent IS NOT NULL excludes non-continent
  aggregate records.
- ORDER BY TotalDeathCount DESC ranks continents from the
  highest to the lowest death count.
===========================================================
*/

-- Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths AS unsigned)) as TotalDeathCount
from portfolioproject2.coviddeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc;

-- Global Numbers

/*
===========================================================
Exploratory Data Analysis
Question 9A:
How did global COVID-19 cases, deaths, and the case fatality
percentage change over time?
===========================================================

Purpose:
- Calculate the daily global total of confirmed COVID-19 cases.
- Calculate the daily global total of reported deaths.
- Track how the global case fatality percentage changed
  throughout the pandemic.

Formula:
Death Percentage =
(Total Deaths / Total Cases) × 100

Note:
- SUM(new_cases) calculates the total confirmed cases
  reported globally for each day.
- SUM(new_deaths) calculates the total reported deaths
  globally for each day.
- GROUP BY date returns one record for each reporting date.
- WHERE continent IS NOT NULL excludes aggregate records
  (e.g., World, Asia, Europe) to prevent double counting.
- ORDER BY 1,2 sorts the results by date.
===========================================================
*/

Select date, SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as unsigned)) as total_deaths, 
SUM(cast(new_deaths as unsigned))/SUM(new_cases)*100 as deathpercentage
from portfolioproject2.coviddeaths
Where continent is not null
group by date
Order by 1,2;

/*
===========================================================
Exploratory Data Analysis
Question 9B:
What were the overall global COVID-19 cases, deaths, and
case fatality percentage?
===========================================================

Purpose:
- Calculate the total confirmed COVID-19 cases worldwide.
- Calculate the total reported COVID-19 deaths worldwide.
- Measure the overall percentage of confirmed cases that
  resulted in death during the selected period.

Formula:
Death Percentage =
(Total Deaths / Total Cases) × 100

Note:
- SUM(new_cases) calculates the total confirmed cases
  across all countries.
- SUM(new_deaths) calculates the total reported deaths
  across all countries.
- WHERE continent IS NOT NULL excludes aggregate records
  (e.g., World, Asia, Europe) to prevent double counting.
- This query returns a single summary row for the entire
  dataset because no GROUP BY clause is used.
===========================================================
*/

Select SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as unsigned)) as total_deaths, 
SUM(cast(new_deaths as unsigned))/SUM(new_cases)*100 as deathpercentage
from portfolioproject2.coviddeaths
Where continent is not null
Order by 1,2;

/*
===========================================================
Data Preparation
Question 10A:
How can COVID-19 deaths and vaccination data be combined
for the same country and date?
===========================================================

Purpose:
- Merge the COVID deaths and vaccination datasets.
- Match records based on location and date.
- Prepare a unified dataset for vaccination analysis.

Note:
- INNER JOIN combines records that exist in both tables.
- Matching on both location and date ensures the correct
  vaccination data is linked to each COVID-19 record.
===========================================================
*/

-- Looking at Total Population Vs Vaccinations

select *
from portfolioproject2.coviddeaths dea
join portfolioproject2.covidvaccinations vac
	ON dea.location = vac.location
    and dea.date = vac.date;
    
/*
===========================================================
Window Function
Question 10B:
How did the cumulative number of vaccinated people change
over time in each country?
===========================================================

Purpose:
- Calculate a running total of COVID-19 vaccinations for
  each country.
- Track vaccination progress over time.
- Prepare the data for calculating the vaccination
  percentage in the next step.

Note:
- INNER JOIN combines COVID-19 deaths and vaccination data
  using location and date.
- PARTITION BY location restarts the running total for
  each country.
- ORDER BY date calculates the cumulative vaccination
  count chronologically.
- CAST(new_vaccinations AS UNSIGNED) converts vaccination
  values into a numeric data type.
- WHERE continent IS NOT NULL excludes aggregate regions.
- The commented calculation
  (RollingPeopleVaccinated / population) * 100
  cannot be used in the same SELECT because
  RollingPeopleVaccinated is an alias created in that query.
===========================================================
*/
    
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated / population)*100
from portfolioproject2.coviddeaths dea
join portfolioproject2.covidvaccinations vac
	ON dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null
order by 2,3;

-- USING CTE

/*
===========================================================
Common Table Expression (CTE)
Question 11:
What percentage of each country's population received
COVID-19 vaccinations over time?
===========================================================

Purpose:
- Calculate the cumulative number of vaccinations for each
  country.
- Reuse the calculated running total using a CTE.
- Measure vaccination progress as a percentage of the
  country's population.

Formula:
Vaccination Percentage =
(Rolling People Vaccinated / Population) × 100

Note:
- The CTE stores the running vaccination total so it can
  be reused in the final SELECT statement.
- PARTITION BY location restarts the running total for
  each country.
- ORDER BY date calculates the cumulative vaccination
  count chronologically.
- WHERE continent IS NOT NULL excludes aggregate regions.
===========================================================
*/

with PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated / population)*100
from portfolioproject2.coviddeaths dea
join portfolioproject2.covidvaccinations vac
	ON dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null
-- order by 2,3
)
Select *, (RollingPeopleVaccinated / population) * 100
from PopvsVac;

-- Temp Table

/*
===========================================================
Temporary Table
Question 12:
How can a Temporary Table be used to store and reuse
vaccination data within the current SQL session?
===========================================================

Purpose:
- Store intermediate vaccination data after performing
  JOINs and Window Functions.
- Avoid recalculating complex queries multiple times.
- Reuse the stored data for additional calculations,
  reporting, or analysis within the same session.

How it Works:
1. Create a temporary table with the required columns.
2. Insert the processed vaccination data into the table.
3. Query the temporary table to calculate additional
   metrics such as Vaccination Percentage.

Formula:
Vaccination Percentage =
(Rolling People Vaccinated / Population) × 100

Why NULLIF()?
- Converts invalid text values like 'nan' into NULL
  before performing calculations.

Why COALESCE()?
- Replaces NULL values with 0 to ensure the running
  total calculation continues correctly.

Why CAST()?
- Converts text values into numeric data types so SQL
  can perform mathematical operations accurately.

Why Window Function?
- Calculates a cumulative (running) total of vaccinations
  for each country over time.

What is a Temporary Table?
- A Temporary Table stores data physically during the
  current database session.
- It can be queried multiple times without recalculating
  the original query.
- It is automatically removed when the session ends.

When to Use:
- When intermediate results need to be reused multiple
  times within the same session.
- When working with large or complex queries that would
  be inefficient to recalculate repeatedly.
===========================================================
*/

Create Table PercentPeopleVaccinated
(
Continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO PercentPeopleVaccinated
SELECT 
dea.continent, 
dea.location, 
dea.date, 

-- ✅ FIX population
CAST(NULLIF(dea.population, 'nan') AS DECIMAL(15,2)),

-- ✅ FIX new_vaccinations
CAST(NULLIF(vac.new_vaccinations, 'nan') AS DECIMAL(15,2)),

SUM(
    COALESCE(
        CAST(NULLIF(vac.new_vaccinations, 'nan') AS DECIMAL(15,2)),
        0
    )
) OVER (PARTITION BY dea.location ORDER BY dea.date)

FROM portfolioproject2.coviddeaths dea
JOIN portfolioproject2.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

Select *, (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
from PercentPeopleVaccinated;

-- Creating view to store data for later visualizations

/*
===========================================================
View
Question 13:
How can a SQL View be used to store reusable vaccination
analysis for reporting and visualization?
===========================================================

Purpose:
- Save the vaccination analysis query as a reusable View.
- Simplify future reporting and dashboard creation.
- Avoid rewriting complex JOINs and Window Functions.

How it Works:
1. Create a View using the required SQL query.
2. SQL stores the query definition (not the data).
3. Query the View just like a normal table whenever
   the latest results are needed.

What is a View?
- A View is a virtual table created from a SQL query.
- It stores only the query, not the actual data.
- Every time the View is queried, SQL executes the
  underlying query and returns the latest results.

Why Use a View?
- Improves code reusability.
- Simplifies reporting and dashboard development.
- Ensures consistent business logic across reports.
- Reduces duplicate SQL code.

Difference Between View and Temporary Table:
Temporary Table
- Stores the data physically.
- Exists only during the current database session.
- Suitable for intermediate calculations.

View
- Stores only the SQL query.
- Can be reused permanently until dropped.
- Always returns the latest data from the source tables.

When to Use:
- When the same query is used frequently in reports,
  dashboards, or business intelligence tools such as
  Power BI or Tableau.
===========================================================
*/

Create View PercentPeopleVaccinated_View as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as unsigned)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated / population)*100
from portfolioproject2.coviddeaths dea
join portfolioproject2.covidvaccinations vac
	ON dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null;
-- order by 2,3

Select *
from PercentPeopleVaccinated;
from PercentPeopleVaccinated;