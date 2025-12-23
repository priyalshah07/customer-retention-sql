-- Time Consistency & Lifecycle Checks
# To check: Do events, subscriptions, orders, payments, and tickets follow a logically correct customer lifecycle over time?

-- Customer Lifecycle Baseline

# Customers should have signup dates in a valid range

SELECT
  MIN(signup_date) AS earliest_signup,
  MAX(signup_date) AS latest_signup
FROM customers;

-- Subscription Lifecycle Checks

# Subscriptions should not start before signup

SELECT COUNT(*) AS subs_before_signup
FROM subscriptions s
JOIN customers c
  ON s.customer_id = c.customer_id
WHERE s.start_date < c.signup_date;         # gives zero, so no issues there

# End date should not precede start date

SELECT COUNT(*) AS invalid_subscription_dates
FROM subscriptions
WHERE end_date IS NOT NULL
  AND end_date < start_date;

# Overlapping subscriptions for same customer (high-signal check)

SELECT COUNT(*) AS overlapping_subscriptions
FROM subscriptions s1
JOIN subscriptions s2
  ON s1.customer_id = s2.customer_id
 AND s1.subscription_id <> s2.subscription_id
 AND s1.start_date < COALESCE(s2.end_date, '9999-12-31')
 AND COALESCE(s1.end_date, '9999-12-31') > s2.start_date;          # gives zero, so no issues there

-- Orders vs Subscriptions

# Orders should occur after subscription start

SELECT COUNT(*) AS orders_before_subscription
FROM orders o
JOIN subscriptions s
  ON o.customer_id = s.customer_id
WHERE o.order_date < s.start_date;       # gives 116252 (high) -> investigate billing logic

# Orders after subscription cancellation

SELECT COUNT(*) AS orders_after_cancellation
FROM orders o
JOIN subscriptions s
  ON o.customer_id = s.customer_id
WHERE s.subscription_status = 'canceled'
  AND o.order_date > s.end_date;         # gives 131477 (high) -> leakage or modeling issue
  
## Maybe we asked the wrong questions above in thos section 
# Trying new VALID questions:

# Orders that do NOT fall into ANY subscription window (true anomaly)
SELECT COUNT(*) AS orders_outside_all_subscriptions
FROM orders o
WHERE NOT EXISTS (
  SELECT 1
  FROM subscriptions s
  WHERE s.customer_id = o.customer_id
    AND o.order_date >= s.start_date
    AND o.order_date <= COALESCE(s.end_date, '9999-12-31')
);
### Gives 15,102 orders (only 3.9% orders - acceptable)
### These likely represent:
#### Annual plans billed before recorded start date
#### Billing retries after brief gaps
#### Grace periods / free trials
#### Reactivation edge cases
#### Modeling simplifications (monthly = 30 days)
### These are lifecycle edge cases, not dirty data.

# Orders after FINAL cancellation (true leakage candidates)
WITH last_subscription AS (
  SELECT
    customer_id,
    MAX(COALESCE(end_date, '9999-12-31')) AS last_end_date
  FROM subscriptions
  GROUP BY customer_id
)
SELECT COUNT(*) AS orders_after_final_churn
FROM orders o
JOIN last_subscription ls
  ON o.customer_id = ls.customer_id
WHERE o.order_date > ls.last_end_date;

### 7,961 orders: these are true revenue leakage candidates.
### They likely indicate:
#### Failed cancellation enforcement
#### Billing retries after churn
#### Refund/reversal edge cases
#### Delayed churn recognition
#### Operational lag between systems

# Let's quanitfy this impact (cost-impact)

SELECT
  ROUND(SUM(o.order_amount), 2) AS revenue_after_final_churn
FROM orders o
JOIN (
  SELECT
    customer_id,
    MAX(COALESCE(end_date, '9999-12-31')) AS last_end_date
  FROM subscriptions
  GROUP BY customer_id
) ls
  ON o.customer_id = ls.customer_id
WHERE o.order_date > ls.last_end_date;  # There was $653,205.93 potential revenue leakage

# Let's segment those lakage orders by by plan & billing cycle (diagnostic)
SELECT
  s.plan_type,
  s.billing_cycle,
  COUNT(*) AS leakage_orders
FROM orders o
JOIN subscriptions s
  ON o.customer_id = s.customer_id
WHERE o.order_date > s.end_date
GROUP BY s.plan_type, s.billing_cycle
ORDER BY leakage_orders DESC;

# Flag them

### Step 1: Create a “last subscription” helper CTE (finds the final subscription end date per customer)
WITH last_subscription AS (
    SELECT
        customer_id,
        MAX(COALESCE(end_date, '9999-12-31')) AS last_end_date
    FROM subscriptions
    GROUP BY customer_id
)

### Step 2: Flag orders after FINAL churn
#### check out flag_after_Final_churn.sql for this

-- Payments vs Orders

# Payments should not precede orders

SELECT COUNT(*) AS payments_before_orders
FROM payments p
JOIN orders o
  ON p.order_id = o.order_id
WHERE p.payment_date < o.order_date;       # gives zero, so no issues there

# Multiple successful payments for same order

SELECT COUNT(*) AS duplicate_successful_payments
FROM (
  SELECT order_id
  FROM payments
  WHERE payment_status = 'success'
  GROUP BY order_id
  HAVING COUNT(*) > 1                        # gives zero, so no issues there
) t;

-- Product Events vs Customer Lifecycle

# Events after customer churn (allowed but meaningful)
## Interpretation: Small → re-engagement, Large → definition of churn needs refinement

SELECT COUNT(*) AS events_after_churn
FROM product_events e
JOIN subscriptions s
  ON e.customer_id = s.customer_id
WHERE s.subscription_status = 'canceled'
  AND e.event_timestamp > s.end_date;      # gives 416393 events
  
## Again, we asked the wrong question earlier

# Identify final churn per customer
WITH final_churn AS (
    SELECT
        customer_id,
        MAX(end_date) AS final_churn_date
    FROM subscriptions
    WHERE subscription_status = 'canceled'
    GROUP BY customer_id
)

# Count events truly after final churn
SELECT COUNT(*) AS events_after_final_churn
FROM product_events e
JOIN final_churn fc
  ON e.customer_id = fc.customer_id
WHERE e.event_timestamp > fc.final_churn_date;    # gives 233,229 events

## We make a analytics_events_VIEW (separate file)

  
-- Support Tickets vs Lifecycle

# Tickets before signup (never allowed)

SELECT COUNT(*) AS tickets_before_signup
FROM support_tickets t
JOIN customers c
  ON t.customer_id = c.customer_id
WHERE t.created_at < c.signup_date;          # gives zero, so no issues there


# Tickets after churn (very interesting signal) - Tickets compared only against final churn date
## Intepretation: High -> friction causing churn; strong feature for churn modeling
  
WITH final_churn AS (
    SELECT
        customer_id,
        MAX(end_date) AS final_churn_date
    FROM subscriptions
    WHERE subscription_status = 'canceled'
    GROUP BY customer_id
)
SELECT COUNT(*) AS tickets_after_final_churn
FROM support_tickets t
JOIN final_churn fc
  ON t.customer_id = fc.customer_id
WHERE t.created_at > fc.final_churn_date;  # 9,093 tickets after churn

## ~ 25–30% of churned customers contacting support after churn









