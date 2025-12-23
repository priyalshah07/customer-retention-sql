import random
from datetime import datetime, timedelta, date

from db_connection import get_connection

# -------------------------------
# Configuration
# -------------------------------

random.seed(42)

BATCH_SIZE = 5000

TICKET_TYPES = (
    ["billing"] * 35 +
    ["technical"] * 40 +
    ["account"] * 15 +
    ["feedback"] * 10
)

RESOLUTION_PROBABILITY = 0.90
MAX_TICKETS_PER_CUSTOMER = 5

END_DATE = date(2024, 12, 31)

# -------------------------------
# Helper Functions
# -------------------------------

def to_date(value):
    """Convert MySQL DATE or string to datetime.date"""
    if value is None:
        return None
    if isinstance(value, date):
        return value
    return datetime.strptime(value, "%Y-%m-%d").date()

# -------------------------------
# Main Generator
# -------------------------------

def generate_support_tickets():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            c.customer_id,
            c.signup_date,
            MIN(s.start_date) AS first_start,
            MAX(COALESCE(s.end_date, %s)) AS last_end,
            MAX(CASE WHEN s.subscription_status = 'canceled' THEN 1 ELSE 0 END) AS churned
        FROM customers c
        LEFT JOIN subscriptions s
            ON c.customer_id = s.customer_id
        GROUP BY c.customer_id, c.signup_date
    """, (END_DATE,))

    customers = cursor.fetchall()

    insert_query = """
        INSERT INTO support_tickets
        (customer_id, created_at, resolved_at, ticket_type, ticket_status)
        VALUES (%s, %s, %s, %s, %s)
    """

    batch = []

    for row in customers:
        customer_id = row["customer_id"]

        signup_date = to_date(row["signup_date"])
        first_start = to_date(row["first_start"])
        last_end = to_date(row["last_end"])

        # Fallback logic (CRITICAL FIX)
        start_date = first_start if first_start else signup_date
        end_date = last_end if last_end else END_DATE

        start = datetime.combine(start_date, datetime.min.time())
        end = datetime.combine(end_date, datetime.min.time())

        churned = row["churned"] == 1

        ticket_count = random.randint(
            1 if churned else 0,
            MAX_TICKETS_PER_CUSTOMER if churned else 2
        )

        for _ in range(ticket_count):
            created_at = start + timedelta(
                days=random.randint(0, max((end - start).days, 1)),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )

            ticket_type = random.choice(TICKET_TYPES)

            if random.random() < RESOLUTION_PROBABILITY:
                resolved_at = created_at + timedelta(days=random.randint(1, 3))
                status = "resolved"
            else:
                resolved_at = None
                status = "open"

            batch.append((
                customer_id,
                created_at,
                resolved_at,
                ticket_type,
                status
            ))

    # -------------------------------
    # Chunked Inserts
    # -------------------------------

    for i in range(0, len(batch), BATCH_SIZE):
        chunk = batch[i:i + BATCH_SIZE]
        cursor.executemany(insert_query, chunk)
        conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {len(batch)} support tickets successfully.")

# -------------------------------
# Run
# -------------------------------

if __name__ == "__main__":
    generate_support_tickets()

