USE RFM_Sales
Go

select top 3
*
from sales

select 
*
from sales
where ORDERNUMBER = 10107

-- Inspects the dimensions
-- status, productline, customername, dealsize

select distinct 
	status
from sales

select distinct productline from sales
select distinct customername from sales
select distinct DEALSIZE from sales
select distinct YEAR_ID from sales

-- EDA or Impact Analysis using Grouping
-- revenue drivers for each dimension: productline, customername, dealsize, year
-- TOTAL SALES ACROSS BOARD
declare @total_sales_amount float;

select @total_sales_amount = sum(sales)
from sales;


-- top productline by revenue share using grouping
with product_line_analysis as (
	SELECT 
	PRODUCTLINE,
	SUM(SALES) AS Revenue
	FROM SALES
	GROUP BY PRODUCTLINE
)
select 
*,
(Revenue * 100.0 / (SELECT SUM(SALES) FROM SALES)) as PercentRevShare
from product_line_analysis
ORDER BY PercentRevShare DESC

--
with product_line_analysis as (
	SELECT 
	PRODUCTLINE,
	SUM(SALES) OVER(
	PARTITION BY PRODUCTLINE
	) AS Revenue
	FROM SALES

)
select 
*,
(Revenue * 100.0 / (SELECT SUM(SALES) FROM SALES)) as PercentRevShare
from product_line_analysis
ORDER BY Revenue


SELECT 
YEAR_ID,
SUM(SALES) AS Revenue
FROM SALES
GROUP BY YEAR_ID
ORDER BY Revenue

SELECT 
DEALSIZE,
SUM(SALES) AS Revenue
FROM SALES
GROUP BY DEALSIZE
ORDER BY Revenue

-- top customer drivers by percent revenue share
with customer_analysis as (
	SELECT 
	customername,
	SUM(SALES) AS Revenue
	FROM SALES
	GROUP BY customername
)
select 
*,
(Revenue * 100.0 / (SELECT SUM(SALES) FROM SALES)) as PercentRevShare
from customer_analysis
ORDER BY PercentRevShare DESC



-- SEGMENTATION VIEW: RFM
-- active, loyal, potential_churners, new_customers, slipping_away, lost
SELECT TOP 2 * FROM SALES

select GETDATE()
SELECT MAX(ORDERDATE) FROM SALES
select format('2026-21-05', 'yyyy-MM')

GO

CREATE OR ALTER VIEW v_rfm_analysis AS 
with rfm_base as (
	SELECT 
		CUSTOMERNAME,
		SUM(SALES) AS Monetary,
		COUNT(DISTINCT ORDERNUMBER) AS Frequency,
		DATEDIFF(DAY, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM SALES)) AS Recency
	FROM SALES
	GROUP BY CUSTOMERNAME
),
rfm_calc as (
select 
	*,
	ntile(4) over (order by Recency desc) as rfm_recency,
	ntile(4) over (order by Frequency asc) as rfm_frequency,
	ntile(4) over (order by Monetary asc) as rfm_monetary
from rfm_base
)
select
    *,
    CASE
        WHEN rfm_recency = 1 AND rfm_frequency <= 2 AND rfm_monetary <= 2 THEN 'lost_customers'
        WHEN rfm_recency = 1 AND (rfm_frequency >= 3 OR rfm_monetary >= 3) THEN 'slipping_away'
        WHEN rfm_recency >= 3 AND rfm_frequency = 1 THEN 'new_customers'
        WHEN rfm_recency = 2 AND rfm_frequency BETWEEN 2 AND 3 THEN 'potential_churners'
        WHEN rfm_recency = 4 AND rfm_frequency >= 3 AND rfm_monetary >= 3 THEN 'loyal'
        WHEN rfm_recency >= 3 AND rfm_frequency >= 2 AND rfm_monetary >= 2 THEN 'active'
        ELSE 'unclassified'
    END AS rfm_segment
from rfm_calc

GO

-- assess the view for segments
select *
from v_rfm_analysis
order by Monetary desc;

-- to confirm that the frequency is correct
select distinct orderdate
from sales
where customername like 'Alpha%'

