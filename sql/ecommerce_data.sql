--task 1
select count(*) from ecommerce_data

select count(*) as total_rows,
       count(distinct InvoiceNo) as total_invoices,
       count(distinct CustomerID) as total_customers,
       count(distinct Country) as total_countries
from ecommerce_data

select max(invoicedate) from ecommerce_data --jan/2011 to sep_2011
select min(invoicedate) from ecommerce_data
--task4
select count(*) as missing_customerid,
       count(*) * 100.0 / (select count(*) from ecommerce_data) as pct_missing
from ecommerce_data
where CustomerID is null
--task2
with finding as(
select description , quantity, left(InvoiceNo,1) as f from ecommerce_data)
select top 10 description,
sum(quantity) as total_quantity
from finding 
where f !='c'
group by description
order by total_quantity desc

--Task 3

select  country
,sum([Quantity]*isnull([UnitPrice],0)) as total_revenue
from
ecommerce_data
group by country
order by total_revenue desc



--task 5
with cancelled_refund as (
select abs(quantity*isnull(unitprice,0)) as total_refund,left(invoiceno,1) as cancelled_invoice 
from ecommerce_data)
select cancelled_invoice, 
sum(total_refund) as total_cancellation_refund
from cancelled_refund
group by cancelled_invoice
having cancelled_invoice ='c'--896812.48 refund
--task 7
with top_customer as (
select customerid,sum(quantity*isnull(unitprice,0)) as total 
from ecommerce_data 
group by customerid
)
select top 5 customerid,total,((total)*100)/sum(total) over()as per from top_customer
order by per desc

--task 6
select customerid,
min(invoicedate) as firts_date,
max(invoicedate) as last_date,
datediff(day,min(invoicedate),max(invoicedate))as purchasing_diff
from ecommerce_data
group by customerid

--task8 RFM
select
  customerid,
  count(distinct invoiceno) as frequency,
  datediff(day, max(invoicedate), (select max(invoicedate) from ecommerce_data)) as recency,
  sum(quantity*isnull(unitprice,0)) as monetary
from ecommerce_data
group by customerid

--task 9
select  
year(invoicedate) as year
,month(invoicedate)as month
,sum(quantity * isnull(unitprice,0)) as total
from ecommerce_data
group by month(invoicedate) ,year(invoicedate)
order by total desc

--task 10
with p_a as (
  select stockcode, sum(abs(quantity)) as cancelled_quantity
  from ecommerce_data
  where left(invoiceno,1) = 'C'
  group by stockcode
),
p_a_2 as (
  select stockcode, sum(quantity) as ordered_quantity
  from ecommerce_data
  where left(invoiceno,1) <> 'C'
  group by stockcode
)
select p_a.stockcode, cancelled_quantity, ordered_quantity,
       cancelled_quantity * 1.0 / nullif(ordered_quantity,0) as return_rate
from p_a
join p_a_2 on p_a.stockcode = p_a_2.stockcode
where ordered_quantity > 0
order by return_rate desc


--sql task 11
WITH best_cus AS (
    SELECT 
        customerid,
        COUNT(DISTINCT invoiceno) AS frequency,
        DATEDIFF(day, MAX(invoicedate), (SELECT MAX(invoicedate) FROM ecommerce_data)) AS recency,
        SUM(quantity * ISNULL(unitprice, 0)) AS monetary
    FROM ecommerce_data
    GROUP BY customerid
),
adding AS (
    SELECT 
        customerid,
        NTILE(5) OVER (ORDER BY recency desc) AS recency_score,      -- smaller recency = more recent
        NTILE(5) OVER (ORDER BY frequency asc) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary asc) AS monetary_score,
        (NTILE(5) OVER (ORDER BY recency desc)
         + NTILE(5) OVER (ORDER BY frequency asc)
         + NTILE(5) OVER (ORDER BY monetary asc)) AS total_score
    FROM best_cus
)
SELECT *,
    CASE 
        WHEN total_score >= 13 THEN 'Champions'
        WHEN total_score BETWEEN 10 AND 12 THEN 'Loyal'
        WHEN total_score BETWEEN 7 AND 9 THEN 'Potential Loyalist'
        WHEN total_score BETWEEN 4 AND 6 THEN 'At Risk'
        ELSE 'Lost'
    END AS segment
FROM adding;


--task 12
WITH cohort AS (
    SELECT 
        CustomerID,
		invoicedate,
        MONTH(InvoiceDate) AS month,
        YEAR(InvoiceDate) AS year,
        MIN(InvoiceDate) OVER (PARTITION BY CustomerID) AS first_date
    FROM ecommerce_data
)
SELECT 
    YEAR(first_date) AS cohort_year,
    MONTH(first_date) AS cohort_month,
    YEAR(InvoiceDate) AS order_year,
    MONTH(InvoiceDate) AS order_month,
    COUNT(DISTINCT CustomerID) AS customers
FROM cohort
GROUP BY 
    YEAR(first_date), MONTH(first_date),
    YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY cohort_year, cohort_month, order_year, order_month;

--OR 
--task 12
WITH cohort AS (
    SELECT 
        CustomerID,
        MONTH(InvoiceDate) AS month,
        YEAR(InvoiceDate) AS year,
        MIN(InvoiceDate) OVER (PARTITION BY CustomerID) AS first_date
    FROM ecommerce_data
)
SELECT * 
FROM cohort
WHERE CustomerID = 17320
GROUP BY CustomerID, month, year, first_date;--THIS EXACTLY TELL US ABOUT WHICH CUSTOMER COMES IN WHICH TIME AND MONTH OF YEAR

--task 13
WITH monthly_total AS (
    SELECT 
        YEAR(InvoiceDate) AS year,
        MONTH(InvoiceDate) AS month,
        SUM(quantity * ISNULL(unitprice, 0)) AS total
    FROM ecommerce_data
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
    year,
    month,
    total,
    SUM(total) OVER ( ORDER BY year,month ASC) AS running_total -- i add partition by year just to see the yearly growth i skip all combination of the years
FROM monthly_total
ORDER BY year, month;

--task 14
with customer_spend as (
    select country, customerid, sum(quantity*isnull(unitprice,0)) as total
    from ecommerce_data
    group by country, customerid    -- both columns, not just country
),
ranked as (
    select *, dense_rank() over (partition by country order by total desc) as rank_in_country
    from customer_spend
)
select * from ranked where rank_in_country <= 3
order by country, rank_in_country

--task 15
with pairs as (
    select a.StockCode as product_a, b.StockCode as product_b, a.InvoiceNo
    from ecommerce_data a
    join ecommerce_data b
        on a.InvoiceNo = b.InvoiceNo
        and a.StockCode < b.StockCode   -- prevents duplicate pairs and self-pairing
    where left(a.InvoiceNo,1) <> 'C'
)
select top 10 product_a, product_b, count( InvoiceNo) as times_bought_together
from pairs
group by product_a, product_b
order by times_bought_together desc
