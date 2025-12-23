# Customer Retention & Churn Analysis (SQL + Python)
## Project Overview

This project simulates a real-world __customer retention and churn analytics pipeline__ for a subscription-based SaaS product. Starting from raw transactional and behavioral data, I designed a relational schema, generated realistic data at scale, performed rigorous data quality checks, engineered analytics-ready features in SQL, and validated churn signals through Python-based exploratory analysis.

The goal was not just to “analyze churn,” but to build a defensible, __production-style analytics workflow__ that mirrors how churn analysis is done in practice.

## Dataset Summary

* 25,000 customers
* 390K+ orders
* 1.4M+ product events
* ~50K support tickets
* Multiple subscriptions per customer, including reactivations and cancellations

## Key Results (At a Glance)

* __54.44% lifetime churn rate__
* Churned customers show __~0.40 product events in the last 30 days__ before churn
* Support activity remains present near churn (__~0.33 tickets in last 30 days__)
* __23% of customers__ continue to engage even after churn
* Retained customers generate __~19% higher lifetime revenue__ on average

## Core Insights

* Churn is preceded by engagement decay, not silence
* __Low engagement + support friction__ is the strongest churn signal
* Early-tenure customers churn at significantly higher rates
* __Order frequency does not equal customer value__
* Post-churn behavior represents __win-back opportunities__, not data errors

## Tools & Technologies
- __MySQL__: schema design, feature engineering, window functions, lifecycle logic
- __Python (Pandas, Seaborn, Matplotlib)__: EDA and validation
- __dotenv + mysql-connector__: secure data extraction
- __SQL Views__: analytics-ready data modeling

## SQL Concepts & Techniques Used
This project demonstrates proficiency in intermediate to advanced SQL, including:
- __Joins & relationship modeling__ (inner/left joins across multi-table schemas)
- __Aggregations & grouping__ (COUNT, SUM, AVG, GROUP BY, HAVING)
- __Conditional logic (CASE WHEN)__ for churn labels and anomaly flags
- __Subqueries & CTEs__ for lifecycle-aware analysis and readability
- __Window functions__ (ROW_NUMBER, RANK, DENSE_RANK) for subscription sequencing
- __Date & time functions__ (DATEDIFF, DATE_SUB, COALESCE) for tenure and rolling windows
- __NULL handling__ & defensive SQL to preserve customers with incomplete data
- __Analytics views (CREATE VIEW)__ for modular, reusable feature engineering

These concepts were applied to solve real-world problems such as __churn labeling, engagement decay analysis, revenue leakage detection, and lifecycle-consistent feature engineering__.

## Project Structure

 ```text
customer-retention-sql/
│
├── analytics/
│   ├── 01_data_quality_checks.sql
│   ├── 02_relationship_integrity.sql
│   ├── 03_time_consistency_checks.sql
│   ├── 04_support_ticket_features.sql
│   ├── 05_product_engagement_features.sql
│   ├── 06_unified_churn_features.sql
│   └── 07_exploratory_churn_analysis.sql
│
├── data_generation/
│   ├── db_connection.py
│   ├── generate_customers.py
│   ├── generate_subscriptions.py
│   ├── generate_orders.py
│   ├── generate_payments.py
│   ├── generate_product_events.py
│   └── generate_support_tickets.py
│
├── notebooks/
│   └── churn_eda.ipynb
│
├── export_churn_features.py
├── schema.sql
├── .env
├── .gitignore
├── README.md
└── REPORT.md
```

## Why This Project Matters
This project demonstrates:
- __strong SQL fundamentals__ and analytical judgment
- ability to reason about lifecycle data and edge cases
- comfort moving from __database → Python → insight__
- business-oriented thinking, not just query writing
