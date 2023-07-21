---\ Creating Database,Schema,Table,File Format and Inserting the dataset /---
CREATE OR replace DATABASE TOURISM;
USE DATABASE TOURISM;

CREATE OR replace SCHEMA EUROPE;
USE SCHEMA EUROPE;

CREATE OR replace TABLE AIRBNB(
    City varchar (30),
    Price NUMBER (12,6),
    DayType varchar(10),
    Room_Type varchar (30),
    Shared_Room varchar(6),
    Private_Room varchar(6),
    Person_Capacity NUMBER(12,6),
    Superhost varchar(6),
    Multiple_Rooms NUMBER (12,6),
    Business NUMBER(12,6),
    Cleanliness_Rating NUMBER (12,6),
    Guest_Satisfaction NUMBER (12,6),
    Bedrooms NUMBER (12,6),
    City_Center NUMBER (12,6),
    Metro_Distance NUMBER (12,6),
    Attraction_Index NUMBER (12,6),
    Normalised_Attraction_Index NUMBER (12,6),
    Restraunt_Index NUMBER (12,6),
    Normalised_Restraunt_Index NUMBER (12,6)
    );


    ---\ CREATE BULK INSERT CSV FORMAT /---
---field optionally enclosed for double quatation in the records ""
create or replace file format csv_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = '\042'
    skip_header = 1;

    --now we will perform eda

    select * from airbnb limit 10;
    select count(*) from AIRBNB; --we have total 41714 records in the dataset

    --to check null values
    SELECT * FROM AIRBNB 
WHERE 
    CITY AND PRICE AND DAYTYPE AND ROOM_TYPE AND SHARED_ROOM AND PRIVATE_ROOM AND PERSON_CAPACITY AND SUPERHOST AND 
    MULTIPLE_ROOMS AND BUSINESS AND CLEANLINESS_RATING AND GUEST_SATISFACTION AND BEDROOMS AND CITY_CENTER AND  METRO_DISTANCE AND ATTRACTION_INDEX AND NORMALISED_ATTRACTION_INDEX AND RESTRAUNT_INDEX AND  NORMALISED_RESTRAUNT_INDEX  IS NULL;--no null values found
    
  --to check blank values

  SELECT * FROM AIRBNB
WHERE 
    CITY AND PRICE AND DAYTYPE AND ROOM_TYPE AND SHARED_ROOM AND PRIVATE_ROOM AND PERSON_CAPACITY AND SUPERHOST AND  MULTIPLE_ROOMS AND BUSINESS AND CLEANLINESS_RATING AND GUEST_SATISFACTION AND BEDROOMS AND CITY_CENTER AND METRO_DISTANCE AND ATTRACTION_INDEX AND NORMALISED_ATTRACTION_INDEX AND RESTRAUNT_INDEX AND  NORMALISED_RESTRAUNT_INDEX = ''
LIMIT 5;  ---no blank values

--to check the number of cities
SELECT COUNT(DISTINCT CITY)
FROM AIRBNB; ---9 City

-- to check citywise bookings
SELECT 
    CITY, 
    COUNT(CITY) AS "NUMBER OF BOOKINGS"
FROM AIRBNB
GROUP BY CITY
ORDER BY 2 DESC; --ROME HAS THE HIGHEST OBSERBATION(9,027), AMSTERDAM HAS LEAST (2,080)

--to check daywise revenue and average booking price
SELECT
      DAYTYPE,
      ROUND(SUM(PRICE),0) AS "TOTAL BOOKING REVENUE",
      ROUND(AVG(PRICE),0) AS "AVERAGE BOOKING PRICE"
FROM AIRBNB
GROUP BY DAYTYPE
ORDER BY 2 DESC;--WEEKEND GENERATES MORE REVENURE THAN WEEKDAY BECAUSE OF IT'S HIGHER AVERAGE BOOKING PRICE

--now we will try to find out if our dataset has any outlier or not

WITH FIVE_NUMBER_SUMMARY AS
(SELECT 
MIN(price) AS MIN_price,
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS Q1,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS MEDIAN,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS Q3,
MAX(price) AS MAX_price,
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price)-PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price)) AS IQR
FROM airbnb),
HINGES AS
(SELECT (Q1-1.5*IQR) AS LOWER_HINGE, (Q3+1.5*IQR) AS UPPER_HINGE
FROM FIVE_NUMBER_SUMMARY AS F)

SELECT 
    COUNT (*) AS "NUMBER OF OUTLIERS IN PRICE FIELD" 
FROM AIRBNB
    WHERE PRICE < (SELECT LOWER_HINGE FROM HINGES) OR PRICE > (SELECT UPPER_HINGE FROM HINGES);---2,891 outliers


--to remove outliers and to store fresh data 

