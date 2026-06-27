USE RFM_Sales
Go

GO

CREATE OR ALTER VIEW v_product_trend AS
with MonthlyProductSales as (
	-- prod rev performance over time (MONTHLY)
	select 
		Productline,
		CAST(DATETRUNC(Month, ORDERDATE) AS DATE) as SalesMonth,
		round(Sum(SALES), 2) as ProductTotalSales
	from sales
	group by 
		Productline,
		CAST(DATETRUNC(Month, ORDERDATE) AS DATE)
),
SalesMomentum as (
	select
		*,
		lag(ProductTotalSales) over (
					partition by productline
					order by SalesMonth) as PrevProductTotalSales,
			-- 3 months rolling average of individual product revenue
		avg(ProductTotalSales) over (
					partition by productline
					order by SalesMonth
					rows between 2 preceding and current row
					) as ProdSalesRollingAvg,
		-- sum all product sales for a given month
		sum(ProductTotalSales) over(
					partition by SalesMonth) as AllProductsSales
		
	from MonthlyProductSales 	
)
-- Comparison
select 
	*,
	COALESCE(
	ROUND(((ProductTotalSales - PrevProductTotalSales)/ PrevProductTotalSales) * 100, 2)
	, 0 ) as [MoMGrowth%],

	COALESCE(
	ROUND((ProductTotalSales / AllProductsSales) * 100, 2)
	, 0 ) as [ProductContribution%]

from SalesMomentum

GO

select * from v_product_trend
order by productline, SalesMonth
GO

select 
(select distinct AllProductsSales from v_product_trend where SalesMonth = '2003-02-01') -
(select distinct AllProductsSales from v_product_trend where SalesMonth = '2003-01-01')
-- BUSINESS ANALYSIS
-- Which product category experienced the highest period-over-period (MOM) growth?
with product_ranking as (
	select 
		*,
		DENSE_RANK() OVER (
		ORDER BY [MoMGrowth%] DESC) AS rn

	from v_product_trend
	where PrevProductTotalSales is NOT NULL
)
SELECT 
	*
FROM product_ranking
where rn <= 2
GO

-- Which product category consistently contributes the largest share of company revenue?
-- avg
select 
	productline,
	round(avg([ProductContribution%]), 2) as AvgContribution

from v_product_trend
where [ProductContribution%] > 0
group by productline
order by AvgContribution desc

-- percentile_cont
select distinct
	productline,
	PERCENTILE_CONT(0.5)
	within group (order by [ProductContribution%])
	over (partition by productline ) as AvgContribution

from v_product_trend
where [ProductContribution%] > 0
order by AvgContribution desc


-- Which product category is performing above or below its recent historical trend?
select 
	*,
	ProductTotalSales - ProdSalesRollingAvg as VarianceFromTrend,
	Case 
		when ProductTotalSales > ProdSalesRollingAvg then 'Above'
		else 'Below'
	end as TrendStatus

from  v_product_trend
where ProdSalesRollingAvg <> ProductTotalSales
order by productline, SalesMonth
GO

-- During periods (month) of overall company growth, which product categories were the primary drivers of that growth?
-- in times of growth, which product actually contributed most to the revenue
WITH company_metrics as (
    SELECT
        SalesMonth,
        MAX(AllProductsSales) AS CompanySales,
        LAG(MAX(AllProductsSales)) OVER (
            ORDER BY SalesMonth
        ) AS PrevCompanySales
    FROM v_product_trend
    GROUP BY SalesMonth
),
CompanyGrowth as (
	select 
		*,
		CompanySales - PrevCompanySales as CompanyGrowth
	from company_metrics
)
SELECT
    cg.*,
    v.ProductLine,
    v.ProductTotalSales,
    v.[ProductContribution%],
    RANK() OVER (
        PARTITION BY v.SalesMonth
        ORDER BY v.[ProductContribution%] DESC
    ) AS rn
FROM v_product_trend v
JOIN CompanyGrowth cg
    ON v.SalesMonth = cg.SalesMonth
WHERE cg.CompanyGrowth > 0
--WHERE rn = 1
ORDER BY
    v.SalesMonth,
    rn;



-- Attrition, in a month of company growth, what was the products attrition 

WITH CompanyGrowth AS (
    SELECT
        SalesMonth,
        MAX(AllProductsSales)
        - LAG(MAX(AllProductsSales)) OVER (
            ORDER BY SalesMonth
        ) AS CompanyGrowth
    FROM v_product_trend
    GROUP BY SalesMonth
)
SELECT
    v.SalesMonth,
    v.ProductLine,
    v.ProductTotalSales - v.PrevProductTotalSales AS ProductGrowth,
    v.[MoMGrowth%]
FROM v_product_trend v
JOIN CompanyGrowth cg
    ON v.SalesMonth = cg.SalesMonth
WHERE cg.CompanyGrowth > 0
ORDER BY
    v.SalesMonth,
    ProductGrowth DESC;