SELECT *
FROM cleaned_shopease;

-- TOTAL REVENUE --
SELECT SUM(Total_Sales) AS total_revenue
FROM cleaned_shopease;

-- TOP SELLING PRODUCTS --
SELECT
    Product,
    SUM(Quantity) AS total_quantity_sold
FROM cleaned_shopease
GROUP BY Product
ORDER BY total_quantity_sold DESC;

-- REVENUE BY REGION --
SELECT
    Region,
    SUM(Total_Sales) AS revenue
FROM cleaned_shopease
GROUP BY Region
ORDER BY revenue DESC;

-- REVENUE BY CITY --
SELECT
    City,
    SUM(Total_Sales) AS revenue
FROM cleaned_shopease
GROUP BY City
ORDER BY revenue DESC;

-- MONTHLY SALES TREND --
SELECT
    MONTH(Order_Date) AS month_number,
    MONTHNAME(Order_Date) AS month_name,
    SUM(Total_Sales) AS monthly_revenue
FROM cleaned_shopease
GROUP BY MONTH(Order_Date), MONTHNAME(Order_Date)
ORDER BY month_number;

-- TOP CUSTOMERS --
SELECT Customer_Name, SUM(Total_Sales) AS total_spent
FROM cleaned_shopease
GROUP BY Customer_Name
ORDER BY total_spent DESC;

-- CUSTOMER SEGMENTION BASED ON TOTAL AMOUNT SPENT --
SELECT 
    Customer_Name,
    SUM(Total_Sales) AS total_spent,
    CASE 
        WHEN SUM(Total_Sales) > 5000000 THEN 'High Value'
        WHEN SUM(Total_Sales) BETWEEN 2000000 AND 5000000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM cleaned_shopease
GROUP BY Customer_Name;
