-- Some Data Analysis in SQL 

-- 1. How many transactions occurred?

-- Answer Using Subquery

SELECT 
  SUM(total_count) AS total_transactions 
FROM 
  (
    SELECT 
      status, 
      COUNT(status) total_count 
    FROM 
      sera.sales_1 
    GROUP BY 
      status
  ) total_transaction;

---  OR

SELECT 
  COUNT (*) 
FROM 
  sera.sales_1;

	 
-- Answer Using Rollup

SELECT 
  COALESCE (status, 'total') AS status, 
  COUNT (*) AS total_transactions 
FROM 
  sera.sales_1 
GROUP BY 
  ROLLUP (status) 
ORDER BY 
  status;


-- 2. What is the period covered in the analysis? 

--- Calculating in years, months, days & time

SELECT 
  MIN(datetime) AS start_date, 
  MAX(datetime) AS end_date, 
  AGE(
    MAX(datetime), 
    MIN(datetime)
  ) AS Period_covered 
FROM 
  sera.sales_1;

--- Calculating in days & time

SELECT 
  MAX(datetime) - MIN(datetime) 
FROM 
  sera.sales_1;


-- 3. Show the transaction count by status and percentage of total for each status

SELECT 
  SUM(
    CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END
  ) AS total_abandoned, 
  SUM(
    CASE WHEN status = 'failed' THEN 1 ELSE 0 END
  ) AS total_failed, 
  SUM(
    CASE WHEN status = 'success' THEN 1 ELSE 0 END
  ) AS total_success, 
  COUNT(status) AS total_rows, 
  ROUND(
    SUM(
      CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END
    ) * 100.0 / SUM(
      CASE WHEN status IN ('abandoned', 'failed', 'success') THEN 1 ELSE 0 END
    ), 
    2
  ) AS abandoned_percentage, 
  ROUND(
    SUM(
      CASE WHEN status = 'failed' THEN 1 ELSE 0 END
    ) * 100.0 / SUM(
      CASE WHEN status IN ('abandoned', 'failed', 'success') THEN 1 ELSE 0 END
    ), 
    2
  ) AS failed_percentage, 
  ROUND(
    SUM(
      CASE WHEN status = 'success' THEN 1 ELSE 0 END
    ) * 100.0 / SUM(
      CASE WHEN status IN ('abandoned', 'failed', 'success') THEN 1 ELSE 0 END
    ), 
    2
  ) AS success_percentage 
FROM 
  sera.sales_1;

--- OR

SELECT 
  *, 
  (
    total_abandoned * 100.0 / total_rows
  ) AS abandoned_percentage 
FROM 
  (
    SELECT 
      SUM(
        CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END
      ) AS total_abandoned, 
      SUM(
        CASE WHEN status = 'failed' THEN 1 ELSE 0 END
      ) AS total_failed, 
      SUM(
        CASE WHEN status = 'success' THEN 1 ELSE 0 END
      ) AS total_success, 
      COUNT(status) AS total_rows 
    FROM 
      sera.sales_1
  );



SELECT * 
FROM sera.sales_1;

SELECT currency, amount, status
FROM sera.sales_1
WHERE status = 'success' AND currency = 'USD';


-- 4a monthly subscription revenue in NGN split by channel

WITH monthly_revenue AS(
  SELECT 
    DATE_TRUNC('month', datetime) AS month_year, 
    channel, 
    ROUND(
      SUM(
        CASE WHEN currency = 'USD' THEN amount * 950 ELSE amount END
      ), 
      2
    ) AS monthly_revenue_by_channel 
  FROM 
    sera.sales_1 
  WHERE 
    status = 'success' 
  GROUP BY 
    month_year, 
    channel 
  ORDER BY 
    month_year DESC, 
    channel DESC
) 
SELECT 
  * 
FROM 
  monthly_revenue;


-- 4b Which month-year had the highest revenue?

