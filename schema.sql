CREATE DATABASE IF NOT EXISTS customer_retention;
USE customer_retention;

CREATE TABLE customers(
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    signup_date DATE NOT NULL,
    country VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    acquisition_channel VARCHAR(50),
    device_type VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    plan_type VARCHAR(20) NOT NULL,
    billing_cycle VARCHAR(20) NOT NULL, -- monthly / annual
    start_date DATE NOT NULL,
    end_date DATE,
    subscription_status VARCHAR(20) NOT NULL, -- active / canceled / paused
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sub_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    order_status VARCHAR(20) NOT NULL, -- completed / refunded
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20), -- card / paypal / other
    payment_status VARCHAR(20) NOT NULL, -- success / failed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE product_events (
    event_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    event_timestamp DATETIME NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_properties JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_event_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    resolved_at DATETIME,
    ticket_type VARCHAR(50), -- billing / technical / account / feedback
    ticket_status VARCHAR(20) NOT NULL, -- open / resolved

    CONSTRAINT fk_ticket_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Indexes for Analytics & Performance

CREATE INDEX idx_customers_signup_date
    ON customers(signup_date);

CREATE INDEX idx_subscriptions_customer_start
    ON subscriptions(customer_id, start_date);

CREATE INDEX idx_orders_customer_date
    ON orders(customer_id, order_date);

CREATE INDEX idx_payments_order_date
    ON payments(order_id, payment_date);

CREATE INDEX idx_events_customer_time
    ON product_events(customer_id, event_timestamp);

CREATE INDEX idx_tickets_customer_created
    ON support_tickets(customer_id, created_at);