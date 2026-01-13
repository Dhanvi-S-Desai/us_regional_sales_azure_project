--Order frequency by product
SELECT TOP 20
  ProductID,
  COUNT(DISTINCT OrderNumber) AS order_count,
  SUM(OrderQuantity) AS units_ordered
FROM analytics.sales_clean
GROUP BY ProductID
ORDER BY order_count DESC;

###############################

--Demand volatility
--High CV = unpredictable demand

WITH monthly AS (
  SELECT
    ProductID,
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS month_start,
    SUM(OrderQuantity) AS monthly_qty
  FROM analytics.sales_clean
  WHERE OrderDate IS NOT NULL
  GROUP BY ProductID, DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
),
stats AS (
  SELECT
    ProductID,
    AVG(CAST(monthly_qty AS float)) AS avg_monthly_qty,
    STDEV(CAST(monthly_qty AS float)) AS sd_monthly_qty
  FROM monthly
  GROUP BY ProductID
)
SELECT TOP 20
  ProductID,
  avg_monthly_qty,
  sd_monthly_qty,
  CASE WHEN avg_monthly_qty = 0 THEN NULL ELSE sd_monthly_qty / avg_monthly_qty END AS demand_volatility_cv
FROM stats
ORDER BY demand_volatility_cv DESC;

###############################

--Frequent small orders vs bulk orders

SELECT TOP 50
  ProductID,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN OrderQuantity <= 5 THEN 1 ELSE 0 END) AS small_orders,
  SUM(CASE WHEN OrderQuantity >= 50 THEN 1 ELSE 0 END) AS bulk_orders,
  CAST(1.0 * SUM(CASE WHEN OrderQuantity <= 5 THEN 1 ELSE 0 END) / COUNT(*) AS decimal(6,4)) AS small_order_rate
FROM analytics.sales_clean
GROUP BY ProductID
HAVING COUNT(*) >= 10
ORDER BY small_order_rate DESC;


