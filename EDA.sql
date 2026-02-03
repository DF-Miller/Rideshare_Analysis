---------------------------------------------------------------------------------------
-- Exploratory Data Analysis

-- Average Price per Product
SELECT
	  p.cab_type
	, p.product_name
    , ROUND( AVG(r.price), 2) AS avg_price
FROM fact_rides r
INNER JOIN dim_products p
	ON r.product_id = p.product_id
GROUP BY 
	  p.product_name
    , p.cab_type
ORDER BY avg_price DESC; -- MySQL allows for using alias in Order By

-- Average Price and Surge Multiplier by Pickup and Drop-off Location

-- Pickup
SELECT
	  l.location_name
    , ROUND (AVG(r.price), 2) AS avg_price
	, ROUND( AVG(r.surge_multiplier), 4) AS avg_surge
FROM fact_rides r
LEFT JOIN dim_location l
	ON r.source_location_id = l.location_id
GROUP BY source_location_id
ORDER BY avg_price DESC;


-- Weather Affects

-- Average Price for Weather Catergory
SELECT
	  short_summary
    , AVG(price) AS avg_price
FROM fact_rides
GROUP BY short_summary
ORDER BY avg_price DESC;

-- Top 3 most expensive weather conditions per location
WITH rk AS (
	SELECT
		  l.location_name
		, r.short_summary
		, AVG(r.price) AS avg_price
		, DENSE_RANK() OVER( PARTITION BY l.location_name ORDER BY AVG(r.price) DESC) AS price_rnk
	FROM fact_rides r INNER JOIN dim_location l 
		ON r.source_location_id = l.location_id
	GROUP BY  
		  l.location_name
		, r.short_summary)
SELECT *
FROM rk
WHERE price_rnk <= 3;

-- How much does any precipitation increase price?
WITH precipitation AS (
	SELECT
		  l.location_name
		, AVG(r.price) AS avg_price_precipitation
	FROM fact_rides r INNER JOIN dim_location l 
			ON r.source_location_id = l.location_id
	WHERE r.short_summary IN ('Rain', 'Light Rain', 'Drizzle')
	GROUP BY l.location_name),
clear AS (
	SELECT
		  l.location_name
		, AVG(r.price) AS avg_price_clear
	FROM fact_rides r INNER JOIN dim_location l 
			ON r.source_location_id = l.location_id
	WHERE r.short_summary = 'Clear'
	GROUP BY l.location_name)
SELECT 
	  c.location_name
    , ROUND(c.avg_price_clear, 2)
    , ROUND(p.avg_price_precipitation, 2)
    , ROUND(p.avg_price_precipitation - c.avg_price_clear , 2) AS price_increase
    , ROUND((p.avg_price_precipitation - c.avg_price_clear) / c.avg_price_clear * 100 , 2) AS percent_difference
FROM clear c INNER JOIN precipitation p	
ON  c.location_name = p.location_name;
    
-- Overall price with precipitation vs clear
SELECT
	CASE WHEN short_summary IN ('Rain', 'Light Rain', 'Drizzle') THEN 'precipitation'
		 WHEN short_summary = 'Clear' THEN 'Clear'
         END AS weather_type 
	, ROUND (AVG(price),2) AS avg_price
FROM fact_rides
WHERE short_summary IN ('Rain', 'Light Rain', 'Drizzle', 'Clear')
GROUP BY weather_type;

-- Precipitation price changes: Uber vs. Lyft
SELECT
	  p.cab_type AS service
	, CASE WHEN short_summary IN ('Rain', 'Light Rain', 'Drizzle') THEN 'precipitation'
		 WHEN short_summary = 'Clear' THEN 'Clear'
         END AS weather_type 
	, ROUND (AVG(price),2) AS avg_price
FROM fact_rides r INNER JOIN dim_products p 
	ON r.product_id = p.product_id
WHERE r.short_summary IN ('Rain', 'Light Rain', 'Drizzle', 'Clear')
GROUP BY 
	  service
    , weather_type
ORDER BY
	  service
    , weather_type;
    
    
-- Temperature effect on cost of rides
SELECT *  FROM fact_rides;

WITH temp AS (
	SELECT
		   Round(temperature / 5 ) * 5 AS nearest_5_degrees
		 , ROUND(AVG(price),2) AS avg_price
	FROM fact_rides
	GROUP BY nearest_5_degrees
	ORDER BY nearest_5_degrees DESC)
SELECT
   *
   , COALESCE(ROUND(avg_price - LAG(avg_price) OVER(ORDER BY nearest_5_degrees DESC) , 2), ' ') AS price_change
   , COALESCE(avg_price - LAG(avg_price, 4)  OVER(ORDER BY nearest_5_degrees DESC), '')  AS price_change_20degrees
   , COALESCE(avg_price - LAG(avg_price, 7)  OVER(ORDER BY nearest_5_degrees DESC), '')  AS price_change_low_high
   , COALESCE(ROUND((avg_price - LAG(avg_price) OVER(ORDER BY nearest_5_degrees DESC)) / LAG(avg_price) OVER(ORDER BY nearest_5_degrees DESC), 4), '') AS price_percent_change_1month

