CREATE OR REPLACE VIEW analytics_product_events AS
SELECT
    e.*,
    CASE
        WHEN fc.final_churn_date IS NOT NULL
         AND e.event_timestamp > fc.final_churn_date
        THEN 1
        ELSE 0
    END AS post_churn_event_flag
FROM product_events e
LEFT JOIN (
    SELECT
        customer_id,
        MAX(end_date) AS final_churn_date
    FROM subscriptions
    WHERE subscription_status = 'canceled'
    GROUP BY customer_id
) fc
  ON e.customer_id = fc.customer_id;
