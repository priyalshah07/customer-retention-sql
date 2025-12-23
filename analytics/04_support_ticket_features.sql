-- Features to create:

# At the customer level:
### total_tickets
### tickets_last_30d_pre_churn
### tickets_last_7d_pre_churn
### tickets_after_final_churn
### has_post_churn_ticket_flag
### days_to_last_ticket_after_churn
## These are classic churn predictors.

# Goal: Transform raw support_tickets into customer-level churn features, without deleting anything.

# Define FINAL churn date per customer
CREATE OR REPLACE VIEW analytics_support_ticket_features AS
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

    /* Total lifetime support tickets */
    COUNT(t.ticket_id) AS total_tickets,

    /* Tickets in last 30 days BEFORE final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND t.created_at BETWEEN DATE_SUB(fc.final_churn_date, INTERVAL 30 DAY)
                                  AND fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS tickets_last_30d_pre_churn,

    /* Tickets in last 7 days BEFORE final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND t.created_at BETWEEN DATE_SUB(fc.final_churn_date, INTERVAL 7 DAY)
                                  AND fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS tickets_last_7d_pre_churn,

    /* Tickets AFTER final churn */
    SUM(
        CASE
            WHEN fc.final_churn_date IS NOT NULL
             AND t.created_at > fc.final_churn_date
            THEN 1 ELSE 0
        END
    ) AS tickets_after_final_churn,

    /* Binary flag: any ticket after churn */
    CASE
        WHEN SUM(
            CASE
                WHEN fc.final_churn_date IS NOT NULL
                 AND t.created_at > fc.final_churn_date
                THEN 1 ELSE 0
            END
        ) > 0
        THEN 1 ELSE 0
    END AS has_post_churn_ticket_flag,

    /* Days from churn to last ticket after churn */
    DATEDIFF(
        MAX(
            CASE
                WHEN fc.final_churn_date IS NOT NULL
                 AND t.created_at > fc.final_churn_date
                THEN t.created_at
                ELSE NULL
            END
        ),
        fc.final_churn_date
    ) AS days_to_last_ticket_after_churn

FROM customers c
LEFT JOIN support_tickets t
    ON c.customer_id = t.customer_id
LEFT JOIN final_churn fc
    ON c.customer_id = fc.customer_id

GROUP BY c.customer_id, fc.final_churn_date;



# Customers with post-churn tickets
SELECT
    has_post_churn_ticket_flag,
    COUNT(*) AS customers
FROM analytics_support_ticket_features;      #4,411 customers



