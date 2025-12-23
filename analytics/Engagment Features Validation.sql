-- Validating Engagement Features

# Engagement Distribution
SELECT
    ever_engaged_flag,
    COUNT(*) AS customers
FROM analytics_product_engagement_features
GROUP BY ever_engaged_flag;                   # 24,991 customers active; only 9 customers inactive (great!)

# Post-Churn Engagement
SELECT
    post_churn_engagement_flag,
    COUNT(*) AS customers
FROM analytics_product_engagement_features
GROUP BY post_churn_engagement_flag;          # 5797 active post-churn (meaningful minority)

# Activity intensity check
SELECT
    events_last_30d_pre_churn,
    COUNT(*) AS customers
FROM analytics_product_engagement_features
GROUP BY events_last_30d_pre_churn
ORDER BY events_last_30d_pre_churn DESC
LIMIT 10;


