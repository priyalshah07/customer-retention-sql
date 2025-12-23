-- Creating Engagement Features View

DROP VIEW IF EXISTS analytics_product_engagement_features;

CREATE OR REPLACE VIEW analytics_product_engagement_features AS
WITH final_churn AS (
    SELECT
        customer_id,
        MAX(end_date) AS final_churn_date
    FROM subscriptions
    WHERE subscription_status = 'canceled'
    GROUP BY customer_id
)
SELECT
    c.customer_id,

    /* Total lifetime events */
    COUNT(e.event_id) AS total_events,

    /* Events in last 30 days BEFORE final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND e.event_timestamp BETWEEN DATE_SUB(fc.final_churn_date, INTERVAL 30 DAY)
                                        AND fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS events_last_30d_pre_churn,

    /* Events in last 7 days BEFORE final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND e.event_timestamp BETWEEN DATE_SUB(fc.final_churn_date, INTERVAL 7 DAY)
                                        AND fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS events_last_7d_pre_churn,

    /* Events AFTER final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND e.event_timestamp > fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS events_after_final_churn,

    /* Binary engagement flags */
    CASE
        WHEN COUNT(e.event_id) > 0 THEN 1 ELSE 0
    END AS ever_engaged_flag,

    CASE
        WHEN SUM(
            CASE
                WHEN fc.final_churn_date IS NOT NULL
                 AND e.event_timestamp > fc.final_churn_date
                THEN 1 ELSE 0
            END
        ) > 0
        THEN 1 ELSE 0
    END AS post_churn_engagement_flag,

    /* Days between churn and last event */
    DATEDIFF(
        MAX(
            CASE
                WHEN fc.final_churn_date IS NOT NULL
                 AND e.event_timestamp > fc.final_churn_date
                THEN e.event_timestamp
                ELSE NULL
            END
        ),
        fc.final_churn_date
    ) AS days_to_last_event_after_churn

FROM customers c
LEFT JOIN product_events e
    ON c.customer_id = e.customer_id
LEFT JOIN final_churn fc
    ON c.customer_id = fc.customer_id

GROUP BY c.customer_id, fc.final_churn_date;
