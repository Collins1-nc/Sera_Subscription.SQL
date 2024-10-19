# Sera_Subscription.sql

### Project Overview

This project provides a comprehensive analysis Payment Subscription of Sera, an international Software as a Service (SaaS) company.  Sera wants to use its data on subscription payments to better understand sales trends and customer retention over time using SQL and Power BI to design and transform database for analysis and a dashboard that answers key business questions respectively.

### Tools

PostgreSQL: Data cleaning, transformation, Pipelining, and preliminary analysis.

Power BI: Data modelling, visualization, and reporting.

### Data Sources

The dataset used for this project is an SQL format (schema file) that contains subscriptions data, transactions data, Dates data (from 2022 to 2023), Country data, among other data.

### Methodology

### Data Cleaning and Transformations in SQL

   I successfully executed the SQL schema file in PostgreSQL, verified the integrity of the data, and transformed the following:

-	STRING manipulation – Date
The transaction_date column is stored as text, so I transformed the column by separating it into its date and time components for easier analysis.

```sql
SELECT 
  transaction_date, 
  SUBSTRING (transaction_date, 1, 14) AS date 
FROM 
  sera.sales_txn 
LIMIT 
  10;
```

-- using the TRIM & TO_DATE Function

```sql
SELECT 
  transaction_date, 
  TO_DATE(
    TRIM(
      SUBSTRING(transaction_date, 1, 14)
    ), 
    'MON, DDth, YYY'
  ) AS date 
FROM 
  sera.sales_txn 
LIMIT 
  10;
```


-- applying the TIMESTAMP

```sql
SELECT 
  transaction_date, 
  TO_TIMESTAMP(
    transaction_date, 'MON, DDth, YYY, HH:MI:SS AM'
  ) AS datetime 
FROM 
  sera.sales_txn 
ORDER BY 
  datetime DESC 
LIMIT 
  10;
```


-- applying the TIMESTAMP using (REGEXP)

```sql
SELECT 
  transaction_date, 
  TO_TIMESTAMP(
    REGEXP_REPLACE(
      transaction_date, '^(\w{3})  (\d{1,2})\w*, (\d{4}) (\d{2}:\d{2}
:\d{2}).*$', 
      '\1 \2 \3, \4'
    ), 
    'Mon DDth YYY HH24:MI:SS'
  ) AS extracted_datetime 
FROM 
  sera.sales_txn 
ORDER BY 
  extracted_datetime DESC 
LIMIT 
  10;
```

-	STRING manipulation - Card Type
  
I transformed the card_type column used in these transactions. There are a number of payment processors involved including Mastercard, Visa, and Verve, however, these are subdivided into credit, debt, or debit-prepaid cards. 
I consolidated the values in this column so that we can better aggregate the data into the high-level payment processor types therefore creating an additional column and used the CASE WHEN approach to ensure that options like Mastercard debit and Mastercard credit only show up as ‘Mastercard’.

-- STRING manipulation - CARD TYPE

```sql
SELECT 
  DISTINCT card_type, 
  CASE WHEN card_type LIKE 'visa%' THEN 'visa' 
       WHEN card_type LIKE 'mastercard%' THEN 'mastercard'  
       WHEN card_type LIKE 'verve%' THEN 'verve' ELSE 'null' END AS card_type_group  
FROM 
  sera.sales_txn;
```

-	STRING manipulation - credit or debit
  
I created another column that extracts whether the card used was a credit or debit card.  Named the column credit_or_debit. 

-- STRING manipulation - CREDIT or DEBIT

```sql
SELECT 
  card_type, 
  CASE WHEN card_type LIKE '%debit%'  THEN 'debit' 
       WHEN card_type LIKE '%DEBIT%'  THEN 'debit' 
       WHEN card_type LIKE '%credit%' THEN 'credit' 
       WHEN card_type LIKE '%CREDIT%' THEN 'credit' ELSE 'null' END AS credit_or_debit 
FROM 
  sera.sales_txn; 
```

-	Combine all transformations into one
	
