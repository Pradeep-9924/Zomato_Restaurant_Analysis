drop database zomatodb;
create database ZomatoDB;
use ZomatoDB;

-- Create Main Table--

CREATE TABLE ZomatoMain (
    Restaurant_ID INT PRIMARY KEY,
    Restaurant_Name VARCHAR(255),
    Country_ID INT,
    City VARCHAR(100),
    Cuisine varchar(1000),
    Currency VARCHAR(5000),
    Has_Table_Booking ENUM('Yes', 'No'),
    Has_Online_Delivery ENUM('Yes', 'No'),
    Is_delivering_now VARCHAR(20),
	Switch_to_order_menu VARCHAR(20),
    Price_range int,
    votes int,
    Average_Cost_for_2 DECIMAL(10,2),
	Rating DECIMAL(3,1),
    YearOpening INT,
    MonthOpening INT,
    DayOpening INT
);
-- Create Country Table--
CREATE TABLE ZomatoCurrency (
    Currency VARCHAR(500) PRIMARY KEY,
    USD_Rate DECIMAL(10,9)
);
-- Create Currency Table --
CREATE TABLE ZomatoCountry (
    Country_ID INT PRIMARY KEY,
    Country_Name VARCHAR(100)
);

-- Load Data into MySQL--

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomatomain.csv'
INTO TABLE zomatomain
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomatocountry.csv'
INTO TABLE zomatocountry
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomatocurrency.csv'
INTO TABLE zomatocurrency
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Join All Tables--
SELECT zm.*, zc.Country_Name, zcr.USD_Rate
FROM zomatomain zm
LEFT JOIN zomatocountry zc ON zm.Country_ID = zc.Country_ID
LEFT JOIN zomatocurrency zcr ON zm.Currency = zcr.Currency;

-- Convert "Average Cost for 2" to USD --
SELECT  
    zm.Restaurant_Name,  
    zm.City,  
    zc.Country_Name,  
    zm.Average_Cost_for_2,  
    zm.Currency,  -- Specify zm.Currency  
    (zm.Average_Cost_for_2 * zcr.USD_Rate) AS Average_Cost_For_2_USD  
FROM zomatomain zm 
LEFT JOIN zomatocountry zc ON zm.Country_ID = zc.Country_ID  
LEFT JOIN zomatocurrency zcr ON zm.Currency = zcr.Currency;

-- Count of Restaurants by City and Country --
SELECT City, Country_Name, COUNT(*) AS Total_Restaurants
FROM zomatomain zm
LEFT JOIN zomatocountry zc ON zm.Country_ID = zc.Country_ID
GROUP BY City, Country_Name
ORDER BY Total_Restaurants DESC;

-- Concat opening columns to get date--
ALTER TABLE zomatomain ADD COLUMN Opening_Date DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE zomatomain
SET Opening_Date = STR_TO_DATE(
    CONCAT(YearOpening, '-', MonthOpening, '-', DayOpening),
    '%Y-%m-%d'
);

-- Count of Restaurants by Year, Quarter, and Month --

SELECT 
    YEAR(Opening_Date) AS Year, 
    QUARTER(Opening_Date) AS Quarter, 
    MONTH(Opening_Date) AS Month, 
    COUNT(*) AS Total_Restaurants
FROM zomatomain
GROUP BY Year, Quarter, Month
ORDER BY Year, Quarter, Month;

-- Count of Restaurants Based on Average Ratings --
SELECT 
    Rating, 
    COUNT(*) AS Total_Restaurants
FROM zomatomain
GROUP BY Rating
ORDER BY Rating DESC;


-- Categorizing Restaurants into Price Buckets --
SELECT 
    CASE 
        WHEN Average_Cost_for_2 < 10 THEN 'Low (<10 USD)'
        WHEN Average_Cost_for_2 BETWEEN 10 AND 50 THEN 'Medium (10-50 USD)'
        WHEN Average_Cost_for_2 BETWEEN 51 AND 100 THEN 'High (51-100 USD)'
        ELSE 'Luxury (>100 USD)'
    END AS Price_Bucket,
    COUNT(*) AS Total_Restaurants
FROM zomatomain zm
LEFT JOIN zomatocurrency zcr ON zm.Currency = zcr.Currency
GROUP BY Price_Bucket
ORDER BY Total_Restaurants DESC;

-- Percentage of Restaurants with Table Booking --
SELECT 
    Has_Table_booking, 
    COUNT(*) AS Total, 
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomatomain)) AS Percentage
FROM zomatomain
GROUP BY Has_Table_booking;


-- Percentage of Restaurants with Online Delivery --
SELECT 
    Has_Online_delivery, 
    COUNT(*) AS Total, 
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomatomain)) AS Percentage
FROM zomatomain
GROUP BY Has_Online_delivery;





-- create calendar--

CREATE TABLE Calendar (
    Opening_Date1 DATE PRIMARY KEY,
    Year INT,
    MonthNo INT,
    MonthFullName VARCHAR(20),
    Quarter VARCHAR(5),
    YearMonth VARCHAR(10),
    WeekdayNo INT,
    WeekdayName VARCHAR(10),
    FinancialMonth VARCHAR(5),
    FinancialQuarter VARCHAR(5)
);

SELECT YearOpening, MonthOpening, DayOpening, COUNT(*) 
FROM ZomatoMain 
GROUP BY YearOpening, MonthOpening, DayOpening 
HAVING COUNT(*) > 1;

ALTER TABLE Calendar DROP PRIMARY KEY, ADD UNIQUE (Opening_Date1);

INSERT INTO Calendar (Opening_Date1, Year, MonthNo, MonthFullName, Quarter, YearMonth, WeekdayNo, WeekdayName, FinancialMonth, FinancialQuarter)
SELECT DISTINCT  
    STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d') AS Opening_Date1,
    YearOpening AS Year,
    MonthOpening AS MonthNo,
    DATE_FORMAT(STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d'), '%M') AS MonthFullName,
    CONCAT('Q', QUARTER(STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d'))) AS Quarter,
    DATE_FORMAT(STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d'), '%Y-%b') AS YearMonth,
    DAYOFWEEK(STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d')) AS WeekdayNo,
    DAYNAME(STR_TO_DATE(CONCAT(YearOpening, '-', LPAD(MonthOpening, 2, '0'), '-', LPAD(DayOpening, 2, '0')), '%Y-%m-%d')) AS WeekdayName,
    CASE  
        WHEN MonthOpening = 4 THEN 'FM1'  
        WHEN MonthOpening = 5 THEN 'FM2'  
        WHEN MonthOpening = 6 THEN 'FM3'  
        WHEN MonthOpening = 7 THEN 'FM4'  
        WHEN MonthOpening = 8 THEN 'FM5'  
        WHEN MonthOpening = 9 THEN 'FM6'  
        WHEN MonthOpening = 10 THEN 'FM7'  
        WHEN MonthOpening = 11 THEN 'FM8'  
        WHEN MonthOpening = 12 THEN 'FM9'  
        WHEN MonthOpening = 1 THEN 'FM10'  
        WHEN MonthOpening = 2 THEN 'FM11'  
        WHEN MonthOpening = 3 THEN 'FM12'  
    END AS FinancialMonth,  
    CASE  
        WHEN MonthOpening BETWEEN 4 AND 6 THEN 'FQ1'  
        WHEN MonthOpening BETWEEN 7 AND 9 THEN 'FQ2'  
        WHEN MonthOpening BETWEEN 10 AND 12 THEN 'FQ3'  
        ELSE 'FQ4'  
    END AS FinancialQuarter  
FROM ZomatoMain;

select * from calendar;


