# Customer Retention & Churn Analysis  
### An End-to-End SQL-First Analytics Project

---

## 1. Introduction & Motivation

Customer churn is one of the most critical challenges for subscription-based businesses. While churn is often treated as a binary outcome, real-world churn analysis is far more nuanced. Customers may churn, re-subscribe, continue interacting with the product, or generate billing and support activity even after cancellation.

The goal of this project was not merely to calculate a churn rate, but to **build a realistic, lifecycle-aware analytics pipeline** that mirrors how churn analysis is performed in real data teams. The focus was on correctness, interpretability, and business relevance rather than purely academic metrics.

This project demonstrates how to:
- design a relational schema for subscription data
- validate data quality at scale
- engineer churn features responsibly using SQL
- handle edge cases such as post-churn behavior
- validate insights using Python-based exploratory analysis

---

## 2. Dataset Overview

The dataset used in this project was synthetically generated to reflect realistic SaaS behavior at scale.

### Dataset Size
- **25,000 customers**
- **390,000+ orders**
- **1.4M+ product events**
- **~50,000 support tickets**
- Multiple subscriptions per customer, including reactivations and cancellations

### Key Characteristics
- Customers can have multiple subscription lifecycles
- Subscriptions may overlap or restart
- Orders, events, and tickets may occur before, during, or after churn
- Data intentionally includes edge cases to surface analytical challenges

---

## 3. Schema Design & Data Generation

A normalized relational schema was designed with the following core tables:

- `customers`
- `subscriptions`
- `orders`
- `payments`
- `product_events`
- `support_tickets`

Python scripts were used to generate realistic distributions for:
- subscription tenure and churn timing
- order frequency and revenue
- engagement intensity
- support ticket volume around churn

The dataset size was chosen deliberately: large enough to expose performance and modeling issues, but still practical for local development.

---

## 4. Data Quality & Sanity Checks

Before any analysis, extensive data quality checks were performed to validate assumptions and uncover potential issues.

### Key Checks Performed
- Null and missing value checks
- Referential integrity across tables
- Orders occurring outside subscription windows
- Events and tickets occurring after churn
- Overlapping subscriptions for the same customer

### A Critical Discovery: Join Inflation
Initial checks suggested very high counts of anomalies (e.g., orders or events after churn). Further investigation revealed that these were caused by **naive joins comparing activity against all historical subscriptions** for a customer.

### Fix
All lifecycle checks were re-anchored to each customer’s **final churn date**, eliminating false positives and ensuring lifecycle consistency.

This step was crucial and mirrors a common real-world pitfall in churn analysis.

---

## 5. Revenue Leakage & Post-Churn Activity

After correcting the lifecycle logic:

- **~2% of orders** occurred after final churn
- These orders were treated as **revenue leakage candidates**, not data errors

Similarly:
- **9,093 support tickets** occurred after final churn
- **5,797 customers** continued product engagement after churn

Rather than deleting this data, post-churn activity was explicitly **flagged and preserved**.

### Rationale
- Churn does not imply immediate disengagement
- Post-churn activity may indicate billing disputes, delayed cancellations, or reactivation intent
- Removing this data would hide valuable business signals

---

## 6. Feature Engineering Strategy

A unified churn feature table was engineered with **one row per customer**, combining data from all source tables.

### Feature Categories

#### Lifecycle & Labels
- Final churn date
- Binary churn indicator

#### Engagement
- Events in last 30 days before churn
- Events in last 7 days before churn
- Post-churn engagement flag

#### Support Friction
- Tickets in last 30 days before churn
- Tickets in last 7 days before churn
- Post-churn ticket flag

#### Revenue & Orders
- Total orders
- Lifetime revenue
- Post-churn billing flag

#### Tenure
- Customer tenure in days
- Number of subscriptions

### Design Principles
- All features were anchored to **final churn** to prevent leakage
- Post-churn behavior was flagged, not used as predictive input
- NULL-safe logic ensured customers were not silently dropped

---

## 7. Churn Distribution & Baseline Metrics

### Overall Churn
- **54.44% of customers churned** over the observed lifecycle

This represents lifetime churn rather than monthly churn and is realistic for long-horizon subscription data. The dataset contains a healthy balance of churned and retained customers, making it suitable for analysis and modeling.

---

## 8. Engagement Patterns Before Churn

Churned customers exhibited clear engagement decay:

- **0.40 average product events** in the last 30 days before churn
- Even lower activity in the final 7 days

This confirms a well-established churn pattern:
> Customers typically disengage before they churn.

The results validated that the engagement features were correctly engineered and leakage-free.

---

## 9. Support Friction Near Churn

Despite declining engagement, churned customers continued to interact with support:

- **0.33 average support tickets** in the last 30 days before churn
- **0.08 tickets** in the final 7 days

This highlights an important insight:
> Churn is often accompanied by unresolved friction, not silence.

Support activity complements engagement decay as a churn signal.

---

## 10. Combined Signal: Engagement × Support

When engagement and support activity were analyzed together, a strong interaction effect emerged:

- Customers with **low engagement and recent support tickets** showed the **highest churn rates**
- This combined signal was more predictive than either metric alone

