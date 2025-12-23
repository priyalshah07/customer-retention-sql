import random
from datetime import timedelta

from db_connection import get_connection

random.seed(42)

# -------------------------------
# Configuration
# -------------------------------

PAYMENT_METHODS = (
    ["card"] * 70 +
    ["paypal"] * 20 +
    ["other"] * 10
)

INITIAL_FAILURE_RATE = 0.08
RETRY_SUCCESS_RATE = 0.70

# -------------------------------
# Main Generator
# -------------------------------

def generate_payments():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT order_id, order_date, order_amount, order_status
        FROM orders
        ORDER BY order_id
    """)
    orders = cursor.fetchall()

    insert_query = """
        INSERT INTO payments
        (order_id, payment_date, payment_amount, payment_method, payment_status)
        VALUES (%s, %s, %s, %s, %s)
    """

    batch = []

    for order in orders:
        order_id = order["order_id"]
        order_date = order["order_date"]
        amount = order["order_amount"]

        payment_method = random.choice(PAYMENT_METHODS)

        # First attempt
        if random.random() < INITIAL_FAILURE_RATE:
            # Failed payment
            batch.append((
                order_id,
                order_date,
                amount,
                payment_method,
                "failed"
            ))

            # Retry attempt
            retry_date = order_date + timedelta(days=random.randint(1, 3))
            retry_status = "success" if random.random() < RETRY_SUCCESS_RATE else "failed"

            batch.append((
                order_id,
                retry_date,
                amount,
                payment_method,
                retry_status
            ))
        else:
            # Successful payment
            batch.append((
                order_id,
                order_date,
                amount,
                payment_method,
                "success"
            ))

    cursor.executemany(insert_query, batch)
    conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {len(batch)} payments successfully.")


if __name__ == "__main__":
    generate_payments()

