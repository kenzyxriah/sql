-- ANSWERING SALES DEPARTMENT QUESTION
USE SalesDB
GO

select top(5) * -- 5 rows
from Sales.Customers

select top(5) * -- 5 rows
from Sales.Employees

select top(5) * -- 5 rows
from Sales.Orders

select top(5) * -- 5 rows
from Sales.OrdersArchive

select top(5) * -- 5 rows
from Sales.Products

-- INNERS
-- Get all customers names that have ordered
select distinct
-- o.*,
c.FirstName,
c.LastName
from Sales.Customers as c
--INNER JOIN
JOIN Sales.Orders as o
on o.CustomerID = c.CustomerID -- readability table b = table a 
--on c.CustomerID = o.CustomerID -- standard table a = table b

select *
from Sales.Customers

-- has Anna (5) made an order
select *
from Sales.Orders as o
where o.CustomerID = 5

-- inner join to find duplicates in a table: SELF INNER JOIN
INSERT Sales.Customers
(CustomerID, FirstName, LastName, Country, Score)
VALUES
(6, N'Cookie', N'Brown', 'UK', 500)
GO

select * from Sales.Customers

-- Customers that have the same LastName
select 
c1.*
from Sales.Customers as c1
inner join Sales.Customers as c2 -- self joining
on c2.LastName = c1.LastName
	and c2.CustomerID <> c1.CustomerID -- dont self check rows 

--select * from Sales.Customers

-- filtering in joins vs filtering with where clause
select 
c1.*
from Sales.Customers as c1
inner join Sales.Customers as c2 -- self joining
on c2.LastName = c1.LastName
where c2.CustomerID <> c1.CustomerID

-- when filtering, include the filter in the join for Inner Join dont use where
-- outer join, where clause for filtering is best/more readable

-- OUTERS (Left join)
select * from Sales.Customers
-- Revenue Orders by Customers

select
c.*,
o.OrderID,
(o.Sales * o.Quantity) as Revenue
from Sales.Customers as c
--left outer join (alternate syntax)
left join Sales.Orders as o
on o.CustomerID = c.CustomerID

-- right join
select
c.*,
o.OrderID,
(o.Sales * o.Quantity) as Revenue
from Sales.Customers as c
right join Sales.Orders as o
on o.CustomerID = c.CustomerID

-- convert this right join back into a left join (the table should follow the structure in rows of Sales.Orders)
select
	c.*,
	o.OrderID,
	(o.Sales * o.Quantity) as Revenue
from Sales.Orders as o
left join Sales.Customers as c
on o.CustomerID = c.CustomerID


-- full outer join
INSERT Sales.Orders
([OrderID], [ProductID], [CustomerID], [SalesPersonID], [OrderDate], [ShipDate], [OrderStatus], [ShipAddress], [BillAddress], [Quantity], [Sales], [CreationTime]) 
VALUES 
(11, 101, 1000, 3, CAST(N'2025-01-01' AS Date), CAST(N'2025-01-05' AS Date), N'Delivered', N'9833 Mt. Dias Blv.', N'1226 Shoe St.', 1, 10, CAST(N'2025-01-01T12:34:56.0000000' AS DateTime2))
GO

select * from Sales.Orders
-- been able to insert an order with no customer

-- are there orders without customers and customers without orders
select 
	o.*,
	c.FirstName,
	c.LastName
from Sales.Customers as c
--full outer join
full join Sales.Orders as o
on o.CustomerID = c.CustomerID


-- ANTI JOIN
-- filtering where orders are without customers and customers are without others
select 
	o.*,
	c.FirstName,
	c.LastName
from Sales.Customers as c
--full outer join
full join Sales.Orders as o
on o.CustomerID = c.CustomerID
where 
o.CustomerID is null
or c.CustomerID is null

-- to validate my data (no nulls)
select 
	o.*,
	c.FirstName,
	c.LastName
from Sales.Customers as c
--full outer join
full join Sales.Orders as o
on o.CustomerID = c.CustomerID
where 
o.CustomerID is not null
and c.CustomerID is not null

-- much better
select 
	o.*,
	c.FirstName,
	c.LastName
from Sales.Customers as c
join Sales.Orders as o
on o.CustomerID = c.CustomerID