USE Ebike_DB
Go

select 
	datetrunc(day, start_time) as ride_date,
	count(*) as daily_ride_count
from rides
group by datetrunc(day, start_time)
GO

-- 7 DAY ROLLING AVERAGE
with daily_rides as (
	select 
		cast(start_time as date) as ride_date,
		count(*) as daily_ride_count
	from rides
	group by cast(start_time as date)
		
)
select 
	*,
	avg(cast(daily_ride_count as float)) over
	(order by ride_date
	rows between 6 preceding and current row) as ma7d

from daily_rides
order by ride_date
GO

-- Rides Week over Week Analysis
-- Is ride demand increasing or decreasing from week to week?
with weekly_rides as (
	select
		cast(datetrunc(week, start_time) as date) as week_start,
		count(*) as weekly_ride_count
	from rides
	group by datetrunc(week, start_time)
)
select 
	*,
	LAG(weekly_ride_count)
	OVER (ORDER BY week_start) as prev_week,
	-- percentage growth
	-- current week - prev/ prev week
	-- (20 - 10)/10 = 1 * 100 = 100%
	(
	weekly_ride_count - LAG(weekly_ride_count) OVER (ORDER BY week_start)
	)* 100
	/
	NULLIF(
	LAG(weekly_ride_count) OVER (ORDER BY week_start),
	0) AS [wow_%growth]-- TO AVOID ZERO DIVISION ERROR

from weekly_rides
GO

-- Cohort Retention Pivot (Month)
with cohort_sizes as (
	select 
		format(created_at, 'yyyy-MM') as cohort_month,
		min(datetrunc(month, created_at)) as cohort_month_date,
		count(user_id) as cohort_size
	from users
	group by format(created_at, 'yyyy-MM')
),
users_months_active as (
	select distinct
		r.user_id,
		u.created_at as account_signup,
		datetrunc(month, u.created_at) as cohort_month_date,
		-- r.start_time,
		cast(datetrunc(month, r.start_time) as date) as activity_month_date

	from rides as r
	join users as u
		on r.user_id = u.user_id
	where r.start_time >= u.created_at
)
select
	cs.cohort_month,
	cs.cohort_size,
	datediff(month, ua.cohort_month_date, ua.activity_month_date) as months_after_signup,
	count(ua.user_id) as active_users,
	(count(ua.user_id) * 100)/cs.cohort_size as active_pct

from cohort_sizes as cs
join users_months_active as ua
	on ua.cohort_month_date = cs.cohort_month_date

-- exclude checks of the first sign up month
where datediff(month, ua.cohort_month_date, ua.activity_month_date) > 0

group by
	cs.cohort_month,
	cs.cohort_size,
	datediff(month, ua.cohort_month_date, ua.activity_month_date)
order by 
	cs.cohort_month,
	months_after_signup

/* 
Inflexion Points: Cross Overs [Bearish and Bullish]
- shorter: 7 day moving average
- longer: monthly moving average

Bearish: when shorter below than longer
Bullish : when shorter above than longer's avg

*/

with daily_rides as (
	select 
		cast(start_time as date) as ride_date,
		count(*) as daily_ride_count
	from rides
	group by cast(start_time as date)
		
),
moving_averages as (
	select 
		*,
		avg(cast(daily_ride_count as float)) over
		(order by ride_date
		rows between 6 preceding and current row) as ma7d,

		avg(cast(daily_ride_count as float)) over
		(order by ride_date
		rows between 29 preceding and current row) as ma30d


	from daily_rides
),
previous_averages as (
	select 
		*,
		lag(ma7d) over (order by ride_date) as prev_ma7,
		lag(ma30d) over (order by ride_date) as prev_ma30
	from moving_averages
)
select
	ride_date,
	daily_ride_count,
	ma7d,
	ma30d,
	case 
		when (prev_ma30 > prev_ma7) and (ma7d > ma30d)
		then 'Bullish'

		when (prev_ma7 > prev_ma30) and (ma7d < ma30d)
		then 'Bearish'

	end as signal
from previous_averages
where 
	(prev_ma30 > prev_ma7) and (ma7d > ma30d) 
	or 
	(prev_ma7 > prev_ma30) and (ma7d < ma30d)
order by ride_date;
