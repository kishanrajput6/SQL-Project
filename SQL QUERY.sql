create database sales
use sales

--Inspecting Data--
SELECT * FROM sales_data_sample

--Checking Unique Values--
SELECT DISTINCT STATUS FROM sales_data_sample
SELECT DISTINCT YEAR_ID FROM sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample
SELECT DISTINCT COUNTRY FROM sales_data_sample
SELECT DISTINCT DEALSIZE FROM sales_data_sample
SELECT DISTINCT TERRITORY FROM sales_data_sample

--Analysis--
--Grouping SALES by PRODUCTLINE--
SELECT PRODUCTLINE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

--Grouping SALES by YEAR_ID--
SELECT YEAR_ID, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

--Grouping SALES by DEALSIZE--
SELECT DEALSIZE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

--What was the best month for sales in a specific year?--
--How much was earned that month?--
SELECT MONTH_ID, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2004 --Change year to see the rest--
GROUP BY MONTH_ID
ORDER BY 2 DESC

--November seems to be the month, What product do they sell in November,  
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --Change year to see the rest--
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC	

--Receny Frequency Monetary (RFM)--
--It is an indexing technique that uses past purchase behaviour to segment customers--
--Data Points used in RFM Analysis
--Recency			: Last Order Date--
--Frequency			: Count of Total Order--
--Monetary Value	: Total Spend --

--Who is the best customer--


--SELECT 
--	CUSTOMERNAME,
--	SUM(SALES) AS MONETARY_VALUE,
--	AVG(SALES) AS AVG_MONETARY_VALUE,
--	COUNT(ORDERNUMBER) AS FREQUENCY,
--	MAX(ORDERDATE) AS LAST_ORDER_DATE
--	FROM sales_data_sample
--GROUP BY CUSTOMERNAME	

--SELECT 
--	CUSTOMERNAME,
--	SUM(SALES) AS MONETARY_VALUE,
--	AVG(SALES) AS AVG_MONETARY_VALUE,
--	COUNT(ORDERNUMBER) AS FREQUENCY,
--	MAX(ORDERDATE) AS LAST_ORDER_DATE,
--  (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS MAX_ORDER_DATE
--	FROM sales_data_sample	--STEP2--
--GROUP BY CUSTOMERNAME

--;WITH RFM AS (
--SELECT 
--	CUSTOMERNAME,
--	SUM(SALES) AS MONETARY_VALUE,
--	AVG(SALES) AS AVG_MONETARY_VALUE,
--	COUNT(ORDERNUMBER) AS FREQUENCY,
--	MAX(ORDERDATE) AS LAST_ORDER_DATE,
--	(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS MAX_ORDER_DATE,
--	DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS RECENCY
--	FROM sales_data_sample
--GROUP BY CUSTOMERNAME
--)
--SELECT R. *,
--	NTILE(4) OVER (ORDER BY RECENCY DESC) AS RFM_RECENCY,
--	NTILE(4) OVER (ORDER BY FREQUENCY) AS RFM_FREQUENCY,
--	NTILE(4) OVER (ORDER BY AVG_MONETARY_VALUE) AS RFM_MONETARY
--FROM RFM AS R
--ORDER BY 4 DESC --STEP3--

DROP TABLE IF EXISTS #RFM
;WITH RFM AS (
SELECT 
	CUSTOMERNAME,
	SUM(SALES) AS MONETARY_VALUE,
	AVG(SALES) AS AVG_MONETARY_VALUE,
	COUNT(ORDERNUMBER) AS FREQUENCY,
	MAX(ORDERDATE) AS LAST_ORDER_DATE,
	(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS MAX_ORDER_DATE,
	DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS RECENCY
	FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
RFM_CALC AS
(
SELECT R. *,
	NTILE(4) OVER (ORDER BY RECENCY DESC) AS RFM_RECENCY,
	NTILE(4) OVER (ORDER BY FREQUENCY) AS RFM_FREQUENCY,
	NTILE(4) OVER (ORDER BY MONETARY_VALUE) AS RFM_MONETARY
FROM RFM AS R
)	
SELECT C. *, RFM_RECENCY + RFM_FREQUENCY AS RFM_CELL,
CAST (RFM_RECENCY AS VARCHAR) + CAST(RFM_FREQUENCY AS VARCHAR) + CAST(RFM_MONETARY AS VARCHAR) AS RFM_CELL_STRING
INTO #RFM
FROM RFM_CALC AS C	--STEP4--
 
--SELECT * FROM #RFM

SELECT CUSTOMERNAME, RFM_RECENCY, RFM_MONETARY, RFM_FREQUENCY,
	CASE
		WHEN RFM_CELL_STRING IN (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'LOST_CUSTOMERS'
		WHEN RFM_CELL_STRING IN (133, 134, 143, 244, 334, 343, 344) THEN 'SLEPPING_AWAY, CANNOT_LOSE'
		WHEN RFM_CELL_STRING IN (311, 411, 331) THEN 'NEW_CUSTOMERS'
		WHEN RFM_CELL_STRING IN (222, 223, 233, 322) THEN 'POTENTIAL_CHURNERS'
		WHEN RFM_CELL_STRING IN (323, 333, 321, 422, 332, 432) THEN 'ACTIVE' --Customer who buy often & recently, but at low price points
		WHEN RFM_CELL_STRING IN (433, 434, 443, 444) THEN 'LOYAL'
	END RFM_SEGMENT
	FROM #RFM

--What product are most often sold together?

--SELECT * FROM sales_data_sample WHERE ORDERNUMBER = 10411--

SELECT ORDERNUMBER, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM sales_data_sample AS P
	WHERE ORDERNUMBER IN 
		(

			SELECT ORDERNUMBER 
			FROM (
				SELECT ORDERNUMBER, COUNT(*) AS RN
				FROM sales_data_sample
				WHERE STATUS = 'SHIPPED'
				GROUP BY ORDERNUMBER
			) AS M
			WHERE RN = 3
		)
		AND P. ORDERNUMBER = S. ORDERNUMBER
		FOR XML PATH ('')),

		1, 1, '') AS PRODUCTCODES

FROM sales_data_sample AS S
ORDER BY 2 DESC
