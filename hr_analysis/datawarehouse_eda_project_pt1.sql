CREATE DATABASE DataWarehouse;
GO -- BATCH BREAKER

-- inside a db, we can have folders/schemas in which our tables will exist under
--create schema gold; -- gold is used for clean tables
--go

/*

*/
use DataWarehouse;
go

-- ALL YOUR TABLES IN A DATABASE
select *
from INFORMATION_SCHEMA.TABLES

-- for all tables
select 
    TABLE_CATALOG,
    TABLE_SCHEMA
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
from INFORMATION_SCHEMA.COLUMNS;

-- filter down using a where clause. for just a table
select 
    TABLE_CATALOG,
    TABLE_SCHEMA
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'dim_customers';

-- only the column names in a particular table
select
COLUMN_NAME 
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'dim_customers'
and TABLE_SCHEMA = 'gold';


-- WITH EDA, WE HAVE TWO THINGS TO LOOK AT: DIMENSIONS (QUALITATIVE/CATEGORICAL), MEASURES (QUANTITATIVE/NUMERIC)
-- IHAVE MOVED TO MY DB TABLES
select *
from gold.dim_customers

select *
from gold.dim_products

select *  -- take all the columns from the table
from gold.fact_sales

-- extract the countrys from the customers table
select 
country,
customer_id,
customer_number
from gold.dim_customers 

-- How many unique countries do my customers originate from
select distinct
 gc.country
from gold.dim_customers as gc

-- in sql, we use `AS` to set alias to a column or a table
-- always press Ctrl + Shift + R to clear squiggly red lines from Intellisense isses when there isnt one

select distinct
 gc.country ,
 gender
from gold.dim_customers as gc

-- select unique countries in an ordered way
select distinct
 gc.country
from gold.dim_customers as gc
order by gc.country

/* 
you can order a query based off numeric or alphabetic values
If its numeric, it uses mathematical order (1,2,3,4,5)

If its alphabetic, it uses alphabetical order (A-Z)

By default, order by is ascending (ASC), but you can also specify it to be descending (DESC)
*/

select distinct
 gc.country
from gold.dim_customers as gc
order by gc.country desc

-- dates, customer key
select distinct
 f.order_date
from gold.fact_sales as f
order by order_date

-- customer key
select distinct
 gc.customer_key
from gold.dim_customers as gc
order by gc.customer_key desc

-- retrieve a list of unique categories, subcategories, and products
select distinct
 gp.category,
 gp.subcategory,
 gp.product_name
from gold.dim_products as gp
-- add on
order by 
gp.category,
gp.subcategory desc, 
gp.product_name

-- EXTRACT PRODUCT NAMES WITH NO CATEGORY OR SUBCATEGORY
select 
 *
from gold.dim_products
where category is null -- identity operator for null values

-- extract a particular product that is null
select
*
from gold.dim_products
where product_name = 'LL Mountain Pedal' -- use single quotes for text values
-- orderby product_name

-- 
select
*
from gold.dim_products
where category_id = 'CO_PE'
   



-- MEASURES: AGGREGATION FUNCTIONS
-- aggregation functions: SUM, COUNT, AVG, MIN, MAX

-- what was the last purchase globally?
select
max(order_date) as last_purchase_date 
from gold.fact_sales


-- Find the total sales
select
sum(f.sales_amount) as sum_of_sales
from gold.fact_sales as f

-- Find how many items are sold
select
sum(quantity) as total_items
from gold.fact_sales

-- Find the average selling price
select
avg(price) as average_selling_price
from gold.fact_sales

-- Find the total number of orders
select
count(f.order_number) as total_orders
from gold.fact_sales as f

-- find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- find total number of paying customers 
select
 count(distinct customer_key) as total_paying_customers
from gold.fact_sales


-- MEASURES: FILTERING WITH WHERE CLAUSE
-- how many orders were made in 2014?
select 
count(order_number) as total_orders_2014
from gold.fact_sales
where YEAR(order_date) = 2014

-- how many subcategories do we have under the category of 'Clothing'?

select 
count(distinct subcategory) as total_clothing_subcategories
from gold.dim_products
where 
category = 'Clothing' 
and subcategory is not null

-- A total report of the metrics
select
sum(sales_amount) as sum_of_sales,
sum(quantity) as total_items,
avg(price) as average_selling_price,
count(order_number) as total_orders
from gold.fact_sales;


-- STACK TABLES TOGETHER USING UNION, IN THIS SITUATION FOR TRANSPOSING THE DATA
select 
'sum_of_sales' as metric, 
sum(sales_amount) as value
from gold.fact_sales

union

select
'total_items' as metric,
sum(quantity) as value
from gold.fact_sales


/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/

-- rank countries by customer count
select
country, -- first select the dimension 
count(customer_key) as customer_count
from gold.dim_customers
group by country -- use the dimension selected. if you try to groupby a column not in the select statement, there woud be an error
having 
country <> 'n/a' -- when you need to filter on a groupby, dont use the where clause, use having instead
order by customer_count desc

-- Find total customers by gender
-- Which product line has the highest average manufacturing cost?
-- Which product category is the most expensive to maintain?

