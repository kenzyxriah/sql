USE DataWarehouse
Go

select TOP 2 *
from gold.dim_customers

select TOP 2 *
from gold.dim_products

select TOP 2 *  -- take all the columns from the table
from gold.fact_sales

-- JOINS
-- Get customer name for all sales transactions
select
fs.*,
dc.first_name,
dc.last_name
from gold.fact_sales as fs
join gold.dim_customers as dc
on fs.customer_key = dc.customer_key

-- What is the distribution (total) of sold items across countries?
select
dc.country,
coalesce(sum(fs.quantity), 0) as total_sold_items
from gold.fact_sales as fs
left join gold.dim_customers as dc
on fs.customer_key = dc.customer_key
group by dc.country
having dc.country <> 'n/a'

-- What are the 5 worst-performing products in terms of sales?
select top 5
dp.product_name,
sum(fs.sales_amount) as total_sales,
COUNT(fs.order_number) as total_orders,
max(fs.price) as max_price

from gold.fact_sales as fs
join gold.dim_products as dp
on fs.product_key = dp.product_key
group by dp.product_name
order by total_sales

select 3191 * 5

-- what is the maximum sales amount recorded in a single order?
select max(sales_amount) as max_sales
from gold.fact_sales

select *
from gold.fact_sales
where sales_amount = (select max(sales_amount) from gold.fact_sales)


-- Find the top 10 customers who have generated the highest revenue
select top 10
dc.customer_key, 
dc.first_name, 
dc.last_name,
sum(fs.sales_amount) as total_revenue

from gold.dim_customers as dc
join gold.fact_sales as fs
on dc.customer_key = fs.customer_key
group by
dc.customer_key, dc.first_name, dc.last_name
order by total_revenue desc


-- Rank countries by total transaction count get top 5
SELECT top (5) 
    c.country, 
    count(*) AS total_sales
from gold.fact_sales as f
JOIN gold.dim_customers as c
    ON c.customer_key = f.customer_key
group by c.country
order by total_sales desc;


-- ADVANCED JOINS 

-- possible matrix combination of customers and products
select distinct
--dc.customer_key,
--dp.product_key
dc.country,
dp.product_name

from gold.dim_customers as dc
cross join gold.dim_products as dp
-- does not require an on statement as it is a cartesian product

select 
dc.country,
dp.product_name,
sum(coalesce(fs.sales_amount, 0)) as total_revenue
from gold.dim_customers as dc
cross join gold.dim_products as dp
left join gold.fact_sales as fs
    on fs.customer_key = dc.customer_key
    and fs.product_key = dp.product_key
group by 
    dc.country,
    dp.product_name
having dc.country <> 'n/a'
order by dc.country, dp.product_name


--Which unique pairs of Australian customers and 'Road' product_line have zero recorded sales?
with 
australian_customers as (
    select customer_key, first_name, last_name
    from gold.dim_customers
    where country = 'Australia'
),
road_products as (
    select product_key, product_name
    from gold.dim_products
    where product_line = 'Road'
)
-- australian_customers has 7 rows
-- road_products has 10 rows
-- the cross join will create a matrix of 7 x 10 = 70 rows
select 
ac.first_name,
ac.last_name,
rp.product_name,
fs.order_number
from australian_customers as ac
cross join road_products as rp
left join gold.fact_sales as fs
    on fs.customer_key = ac.customer_key
    and fs.product_key = rp.product_key
where fs.order_number is null

select top 2 * from gold.fact_sales

--Which unique pairs of Australian customers and 'Road' product_line have at least one recorded sales?

select distinct
ac.first_name,
ac.last_name,
rp.product_name
from (
    select customer_key, first_name, last_name
    from gold.dim_customers
    where country = 'Australia'
) as ac
cross join (
    select product_key, product_name
    from gold.dim_products
    where product_line = 'Road'
) as rp
left join gold.fact_sales as fs
    on fs.customer_key = ac.customer_key
    and fs.product_key = rp.product_key
where fs.order_number is not null


