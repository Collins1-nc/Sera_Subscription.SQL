-- string manipulation = date

SELECT 
  transaction_date, 
  SUBSTRING (transaction_date, 1, 14) AS date 
FROM 
  sera.sales_txn 
LIMIT 
  10;

-- using the TRIM & TO_DATE Function

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


-- applying the TIMESTAMP

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


-- applying the TIMESTAMP using (REGEXP)

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

