# Rideshare Analysis
## Uber and Lyft Analysis for Customers

This data is from a 1 table dataset containing Uber and Lyft pricing information. The table contains data from November and December 2018 uber and Lyft rides in Boston, MA. USA. The *raw file columns and descriptions* section describe the original Kaggle dataset before cleaning. Some of these columns could be used for future analysis. The *Database Cleanup* section details the size of the original table and details how it was converted into a STAR schema. The *Data Analysis* section summarizes key insights.

Data Source: https://www.kaggle.com/datasets/brllrb/uber-and-lyft-dataset-boston-ma

### Raw File Columns and Descriptions

#### Ride ID and Time Columns 
*	Id: unique row identifier
*	Timestamp: Unix timestamp
*	Datetime: Date and Time of ride
*	Hour: hour of day on 24 hour scale
*	Day: day of month
*	Month: month of year (1-12)
*	Timezone: all US Eastern Time
#### Location / Trip Information
*	Source: pickup location
*	Destination: drop-off location
*	Latitude: latitude of the route / city
*	Longitude: Longitude of the route / city
*	Distance: Distance of ride
#### Product (Car Type) Information
*	Cab_type: Service Provider (Lyft and Uber)
*	Product_id: Unique ID for ride type
*	Name: Product name user selects (uberX, Uber Black, etc.)
####	Pricing
*	Price: price of ride
*	Surge multiplier: surge pricing multiplier
####	Weather (During Trip)
*	temperature:	actual temperature
*	apparentTemperature:	“feels like” temperature
*	humidity: relative humidity
*	dewpoint: dew point
* pressure: atmospheric pressure
*	windspeed: wind speed
*	windGust: wind gust speed
*	windGustTime: time of strongest gust
*	windBearing:	wind direction (degrees)
*	cloudCover: % cloud cover
*	uvIndex: UV index
*	visibility: visibility distance
*	visibility.1: duplicate visibility column (likely Kaggle artifact)
*	ozone: ozone concentration
*	short_summary: Short text description of weather
*	long_summary: Longer text description of weather
*	icon: Weather Condition icon label (rainy, cloudy, etc.)
#### Weather Extremes (Daily, not trip time)
*	temperatureHigh: Daily high temp
*	temperatureHighTime:	Time of daily high
*	temperatureLow: Daily low temp
*	temperatureLowTime:	Time of daily low
*	temperatureMin: Min temp observed
*	temperatureMinTime:	Time of min temp
*	temperatureMax: Max temp observed
*	temperatureMaxTime:	Time of max temp
*	apparentTemperatureHigh: Daily high “feels like” temp
*	apparentTemperatureHighTime: Time of highest “feels like” temperature
*	apparentTemperatureLow: Daily low “feels like”
*	apparentTemperatureLowTime:	Time of low “feels like” temperature
*	apparentTemperatureMin: Min feels-like
*	apparentTemperatureMinTime:	Time of min “feels like” temperature
*	apparentTemperatureMax: Max feels-like
*	apparentTemperatureMaxTime:	Time of max “feels like” temperature
#### Precipitation and Other
*	precipIntensity: Rain intensity at time
*	precipProbability: Probability of precipitation
*	precipIntensityMax: Max rain intensity that day
*	sunriseTime: Sunrise timestamp
*	sunsetTime: Sunset timestamp
*	moonPhase: Moon phase (0–1)
*	uvIndexTime: Time of max UV

### Database Cleanup
* Raw File Size: 302MB

#### Dimension Tables
* *dim_products* table: Stores unique ride types, eliminates repetition
  *	product_id: Unique identifier for each ride type (Primary Key)
  *	cab_type: Company (Uber or Lyft)
  *	product_name: Different types of Uber/Lyft services (XL, Shared, etc)
* *dim_location* table: Stores Unique source and destination locations
  * location_id : Primary key, unique location identifier
  * location_name: Area ride began or ended
#### Fact Table
* *fact_rides* table: Fact table for majority of analysis. I created a surrogate primary key because the original id column was a long, non-semantic string.
  * ride_id: Primary key
  * source_id: original id
  * product_id: foreign key from products table
  * ride_date: Parsed date from datetime_raw column
  * ride_time: Parsed time from datetime_raw column
  * ride_datetime: original datetime
  * Source: pickup location
  * Destination: drop-off location
  * Distance: Distance of ride
  * Price: price of ride
  * Surge multiplier: surge pricing multiplier. 1.25-3 times price increase during high demand times of day
  * temperature:	actual temperature
  * short_summary: Short text description of weather
  * humidity: relative humidity
  * windspeed: wind speed
  * windGust: wind gust speed
  * visibility: visibility distance
  * precipIntensity: Rain intensity at time
  * sunriseTime: Sunrise timestamp
  * sunsetTime: Sunset timestamp

Updated rideshare database schema is 264.23MB

### Data Cleaning
* *fact_rides* table: Dropped all values in fact_rides with NULL pricing values
  * This analysis focuses on price and how different variables affect it
    * Dropping this allowed me to drop 55K rows from the table that would have had no use in analysis
  * *short_summary* column: The values in this column contained leading and trailing spaces, making filtering on the values within this column difficult. I updated the column using the TRIM function in SQL.
    * Discovered using the LENGTH function in SQL after WHERE filtering was not working properly with this column 
* *dim_products* table: Dropped the Taxi product row
  * All the rows with NULL pricing values that were dropped were Taxis ordered through uber. There for this row was unnecessary.

### Data Analysis
* Average Price Per Product
  * The most expensive product is Lyft Lux Black XL, averaging $32.32 per ride
     * This is followed by Uber Black SUV at $30.29, and then Lyft Lux black at $23.06
     * The cheapest option is Lyft Shared, averaging $6.03 per ride. Followed by UberPool at $8.75 a ride.