WITH monthly_revenue AS (
  SELECT 
    TO_CHAR(datetime, 'mm - yyyy') AS month_year, 
    ROUND(
      SUM(
        CASE WHEN currency = 'USD' THEN amount * 950 ELSE amount END
      ), 
      2
    ) AS max_monthly_revenue 
  FROM 
    sera.sales_1 
  WHERE 
    status = 'success' 
  GROUP BY 
    month_year
), 
highest_revenue_month AS (
  SELECT 
    month_year, 
    max_monthly_revenue 
  FROM 
    monthly_revenue 
  ORDER BY 
    max_monthly_revenue DESC 
  LIMIT 
    1
) 
SELECT 
  * 
FROM 
  highest_revenue_month;



-- 4c What trend do you generally notice?


/* I noticed that most of the of the successful, failed, and abandoned transactions occurred via 
   card and the year 2023 was the highest.
*/


-- 5a Show the total transactions by channel split by the transaction status

SELECT 
  channel, 
  COUNT(status) AS total_txn, 
  SUM(
    CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END
  ) AS total_abandoned, 
  SUM(
    CASE WHEN status = 'failed' THEN 1 ELSE 0 END
  ) AS total_failed, 
  SUM(
    CASE WHEN status = 'success' THEN 1 ELSE 0 END
  ) AS total_successful 
FROM 
  sera.sales_1 
GROUP BY 
  channel;


-- 5b Which channel has the highest rate of success?

SELECT 
  channel, 
  SUM(
    CASE WHEN status = 'success' THEN 1 ELSE 0 END
  ) AS highest_success 
FROM 
  sera.sales_1 
WHERE 
  channel = 'card' 
GROUP BY 
  channel;


-- 5c Which has the highest rate of failure?

SELECT 
  channel, 
  SUM(
    CASE WHEN status = 'failed' THEN 1 ELSE 0 END
  ) AS highest_failed 
FROM 
  sera.sales_1 
WHERE 
  channel = 'card' 
GROUP BY 
  channel;


-- 6. How many subscribers are there in total? 

SELECT 
  COUNT (DISTINCT user_id) AS total_subscriber 
FROM 
  sera.sales_1 
WHERE 
  status = 'success';


-- 7 list of users showing their number of active months, total successful, abandoned and failed transactions

WITH monthly_txns AS (
  SELECT 
    DISTINCT user_id, 
    DATE_TRUNC('month', datetime) AS months, 
    status 
  FROM 
    sera.sales_1
), 
active_month AS (
  SELECT 
    user_id, 
    COUNT(DISTINCT months) AS active_months 
  FROM 
    monthly_txns 
  GROUP BY 
    user_id
), 
status_total AS (
  SELECT 
    user_id, 
    SUM (
      CASE WHEN status = 'success' THEN 1 ELSE 0 END
    ) AS successful_txns, 
    SUM (
      CASE WHEN status = 'abandoned' THEN 1 ELSE 0 END
    ) AS abandoned_txns, 
    SUM (
      CASE WHEN status = 'failed' THEN 1 ELSE 0 END
    ) AS failed_txns 
  FROM 
    sera.sales_1 
  GROUP BY 
    user_id
) 
SELECT 
  a.user_id, 
  a.active_months, 
  s.successful_txns, 
  s.abandoned_txns, 
  s.failed_txns 
FROM 
  active_month a 
  JOIN status_total s ON a.user_id = s.user_id 
ORDER BY 
  active_months DESC;



-- 8. Identify the users with more than 1 active month without a successful transaction
	                      
WITH monthly_txns AS (
  SELECT 
    DISTINCT user_id, 
    DATE_TRUNC('month', datetime) AS months 
  FROM 
    sera.sales_1 
  GROUP BY 
    user_id, 
    months
), 
active_month AS (
  SELECT 
    user_id, 
    COUNT(DISTINCT months) AS active_months 
  FROM 
    monthly_txns 
  GROUP BY 
    user_id
), 
users_without_successful_txns AS (
  SELECT 
    user_id 
  FROM 
    sera.sales_1 
  GROUP BY 
    user_id 
  HAVING 
    COUNT(
      CASE WHEN status = 'success' THEN 1 ELSE NULL END
    ) = 0
) 
SELECT 
  a.user_id, 
  a.active_months 
FROM 
  active_month a 
  JOIN users_without_successful_txns u ON a.user_id = u.user_id 
WHERE 
  a.active_months > 1;




