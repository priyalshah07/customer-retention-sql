BATCH_SIZE = 5000

import random
import json
from datetime import datetime, timedelta

from db_connection import get_connection

random.seed(42)

# -------------------------------
# Configuration
# -------------------------------

EVENT_TYPES = (
    ["login"] * 30 +
    ["page_view"] * 30 +
    ["feature_use"] * 25 +
    ["export_data"] * 10 +
    ["settings_change"] * 5
)

FEATURES = ["dashboard", "reports", "analytics", "billing", "settings"]

POWER_USER_RATE = 0.20
END_DATE = datetime(2024, 12, 31)

# -------------------------------
# Helper Functions
# -------------------------------

def random_event_properties(event_type):
    return json.dumps({
        "feature": random.choice(FEATURES),
        "duration_sec": random.randint(5, 300),
        "success": True if event_type != "export_data" else random.random() > 0.1
    })


# -------------------------------
# Main Generator
# -------------------------------

def generate_product_events():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT customer_id, start_date, end_date, subscription_status
        FROM subscriptions
        ORDER BY customer_id
    """)
    subs = cursor.fetchall()

    insert_query = """
        INSERT INTO product_events
        (customer_id, event_timestamp, event_type, event_properties)
        VALUES (%s, %s, %s, %s)
    """
import random
import json
from datetime import datetime, timedelta

from db_connection import get_connection

# -------------------------------
# Configuration
# -------------------------------

random.seed(42)

BATCH_SIZE = 5000

EVENT_TYPES = (
    ["login"] * 30 +
    ["page_view"] * 30 +
    ["feature_use"] * 25 +
    ["export_data"] * 10 +
    ["settings_change"] * 5
)

FEATURES = ["dashboard", "reports", "analytics", "billing", "settings"]

POWER_USER_RATE = 0.20
END_DATE = datetime(2024, 12, 31)

# -------------------------------
# Helper Functions
# -------------------------------

def random_event_properties(event_type):
    return json.dumps({
        "feature": random.choice(FEATURES),
        "duration_sec": random.randint(5, 300),
        "success": True if event_type != "export_data" else random.random() > 0.1
    })

# -------------------------------
# Main Generator
# -------------------------------

def generate_product_events():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT customer_id, start_date, end_date, subscription_status
        FROM subscriptions
        ORDER BY customer_id
    """)
    subs = cursor.fetchall()

    insert_query = """
        INSERT INTO product_events
        (customer_id, event_timestamp, event_type, event_properties)
        VALUES (%s, %s, %s, %s)
    """

    batch = []

    for sub in subs:
        customer_id = sub["customer_id"]
        start = datetime.combine(sub["start_date"], datetime.min.time())

        if sub["end_date"]:
            end = datetime.combine(sub["end_date"], datetime.min.time())
        else:
            end = END_DATE

        is_power_user = random.random() < POWER_USER_RATE
        total_days = max((end - start).days, 1)

        current = start

        while current <= end:
            days_remaining = max((end - current).days, 1)

            base_events = 3 if is_power_user else 1
            daily_events = max(
                0,
                int(base_events * (days_remaining / total_days))
            )

            for _ in range(daily_events):
                event_type = random.choice(EVENT_TYPES)

                event_time = current + timedelta(
                    hours=random.randint(0, 23),
                    minutes=random.randint(0, 59)
                )

                batch.append((
                    customer_id,
                    event_time,
                    event_type,
                    random_event_properties(event_type)
                ))

            current += timedelta(days=random.randint(1, 3))

    # -------------------------------
    # Chunked Inserts (CRITICAL FIX)
    # -------------------------------

    for i in range(0, len(batch), BATCH_SIZE):
        chunk = batch[i:i + BATCH_SIZE]
        cursor.executemany(insert_query, chunk)
        conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {len(batch)} product events successfully.")

# -------------------------------
# Run
# -------------------------------

if __name__ == "__main__":
    generate_product_events()