After I have transformed multiple different columns. I selected all the columns including the transformed columns that I needed for my actual analysis and stored them as a view in the database I created. 
 The entire code looks like this:

  ```sql 
           CREATE VIEW sera.sales AS (
  SELECT 
    reference, 
    TO_TIMESTAMP(
      transaction_date, 'MON, DDth, YYY, HH:MI:SS AM'
    ) AS datetime, 
    user_id, 
    amount, 
    gateway_response, 
    transaction_id, 
    card_type, 
    CASE WHEN card_type LIKE 'visa%' THEN 'visa' WHEN card_type LIKE 'mastercard%' THEN 'mastercard' WHEN card_type LIKE 'verve%' THEN 'verve' ELSE 'card_type' END AS card_type_group, 
    CASE WHEN card_type LIKE '%debit%' THEN 'debit' WHEN card_type LIKE '%DEBIT%' THEN 'debit' WHEN card_type LIKE '%credit%' THEN 'credit' WHEN card_type LIKE '%CREDIT%' THEN 'credit' ELSE 'debit_credit' END AS credit_or_debit, 
    card_bank, 
    country_code, 
    currency, 
    source, 
    status, 
    channel 
  FROM 
    sera.sales_txn
);
```

### Data Analysis in SQL

1. How many transactions occurred?

-- Answer Using Subquery

```sql
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
```


2. What is the period covered in the analysis? 

--- Calculating in years, months, days & time

```sql
SELECT 
  MIN(datetime) AS start_date, 
  MAX(datetime) AS end_date, 
  AGE(
    MAX(datetime), 
    MIN(datetime)
  ) AS Period_covered 
FROM 
  sera.sales_1;
```

--- Calculating in days & time

```sql
SELECT 
  MAX(datetime) - MIN(datetime) 
FROM 
  sera.sales_1;
```


3. Show the transaction count by status and percentage of total for each status

```sql
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
```

--- OR

```sql
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
```





 4a monthly subscription revenue in NGN split by channel

```sql
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
```


 4b Which month-year had the highest revenue?

```sql
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
```



4c What trend do you generally notice?

```sql
/* I noticed that most of the of the successful, failed, and abandoned transactions occurred via 
   card and the year 2023 were the highest.
*/
```


5a Show the total transactions by channel split by the transaction status

```sql
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
```


 5b Which channel has the highest rate of success?

```sql
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
```


5c Which has the highest rate of failure?

```sql
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
```


6. How many subscribers are there in total? (A subscriber is a user with a successful payment)

```sql
SELECT 
  COUNT (DISTINCT user_id) AS total_subscriber 
FROM 
  sera.sales_1 
WHERE 
  status = 'success';
```


 7 list of users showing their number of active months, total successful, abandoned and failed transactions

```sql
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
```

 8. Identify the users with more than 1 active month without a successful transaction

```sql	                      
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
```

### Data Analysis in Power BI

1.	The monthly trend of revenue, NGN, and USD.
2.	The monthly trend of subscribers.
3.	KPI card - current month revenue + monthly change in %.
4.	KPI card - current month subscribers + monthly change in %.
5.	Map: location of where users are attempting to pay from.
6.	Spread of successful payments by channel, card_type (credit or debit), and card_bank.
7.	Display and analysis of users by their count of active months and total transactions by status.

### Recommendations

- The total count of the Abandoned transactions is much higher compared to the Successful transactions which may be due to network failure and might discourage the subscribers. I recommend that Sera’s Customer Care Representatives should always reach out to the subscribers who have abandoned transactions and encourage them to try subscribing and render any other helping hands. 

- Most of the subscribers are from Nigeria while the least of the subscriber (1 subscriber) is from United Arab Emirates. This might be due to lack of proper advertisement of the company in that region or because the subscriber in that country had a FAILED transaction on his first attempt, this can bring about lack of interest to subscribe next time and also discourage potential subscribers in that country. I recommend that more advertisements should be centred more in the United Arab Emirates and other European countries that have small numbers of subscribers, also I recommend that Sera should increase their network coverage and strengthened their signal so that issues of failed or abandoned transactions will be reduced.  

- The current month revenue dropped by more than half when compared to the previous month revenue and this might be due to the subscribers having challenges to make a successful transaction for the current month. I will recommend that Sera should enhance their payment methods to ease successful transactions possibly by creating more application software. 




