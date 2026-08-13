select 
datepart(year,orderdate) as years,
sum(TotalDue) as total_revenue_by_year
from sales.SalesOrderHeader
group by 
datepart(year,orderdate) 
select * from sales.SalesOrderHeader
select * from sales.SalesTerritory
select name 
,sum(soh.TotalDue) as total_sales
from Sales.SalesTerritory as st
join sales.SalesOrderHeader as soh
on st.TerritoryID=soh.TerritoryID
group by Name
order by total_sales asc


select top 10
p.FirstName, p.LastName,
sum(soh.TotalDue) as total_sales
from Sales.SalesOrderHeader as soh
join Sales.SalesPerson as sp on soh.SalesPersonID = sp.BusinessEntityID
join Person.Person as p on sp.BusinessEntityID = p.BusinessEntityID
group by p.FirstName, p.LastName
order by total_sales desc


select
TerritoryID,
avg(TotalDue) as average
from sales.SalesOrderHeader
group by TerritoryID



---Section 2 — Product & category analysis
---"Which product categories generate the most revenue?" — Join SalesOrderDetail ? Product ? ProductSubcategory ? ProductCategory, sum LineTotal.

select 
sum(LineTotal) as total_revenue,
pc.Name
from sales.SalesOrderDetail as sod 
join Production.Product as p
on sod.ProductID=p.ProductID
join Production.ProductSubcategory as psc
on p.ProductSubcategoryID=psc.ProductSubcategoryID
join Production.ProductCategory as pc
on pc.ProductCategoryID=psc.ProductCategoryID
group by
pc.Name
order by total_revenue desc

--2 "What's our profit margin by product?" — Calculate (ListPrice - StandardCost) / ListPrice per product, find the top and bottom 10.


select
top 10
name,
(ListPrice-StandardCost)/nullif(ListPrice,0) as profit_margin
from production.Product
where (ListPrice-StandardCost)/nullif(ListPrice,0) is  not null
order by profit_margin desc

--bottom 10
select
top 10
name,
(ListPrice-StandardCost)/nullif(ListPrice,0) as profit_margin
from production.Product
where (ListPrice-StandardCost)/nullif(ListPrice,0) is  not null
order by profit_margin asc

--"Which products have never sold?" — Products in Production.Product with no matching rows in SalesOrderDetail (think LEFT JOIN ... WHERE NULL).

select 
p.name,
sod.ProductID
from Sales.SalesOrderDetail as sod
right join Production.Product as p
on sod.ProductID = p.ProductID 
where sod.ProductID is  null

--"What's the average customer rating per product, and which products need attention?" — Use Production.ProductReview, average Rating per product, find anything below 3.

select 
avg(pr.Rating) as avg_rating,
p.Name,
p.ProductID
from production.ProductReview as pr
join production .Product as p
on pr.ProductID =p.ProductID
group by p.name,p.ProductID
having avg(pr.Rating) <3




--Section 3 — Customer behavior
--"Who are our top 20 customers by lifetime spend?" — Sum TotalDue grouped by CustomerID, joined to Person for names.

select top 20
p.FirstName, p.LastName,
soh.CustomerID,
sum(soh.TotalDue) as total
from Sales.SalesOrderHeader as soh
join Sales.Customer as c on soh.CustomerID = c.CustomerID
join Person.Person as p on c.PersonID = p.BusinessEntityID
group by soh.CustomerID, p.FirstName, p.LastName
order by total desc

--2"How many orders does the average customer place, and who are the outliers?" — Count orders per customer, compare to the overall average.
with order_count as(
select CustomerID
,count(SalesOrderID) as total_orders
from [Sales].[SalesOrderHeader]
group by CustomerID)
 select 
   customerid,total_orders ,
   case
    when total_orders >(select avg(total_orders) from order_count) then 'above average'
	when total_orders <(select avg(total_orders) from order_count) then 'below average'
	else'average'
	end as category
 from order_count
 order by total_orders desc


 --"Which customers haven't ordered in the last 12 months?" (a churn-risk question) — Customers whose most recent OrderDate is more than a year before the latest date in the dataset.

select CustomerID
from [Sales].[SalesOrderHeader]
group by CustomerID
having max(OrderDate) < dateadd(month, -12, (select max(OrderDate) from [Sales].[SalesOrderHeader]));


--Section 4 — HR / workforce (a different business function)
--"What's the average tenure of employees by department?" — Use HireDate vs. today (or a fixed reference date), grouped through EmployeeDepartmentHistory ? Department.


select 
    d.Name as DepartmentName,
    avg(datediff(year, e.HireDate, getdate())) as AvgTenureYears
