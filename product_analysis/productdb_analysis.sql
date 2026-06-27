Use ProductSales
GO

select * from discount_data

select * from product_data	

select * from product_sales

select 
FORMAT(ps.Date, 'MMMM') as Sales_Month,
FORMAT(ps.Date, 'yyyy') as Sales_Year,
(pd.Sale_Price * ps.Units_Sold) as Revenue,
(pd.Cost_Price * ps.Units_Sold) as Total_Cost,
ps.Discount_Band

-- create temp table using #TableName
into #MasterSaless
from product_data as pd
join product_sales as ps
on pd.Product_ID = ps.Product_ID

-- requery my table
select * from #MasterSaless

-- Discount_Revenue
SELECT 
    m.*,
    d.Discount,
    (1 - d.Discount * 1.0 / 100) * m.Revenue AS Discount_Revenue
FROM #MasterSaless m
JOIN discount_data d 
    ON m.Discount_Band = d.Discount_Band 
    AND m.Sales_Month = d.Month;

-- Instead of a temporary table, we can use a nested CTE approach here instead
WITH MasterSales AS (
    SELECT 
        FORMAT(ps.Date, 'MMMM') AS Sales_Month,
        FORMAT(ps.Date, 'yyyy') AS Sales_Year,
        (pd.Sale_Price * ps.Units_Sold) AS Revenue,
        (pd.Cost_Price * ps.Units_Sold) AS Total_Cost,
        ps.Discount_Band
    FROM product_data AS pd
    JOIN product_sales AS ps
        ON pd.Product_ID = ps.Product_ID
),

DiscountedSales AS (
    SELECT 
        m.*,
        d.Discount,
        (1 - d.Discount * 1.0 / 100) * m.Revenue AS Discount_Revenue
    FROM MasterSales m -- nested ctes
    JOIN discount_data d
        ON m.Discount_Band = d.Discount_Band
       AND m.Sales_Month = d.Month
)

SELECT *
FROM DiscountedSales;


-- USE Subqueries instead
SELECT 
    m.*,
    d.Discount,
    (1 - d.Discount * 1.0 / 100) * m.Revenue AS Discount_Revenue
FROM (
        SELECT 
        FORMAT(ps.Date, 'MMMM') AS Sales_Month,
        FORMAT(ps.Date, 'yyyy') AS Sales_Year,
        (pd.Sale_Price * ps.Units_Sold) AS Revenue,
        (pd.Cost_Price * ps.Units_Sold) AS Total_Cost,
        ps.Discount_Band
    FROM product_data AS pd
    JOIN product_sales AS ps
        ON pd.Product_ID = ps.Product_ID
) AS m 
JOIN discount_data d
    ON m.Discount_Band = d.Discount_Band
   AND m.Sales_Month = d.Month

/* 
Temp table vs CTE
CTE advantages

Good for:

1. readability
2. transformations
3. one-time query pipelines
4. avoiding clutter in tempdb

Cleaner for analytics-style SQL.

Temp table advantages

Better when:

1. reused multiple times
2. very large intermediate results
3. indexing is needed
4. performance tuning matters
5. debugging intermediate data
*/