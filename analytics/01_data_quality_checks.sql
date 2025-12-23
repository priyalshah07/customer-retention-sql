-- Data Sanity Checks

-- Row counts

SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'product_events', COUNT(*) FROM product_events
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM support_tickets;

-- NULL checks (critical columns only)

# Customers
SELECT
  SUM(signup_date IS NULL) AS null_signup,
  SUM(country IS NULL) AS null_country
FROM customers;

# Subscriptions
SELECT
  SUM(start_date IS NULL) AS null_start,
  SUM(subscription_status IS NULL) AS null_status
FROM subscriptions;

# Orders
SELECT
  SUM(order_amount IS NULL) AS null_amount,
  SUM(order_date IS NULL) AS null_date
FROM orders;

# Payments
SELECT
  SUM(payment_amount IS NULL) AS null_amount,
  SUM(payment_status IS NULL) AS null_status
FROM payments;

# Product Events
SELECT
  SUM(event_type IS NULL) AS null_type,
  SUM(event_timestamp IS NULL) AS null_time
FROM product_events;

# Support Tickets
SELECT
  SUM(customer_id IS NULL) AS null_customer_id,
  SUM(created_at IS NULL) AS null_created_at,
  SUM(ticket_type IS NULL) AS null_ticket_type,
  SUM(ticket_status IS NULL) AS null_ticket_status,
  SUM(resolved_at IS NULL) AS null_resolved_at
FROM support_tickets;

SELECT COUNT(*) AS invalid_resolved_tickets
FROM support_tickets
WHERE ticket_status = 'resolved'
  AND resolved_at IS NULL;

SELECT COUNT(*) AS invalid_open_tickets
FROM support_tickets
WHERE ticket_status = 'open'
  AND resolved_at IS NOT NULL;
  





