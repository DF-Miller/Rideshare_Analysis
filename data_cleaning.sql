-- Data Cleaning

-- Fact_rides 
SELECT count(*) FROM fact_rides;

SELECT count(*)
FROM fact_rides
WHERE price IS NULL;
-- 55k Rows with NULL price.

SELECT 
	  r.product_id
    , r.price  
    , p.cab_type
    , p.product_name
FROM fact_rides r
INNER JOIN dim_products p
ON r.product_id = p.product_id
WHERE price IS NULL;


SELECT COUNT(*) AS non_taxi_null_prices
FROM fact_rides r
INNER JOIN dim_products p
    ON r.product_id = p.product_id
WHERE r.price IS NULL
  AND p.product_name <> 'taxi';
  
  
  -- Drop NULL values in the price column of the fact_rides Tables
  DELETE FROM fact_rides
  WHERE price IS NULL;

-- All Null Price Values are From Taxis Ordered through Uber
-- The Main analysis focuses on pricing and variables that affect it, therefore rows with NULL values in price can be dropped
-- Dropping the ~55K unnecessary rows improves the performance of Power BI Desktop

SELECT * FROM fact_rides;

-- Dimension Tables Cleaning
SELECT * FROM dim_products;

SELECT * FROM fact_rides
WHERE product_id = '8cf7e821-f0d3-49c6-8eba-e679c0ebcf6a'; -- Direct Check

SELECT COUNT(*) AS taxi_rows
FROM fact_rides r
INNER JOIN dim_products p
  ON r.product_id = p.product_id
WHERE p.product_name = 'taxi'; -- Further check

DELETE FROM dim_products
WHERE product_name = 'taxi';

-- The row for the product_name taxi is no longer necessary
-- The product_id associated with taxi was entirely removed from fact_rides when NULL price rows were deleted