CREATE VIEW CLEANED AS
(
    WITH FIVE_NUMBER_SUMMARY AS
(SELECT 
MIN(PRICE) AS MIN_ORDER_VALUE,
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY PRICE) AS Q1,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY PRICE) AS MEDIAN,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY PRICE) AS Q3,
MAX(PRICE) AS MAX_ORDER_VALUE,
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY PRICE)-PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY PRICE)) AS IQR
FROM AIRBNB),

HINGES AS
(SELECT (Q1-1.5*IQR) AS LOWER_HINGE, (Q3+1.5*IQR) AS UPPER_HINGE
FROM FIVE_NUMBER_SUMMARY)

SELECT * FROM AIRBNB
WHERE PRICE > (SELECT LOWER_HINGE FROM HINGES) AND PRICE < (SELECT UPPER_HINGE FROM HINGES)
    );

select * from cleaned;
select count(*) from cleaned;--total records 38,823



---Room Type wise summary
SELECT 
    ROOM_TYPE AS "ROOM TYPE",
    COUNT(*) AS "NO. OF Bookings", 
    ROUND(MIN(PRICE),1) AS "MINIMUM PRICE VALUE",
    ROUND(MAX(PRICE),1) AS "MAXIMUM PRICE VALUE",
    ROUND(AVG(PRICE),1) AS "AVERAGE PRICE VALUE"
FROM CLEANED
GROUP BY ROOM_TYPE;--the maximum number of bookings for the room type is entire home(25,728). The private room is the cheapest place to stay and entire home is the most expensive

---City & Room Type wise Summary
SELECT 
    CITY,
    ROOM_TYPE AS "ROOM TYPE", 
    ROUND(SUM(PRICE),0) AS  "TOTAL REVENUUE"
FROM CLEANED
GROUP BY CITY, ROOM_TYPE
ORDER BY 3 desc;--the entire home in rome is the highest generating revenue

--Room type and Day type wise summary
SELECT 
    DAYTYPE,
    ROOM_TYPE AS "ROOM TYPE", 
    ROUND(SUM(PRICE),0) AS  "TOTAL REVENUUE"
FROM CLEANED
GROUP BY DAYTYPE, ROOM_TYPE
ORDER BY 3 desc; --weekend and entire home is the most profitable combination whereas weekday and shared room is the least


--distance wise price

SELECT 
   ROOM_TYPE,
    ROUND(AVG(PRICE),2) as "Average Price",
    ROUND(avg(metro_distance), 2) AS "AVERAGE DISTANCE FROM METRO KM",
    ROUND(avg(city_center), 2) AS "AVERAGE DISTANCE FROM CITY CENTRE IN KM"
    FROM CLEANED
GROUP BY 1
ORDER BY 2 DESC;

--to find out correlation between variables

SELECT 
    CORR(PRICE,METRO_DISTANCE) AS "CORRELATION BETWEEN PRICE AND METRO DISTANCE",
    CORR(PRICE,CITY_CENTER) AS "CORRELATION BETWEEN PRICE AND CITY CENTER DISTANCE",
    CORR(PRICE,GUEST_SATISFACTION) AS "CORRELATION BETWEEN PRICE AND GUEST SATISFACTION"
FROM CLEANED;--distance has no effect on the price as the correlation is very weak

-- to find out the cause of guest satisfaction
select
    corr(guest_satisfaction,cleanliness_rating) as "correlatiion between guest satisfaction and cleanliness rating",
    corr(guest_satisfaction,attraction_index) as "correlation between guest satisfaction and attraction indesx",
    corr(guest_satisfaction,restraunt_index) as "correlatioin between guest satisfaction and restaurant index"
from cleaned;--there has a strong relationship between guest satisfaction and cleanliness


--GUEST SATISFACTION BY CITY
SELECT 
    CITY,
    ROUND(AVG(GUEST_SATISFACTION),1) AS AVERAGE_GUEST_SATISFACTION_SCORE
FROM CLEANED
    GROUP BY CITY
    ORDER BY AVERAGE_GUEST_SATISFACTION_SCORE DESC;--the average guest satisfaction is the highest for the city Athens


--to find cleanliest city

SELECT 
      CITY,
      ROUND(AVG(CLEANLINESS_RATING),2) AS "AVERAGE CLEANLINESS RATING"
FROM CLEANED
GROUP BY 1
ORDER BY 2 DESC;--ATHENS IS THE MOST CLEAN CITY FOR THE TOURIST AND LOWEST FOR PARIS

--CLEANLINESS_RATING
SELECT 
CITY,
cleanliness_rating, count(cleanliness_rating) AS Frequency
FROM CLEANED
GROUP BY 1,2
ORDER BY 2 desc, 3 DESC;--Rome has got highest number of clealiness rating  10

SELECT CITY, 
    cleanliness_rating,
    COUNT(CITY) AS FREQUENCY
FROM CLEANED
where CLEANLINESS_RATING BETWEEN 3 AND 6
group by 1,2
order by 2 ,3 desc;

