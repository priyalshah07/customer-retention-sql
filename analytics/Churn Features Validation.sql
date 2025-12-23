-- Churn Feature Table Validation Queries

SELECT COUNT(*) FROM analytics_unified_churn_features; # should be equal to total number of customers

# Churn Rate sanity check
SELECT
    is_churned,
    COUNT(*) AS customers
FROM analytics_unified_churn_features
GROUP BY is_churned;                       # 13,611 churned (out of total 25000 customers)

# Feature sanity check
SELECT
    AVG(events_last_30d_pre_churn) AS avg_events_30d,
    AVG(tickets_last_30d_pre_churn) AS avg_tickets_30d
FROM analytics_unified_churn_features
WHERE is_churned = 1;

