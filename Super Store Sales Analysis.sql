-- Create Databse

CREATE DATABASE superstore;
USE superstore;

-- Create the Table

CREATE TABLE orders (
  order_id VARCHAR(20),
  order_date DATE,
  ship_date DATE,
  ship_mode VARCHAR(50),
  customer_id VARCHAR(20),
  customer_name VARCHAR(100),
  segment VARCHAR(50),
  country VARCHAR(50),
  city VARCHAR(50),
  state VARCHAR(50),
  postal_code VARCHAR(20),
  region VARCHAR(50),
  product_id VARCHAR(20),
  category VARCHAR(50),
  sub_category VARCHAR(50),
  product_name VARCHAR(200),
  sales DECIMAL(10,5),
  quantity INT,
  discount DECIMAL(4,5),
  profit DECIMAL(10,5)
);

CREATE TABLE returns (
  return_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(20),
  status VARCHAR(50)
);

SELECT * FROM orders LIMIT 10;

-- Sales & Profitability Analysis

SELECT 
  category,
  sub_category,
  region,
  ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin,
  RANK() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS sales_rank
FROM orders
GROUP BY category, sub_category, region;

-- Customer Segmentation with RFM Analysis
-- Segment customers based on Recency, Frequency, and Monetary value.

WITH rfm AS (
  SELECT 
    customer_id,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS recency,
    COUNT(order_id) AS frequency,
    SUM(sales) AS monetary
  FROM orders
  GROUP BY customer_id
)
SELECT *,
  NTILE(4) OVER (ORDER BY recency DESC) AS recency_score,
  NTILE(4) OVER (ORDER BY frequency) AS frequency_score,
  NTILE(4) OVER (ORDER BY monetary) AS monetary_score
FROM rfm;

-- Shipping & Fulfillment Performance
-- Measure delivery delays and their impact on customer satisfaction.

SELECT 
  order_id,
  DATEDIFF(ship_date, order_date) AS delivery_days,
  CASE 
    WHEN DATEDIFF(ship_date, order_date) > 5 THEN 'Delayed'
    ELSE 'On Time'
  END AS delivery_status
FROM orders;


-- Discount Optimization Analysis
-- Evaluate whether discounts increase sales or just reduce profit.

SELECT 
  discount,
  ROUND(AVG(sales), 2) AS avg_sales,
  ROUND(AVG(profit), 2) AS avg_profit
FROM orders
GROUP BY discount
ORDER BY discount;

-- Sales Forecasting (Moving Average)
-- Forecast next 3 months’ sales using SQL logic.

WITH monthly_sales AS (
  SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(sales) AS total_sales
  FROM orders
  GROUP BY month
)
SELECT 
  month,
  total_sales,
  ROUND(AVG(total_sales) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS forecast_sales
FROM monthly_sales;

-- Returns & Loss Analysis
-- Identify products or categories with high return rates.
SELECT 
  o.product_id,
  COUNT(r.return_id) AS return_count,
  COUNT(o.order_id) AS total_orders,
  ROUND(COUNT(r.return_id) / COUNT(o.order_id) * 100, 2) AS return_rate
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY o.product_id
HAVING return_rate > 10;

-- Geographic Performance Analysis
-- Spot regional trends and outliers.

SELECT 
  region, state,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit
FROM orders
GROUP BY region, state
ORDER BY total_profit ASC;

-- BI Integration

CREATE VIEW sales_summary AS
SELECT region, category, sub_category,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit
FROM orders
GROUP BY region, category, sub_category;