--City Ranking by Revenue
SELECT
CITY,
ROUND(SUM(PRICE),0) AS Revenue
FROM CLEANED
GROUP BY CITY
ORDER BY Revenue DESC;

SELECT
row_number() OVER(ORDER BY SUM(PRICE) DESC) AS Ranking,
CITY,
ROUND(SUM(PRICE),0) AS Revenue
FROM CLEANED
GROUP BY CITY;


--City Ranking by Revenue
SELECT
CITY,
ROUND(SUM(PRICE),0) AS Revenue
FROM CLEANED
GROUP BY CITY
ORDER BY Revenue DESC;

SELECT
row_number() OVER(ORDER BY SUM(PRICE) DESC) AS Ranking,
CITY,
ROUND(SUM(PRICE),0) AS Revenue
FROM CLEANED
GROUP BY CITY;



--Room Type wise Booking & Revenue
SELECT
ROOM_TYPE AS "ROOM TYPE",
COUNT(ROOM_TYPE) AS "Number of Booking",
ROUND(SUM(PRICE),0) AS "Total Revenue"
FROM CLEANED
GROUP BY "ROOM TYPE"
ORDER BY 3 DESC;

--Association of Guest Satisfaction Score with Other Performance Metrics of the Cites
SELECT
CITY,
ROUND(AVG(GUEST_SATISFACTION),1) AS "Average Guest Satisfaction Score",
ROUND(AVG(CLEANLINESS_RATING),2) AS "Average Cleanliness Score",
ROUND(AVG(PRICE),0) AS "Average Booking Value",
ROUND(AVG(NORMALISED_ATTRACTION_INDEX),1) AS "Average Attraction Index",
ROUND(MAX(CITY_CENTER),1) AS "Average Distance from City Center",
ROUND(MAX(METRO_DISTANCE),1) AS "Average Distance from Metro"
FROM CLEANED
GROUP BY CITY
ORDER BY "Average Guest Satisfaction Score" DESC;

-- =============== Dashboard Queries ===================== --
--KPI: AVERAGE BOOKING VALUE
SELECT ROUND(AVG(PRICE),0) AS "Average Booking Value" FROM CLEANED;
--KPI: AVERAGE Guest Satisfaction Score

SELECT ROUND(AVG(GUEST_SATISFACTION),1) AS "Average Guest Satisfaction Score"
FROM CLEANED;
--KPI: AVERAGE Cleanliness Score
SELECT ROUND(AVG(CLEANINGNESS_RATING),1) AS "Average Cleanliness Score" FROM
CLEANED;

--RE-CODING AND SUBQUERY
SELECT DISTINCT ROOM_TYPE_CLEANED
FROM
(SELECT
CASE WHEN ROOM_TYPE = 'Private room' THEN 'Private'
WHEN ROOM_TYPE = 'Entire home/apt' THEN 'APARTMENT'
ELSE 'SHARED' END AS ROOM_TYPE_CLEANED
FROM CLEANED);

--RE-CODING AND CTE (COMMON TABLE EXPRESSION)
WITH TEMPORARY_OUTPUT AS
(SELECT *,
CASE WHEN ROOM_TYPE = 'Private room' THEN 'Private'
WHEN ROOM_TYPE = 'Entire home/apt' THEN 'APARTMENT'
ELSE 'SHARED' END AS ROOM_TYPE_CLEANED
FROM AIRBNB)
SELECT ROOM_TYPE_CLEANED, COUNT(*) AS NUMBER_OF_BOOKING
FROM TEMPORARY_OUTPUT
GROUP BY ROOM_TYPE_CLEANED;



--INSPECTING THE REASON BEHIND THE DIFFERENCE IN AVERAGE GUEST
SATISFACTION SCORE
SELECT

CITY,
ROUND(AVG(GUEST_SATISFACTION),1) AS
AVERAGE_GUEST_SATISFACTION_SCORE,
ROUND(AVG(CLEANINGNESS_RATING),2) AS AVERAGE_CLEANLINESS_RATING,
ROUND(AVG(PRICE),0) AS AVERAGE_PRICE,
ROUND(AVG(NORMALSED_ATTACTION_INDEX),1) AS AVERAGE_ATTRACTION_INDEX,
ROUND(MAX(CITY_CENTER_KM),1) AS AVERAGE_DISTANCE_FROM_CITY_CENTER,
ROUND(MAX(METRO_DISTANCE_KM),1) AS AVERAGE_DISTANCE_FROM_METRO
FROM CLEANED
GROUP BY CITY
ORDER BY AVERAGE_GUEST_SATISFACTION_SCORE DESC;
/*
So, guests are leaving Athens, Budapest with more ratings in terms of satisfaction because
average booking price is low
compare with the other cities and those have the highest cleanlinsess rating as well.
However, the attraction index and distance from the city center or metro do not substantially
impact the guest satisfaction score.
*/














