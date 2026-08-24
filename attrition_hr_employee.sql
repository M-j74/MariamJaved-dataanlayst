SELECT COUNT(DISTINCT EmployeeCount) AS ec, 
       COUNT(DISTINCT StandardHours) AS sh, 
       COUNT(DISTINCT Over18) AS o18
FROM  [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
--BASIC ANALYSIS
--THIS PART BELONG THE ATTRITION RATE (MEAN THE EMPLOYEE LEAVE DUE TO RESIGNMENT ,RETIRE OR DEATH)
----simply say employee leave but there is not replacement
SELECT 
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / COUNT(*) AS AttritionRate
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition];
---16.12244 attritionrate here
SELECT department,
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / COUNT(*) AS AttritionRate
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
group by Department
order by AttritionRate desc ----sales have higher attritionrate

SELECT overtime,
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / COUNT(*) AS AttritionRate
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
group by [OverTime]---yes attrirtion rate seems increase by over time

--SECTION 2 (COMPESTION AND STISFICTION)
select attrition,
avg(MonthlyIncome) as avg_income
from [WA_Fn-UseC_-HR-Employee-Attrition]
group by Attrition---yes attrition have less average

select attrition,
avg(JobSatisfaction) as avg_stis_
from [WA_Fn-UseC_-HR-Employee-Attrition]
group by Attrition---both seems same staisfiction average

SELECT JobRole,
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / COUNT(*) AS AttritionRate
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
group by JobRole
order by AttritionRate desc ----sales representive have higher attrition rate

--Section 3 — Advanced
with ranking as (
SELECT Department,
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / COUNT(*) AS AttritionRate
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
group by [Department]
)
select * 
,rank() over(order by attritionrate desc) as ranking
from ranking
---sales get higher rank in attritionrate

SELECT 
    Department,
    COUNT(CASE WHEN Attrition = 1 THEN 1 END) AS DeptAttritionCount,
    COUNT(*) AS DeptTotalEmployees,
    (COUNT(CASE WHEN Attrition = 1 THEN 1 END) * 100.0) / SUM(COUNT(CASE WHEN Attrition = 1 THEN 1 END)) OVER() AS PercentOfTotalAttrition
FROM [dbo].[WA_Fn-UseC_-HR-Employee-Attrition]
GROUP BY Department
ORDER BY PercentOfTotalAttrition DESC;

with counting as(
select [EmployeeNumber],[JobSatisfaction],[OverTime]
from [WA_Fn-UseC_-HR-Employee-Attrition]
where [JobSatisfaction]=1 and [OverTime] = 1) select count(* )from counting
--there is no result about this query so mean there is not red flag right now


select attrition, avg(cast(JobSatisfaction as float)) as avg_satisfaction
from [WA_Fn-UseC_-HR-Employee-Attrition]
group by Attrition