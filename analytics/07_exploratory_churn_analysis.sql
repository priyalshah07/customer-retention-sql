-- Exploratory Churn Analysis

# Baseline - Churn Rate
SELECT is_churned,
COUNT(*) AS customers,
ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers
FROM analytics_unified_churn_features
GROUP BY is_churned;                                    # 54.44% churned

# Engagement vs Churn - Do churned users engage less before churn?
SELECT is_churned,
ROUND(AVG(events_last_30d_pre_churn), 2) AS avg_events_30d,
ROUND(AVG(events_last_7d_pre_churn), 2) AS avg_events_7d
FROM analytics_unified_churn_features
GROUP BY is_churned;

# Support Friction vs Churn - Do churned users contact support more before churn?
SELECT is_churned,
ROUND(AVG(tickets_last_30d_pre_churn), 2) AS avg_tickets_30d,
ROUND(AVG(tickets_last_7d_pre_churn), 2) AS avg_tickets_7d
FROM analytics_unified_churn_features
GROUP BY is_churned;

# Combined Signal: Low Engagement + Support Tickets -> What happens when users are disengaged and contacting support?
SELECT
    CASE
        WHEN events_last_30d_pre_churn <= 1 THEN 'Low Engagement'
        ELSE 'High Engagement'
    END AS engagement_bucket,
    CASE
        WHEN tickets_last_30d_pre_churn >= 1 THEN 'Has Tickets'
        ELSE 'No Tickets'
    END AS support_bucket,
    ROUND(AVG(is_churned), 3) AS churn_rate,
    COUNT(*) AS customers
FROM analytics_unified_churn_features
GROUP BY engagement_bucket, support_bucket
ORDER BY churn_rate DESC;                         # The highest churn rates occur when engagement is low and support tickets are present.

# Revenue vs Churn - Do churned customers generate less revenue?
SELECT
    is_churned,
    ROUND(AVG(total_revenue), 2) AS avg_lifetime_revenue,
    ROUND(AVG(total_orders), 2) AS avg_orders
FROM analytics_unified_churn_features
GROUP BY is_churned;

# Post-Churn Behavior (Re-engagement Signal) - Do users still interact after churn?
SELECT
    post_churn_engagement_flag,
    COUNT(*) AS customers,
    ROUND(AVG(is_churned), 2) AS churn_rate
FROM analytics_unified_churn_features
GROUP BY post_churn_engagement_flag;

# Tenure vs Churn - Are short-tenure users more likely to churn?
SELECT
    CASE
        WHEN tenure_days < 30 THEN '< 1 month'
        WHEN tenure_days < 90 THEN '1–3 months'
        WHEN tenure_days < 180 THEN '3–6 months'
        ELSE '6+ months'
    END AS tenure_bucket,
    ROUND(AVG(is_churned), 3) AS churn_rate,
    COUNT(*) AS customers
FROM analytics_unified_churn_features
GROUP BY tenure_bucket
ORDER BY churn_rate DESC;

# Revenue Leakage Signals - How common are post-churn orders?
SELECT
    post_churn_order_flag,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM analytics_unified_churn_features
GROUP BY post_churn_order_flag;




