CREATE DATABASE rideshare;
USE rideshare;

SELECT * FROM  rideshare_staging;


-- Backup table to be deleted after data prep completed 

CREATE TABLE rideshare_staging_backup AS
SELECT * FROM rideshare_staging;



-- Raw Datebase Size
SELECT table_schema AS db_rideshare,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS size_mb
FROM information_schema.tables
WHERE table_schema = 'rideshare'
GROUP BY table_schema;

-- 302.0 mb before cleaning


-- Product Table
CREATE TABLE products (
	  product_id VARCHAR(50) PRIMARY KEY
    , cab_type VARCHAR(10)
    , product_name VARCHAR(30));
    
INSERT INTO products ( product_id, cab_type, product_name)
SELECT
    product_id,
    MAX(cab_type),
    MAX(name)
FROM rideshare_staging
GROUP BY product_id;
 
 

 
-- Drop cab_type and name column from rideshare_staging
ALTER TABLE rideshare_staging
  DROP COLUMN cab_type
, DROP COLUMN name;

-- timezone column drop

SELECT COUNT( DISTINCT timezone)
from rideshare_staging;
-- 1 timezone in DB, therefore its a waste of space

ALTER TABLE rideshare_staging
  DROP COLUMN  timezone;


select * from rideshare_staging;
select COUNT(*) from rideshare_staging;
select COUNT(DISTINCT id) from rideshare_staging;


-- fact_rides table

CREATE TABLE fact_rides (
	  ride_id BIGINT AUTO_INCREMENT PRIMARY KEY
    , source_ride_id VARCHAR(50) UNIQUE
    , product_id VARCHAR(50)
	, ride_date DATE
    , ride_time TIME
    , ride_datetime DATETIME
    , source VARCHAR(50)
    , destination VARCHAR(50)
    , distance DECIMAL(6,2)
    , price DECIMAL(6,2)
    , surge_multiplier DECIMAL(4,2)
    , latitude DECIMAL(8,5)
    , longitude DECIMAL(8,5)
    , temperature DECIMAL(5,2)
    , short_summary VARCHAR(50)
    , precipIntensity DECIMAL(6,4)
    , humidity DECIMAL(4,2)
    , windSpeed DECIMAL(5,2)
    , windGust DECIMAL(5,2)
    , visibility DECIMAL(5,2)
    , sunriseTime BIGINT
    , sunsetTime BIGINT
    , FOREIGN KEY (product_id)      REFERENCES products(product_id)
);

INSERT INTO fact_rides (
      source_ride_id
    , product_id
    , ride_date
    , ride_time
    , ride_datetime
    , source
    , destination
    , distance
    , price
    , surge_multiplier
    , latitude
    , longitude
    , temperature
    , short_summary
    , precipIntensity
    , humidity
    , windSpeed
    , windGust
    , visibility
    , sunriseTime
    , sunsetTime
)
SELECT
      id
    , product_id
    , DATE(STR_TO_DATE(datetime_raw, '%m/%d/%Y %H:%i'))
    , TIME(STR_TO_DATE(datetime_raw, '%m/%d/%Y %H:%i'))
    , STR_TO_DATE(datetime_raw, '%m/%d/%Y %H:%i')
    , source
    , destination
    , distance
    , NULLIF(price, '')
    , surge_multiplier
    , latitude
    , longitude
    , temperature
    , short_summary
    , precipIntensity
    , humidity
    , windSpeed
    , windGust
    , visibility
    , sunriseTime
    , sunsetTime
FROM rideshare_staging;


SELECT 
	  source
    , destination
from fact_rides;

-- Source and Destination are 1000s of repeated values, it makes sense to store them in a dimension table with a unique Id
 CREATE TABLE dim_location (
      location_id INT AUTO_INCREMENT PRIMARY KEY
    , location_name VARCHAR(50) UNIQUE);


ALTER TABLE fact_rides
  ADD source_location_id INT
, ADD destination_location_id INT
, ADD FOREIGN KEY (source_location_id) REFERENCES dim_location(location_id)
, ADD FOREIGN KEY (destination_location_id) REFERENCES dim_location(location_id);

INSERT INTO dim_location (location_name)
SELECT DISTINCT source FROM rideshare_staging UNION SELECT DISTINCT destination FROM rideshare_staging;


UPDATE fact_rides fr
JOIN dim_location l ON fr.source = l.location_name SET fr.source_location_id = l.location_id;
UPDATE fact_rides fr
JOIN dim_location l ON fr.destination = l.location_name SET fr.destination_location_id = l.location_id;


ALTER TABLE fact_rides
	  DROP COLUMN source
 	, DROP COLUMN destination;
    
Select * from fact_rides;
SELECT * from dim_location;
RENAME TABLE products TO dim_products;


-- New table size
SELECT
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.tables
WHERE table_schema = 'rideshare'
  AND table_name IN ('dim_location', 'dim_products', 'fact_rides');
  
-- DROP TABLE rideshare_staging;
-- DROP TABLE rideshare_staging_backup;