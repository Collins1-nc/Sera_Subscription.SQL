-- STRING manipulation - CARD TYPE

SELECT 
  DISTINCT card_type, 
  CASE WHEN card_type LIKE 'visa%' THEN 'visa' 
       WHEN card_type LIKE 'mastercard%' THEN 'mastercard'  
       WHEN card_type LIKE 'verve%' THEN 'verve' ELSE 'null' END AS card_type_group  
FROM 
  sera.sales_txn;



-- STRING manipulation - CREDIT or DEBIT


SELECT 
  card_type, 
  CASE WHEN card_type LIKE '%debit%'  THEN 'debit' 
       WHEN card_type LIKE '%DEBIT%'  THEN 'debit' 
       WHEN card_type LIKE '%credit%' THEN 'credit' 
       WHEN card_type LIKE '%CREDIT%' THEN 'credit' ELSE 'null' END AS credit_or_debit 
FROM 
  sera.sales_txn;


