import random
from datetime import datetime, timedelta

from db_connection import get_connection

random.seed(42)

# -------------------------------
# Configuration
# -------------------------------

PLAN_DISTRIBUTION = (
    ["basic"] * 50 +
    ["pro"] * 35 +
    ["premium"] * 15
)

BILLING_CYCLES = (
    ["monthly"] * 80 +
    ["annual"] * 20
)

CHURN_PROBABILITY = {
    "basic": 0.07,
    "pro": 0.035,
    "premium": 0.015
}

MAX_SUBSCRIPTIONS_PER_CUSTOMER = 3

END_DATE = datetime(2024, 12, 31)

# -------------------------------
# Helper Functions
# -------------------------------

def months_between(start, end):
    return (end.year - start.year) * 12 + (end.month - start.month)


# -------------------------------
# Main Generator
# -------------------------------

def generate_subscriptions():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT customer_id, signup_date
        FROM customers
        ORDER BY customer_id
    """)
    customers = cursor.fetchall()

    insert_query = """
        INSERT INTO subscriptions
        (customer_id, plan_type, billing_cycle, start_date, end_date, subscription_status)
        VALUES (%s, %s, %s, %s, %s, %s)
    """

    batch = []

    for customer in customers:
        customer_id = customer["customer_id"]
        current_start = datetime.combine(customer["signup_date"], datetime.min.time())

        num_subs = random.randint(1, MAX_SUBSCRIPTIONS_PER_CUSTOMER)

        for i in range(num_subs):
            if current_start >= END_DATE:
                break

            plan = random.choice(PLAN_DISTRIBUTION)
            billing = random.choice(BILLING_CYCLES)

            churn_prob = CHURN_PROBABILITY[plan]

            if billing == "annual":
                churn_prob *= 0.5

            active_months = 1
            while random.random() > churn_prob and current_start + timedelta(days=30 * active_months) < END_DATE:
                active_months += 1

            end_date = current_start + timedelta(days=30 * active_months)

            status = "active" if end_date >= END_DATE else "canceled"

            batch.append((
                customer_id,
                plan,
                billing,
                current_start.date(),
                None if status == "active" else end_date.date(),
                status
            ))

            # Gap before possible re-subscription
            current_start = end_date + timedelta(days=random.randint(15, 90))

    cursor.executemany(insert_query, batch)
    conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {len(batch)} subscriptions successfully.")


if __name__ == "__main__":
    generate_subscriptions()

