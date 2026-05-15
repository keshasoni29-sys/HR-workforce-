create database hr
use hr

select * from hr_data

select termdate from hr_data
order by termdate desc

update hr_data
set termdate = format(convert(datetime,left(termdate,19),120),'yyyy-mm-dd')

alter table hr_data
add new_termdate date

---copy converted time values from termdate to new_termdate--
update hr_data
set new_termdate = case
 when termdate is not null and isdate(termdate) = 1 then cast(termdate as datetime) else null end

 --create new column "age"--
 alter table hr_data
 add age nvarchar(50);

 --populate new column with age--
 update hr_data
 set age = DATEDIFF(year,birthdate,getdate())

 select age from hr_data

 --Questions from answer the data--
 --1. whats the age distrubition in the company?
 --age distribution

 select MIN(age) as youngest, MAX(age) as oldest from hr_data

 --age group distribution
  select age_group,
 count(*) as count
 FROM
 (select 
  case 
   when age >= 21 and age <= 30 then '21 to 30'
   when age >= 31 and age <= 40 then '31 to 40'
   when age >= 41 and age <= 50 then '41 to 50'
   else '50+'
   end as age_group
 from hr_data
 where new_termdate is NULL
 ) as subquery
group by age_group
order by age_group desc

--
WITH ActiveEmployees AS (
    SELECT *, 
        (CONVERT(int, CONVERT(char(8), GETDATE(), 112)) - CONVERT(int, CONVERT(char(8), birthdate, 112))) / 10000 AS exact_age
    FROM hr_data
    WHERE new_termdate IS NULL OR new_termdate > GETDATE()
)
-- Q1: Age Distribution
SELECT 
    CASE 
        WHEN exact_age BETWEEN 21 AND 30 THEN '21 to 30'
        WHEN exact_age BETWEEN 31 AND 40 THEN '31 to 40'
        WHEN exact_age BETWEEN 41 AND 50 THEN '41 to 50'
        ELSE '50+' 
    END AS age_group,
    COUNT(*) AS count
FROM ActiveEmployees
GROUP BY CASE 
        WHEN exact_age BETWEEN 21 AND 30 THEN '21 to 30'
        WHEN exact_age BETWEEN 31 AND 40 THEN '31 to 40'
        WHEN exact_age BETWEEN 41 AND 50 THEN '41 to 50'
        ELSE '50+' 
    END
-- Added ORDER BY clause here
ORDER BY age_group DESC;

--age group distribution by gender
 select age_group,
 gender,
 count(*) as count
 FROM
 (select 
  case 
   when age >= 21 and age <= 30 then '21 to 30'
   when age >= 31 and age <= 40 then '31 to 40'
   when age >= 41 and age <= 50 then '41 to 50'
   else '50+'
   end as age_group,
   gender
 from hr_data
 where new_termdate is NULL
 ) as subquery
group by age_group,gender
order by age_group,gender asc

--
WITH ActiveEmployeeData AS (
    SELECT 
        gender,
        -- Calculating precise age to ensure people are placed in the correct bucket
        (CONVERT(int, CONVERT(char(8), GETDATE(), 112)) - CONVERT(int, CONVERT(char(8), birthdate, 112))) / 10000 AS age
    FROM hr_data
    -- Inclusion of future termination dates ensures 1,477 extra active employees are counted
    WHERE new_termdate IS NULL OR new_termdate > GETDATE()
)
SELECT 
    age_group,
    gender,
    COUNT(*) AS count
FROM (
    SELECT 
        gender,
        CASE 
            WHEN age BETWEEN 21 AND 30 THEN '21 to 30'
            WHEN age BETWEEN 31 AND 40 THEN '31 to 40'
            WHEN age BETWEEN 41 AND 50 THEN '41 to 50'
            ELSE '50+' 
        END AS age_group
    FROM ActiveEmployeeData
    WHERE age >= 21
) AS AgeBuckets
GROUP BY age_group, gender
ORDER BY age_group, gender;

--2. what's the gender breakdown in the company?
SELECT gender, COUNT(*) as count 
FROM hr_data 
GROUP BY gender;

--3. How does gender vary across the department and gender?
select department,
gender,
COUNT(gender) as count
from hr_data
where new_termdate is null
group by department, gender
order by department,gender asc;

--job title--
select department,
jobtitle,gender,
COUNT(gender) as count
from hr_data
where new_termdate is null
group by department,jobtitle, gender
order by department,jobtitle,gender asc;

--similar to above
/*select department,
      jobtitle,
	  SUM(case when gender = 'Male' then 1 else 0 end) as male_count,
	  SUM(case when gender = 'Female' then 1 else 0 end) as female_count
from hr_data
where new_termdate is null
group by department , jobtitle asc;*/

--4. what's the race distribution in the company?

select race,
COUNT(*) as count
from hr_data
where new_termdate is null
group by race
order by count desc;

--5. what's the average length of employment in the company?
select 
avg(DATEDIFF(year,hire_date,new_termdate)) as tenure
from hr_data
where new_termdate is not null and new_termdate <= GETDATE();

-- Average tenure of everyone (Active + Terminated)
/*SELECT 
    AVG(DATEDIFF(year, hire_date, ISNULL(new_termdate, GETDATE()))) AS avg_tenure_years
FROM hr_data;*/

--6. which department has the highest turnover rate?
--get total count
--get terminate count
--terminated count/total count

select department,
total_count,
terminated_count,
round((cast(terminated_count as float)/total_count),2)*100 as turnover_rate
from 
    (select 
     department,
     COUNT(*) as total_count,
     sum(case
        when new_termdate is not null and new_termdate <= getdate() then 1 else 0
	    end
        ) as terminated_count
     from hr_data
     group by department
	 ) as subquery
order by turnover_rate desc;

--
SELECT department,
    total_count,
    terminated_count,
    ROUND((CAST(terminated_count AS float) / total_count) * 100, 2) AS turnover_percent
FROM (
    SELECT department,
        COUNT(*) AS total_count,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) AS terminated_count
    FROM hr_data
    GROUP BY department
) as subquery
ORDER BY turnover_percent DESC;

--7. What is the tenure distribution for each department?

select 
department,
AVG(datediff(year,hire_date,new_termdate)) as tenure
from hr_data
where new_termdate is not null and new_termdate <= GETDATE()
group by department
order by tenure desc;

--8. How many employees work remotely for each department?

select
location,
COUNT(*) as count
from hr_data
where new_termdate is null
group by location;

--9. what's the distribution of employees across different states?

select 
location_state,
COUNT(*) as count
from hr_data
where new_termdate is null
group by location_state
order by count desc;

--10. How are job titles distributed in company?

select 
 jobtitle,
 COUNT(*) as count
 from hr_data
 where new_termdate is null
 group by jobtitle
 order by count desc;

 --11. how have employees hire counts varied over time?
 --calculate hires
 --calculate terminations
 --(hires-terminations)/hires percent hire change

 select 
 hire_year,
 hires,
 terminations,
 hires - terminations as net_change,
 round(cast(hires - terminations AS float)/nullif(hires,0)*100,2) as percent_hire_changes
 from
  (select
   YEAR(hire_date) as hire_year,
   count(*) as hires,
   sum(case when new_termdate is not null and new_termdate <= getdate() then 1 else 0 end) as terminations
   from hr_data
   group by year(hire_date)
   ) as subquery
order by hire_year asc;