select 
*
from sales
where customername like 'Alpha%'
order by ordernumber, orderdate

-- select 2026-06-02 - 2026-06-01

-- COHORT ANALYSIS
-- cohort by first purchase year , additionally adding their historical CLV and monthly revenue
-- last activity month
-- total revenue by customer,month
-- number of months active

select top 2 * from sales
GO

CREATE OR ALTER VIEW v_cohort_monthly_analysis AS
with CohortBase as (
	select 
	CUSTOMERNAME,
	min(year_id) as CohortYear,
	min(ORDERDATE) as FirstPurchaseDate

	from sales
	group by 
		customername
),
CustomerActivity as (
	select 
		cb.CUSTOMERNAME,
		FORMAT(cb.FirstPurchaseDate, 'yyyy-MM') as CohortMonth,
		FORMAT(s.ORDERDATE, 'yyyy-MM') as ActivityMonth,
		MIN(cb.CohortYear) AS CustomerCohortYear,
		DATEDIFF(MONTH, cb.FirstPurchaseDate, MAX(s.ORDERDATE)) as CustomerTenureMonths,
		sum(s.SALES) as MonthlyRevenue
	FROM CohortBase as cb
	join sales as s
		on s.CUSTOMERNAME = cb.CUSTOMERNAME
	GROUP BY 
		cb.CUSTOMERNAME,
		cb.FirstPurchaseDate,
		FORMAT(s.ORDERDATE, 'yyyy-MM')
)
select 
	*,
	sum(MonthlyRevenue) OVER (PARTITION BY CUSTOMERNAME) as CLTV,
	lag(ActivityMonth) OVER (PARTITION BY CUSTOMERNAME ORDER BY ActivityMonth) as PreviousActivityMonth,
	lead(ActivityMonth) OVER (PARTITION BY CUSTOMERNAME ORDER BY ActivityMonth) as NextActivityMonth,
	coalesce((MonthlyRevenue - lag(MonthlyRevenue) OVER (PARTITION BY CUSTOMERNAME ORDER BY ActivityMonth))
	/ coalesce(lag(MonthlyRevenue) OVER (PARTITION BY CUSTOMERNAME ORDER BY ActivityMonth), 1)
	* 100, 0) as MoMRevenueGrowthPercent
from CustomerActivity

GO

SELECT * FROM v_cohort_monthly_analysis
GO



-- SHOW CASE REASON FOR FORMAT
select
 datetrunc(month, '2026-06-20') as ActivityMonth,
 format(CAST('2026-06-20' AS date), 'yyyy-MM') as ActivityMonthFormatted

 -- PRODUCT TREND ANALYSIS
 -- Market Basket and Recommendation Engine

 -- Calculate general co product purchase patterns(FREQ COUNT) in a given order, across all orders
 -- RANK TOP PRODUCT BUNDLES
 select top 2 * from sales

 SELECT DISTINCT 
 PRODUCTCODE
 FROM SALES
 WHERE PRODUCTLINE = 'Classic Cars'

WITH ProductBundles AS (
	SELECT
		s1.PRODUCTCODE AS Product1,
		s2.PRODUCTCODE AS Product2,
		COUNT(*) AS TimesBoughtTogether

	 FROM sales as s1
	 INNER JOIN sales as s2
		ON s1.ORDERNUMBER = s2.ORDERNUMBER
		AND s1.PRODUCTCODE <> s2.PRODUCTCODE
	GROUP BY 
		s1.PRODUCTCODE,
		s2.PRODUCTCODE
)
SELECT
	Product1 + ' & ' + Product2 AS ProductBundle,
	TimesBoughtTogether,
	DENSE_RANK() OVER (ORDER BY TimesBoughtTogether DESC) AS BundleRank
FROM ProductBundles
GO

