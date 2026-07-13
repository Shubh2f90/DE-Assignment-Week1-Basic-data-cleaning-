import os
import sqlite3
import pandas as pd

CLEAN_DIR = os.path.join("data", "cleaned")
DB_PATH = os.path.join("ecommerce.db")
SCHEMA_PATH = os.path.join("sql", "schema.sql")

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# run schema.sql to (re)create tables
with open(SCHEMA_PATH, "r") as f:
    schema_sql = f.read()
cur.executescript(schema_sql)
conn.commit()
print("schema created")

customers = pd.read_csv(os.path.join(CLEAN_DIR, "customers_clean.csv"))
products = pd.read_csv(os.path.join(CLEAN_DIR, "products_clean.csv"))
orders = pd.read_csv(os.path.join(CLEAN_DIR, "orders_clean.csv"))
order_items = pd.read_csv(os.path.join(CLEAN_DIR, "order_items_clean.csv"))

# order_items still has some rows pointing to order_ids not in orders (edge case testing needs this in raw,
# but for the actual db load we need clean FK so filtering here again just in case)
valid_orders = set(orders["order_id"])
order_items = order_items[order_items["order_id"].isin(valid_orders)]

customers.to_sql("customers", conn, if_exists="append", index=False)
products.to_sql("products", conn, if_exists="append", index=False)
orders.to_sql("orders", conn, if_exists="append", index=False)
order_items.to_sql("order_items", conn, if_exists="append", index=False)

conn.commit()

# quick verification - row counts
for table in ["customers", "products", "orders", "order_items"]:
    count = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    print(f"{table}: {count} rows loaded")

conn.close()
print("\ndone - db saved at", DB_PATH)