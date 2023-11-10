
-- Viewing our full covid deaths dataset and trying to familiarize with the data and finding inconsistencies
SELECT *
FROM PortfolioProject..CovidDeaths
order by 3,4

-- Viewing our full covid vaccine dataset and trying to familiarize with the data and finding inconsistencies
SELECT *
FROM PortfolioProject..CovidVaccinations
order by 3,4

-- Selecting the specific columns of data that we are going to be using
SELECT location, date, total_cases, total_deaths, new_cases, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at total cases vs total deaths, showing the likelihood of dying of covid in each country

-- Looking at the total amount of cases in relation to each countries population, change '%countryname%' in order to se stats for wished country
SELECT location, date, total_cases, population, (total_cases/population)*100 as cases_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Sweden%' and continent is not null
ORDER BY cases_percentage DESC

-- Looking at the amount of deaths for each country (of those infected), in percentage, change '%countryname%' in order to se stats for wished country
SELECT location, date, total_cases, cast(total_deaths as int), (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Sweden%' and continent is not null
ORDER BY death_percentage DESC


--  Showing countries with highest highest infection count per population, ranking the country with highest number of COVID infected at the top.
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as Percent_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY Percent_population_infected DESC

-- Showing countries with highest death count per population. Ranking the country with highest amount of deathcases at the top.
SELECT location, population, MAX(cast(total_deaths as int)) as highest_deaths_count, MAX((total_deaths/population))*100 as Percent_population_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY population, location
ORDER BY Percent_population_deaths DESC

-- Breaking things down in continents and showing the total deaths of each continent
SELECT location, MAX(cast(total_deaths as int)) as total_deaths_count
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY total_deaths_count DESC


-- Breaking things down in continents and showing the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as total_deaths_count, MAX(total_deaths/population)*100 as Percent_continent_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY percent_continent_deaths DESC


-- Showing global numbers across the world, as death percentage

SELECT SUM(new_cases) as total_cases,
SUM(cast(new_deaths as int)) as total_deaths,
 SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Deathpercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Now I join the two tables together, in order to find more patterns

select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Let's now look at the total amount of people that have been vaccinatied each day in each country

	
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3


	
-- I want to do a rolling count that sums up tha vaccinated and adds them up, resulting in a count function
	
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac


-- Here we get the % of total cases based on the population in each country

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc


-- Running the same query but instead showing the highest infection ocunt and percent of popoulation infected for each country in the world
WITH RankedLocations AS
(
SELECT Location, Population, date,total_cases,ROW_NUMBER() OVER (PARTITION BY Location ORDER BY total_cases DESC) AS LocationRank
  FROM PortfolioProject..CovidDeaths
  WHERE Continent is not null
)
SELECT Location, Population, date, total_cases AS HighestInfectionCount, (total_cases / Population) * 100 AS PercentPopulationInfected
FROM RankedLocations
WHERE LocationRank = 1
ORDER BY  PercentPopulationInfected DESC
