-- Relationship Integrity Checks

-- Customers ↔ Subscriptions

# Do all subscriptions belong to valid customers?

SELECT COUNT(*) AS orphan_subscriptions
FROM subscriptions s
LEFT JOIN customers c
  ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;             # gives zero, so no issue there

# Customers without subscriptions (this is allowed)

SELECT COUNT(*) AS customers_without_subscriptions
FROM customers c
LEFT JOIN subscriptions s
  ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL;


-- Customers ↔ Orders

# Does every order belong to a valid customer?

SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
  ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;                # gives zero, so no issue there

-- Orders ↔ Payments (CRITICAL)

# Does every payment map to a real order?

SELECT COUNT(*) AS orphan_payments
FROM payments p
LEFT JOIN orders o
  ON p.order_id = o.order_id
WHERE o.order_id IS NULL;                   # gives zero, so no issue there

# Orders without successful payments (revenue leakage candidates) (failed payment attempts or no payment yet or no payment at all)

SELECT COUNT(DISTINCT o.order_id) AS unpaid_orders
FROM orders o
LEFT JOIN payments p
  ON o.order_id = p.order_id
WHERE p.payment_status != 'success'
   OR p.order_id IS NULL;                 # 31471 unpaid orders, requires further investigation
   
   
-- Customers ↔ Product Events

# Do all events belong to valid customers?

SELECT COUNT(*) AS orphan_events
FROM product_events e
LEFT JOIN customers c
  ON e.customer_id = c.customer_id
WHERE c.customer_id IS NULL;               # gives zero, so no issue there


-- Customers ↔ Support Tickets

# Do all tickets belong to valid customers?

SELECT COUNT(*) AS orphan_tickets
FROM support_tickets t
LEFT JOIN customers c
  ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;               # gives zero, so no issue there


-- Time-Based Relationship Sanity (Very Important)

# Orders should not predate customer signup

SELECT COUNT(*) AS orders_before_signup
FROM orders o
JOIN customers c
  ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;        # gives zero, so no issue there

# Events should not predate signup

SELECT COUNT(*) AS events_before_signup
FROM product_events e
JOIN customers c
  ON e.customer_id = c.customer_id
WHERE e.event_timestamp < c.signup_date;     # gives zero, so no issue there




