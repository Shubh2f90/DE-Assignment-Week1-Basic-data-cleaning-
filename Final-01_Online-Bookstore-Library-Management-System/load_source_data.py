import psycopg2
import pandas as pd
from psycopg2.extras import execute_values


CONN_STR = "postgresql://neondb_owner:npg_v23EjFNHXzUZ@ep-still-morning-atgoy6du.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"

conn = psycopg2.connect(CONN_STR)
cur = conn.cursor()

# 1. Create source (OLTP) tables
cur.execute("""
DROP TABLE IF EXISTS orders, loans, reviews, customers, books CASCADE;

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    genre VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    published_on DATE
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    city VARCHAR(100),
    joined_on DATE,
    membership VARCHAR(20)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    order_date DATE,
    quantity INT,
    status VARCHAR(20)
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    loan_date DATE,
    due_date DATE,
    return_date DATE
);

CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    rating INT,
    review_text TEXT,
    created_at TIMESTAMP
);
""")
conn.commit()
print("Source tables created.")

# 2. Load CSVs
BASE = "dataset/cityreads_dataset"
for table, file in [
    ("books", "books.csv"), ("customers", "customers.csv"),
    ("orders", "orders.csv"), ("loans", "loans.csv"), ("reviews", "reviews.csv")
]:
    df = pd.read_csv(f"{BASE}/{file}")
    cols = ",".join(df.columns)
    placeholders = ",".join(["%s"] * len(df.columns))
    rows = [tuple(r) for r in df.where(pd.notnull(df), None).values]
    execute_values(cur, f"INSERT INTO {table} ({cols}) VALUES %s ON CONFLICT DO NOTHING", rows)
    conn.commit()
    print(f"{table}: {len(rows)} rows loaded")

cur.close()
conn.close()
print("Done.")