This pattern reflects real-world churn dynamics, where disengagement coupled with friction often precedes cancellation.

---

## 11. Tenure Effects

Tenure-based analysis revealed strong lifecycle effects:

- Near-total churn among very short-tenure customers
- Significantly lower churn among customers retained beyond 6 months

This underscores the importance of onboarding quality and early value realization.

---

## 12. Revenue vs Order Frequency

Revenue analysis surfaced a subtle but important insight:

- Churned customers placed **more orders on average**
- Retained customers generated **~19% higher lifetime revenue**

This indicates that:
> Order frequency does not equate to customer value.

Higher-value customers tend to remain subscribed longer, even with fewer transactions.

---

## 13. Post-Churn Engagement

Approximately **23% of customers** continued engaging with the product after churn.

By definition, these customers all churned, but their behavior suggests:
- reactivation attempts
- delayed churn enforcement
- or continued value perception

Post-churn engagement was treated as a **descriptive segmentation signal**, not a predictive feature.

---

## 14. Python-Based Validation (EDA)

To validate SQL-engineered features, the unified churn table was exported securely to Python and analyzed using Pandas and visualization libraries.

Exploratory analysis confirmed:
- engagement decay prior to churn
- persistence of support activity
- higher lifetime value among retained customers
- meaningful post-churn behavior

This step ensured that SQL logic translated into real behavioral patterns rather than artifacts.

---

## 15. Key Takeaways

- Churn is a process, not an instant event
- Engagement decay is a strong leading indicator
- Support friction amplifies churn risk
- Early lifecycle experiences matter disproportionately
- Revenue quality outweighs transaction quantity
- Post-churn behavior should be modeled, not discarded

---

## 16. Conclusion

This project demonstrates an end-to-end churn analytics workflow that prioritizes:
- correctness over convenience
- lifecycle-aware modeling
- explicit handling of edge cases
- business interpretation alongside technical rigor

By combining SQL-first feature engineering with Python-based validation, the analysis reflects how churn is handled in real analytics and data science teams.

---

## 17. Key Modeling Decisions & Rationale

Several intentional modeling decisions were made to ensure analytical correctness and business relevance:

- **Anchoring all features to final churn**  
  Customers may have multiple subscriptions over time. All churn labels, rolling windows, and lifecycle checks were explicitly anchored to each customer’s *final churn date* to avoid false positives and data leakage.

- **Flagging anomalies instead of deleting data**  
  Orders, events, and tickets occurring after churn were preserved and flagged rather than removed. This approach reflects real-world analytics practice, where unusual behavior often contains valuable signals.

- **Separating descriptive vs predictive features**  
  Post-churn engagement and billing activity were modeled as descriptive attributes to support segmentation and strategy, but were intentionally excluded from predictive churn inputs.

- **Favoring interpretability over complexity**  
  Feature engineering focused on transparent, business-interpretable metrics (e.g., events in last 30 days, tickets in last 7 days) rather than opaque transformations.

---

## 18. Lifecycle Edge Cases & How They Were Handled

Several lifecycle-related edge cases emerged during analysis:

- **Join inflation across historical subscriptions**  
  Initial sanity checks incorrectly flagged large volumes of post-churn activity. Investigation revealed this was caused by joining events and orders against *all* historical subscriptions.  
  **Fix:** Lifecycle checks were re-based on each customer’s final churn date.

- **Overlapping subscriptions**  
  Some customers exhibited overlapping subscription periods. Rather than treating these as errors, they were retained to reflect realistic billing or renewal behavior.

- **Post-churn activity**  
  Approximately **23% of customers** continued to engage with the product after churn, and **~9,000 support tickets** occurred post-churn. These were treated as legitimate behavioral signals rather than data quality issues.

Handling these edge cases explicitly prevented misleading conclusions and strengthened the validity of the analysis.

---

## 19. Implications for Retention Strategy

The insights from this analysis suggest several actionable retention strategies:

- **Early engagement interventions**  
  Churn is heavily front-loaded among short-tenure customers, indicating that onboarding and early value realization are critical.

- **Monitor engagement decay, not just inactivity**  
  Customers rarely churn abruptly. Declining engagement in the final 30 days provides an opportunity for proactive outreach.

- **Address support friction quickly**  
  Support activity remains present near churn. Customers experiencing friction while disengaging are at the highest churn risk.

- **Segment post-churn users for win-back efforts**  
  Post-churn engagement signals potential reactivation opportunities rather than lost customers.

- **Focus on value, not volume**  
  Retained customers generated **~19% higher lifetime revenue** despite placing fewer orders, suggesting retention strategies should prioritize high-value users.

---

## 20. What This Project Demonstrates

- Strong intermediate-to-advanced SQL skills
- Comfort working with large, relational datasets
- Ability to reason about lifecycle complexity
- Clear communication of business-relevant insights
- End-to-end ownership of an analytics problem

---

## 21. Final Reflection

This project demonstrates how churn analysis extends beyond simple metrics into lifecycle reasoning, anomaly interpretation, and business decision-making.

By combining SQL-first feature engineering with careful validation and narrative-driven analysis, the project reflects how real analytics teams approach retention problems in practice.





