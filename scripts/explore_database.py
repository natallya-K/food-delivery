import sqlite3
import pandas as pd

# Connect to the database
conn = sqlite3.connect('database/takeaway.db')

# List all tables
tables = pd.read_sql_query("SELECT name FROM sqlite_master WHERE type='table';", conn)
print("Tables in the database:")
print(tables)

# Explore each table structure
for table in tables['name']:
    print(f"\n--- {table} ---")
    info = pd.read_sql_query(f"PRAGMA table_info({table});", conn)
    print(info)
    
    # Show first few rows
    sample = pd.read_sql_query(f"SELECT * FROM {table} LIMIT 5;", conn)
    print(f"Sample data from {table}:")
    print(sample)

conn.close()