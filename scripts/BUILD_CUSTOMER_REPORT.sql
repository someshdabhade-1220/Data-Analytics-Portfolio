	/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================

CREATE VIEW GOLD.REPORT_CUSTOMER AS
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
WITH BASE_QUERY AS
(
SELECT 
CONCAT(C.FIRST_NAME,' ',C.LAST_NAME) AS CUSTOMERNAME,
C.BIRTHDATE,
C.CUSTOMER_KEY,
C.customer_number,
F.ORDER_NUMBER,
F.order_date,
F.SALES_AMOUNT,
F.PRODUCT_KEY,
F.quantity,
DATEDIFF(YEAR, C.BIRTHDATE, GETDATE()) AS AGE
FROM GOLD.fact_sales F
LEFT JOIN GOLD.dim_customers C
ON C.customer_key = F.customer_key
WHERE ORDER_DATE IS NOT NULL
)
, CUSTOMER_AGGREGATIONS AS
(
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
SELECT
CUSTOMER_KEY,
customer_number,
CUSTOMERNAME,
AGE,
COUNT(DISTINCT ORDER_NUMBER) AS TOTALORDERS,
SUM(SALES_AMOUNT) AS TOTALSALES,
SUM(QUANTITY) AS TOTALQUANTITY,
COUNT(DISTINCT PRODUCT_KEY) AS TOTALPRODUCTS,
MAX(ORDER_DATE) AS LAST_ORDER_DATE,
DATEDIFF(MONTH, MIN(ORDER_DATE), MAX(ORDER_DATE)) LIFESPAN
FROM BASE_QUERY
GROUP BY CUSTOMER_KEY,
customer_number,
CUSTOMERNAME,
AGE
)

SELECT 
CUSTOMER_KEY,
customer_number,
CUSTOMERNAME,
AGE,
CASE	
	WHEN AGE < 20 then 'UNDER 20'
	WHEN AGE BETWEEN 20 AND 29 THEN '20 - 29'
	WHEN AGE BETWEEN 30 AND 39 THEN '30 - 39'
	WHEN AGE BETWEEN 40 AND 49 THEN '40 - 49'
	ELSE '50 AND ABOVE'
END AS AGE_GROUP,
CASE 
    WHEN lifespan >= 12 AND totalsales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND totalsales <= 5000 THEN 'Regular'
    ELSE 'New'
END AS customer_segment,
LAST_ORDER_DATE,
DATEDIFF(MONTH, LAST_ORDER_DATE, GETDATE()) AS RECENCY,
TOTALORDERS,
TOTALSALES,
TOTALQUANTITY,
TOTALPRODUCTS,
LIFESPAN,
-- COMPUTE AVG ORDER VALUE
TOTALSALES / TOTALORDERS AS AVG_ORDER_VALUE,
-- COMPUTE AVG MONTHLY SPEND
CASE WHEN LIFESPAN = 0 THEN TOTALSALES
	ELSE TOTALSALES / LIFESPAN 
	END AVG_MONTHLY_SPEND
FROM CUSTOMER_AGGREGATIONS

