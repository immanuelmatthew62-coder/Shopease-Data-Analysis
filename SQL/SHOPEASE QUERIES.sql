-- CREATE STAGING TABLE --
CREATE TABLE `shopease_staging` (
  `Order_ID` text,
  `Order_Date` text,
  `Customer_Name` text,
  `Gender` text,
  `City` text,
  `Region` text,
  `Product` text,
  `Category` text,
  `Quantity` int DEFAULT NULL,
  `Unit_Price_NGN` text,
  `Payment_Method` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--  LOAD RAW DATA INTO STAGING TABLE --
INSERT shopease_staging
SELECT *
FROM shopease_raw_sales_data;

-- CHECK FOR DUPLICATES --
SELECT
    Order_ID,
    COUNT(*) AS duplicate_count
FROM shopease_staging
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- DELETE DUPLICATES --
DELETE r1
FROM shopease_staging r1
JOIN shopease_staging r2
ON r1.Order_ID = r2.Order_ID
AND r1.id > r2.id;

-- STANDARDIZE GENDER --
SELECT DISTINCT Gender
FROM shopease_staging;
UPDATE shopease_staging
SET Gender = CASE
    WHEN UPPER(Gender) IN ('M', 'MALE') THEN 'Male'
    WHEN UPPER(Gender) IN ('F', 'FEMALE') THEN 'Female'
    ELSE NULL
END;

-- STANDARDIZE CATEGORY NAMES --
SELECT DISTINCT Category
FROM shopease_staging;
UPDATE shopease_staging
SET Category = 'Home Appliance'
WHERE LOWER(Category) = 'home appliance';
UPDATE shopease_staging
SET Category = 'Electronics'
WHERE LOWER(Category) = 'electronics';
UPDATE shopease_staging
SET Category = TRIM(Category);

-- STANDARDIZE PRODUCT NAMES --
UPDATE shopease_staging
SET Product = CONCAT(
    UPPER(LEFT(Product,1)),
    LOWER(SUBSTRING(Product,2))
);

-- STANDARDIZE REGION VALUES --
SELECT DISTINCT Region
FROM shopease_staging;
UPDATE shopease_staging
SET Region = CASE
    WHEN UPPER(Region) = 'NORTH-WEST' THEN 'North-West'
    WHEN UPPER(Region) = 'NORTH CENTRAL' THEN 'North-Central'
    WHEN UPPER(Region) = 'SOUTH-WEST' THEN 'South-West'
    WHEN UPPER(Region) = 'SOUTH-SOUTH' THEN 'South-South'
    WHEN UPPER(Region) = 'SOUTH-EAST' THEN 'South-East'
	WHEN (Region) = 'south east' THEN 'South-East'
    WHEN (Region) = 'North West' THEN 'North-West'
    WHEN (Region) = 'south west' THEN 'South-west'
    WHEN (Region) = 'south south' THEN 'South-South'
    ELSE Region
END;

-- STANDARDIZE CITY NAMES --
SELECT DISTINCT City
FROM shopease_staging;
UPDATE shopease_staging
SET City = 'Port Harcourt'
WHERE LOWER(City) IN ('portharcourt', 'port harcourt');
UPDATE shopease_staging
SET City = CASE
    WHEN UPPER(City) = 'Enugi' THEN 'Enugu'
    WHEN UPPER(City) = 'Lagoss' THEN 'Lagos'
    ELSE City
END;
UPDATE shopease_staging
SET City = CONCAT(
    UPPER(LEFT(City,1)),
    LOWER(SUBSTRING(City,2))
);
UPDATE shopease_staging
SET City = TRIM(City);

-- FIX MISSING PAYMENT METHOD --
UPDATE shopease_staging
SET Payment_Method = 'Unknown'
WHERE Payment_Method IS NULL
OR Payment_Method = '';

-- HANDLE MISSING UNIT PRICE --
SELECT *
FROM shopease_staging
WHERE Unit_Price_NGN IS NULL
 OR Unit_Price_NGN = '';
 UPDATE shopease_staging  r
JOIN (
    SELECT Product, AVG(Unit_Price_NGN) AS avg_price
    FROM shopease_staging
    WHERE Unit_Price_NGN IS NOT NULL
    GROUP BY Product
) avg_table
ON r.Product = avg_table.Product
SET r.Unit_Price_NGN = avg_table.avg_price
WHERE r.Unit_Price_NGN IS NULL
 OR Unit_Price_NGN = '';
 UPDATE shopease_staging
SET Unit_Price_NGN = ROUND(Unit_Price_NGN, 0);
 
 -- STANDARDIZE PAYMENT METHOD --
  SELECT DISTINCT PAYMENT_METHOD
 FROM shopease_staging;
 
 -- STANDARDIZE DATE --
 ALTER TABLE shopease_staging
ADD Clean_Order_Date DATE;
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%Y-%m-%d')
WHERE Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%Y/%m/%d')
WHERE Order_Date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$';
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%d/%m/%Y')
WHERE Order_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
AND CAST(SUBSTRING_INDEX(Order_Date,'/',1) AS UNSIGNED) > 12;
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%m/%d/%Y')
WHERE Order_Date LIKE '%/%/%'
AND Clean_Order_Date IS NULL;
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%m-%d-%Y')
WHERE Order_Date LIKE '%-%-%'
AND Clean_Order_Date IS NULL;
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%M %d %Y')
WHERE Order_Date REGEXP '^[A-Za-z]+ [0-9]{1,2} [0-9]{4}$'
AND LENGTH(SUBSTRING_INDEX(Order_Date,' ',1)) > 3
AND Clean_Order_Date IS NULL;
UPDATE shopease_staging
SET Clean_Order_Date = STR_TO_DATE(Order_Date, '%b %d %Y')
WHERE Order_Date REGEXP '^[A-Za-z]{3} [0-9]{1,2} [0-9]{4}$'
AND Clean_Order_Date IS NULL;
SELECT Order_Date, Clean_Order_Date
FROM shopease_staging;

-- REMOVE LEADING AND TRAILING SPACES --
UPDATE shopease_staging
SET
    Customer_Name = TRIM(Customer_Name),
    City = TRIM(City),
    Region = TRIM(Region),
    Product = TRIM(Product),
    Category = TRIM(Category),
    Payment_Method = TRIM(Payment_Method);
    
-- STANDARDIZE PRODUCT CATEGORY --
SELECT *
FROM shopease_staging
WHERE Category IS NULL
OR Category = '';
UPDATE shopease_staging s1
JOIN shopease_staging s2
ON s1.Product = s2.Product
SET s1.Category = s2.Category
WHERE (s1.Category IS NULL OR s1.Category = '')
AND s2.Category IS NOT NULL;

-- DROP MESSY DATE COLUMN --
ALTER TABLE shopease_staging
DROP COLUMN Order_Date;
ALTER TABLE shopease_staging
CHANGE Clean_Order_Date Order_Date DATE;

-- STANDARDIZE QUANTITY --
SELECT *
FROM shopease_staging
WHERE quantity < 0;
UPDATE shopease_staging
SET quantity = ABS(quantity)
WHERE quantity < 0;

-- FIX NULL GENDERS --
UPDATE shopease_staging s1
JOIN shopease_staging s2
ON s1.customer_name = s2.customer_name
SET s1.gender = s2.gender
WHERE (s1.gender IS NULL OR s1.gender = '')
AND s2.gender IS NOT NULL;

-- CREATE TOTAL SALES COLUMN --
ALTER TABLE shopease_staging
ADD Total_Sales DECIMAL(14,2);
UPDATE shopease_staging
SET Total_Sales = Quantity * Unit_Price_NGN;

-- DROP ID COLUMN --
ALTER TABLE shopease_staging
DROP COLUMN id;

-- CREATE FINAL CLEAN TABLE --
CREATE TABLE cleaned_shopease AS
SELECT
    Order_ID,
    Order_Date,
    Customer_Name,
    Gender,
    City,
    Region,
    Product,
    Category,
    Quantity,
    Unit_Price_NGN,
    Total_Sales,
    Payment_Method
FROM shopease_staging;

SELECT *
FROM cleaned_shopease
ORDER BY Order_ID ASC;
