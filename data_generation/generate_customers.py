import random
from datetime import datetime, timedelta

import mysql.connector
from faker import Faker

from db_connection import get_connection

fake = Faker()
Faker.seed(42)
random.seed(42)

TOTAL_CUSTOMERS = 25000

# -------------------------------
# Distribution Definitions
# -------------------------------

COUNTRIES = (
    ["United States"] * 75 +
    ["Canada"] * 10 +
    ["United Kingdom"] * 10 +
    ["Other"] * 5
)

ACQUISITION_CHANNELS = (
    ["organic"] * 35 +
    ["paid_search"] * 25 +
    ["referral"] * 20 +
    ["social"] * 10 +
    ["email"] * 10
)

DEVICE_TYPES = (
    ["web"] * 55 +
    ["mobile"] * 45
)

US_STATES = [
    "CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA",
    "NC", "MI", "NJ", "VA", "WA", "AZ", "MA"
]

START_DATE = datetime(2021, 1, 1)
END_DATE = datetime(2024, 12, 31)


# -------------------------------
# Helper Functions
# -------------------------------

def random_signup_date():
    delta_days = (END_DATE - START_DATE).days
    return START_DATE + timedelta(days=random.randint(0, delta_days))


# -------------------------------
# Main Generator
# -------------------------------

def generate_customers():
    conn = get_connection()
    cursor = conn.cursor()

    insert_query = """
        INSERT INTO customers
        (signup_date, country, state, acquisition_channel, device_type, is_active)
        VALUES (%s, %s, %s, %s, %s, %s)
    """

    batch = []

    for _ in range(TOTAL_CUSTOMERS):
        signup_date = random_signup_date()
        country = random.choice(COUNTRIES)

        state = random.choice(US_STATES) if country == "United States" else None

        acquisition_channel = random.choice(ACQUISITION_CHANNELS)
        device_type = random.choice(DEVICE_TYPES)

        is_active = True

        batch.append((
            signup_date.date(),
            country,
            state,
            acquisition_channel,
            device_type,
            is_active
        ))

    cursor.executemany(insert_query, batch)
    conn.commit()

    cursor.close()
    conn.close()

    print(f"Inserted {TOTAL_CUSTOMERS} customers successfully.")


if __name__ == "__main__":
    generate_customers()

