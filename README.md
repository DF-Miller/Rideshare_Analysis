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
* *fact_rides* table: Dropped all values in fact_rides with NULL pricing values.
  * This analysis focuses on price and how different variables affect it.
    * Dropping this allowed me to drop 55K rows from the table that would have had no use in analysis.
  * *short_summary* column: The values in this column contained leading and trailing spaces, making filtering on the values within this column difficult. I updated the column using the TRIM function in SQL.
    * Discovered using the LENGTH function in SQL after WHERE filtering was not working properly with this column. 
* *dim_products* table: Dropped the Taxi product row.
  * All the rows with NULL pricing values that were dropped were Taxis ordered through uber. There for this row was unnecessary.

### Data Analysis
* Average Price Per Product
  * The most expensive product is Lyft Lux Black XL, averaging $32.32 per ride.
     * This is followed by Uber Black SUV at $30.29, and then Lyft Lux black at $23.06.
     * The cheapest option is Lyft Shared, averaging $6.03 per ride. Followed by UberPool at $8.75 a ride.
       
 ![](pics/avg%20cost%20per%20ride%20type.png)


* Location
  * Boston University is the most expensive place to order an Uber to or from, averaging $18.85 per ride.
    * Followed by Fenway ($18.38) and then the Financial District ($18.18).
    * Back Bay has the highest average surge multiplier at just below 3%.
  * The Financial District Is the most popular drop-off and pick-up site, followed by Back Bay, and the Theatre District.
-- Pricture

![](pics/avg%20price%20per%20location.png)


* Distance Pricing
    * For every addition mile of a ride, the average price increase is $2.14. For every 10th of a mile, the cost is $0.23.
      * The everage price per addition mile for Lyft's is $3.53, while for Uber it is $2.18.
     
   -- Picture

* Weather
   * Precipitation slightly influences ride prices. Looking at the average cost of rides for all different weather conditions, all weather summaries that include current precipitation or overcast are more expensive than when it is clear outside or when there is the potential for rain.
   * The Price of getting a ride increases in 7 of the 12 locations when it is drizzling, lighting raining, or raining.
      * The biggest price increase is in the financial district where prices increase by almost 1.5% or 26 cents per ride.
      * The average price of a ride increases about 9 cents when there is some form of rain.
      * Uber increases their prices more than Lyft. Uber prices jump by 11 cents, while Lyft price increase by 2 cents
  * Temperature does not appear to affect ride prices. There are no clear trends in price changes as temperature falls. Looking at average ride costs for every 5-degree change in temperature, ride prices fluctuate by only a few cents in either direction, seemingly unaffected by outside temperature. Prices when the temperature is around 20 degrees are about 9 cents higher than when it is around 55 degrees, but prices when it is 25 degrees are actually about 5 cents lower than when it is 55 degrees. The percentage change across 5-degree temperature groups shows no consistent trend in price increases as temperatures drop.
  * Visibility also does not appear to affect ride prices, unless there is under 0.5 miles of visibility. When Visibility falls under 0.5 miles, the average cost of a ride increases by 50 cents. Aside from this, there is no obvious trend in price change as visibility decreases. When visibility is grouped in 1-mile increments (Visivilty is the distance in miles a person can clearly see horizontally), the percentage change in pricing appears random, showing both increases and decreases in price as visibility worsens. Prices when visibility is limited to 1 mile are nearly 2 cents cheaper than when visibility is 10 miles.
  -- Pictures 
* Time
   * There is no time period of the day where rides are significantly more expensive (ignoring the surge multiplier). Ride prices are not affected by it being morning, afternoon, or night.
   * Sunset and Sunrise do not have any effect on the cost of a ride. If you get a ride before sunrise or after sunset there is no difference in price if you were to get a ride while the sun was still out.
