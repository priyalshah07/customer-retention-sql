-- Validating the features created

SELECT tickets_after_final_churn,
COUNT(*) AS customers
FROM analytics_support_ticket_features
GROUP BY tickets_after_final_churn
ORDER BY tickets_after_final_churn DESC;


SHOW FULL TABLES WHERE Table_type = 'VIEW';
