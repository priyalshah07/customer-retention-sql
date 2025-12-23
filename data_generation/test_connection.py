from db_connection import get_connection

conn = get_connection()
cursor = conn.cursor()

cursor.execute("SHOW TABLES;")
tables = cursor.fetchall()

print("Tables in database:")
for table in tables:
    print(table[0])

cursor.close()
conn.close()