-- Analyze co purchase for products purchased together that bear the same product line
WITH ProductBundles2 AS (
	SELECT
		s1.PRODUCTLINE,
		s1.PRODUCTCODE AS Product1,
		s2.PRODUCTCODE AS Product2,
		COUNT(*) AS TimesBoughtTogether

	 FROM sales as s1
	 INNER JOIN sales as s2
		ON s1.ORDERNUMBER = s2.ORDERNUMBER
		AND s1.PRODUCTCODE <> s2.PRODUCTCODE
		AND s1.PRODUCTLINE = s2.PRODUCTLINE
	GROUP BY 
		s1.PRODUCTLINE,
		s1.PRODUCTCODE,
		s2.PRODUCTCODE
)
SELECT
	PRODUCTLINE,
	Product1 + ' & ' + Product2 AS ProductBundle,
	TimesBoughtTogether,
	DENSE_RANK() OVER (
		PARTITION BY PRODUCTLINE
		ORDER BY TimesBoughtTogether DESC) AS BundleRank
FROM ProductBundles2
GO

-- Product recommendation engine: 
-- 1. For a given product, recommend the top 3 most frequently co-purchased products
-- 2. Calculate the average order value for orders containing the base product
-- 3. Calculate the average order value for orders containing both the base product and the recommended product as Bundle AOV

CREATE OR ALTER VIEW v_recommendation_engine AS
with OrderRevenue as (
	select 
		ORDERNUMBER,
		SUM(SALES) AS OrderValue
	from sales
	group by ORDERNUMBER
),
ProductOrders as (
	select distinct
		ORDERNUMBER,
		PRODUCTCODE
	from sales
),
ProductPairs as (
  select
	p1.PRODUCTCODE AS BaseProduct,
	p2.PRODUCTCODE AS RecommendedProduct,
	count(distinct p1.ORDERNUMBER) AS TimesBoughtTogether

  from ProductOrders as p1
  inner join ProductOrders as p2
	on p1.ORDERNUMBER = p2.ORDERNUMBER
	and p1.PRODUCTCODE <> p2.PRODUCTCODE
  group by
	p1.PRODUCTCODE,p2.PRODUCTCODE
),
BundleMetrics as (
 select
	p1.PRODUCTCODE AS BaseProduct,
	p2.PRODUCTCODE AS RecommendedProduct,
	avg(o.OrderValue) as BundleAOV
	

  from ProductOrders as p1
  inner join ProductOrders as p2
	on p1.ORDERNUMBER = p2.ORDERNUMBER
	and p1.PRODUCTCODE <> p2.PRODUCTCODE
  join OrderRevenue as o
	on p1.ORDERNUMBER = o.ORDERNUMBER
  group by
	p1.PRODUCTCODE,p2.PRODUCTCODE
),
BaseProductMetrics as (
    SELECT
        p.PRODUCTCODE,
        COUNT(DISTINCT p.ORDERNUMBER) AS ProductOrders,
        AVG(o.OrderValue) AS ProductAOV
    FROM ProductOrders p
    JOIN OrderRevenue o
        ON p.ORDERNUMBER = o.ORDERNUMBER
    GROUP BY
        p.PRODUCTCODE
),
Calculations as (

	select
		pp.BaseProduct,
		pp.RecommendedProduct,
		pp.TimesBoughtTogether,
		bm.BundleAOV,
		bpm.ProductAOV,
		100 * pp.TimesBoughtTogether / bpm.ProductOrders as ConversionRate,
		-- Projected AOV Lift % = (Bundle AOV - Base Product AOV) / Base Product AOV * 100
		100 * (bm.BundleAOV - bpm.ProductAOV)/bpm.ProductAOV as ProjectedAOVLift,

		dense_rank() over (
			partition by pp.BaseProduct
			order by pp.TimesBoughtTogether desc
		) as RankNumber

	from ProductPairs as pp
	join BundleMetrics as bm
		on pp.BaseProduct = bm.BaseProduct
		and pp.RecommendedProduct = bm.RecommendedProduct
	join BaseProductMetrics as bpm
		on pp.BaseProduct = bpm.PRODUCTCODE
)
select 
	BaseProduct,
	RecommendedProduct,
	TimesBoughtTogether,
	BundleAOV,
	ProductAOV,
	ConversionRate,
	ProjectedAOVLift

from Calculations
where RankNumber <= 5

GO

SELECT * FROM v_recommendation_engine
GO