use DataWarehouse;
go


-- UNION
-- fetch all dates records for any interactions (orders, shipping, due): distinct list of dates
select 
order_date as interaction_date
from gold.fact_sales

union

select 
shipping_date as interaction_date
from gold.fact_sales
union

select 
due_date as interaction_date
from gold.fact_sales

-- INTERSECT
-- Identify products that have at least generated sales
select 
product_key
from gold.dim_products

intersect 

select
product_key
from gold.fact_sales

-- here I cannot input any column that is not in both tables
-- to solve this, I could use a join
SELECT DISTINCT 
dp.product_name
FROM gold.dim_products dp
JOIN gold.fact_sales fs
    ON dp.product_key = fs.product_key;

-- EXCEPT
-- Identify products that have NEVER MADE A SALE
select 
product_key
from gold.dim_products

EXCEPT

select
product_key
from gold.fact_sales

-- USE A JOIN TO SOLVE THIS SO I CAN SHOWCASE PRODUCT NAMES
SELECT distinct
dp.product_name,
dp.product_key,
fs.*

FROM gold.dim_products dp
LEFT JOIN gold.fact_sales fs
    ON dp.product_key = fs.product_key
WHERE fs.product_key IS NULL; -- ANTI JOIN


-- What is the combined, distinct list of customer keys belonging to either Australian residents or buyers of 'Road' products?
with 
australian_customers as (
    select customer_key
    from gold.dim_customers
    where country = 'Australia'
),
buyers_of_road_products as (
    select customer_key
    from gold.fact_sales as fs
    join gold.dim_products as dp
        on fs.product_key = dp.product_key
    where dp.product_line = 'Road'
)
select *
from australian_customers 
union
select *
from buyers_of_road_products

-- directly without CTEs
SELECT customer_key 
FROM gold.dim_customers 
WHERE country = 'Australia'

UNION

SELECT f.customer_key 
FROM gold.fact_sales f
JOIN gold.dim_products p 
    ON f.product_key = p.product_key
WHERE p.product_line = 'Road';


-- What is the total volume of combined order and shipping events for each date, ordered from busiest to quietest?
select * from gold.fact_sales

with AllDateEvents as (
    select order_date as event_date
    from gold.fact_sales

    union all

    select shipping_date as event_date
    from gold.fact_sales
)
select 
    event_date, 
    count(*) as total_events
from AllDateEvents
group by event_date
order by total_events desc


-- replicate this with a sub query instead of a CTE
select 
    event_date, 
    count(*) as total_events
from (
    select order_date as event_date
    from gold.fact_sales

    union all

    select shipping_date as event_date
    from gold.fact_sales
) as AllDateEvents
group by event_date
order by total_events desc



-- Which customers bought from us in H1 2013 but completely flatlined (ordered nothing) in H2 2013, ordered by their H1 spending?
-- churn analysis
select count(distinct customer_key) from gold.fact_sales
where YEAR(order_date) = 2013


-- 2013 h1
with churned_customers_keys as 
    (select customer_key
    from gold.fact_sales
    where order_date >= '2013-01-01' and order_date < '2013-07-01'

    except -- filters customers in h1 who are not in h2 sales

    -- 2013 h2
    select customer_key
    from gold.fact_sales
    where order_date >= '2013-07-01' and order_date < '2014-01-01'
)
select 
fs.customer_key,
sum(fs.sales_amount) as h1_spending
from gold.fact_sales as fs
where fs.customer_key in (select customer_key from churned_customers_keys)
and fs.order_date >= '2013-01-01' and fs.order_date < '2013-07-01'

group by fs.customer_key
having sum(fs.sales_amount) > 1000 -- filter for customers who spent more than 1000 in H1 but churned
order by h1_spending desc









