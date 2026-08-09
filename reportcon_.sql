--BASIC
select 
c.FirstName,
c.LastName,
i.InvoiceId
from Customer as c
join Invoice as i
on c.CustomerId = i.CustomerId

--2
select 
t.name,
ar.name,
a.title
from album as a
join artist as ar
on a.artistid = ar.artistid
join track as t
on a.albumid = t.albumid

--3
select 
t.name as track_name,
g.name as genre_name
from genre as g
join track as t
on g.genreid = t.genreid
where g.name = 'rock'
--4
select c.* 
from customer as c
left join invoice as i
on c.customerid = i.customerid
where i.customerid is null

--aggregation
select 
c.country,
sum(i.total) as revenue
from customer as c
join invoice as i
on c.customerid = i.customerid
group by c.country
order by revenue desc
----
select 
g.name,
count(g.name) as genre_name
from genre as g
join track as t
on g.genreid = t.genreid
group by g.name

----------------------
select top 5
t.name as genre_name,
sum(i.quantity) as total_q
from track as t
join invoiceline as i
on i.trackid = t.trackid
group by t.name
order by total_q desc

-----
select 
i.customerid,
avg(total) as averagebycus_
from customer as c
join invoice as i
on c.customerid = i.customerid
group by i.customerid
---FILTERING 
select 
billingcountry,
total
from invoice
where (billingcountry = 'USA' or  billingcountry='Canada') and total > 10
-----
with trackdur_ as(
select 
name,
milliseconds/(1000*60) as minutes
from track)
select 
* from trackdur_
where minutes > 5

----
select 
c.firstname,
i.customerid,
count(invoiceid) as invoices
from customer as c
join invoice as i 
on c.customerid = i.customerid
group by i.customerid,c.firstname
having count(invoiceid) > 5

---advanced
SELECT TOP 3 ar.name AS Artist,
       SUM(i.unitprice * i.quantity) AS TotalRevenue
FROM artist AS ar
JOIN album AS a ON ar.artistid = a.artistid
JOIN track AS t ON a.albumid = t.albumid
JOIN invoiceline AS i ON t.trackid = i.trackid
GROUP BY ar.name
ORDER BY TotalRevenue DESC;

----
select 
i.customerid,
max(total) as max_total
from customer as a
join invoice as i
on a.customerid=i.customerid
group by i.customerid

-----
select 
i.customerid,
total
from customer as c
join invoice as i
on c.customerid=i.customerid
where i.total > (select avg(total) as total_avg from invoice ) 
------
select  
g.name as genre,
i.billingcountry,
sum(iv.quantity) as total_by_coun_,
rank() over(PARTITION BY i.billingcountry ORDER BY SUM(iv.quantity) DESC) as ranking
from genre as g
join track as t
on g.genreid = t.genreid
join album as a
on t.albumid = a.albumid
join invoiceline as iv
on t.trackid=iv.trackid
join invoice as i
on iv.invoiceid = i.invoiceid
group by g.name,i.billingcountry
order by i.billingcountry,ranking