from HumanResources.Employee as e
join HumanResources.EmployeeDepartmentHistory as edh
    on e.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department as d
    on edh.DepartmentID = d.DepartmentID and edh.enddate is null
group by d.Name
order by AvgTenureYears desc;


--"Which departments have the most employees?" — Count of employees per Department.Name.
select 
d.Name as DepartmentName,
count(e.BusinessEntityID) as employees
from HumanResources.Employee as e
join HumanResources.EmployeeDepartmentHistory as edh
    on e.BusinessEntityID = edh.BusinessEntityID
join HumanResources.Department as d
    on edh.DepartmentID = d.DepartmentID
	and edh.enddate is null
	group by d.name
	order by employees desc


--*Section 5 — Advanced / window functions (the "real analyst" stuff)
--"Rank salespeople within their own territory by total sales." — RANK() OVER (PARTITION BY TerritoryID ORDER BY SUM(sales) DESC).

select 
    TerritoryID,
    SalesPersonID,
    sum(SubTotal) as total_sales,
    rank() over (partition by TerritoryID order by sum(SubTotal) desc) as ranking
from Sales.SalesOrderHeader
where SalesPersonID is not null
group by TerritoryID, SalesPersonID
order by TerritoryID, ranking


--"Show month-over-month revenue growth." — Use LAG() to compare each month's revenue to the previous month.
--"What % of total company revenue does each product category represent?" — Category revenue divided by a window-function total, or a subquery for the grand total.
--"Find the running total of revenue over time (cumulative sales)." — SUM(...) OVER (ORDER BY OrderDate).---
with m_o_m as(
select
    datepart(year, OrderDate) as order_year,
    datepart(month, OrderDate) as order_month,
    sum(SubTotal) as monthly_revenue
from Sales.SalesOrderHeader
group by datepart(year, OrderDate), datepart(month, OrderDate)
)
select  *  , lag(monthly_revenue) over (order by order_year,order_month)as lagging,
lag(monthly_revenue) over (order by order_year,order_month)-monthly_revenue as diffrence
from m_o_m

--"What % of total company revenue does each product category represent?" — Category revenue divided by a window-function total, or a subquery for the grand total.

with category_revenue as (
    select 
        pc.Name as category_name,
        sum(sod.LineTotal) as revenue
    from Sales.SalesOrderDetail as sod
    join Production.Product as p on sod.ProductID = p.ProductID
    join Production.ProductSubcategory as psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
    join Production.ProductCategory as pc on psc.ProductCategoryID = pc.ProductCategoryID
    group by pc.Name
)
select 
    category_name,
    revenue,
    round(revenue / sum(revenue) over () * 100, 2) as pct_of_total
from category_revenue
order by pct_of_total desc--bike have 86.17 perctage that mean it contribute more in revenue

with daily_revenue as (
    select 
        OrderDate,
        sum(SubTotal) as daily_total
    from Sales.SalesOrderHeader
    group by OrderDate
)
select
    OrderDate,
    daily_total,
    sum(daily_total) over (order by OrderDate) as running_total
from daily_revenue
order by OrderDate

---master query for python automation
	
select 
soh.SalesOrderID,
soh.OrderDate,soh.CustomerID,soh.TerritoryID,soh.SalesPersonID
,sod.OrderQty,sod.UnitPrice,sod.UnitPriceDiscount,sod.LineTotal,
p.Name as product_name,p.ProductID,p.StandardCost,p.ListPrice,
psc.Name as subcategory,pc.Name as category,t.Name as territory,
t.CountryRegionCode 
from[Sales].[SalesOrderHeader] as soh 
join [Sales].[SalesTerritory] as t
on soh.TerritoryID=t.TerritoryID
join [Sales].[SalesOrderDetail] as sod
on soh.SalesOrderID=sod.SalesOrderID
join [Production].[Product] as p
on sod.ProductID=p.ProductID
join [Production].[ProductSubcategory] as psc
on p.ProductSubcategoryID=psc.ProductSubcategoryID
join [Production].[ProductCategory] as pc 
on psc.ProductCategoryID=pc.ProductCategoryID
 
	
	(--check if join dropped silently...
select count(*) from Sales.SalesOrderDetail;  -- raw row count
  --vs
select count(*) 
from [Sales].[SalesOrderHeader] as soh 
join [Sales].[SalesTerritory] as t on soh.TerritoryID = t.TerritoryID
join [Sales].[SalesOrderDetail] as sod on soh.SalesOrderID = sod.SalesOrderID
join [Production].[Product] as p on sod.ProductID = p.ProductID
join [Production].[ProductSubcategory] as psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
join [Production].[ProductCategory] as pc on psc.ProductCategoryID = pc.ProductCategoryID)
--as a result: both return 121317 rows mean nothing noticeable

