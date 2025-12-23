
DROP VIEW IF EXISTS analytics_unified_churn_features;

CREATE OR REPLACE VIEW analytics_unified_churn_features AS
WITH final_churn AS (
    SELECT
        customer_id,
        MAX(end_date) AS final_churn_date
    FROM subscriptions
    WHERE subscription_status = 'canceled'
    GROUP BY customer_id
),
subscription_features AS (
    SELECT
        customer_id,
        COUNT(*) AS num_subscriptions,
        MIN(start_date) AS first_subscription_date,
        MAX(COALESCE(end_date, '9999-12-31')) AS last_subscription_date
    FROM subscriptions
    GROUP BY customer_id
),
order_features AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_amount) AS total_revenue,
        MAX(post_churn_order_flag) AS post_churn_order_flag
    FROM analytics_orders
    GROUP BY customer_id
)
SELECT
    c.customer_id,

    /* Churn label */
    CASE
        WHEN fc.final_churn_date IS NOT NULL THEN 1
        ELSE 0
    END AS is_churned,

    fc.final_churn_date,

    /* Subscription features */
    sf.num_subscriptions,
    DATEDIFF(
        COALESCE(fc.final_churn_date, sf.last_subscription_date),
        sf.first_subscription_date
    ) AS tenure_days,

    /* Order features */
    COALESCE(ofe.total_orders, 0) AS total_orders,
    COALESCE(ofe.total_revenue, 0) AS total_revenue,
    COALESCE(ofe.post_churn_order_flag, 0) AS post_churn_order_flag,

    /* Support ticket features */
    COALESCE(stf.total_tickets, 0) AS total_tickets,
    COALESCE(stf.tickets_last_30d_pre_churn, 0) AS tickets_last_30d_pre_churn,
    COALESCE(stf.tickets_last_7d_pre_churn, 0) AS tickets_last_7d_pre_churn,
    COALESCE(stf.has_post_churn_ticket_flag, 0) AS has_post_churn_ticket_flag,

    /* Product engagement features */
    COALESCE(pef.total_events, 0) AS total_events,
    COALESCE(pef.events_last_30d_pre_churn, 0) AS events_last_30d_pre_churn,
    COALESCE(pef.events_last_7d_pre_churn, 0) AS events_last_7d_pre_churn,
    COALESCE(pef.post_churn_engagement_flag, 0) AS post_churn_engagement_flag

FROM customers c
LEFT JOIN final_churn fc
    ON c.customer_id = fc.customer_id
LEFT JOIN subscription_features sf
    ON c.customer_id = sf.customer_id
LEFT JOIN order_features ofe
    ON c.customer_id = ofe.customer_id
LEFT JOIN analytics_support_ticket_features stf
    ON c.customer_id = stf.customer_id
LEFT JOIN analytics_product_engagement_features pef
    ON c.customer_id = pef.customer_id;
