import pandas as pd
import mysql.connector
import os
from dotenv import load_dotenv

# Load env vars
load_dotenv()

conn = mysql.connector.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("MYSQL_PASSWORD"),
    database=os.getenv("MYSQL_DB")
)

query = "SELECT * FROM analytics_unified_churn_features"

df = pd.read_sql(query, conn)
conn.close()

# Save to notebooks folder
output_path = "notebooks/churn_features.csv"
df.to_csv(output_path, index=False)

print(f"Exported {len(df)} rows to {output_path}")

