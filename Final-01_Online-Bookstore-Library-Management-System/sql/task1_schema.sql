-- =========================================================
-- TASK 1: Schema for Bronze / Silver / Gold layers
-- Database: PostgreSQL 18 (Neon)
-- =========================================================

-- Control table: tracks watermark per source table for incremental loads
CREATE TABLE pipeline_metadata (
    table_name VARCHAR(100) PRIMARY KEY,
    last_loaded_at TIMESTAMP NOT NULL DEFAULT '2000-01-01',
    rows_loaded INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'PENDING'
);

-- seed one row per bronze table, watermark starts far in the past
-- so the very first Bronze load pulls everything
INSERT INTO pipeline_metadata (table_name) VALUES
('bronze_books'), ('bronze_customers'), ('bronze_orders'),
('bronze_loans'), ('bronze_reviews');

-- =========================================================
-- BRONZE LAYER: exact copy of source, no constraints, keep duplicates/nulls as-is
-- =========================================================

CREATE TABLE bronze_books (
    book_id INT,
    title VARCHAR(255),
    author VARCHAR(255),
    genre VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    published_on DATE,
    ingested_at TIMESTAMP DEFAULT NOW(),
    batch_id VARCHAR(50)
);

CREATE TABLE bronze_customers (
    customer_id INT,
    name VARCHAR(255),
    email VARCHAR(255),
    city VARCHAR(100),
    joined_on DATE,
    membership VARCHAR(20),
    ingested_at TIMESTAMP DEFAULT NOW(),
    batch_id VARCHAR(50)
);

CREATE TABLE bronze_orders (
    order_id INT,
    customer_id INT,
    book_id INT,
    order_date DATE,
    quantity INT,
    status VARCHAR(20),
    ingested_at TIMESTAMP DEFAULT NOW(),
    batch_id VARCHAR(50)
);

CREATE TABLE bronze_loans (
    loan_id INT,
    customer_id INT,
    book_id INT,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    ingested_at TIMESTAMP DEFAULT NOW(),
    batch_id VARCHAR(50)
);

CREATE TABLE bronze_reviews (
    review_id INT,
    customer_id INT,
    book_id INT,
    rating INT,
    review_text TEXT,
    created_at TIMESTAMP,
    ingested_at TIMESTAMP DEFAULT NOW(),
    batch_id VARCHAR(50)
);

-- =========================================================
-- SILVER LAYER: cleaned, PK/FK enforced, derived columns added
-- =========================================================

CREATE TABLE silver_books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    genre VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    published_on DATE
);

CREATE TABLE silver_customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    city VARCHAR(100),
    joined_on DATE,
    membership VARCHAR(20)
);
CREATE INDEX idx_silver_customers_city ON silver_customers(city);

CREATE TABLE silver_orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES silver_customers(customer_id),
    book_id INT REFERENCES silver_books(book_id),
    order_date DATE,
    quantity INT,
    status VARCHAR(20),
    order_value DECIMAL(12,2)
);
CREATE INDEX idx_silver_orders_date ON silver_orders(order_date);
CREATE INDEX idx_silver_orders_customer ON silver_orders(customer_id);
CREATE INDEX idx_silver_orders_book ON silver_orders(book_id);

CREATE TABLE silver_loans (
    loan_id INT PRIMARY KEY,
    customer_id INT REFERENCES silver_customers(customer_id),
    book_id INT REFERENCES silver_books(book_id),
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    days_overdue INT,
    overdue_category VARCHAR(20)
);
CREATE INDEX idx_silver_loans_duedate ON silver_loans(due_date);

CREATE TABLE silver_reviews (
    review_id INT PRIMARY KEY,
    customer_id INT REFERENCES silver_customers(customer_id),
    book_id INT REFERENCES silver_books(book_id),
    rating INT,
    review_text TEXT,
    created_at TIMESTAMP
);
CREATE INDEX idx_silver_reviews_book ON silver_reviews(book_id);

-- audit table for rows that fail Silver quality checks
CREATE TABLE silver_rejected_rows (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    source_id VARCHAR(50),
    rejection_reason TEXT,
    rejected_at TIMESTAMP DEFAULT NOW()
);

-- =========================================================
-- GOLD LAYER: view stubs (real logic added in Task 4)
-- =========================================================

CREATE OR REPLACE VIEW gold_kpi_revenue_growth AS
SELECT NULL::numeric AS kpi_value, NULL::numeric AS kpi_target, NULL::text AS status, NULL::timestamp AS calculated_at LIMIT 0;

CREATE OR REPLACE VIEW gold_kpi_retention_rate AS
SELECT NULL::numeric AS kpi_value, NULL::numeric AS kpi_target, NULL::text AS status, NULL::timestamp AS calculated_at LIMIT 0;

CREATE OR REPLACE VIEW gold_kpi_sell_through AS
SELECT NULL::numeric AS kpi_value, NULL::numeric AS kpi_target, NULL::text AS status, NULL::timestamp AS calculated_at LIMIT 0;

CREATE OR REPLACE VIEW gold_kpi_return_compliance AS
SELECT NULL::numeric AS kpi_value, NULL::numeric AS kpi_target, NULL::text AS status, NULL::timestamp AS calculated_at LIMIT 0;

CREATE OR REPLACE VIEW gold_kpi_review_coverage AS
SELECT NULL::numeric AS kpi_value, NULL::numeric AS kpi_target, NULL::text AS status, NULL::timestamp AS calculated_at LIMIT 0;

CREATE OR REPLACE VIEW gold_top_books AS
SELECT NULL::int AS book_id, NULL::text AS title, NULL::text AS genre,
       NULL::numeric AS total_revenue, NULL::numeric AS avg_rating, NULL::int AS units_sold LIMIT 0;

CREATE OR REPLACE VIEW gold_customer_segments AS
SELECT NULL::int AS customer_id, NULL::numeric AS total_spend, NULL::text AS segment LIMIT 0;