FROM temp;

-- Visability effect on price
WITH viz AS (
	SELECT
		 ROUND(Visibility) AS visibility_group
	   , AVG(price) AS avg_price
	FROM fact_rides
	GROUP BY visibility_group
	ORDER BY visibility_group DESC)
SELECT
	  *
    , COALESCE(avg_price - LAG(avg_price) OVER(ORDER BY visibility_group DESC), '') AS price_change
    , COALESCE(ROUND((avg_price - LAG(avg_price) OVER(ORDER BY visibility_group DESC)) / LAG(avg_price) OVER(ORDER BY visibility_group DESC) * 100, 2 ), '') AS price_percent_change
    , COALESCE(avg_price - LAG(avg_price, 9) OVER(ORDER BY visibility_group DESC),'') AS highlow_diff
FROM viz;


-- Busiest Locations
WITH dropoff AS (
	SELECT
		   l.location_name 
		 , COUNT(*) AS dropoff_total
	FROM fact_rides r LEFT JOIN dim_location l
		ON r.destination_location_id = l.location_id
	GROUP BY r.destination_location_id),
pickup AS (
	SELECT
		   l.location_name 
		 , COUNT(*) AS pickup_total
	FROM fact_rides r LEFT JOIN dim_location l
		ON r.source_location_id = l.location_id
	GROUP BY source_location_id)
SELECT
	  dropoff.location_name
    , dropoff.dropoff_total
    , ROW_NUMBER() OVER(ORDER BY dropoff_total DESC) AS dropoff_rank
    , pickup.pickup_total
    , ROW_NUMBER() OVER(ORDER BY pickup_total DESC) AS dropoff_rank
FROM dropoff JOIN pickup
	ON dropoff.location_name = pickup.location_name
ORDER BY pickup.pickup_total DESC;


-- Distance Effect on Cost of Rides

-- Cost per 10th of a mile
WITH avmile AS (
	SELECT
		  ROUND(distance, 1) AS mile
		, ROUND(AVG(price),2) AS average_price
	FROM fact_rides
	GROUP BY mile),
dif AS (
	SELECT 
		  *
		, average_price - LAG(average_price) OVER(ORDER BY mile ASC) as dif
	FROM avmile
	WHERE mile > 0)
SELECT
	ROUND( AVG(dif), 2) cost_per_onetenth_mile
FROM dif;


-- Cost per mile and increase cost mile over mile

WITH avmile AS (
	 SELECT 
	DISTINCT ROUND(distance, 0) AS mile 
	, ROUND(AVG(price),2) AS average_price 
	FROM fact_rides 
-- WHERE product_ID NOT LIKE '%lyft%' 
GROUP BY mile ORDER BY mile ), dif AS 
( SELECT * , average_price - LAG(average_price) OVER(ORDER BY mile ASC) as dif FROM avmile WHERE mile > 0) 
SELECT ROUND( AVG(dif), 2) cost_per_mile 
FROM dif;


SELECT
    ROUND(AVG(price / distance), 2) AS cost_per_mile
FROM fact_rides
WHERE distance > 0;

SELECT
  CASE 
    WHEN product_ID LIKE '%lyft%' THEN 'Lyft'
    ELSE 'Non-Lyft'
  END AS provider,
  ROUND(AVG(price / distance), 2) AS cost_per_mile
FROM fact_rides
WHERE distance > 0
GROUP BY provider;


-- Cost per Mile Breakdown
SELECT
	  DISTINCT ROUND(distance, 0) AS mile
	, ROUND(AVG(price),2) AS average_price
FROM fact_rides
GROUP BY mile
ORDER BY mile;


-- Time of the day pricing
WITH tyme AS (
	SELECT
		  HOUR(ride_time) AS hour_of_day
		, ROUND(AVG(price), 2) AS avg_price
	FROM fact_rides
	GROUP BY hour_of_day
	ORDER BY avg_price DESC )
SELECT
	  *
    , DENSE_RANK() OVER(ORDER BY avg_price DESC) as rnk
FROM tyme;


-- Price pre and post sunset
SELECT
      ROUND( AVG(CASE WHEN ride_time < TIME(FROM_UNIXTIME(sunsetTime))THEN price END) ,2) AS avg_price_pre_sunset
    , ROUND( AVG(CASE WHEN ride_time >= TIME(FROM_UNIXTIME(sunsetTime))THEN price END), 2) AS avg_price_after_sunset
FROM fact_rides;





