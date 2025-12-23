DROP VIEW IF EXISTS analytics_orders;

CREATE VIEW analytics_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_amount,
    o.currency,
    o.order_status,
    CASE
        WHEN o.order_date > ls.last_end_date THEN 1
        ELSE 0
    END AS post_churn_order_flag
FROM orders o
LEFT JOIN (
    SELECT
        customer_id,
        MAX(COALESCE(end_date, '9999-12-31')) AS last_end_date
    FROM subscriptions
    GROUP BY customer_id
) ls
    ON o.customer_id = ls.customer_id;
    
SHOW FULL TABLES WHERE Table_type = 'VIEW';

SELECT post_churn_order_flag, COUNT(*)
FROM analytics_orders
GROUP BY post_churn_order_flag;


