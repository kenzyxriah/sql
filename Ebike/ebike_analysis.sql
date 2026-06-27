use Ebike_DB
go

select * from rides
-- 
select top 3 * from rides

select top 3 * from stations

select top 3 * from users

-- DATA CHECKS
-- COUNT OF ALL DATA POINTS
select 
'rides' as [type], 
count(*) as [count]
from rides

union all

select 
'stations' as [type],
count(*) as [count]
from stations

union all 
select 
'users' as [type],
count(*) as [count]
from users


-- MISSING VALUES
-- '', NULL AS A STRING, NULL DATA TYPE
select
	sum(case when user_id is null then 1 else 0 end) as null_user_ids,
	sum(case when start_time is null then 1 else 0 end) as null_start_time,
	sum(case when end_time is null then 1 else 0 end) as null_end_time
from rides

-- SUMMARY STATS OF THE DATA
-- min, max, avg (distance and duration)

ALTER TABLE rides
ALTER COLUMN end_time DATETIME2(6);

select
	min(distance_km) as min_dist,
	max(distance_km) as max_dist,
	avg(distance_km) as avg_dist,
	min(datediff(minute, start_time, end_time)) as min_dur,
	max(datediff(minute, start_time, end_time)) as max_dur,
	avg(datediff(minute, start_time, end_time)) as avg_dur

from rides

-- DATA QUALITY

-- extract rides where minutes is 0
select *
from rides
where datediff(minute, start_time, end_time) = 0

-- invalid rides
delete from rides
where distance_km = 0

-- extract where minutes is less than 2
select 
count(r.ride_id) as count_under_2_mins, -- unique value
cast(count(r.ride_id) as float)/(select cast(count(*) as float) from rides) as pct_under_2_minutes

from rides as r
where datediff(minute, start_time, end_time) <= 2

select count(*) from rides
select cast(count(*) as float) from rides

-- REMOVAL OF DURATION OUTLIERS, OR YOU FILTER
delete from rides
where datediff(minute, start_time, end_time) <= 2

-- TIME SERIES ANALYSIS
-- date time follows a 0-24 hours structure

SELECT
	DATENAME(HOUR, '2026-06-13 23:23:00'),
	DATEPART(HOUR, '2026-06-13 12:23:00'),
	DATENAME(WEEKDAY, '2026-06-13 12:23:00'),
	DATEPART(WEEKDAY, '2026-06-13 12:23:00'),
	DATENAME(MONTH, '2026-06-13 12:23:00'),
	DATEPART(MONTH, '2026-06-13 12:23:00')

-- PEAK HOURS; GLOBALLY
SELECT 
	DATENAME(HOUR, start_time) AS day_hour,
	COUNT(*) as ride_count
FROM rides
GROUP BY DATENAME(HOUR, start_time)
HAVING COUNT(*) > 0
ORDER BY ride_count desc
-- in top 10, 12 -6 pm are highlighted
-- and a surge of early mornings at 6-7am

-- POPULAR STATIONS
-- amount of rides being booked within the station
select 
'rides' as [type], 
count(*) as [count]
from rides

-- temporal data to plot on the map
select
-- top 10
	s.station_name,
	s.lat,
	s.lon,
	count(r.ride_id)  as total_starts
from rides as r
join stations as s
	on s.station_id = r.start_station_id
group by s.station_name, s.lat, s.lon
order by total_starts desc

-- UTILIZATION RATE FOR THE STATION
-- DAILY USAGE, DAILY UTILIZATION, then TOTAL AGGREGRATE
with daily_usage as (
	select 
		start_station_id,
		cast(start_time as date) as ride_date,
		count(*) as daily_rides
	from rides
	group by start_station_id, cast(start_time as date)
),
daily_utilization as (
	select
		u.ride_date,
		u.start_station_id,
		s.station_name,
		s.capacity,
		u.daily_rides,
		cast(u.daily_rides as float)/nullif(s.capacity,0) * 100 as daily_util_rate

	from daily_usage as u
	join stations as s
		on u.start_station_id = s.station_id
)
Select
	station_name,
	capacity,
	avg(daily_util_rate) as avg_util,
	max(daily_util_rate) as max_util
from daily_utilization
group by 
	station_name,
	capacity
order by max_util desc
GO


-- alternate approach to getting utilization via window functions
WITH daily_usage AS (
    SELECT 
        start_station_id,
        CAST(start_time AS DATE) AS ride_date,
        COUNT(*) AS daily_rides
    FROM rides
    GROUP BY 
        start_station_id,
        CAST(start_time AS DATE)
)
SELECT DISTINCT
    s.station_name,
    s.capacity,
    AVG(CAST(u.daily_rides AS FLOAT) / NULLIF(s.capacity, 0))
			OVER(PARTITION BY s.station_id) AS avg_util,
    MAX(CAST(u.daily_rides AS FLOAT) / NULLIF(s.capacity, 0)) 
			OVER(PARTITION BY s.station_id) AS max_util
FROM daily_usage u 
JOIN stations s 
    ON u.start_station_id = s.station_id
ORDER BY 
    max_util DESC;
GO

-- BINNING RIDE DURATION using MINUTES
-- short (10), medium (35), long ride
with rides_bins as (
	select
		case 
			-- incremental conditional check
			when datediff(minute, start_time, end_time) <= 10 then 'Short'
			when datediff(minute, start_time, end_time) <= 35 then 'Medium'
			-- when datediff(minute, start_time, end_time) between 11 and 35
			else 'Long'
		end as ride_category
	from rides
)
select 
	ride_category,
	count(*) as ride_count
from rides_bins
group by ride_category
order by ride_count desc
GO
-- rides largely fall under medium and long rides, given for rides above 30 mins
-- basically average ride is majorly over 30 mins, 80+ % of the time

-- OUTLIER; HIGHER LIMIT
with rides_duration as (
	select 
		r.*,
		datediff(minute, start_time, end_time) as duration
	from rides as r
)
SELECT top 1
	PERCENTILE_CONT(0.95)
	WITHIN GROUP (ORDER BY duration)
	OVER() as p95_duration
FROM rides_duration
GO

-- Extract unusually high rides
with rides_duration as (
	select 
		r.*,
		datediff(minute, start_time, end_time) as duration
	from rides as r
),
p95 as (
SELECT top 1
	PERCENTILE_CONT(0.95)
	WITHIN GROUP (ORDER BY duration)
	OVER() as p95_duration
FROM rides_duration
)
select
	*
from rides_duration 
where duration > (SELECT top 1
						PERCENTILE_CONT(0.95)
						WITHIN GROUP (ORDER BY duration)
						OVER() as p95_duration
				  FROM rides_duration)
order by 
 duration desc
--cast(start_time as date)
GO
-- future outlook is to basically perform a scatter plot or correlation analysis on this subset of data
-- to find relationships between duration and either start time and distance

-- USER GROWTH (MONTH OVER MONTH)
WITH signups AS
(
    SELECT
        DATETRUNC(MONTH, created_at) AS signup_month,
        COUNT(*) AS signup_count
    FROM users
    GROUP BY DATETRUNC(MONTH, created_at)
)
SELECT
    signup_month,
    signup_count,
    LAG(signup_count)
        OVER(ORDER BY signup_month) AS prev_month,
    ROUND(
            (signup_count
            - LAG(signup_count)
                OVER(ORDER BY signup_month)
				) * 100.0
        /
        NULLIF(
            LAG(signup_count)
                OVER(ORDER BY signup_month),
            0
        ),
        2
    ) AS [user_growth_pct%]
FROM signups
ORDER BY signup_month
GO