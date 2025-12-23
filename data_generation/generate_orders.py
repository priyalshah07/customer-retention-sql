import random
from datetime import datetime, timedelta

from db_connection import get_connection

random.seed(42)

# -------------------------------
# Pricing Rules
# -------------------------------

PRICE_RANGES = {
    "basic": (15, 20),
    "pro": (35, 50),
    "premium": (80, 120)
}

REFUND_RATE = 0.05

END_DATE = datetime(2024, 12, 31)

# -------------------------------
# Helper Functions
# -------------------------------

def monthly_price(plan):
    low, high = PRICE_RANGES[plan]
    return round(random.uniform(low, high), 2)


# -------------------------------
# Main Generator
# -------------------------------

def generate_orders():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT subscription_id, customer_id, plan_type, billing_cycle,
               start_date, end_date, subscription_status
        FROM subscriptions
        ORDER BY subscription_id
    """)
    subscriptions = cursor.fetchall()

    insert_query = """
        INSERT INTO orders
        (customer_id, order_date, order_amount, currency, order_status)
        VALUES (%s, %s, %s, %s, %s)
    """

    batch = []

    for sub in subscriptions:
        customer_id = sub["customer_id"]
        plan = sub["plan_type"]
        billing = sub["billing_cycle"]

        start = datetime.combine(sub["start_date"], datetime.min.time())
        end = (
            datetime.combine(sub["end_date"], datetime.min.time())
            if sub["end_date"] else END_DATE
        )

        price = monthly_price(plan)

        current_date = start

        while current_date <= end:
            if billing == "monthly":
                amount = price
                current_date += timedelta(days=30)
            else:
                amount = price * 12
                current_date += timedelta(days=365)

            status = "refunded" if random.random() < REFUND_RATE else "completed"

            batch.append((
                customer_id,
                current_date.date(),
                round(amount, 2),
                "USD",
                status
            ))

    cursor.executemany(insert_query, batch)
    conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {len(batch)} orders successfully.")


if __name__ == "__main__":
    generate_orders()

