-- =========================================================
-- TASK 3: Silver transform — dedup, validate, reject, enrich
-- Order matters: books & customers first (no FK deps),
-- then orders/loans/reviews (depend on silver_customers/silver_books existing)
-- =========================================================

-- ---------- BOOKS: dedup only, no mandatory checks defined for this table ----------
CREATE TEMP TABLE dedup_books AS
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY book_id ORDER BY ingested_at DESC) AS rn
    FROM bronze_books
    WHERE book_id IS NOT NULL
) t WHERE rn = 1;

INSERT INTO silver_books (book_id, title, author, genre, price, stock, published_on)
SELECT book_id, TRIM(title), TRIM(author), TRIM(genre), price, stock, published_on
FROM dedup_books
ON CONFLICT (book_id) DO NOTHING;

-- ---------- CUSTOMERS: dedup + check(email NOT NULL, membership valid) ----------
CREATE TEMP TABLE dedup_customers AS
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ingested_at DESC) AS rn
    FROM bronze_customers
    WHERE customer_id IS NOT NULL
) t WHERE rn = 1;

INSERT INTO silver_customers (customer_id, name, email, city, joined_on, membership)
SELECT customer_id, TRIM(name), TRIM(email), TRIM(city), joined_on, UPPER(TRIM(membership))
FROM dedup_customers
WHERE email IS NOT NULL
  AND UPPER(TRIM(membership)) IN ('BASIC','PREMIUM','LIBRARY')
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO silver_rejected_rows (table_name, source_id, rejection_reason)
SELECT 'bronze_customers', customer_id::text,
    CASE
        WHEN email IS NULL THEN 'email is null'
        ELSE 'invalid membership value'
    END
FROM dedup_customers
WHERE email IS NULL
   OR UPPER(TRIM(membership)) NOT IN ('BASIC','PREMIUM','LIBRARY');

-- ---------- ORDERS: dedup + check(quantity>0, status valid, FK valid) ----------
CREATE TEMP TABLE dedup_orders AS
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ingested_at DESC) AS rn
    FROM bronze_orders
    WHERE order_id IS NOT NULL
) t WHERE rn = 1;

INSERT INTO silver_orders (order_id, customer_id, book_id, order_date, quantity, status, order_value)
SELECT o.order_id, o.customer_id, o.book_id, o.order_date, o.quantity,
       UPPER(TRIM(o.status)), o.quantity * b.price
FROM dedup_orders o
JOIN silver_customers c ON c.customer_id = o.customer_id
JOIN silver_books b ON b.book_id = o.book_id
WHERE o.quantity > 0
  AND UPPER(TRIM(o.status)) IN ('PENDING','SHIPPED','DELIVERED','CANCELLED')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO silver_rejected_rows (table_name, source_id, rejection_reason)
SELECT 'bronze_orders', o.order_id::text,
    CASE
        WHEN o.quantity IS NULL OR o.quantity <= 0 THEN 'quantity not > 0'
        WHEN UPPER(TRIM(o.status)) NOT IN ('PENDING','SHIPPED','DELIVERED','CANCELLED') THEN 'invalid status value'
        WHEN NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = o.customer_id) THEN 'invalid customer_id FK'
        WHEN NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = o.book_id) THEN 'invalid book_id FK'
    END
FROM dedup_orders o
WHERE o.quantity IS NULL OR o.quantity <= 0
   OR UPPER(TRIM(o.status)) NOT IN ('PENDING','SHIPPED','DELIVERED','CANCELLED')
   OR NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = o.customer_id)
   OR NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = o.book_id);

-- ---------- LOANS: dedup + check(due_date > loan_date, FK valid) ----------
CREATE TEMP TABLE dedup_loans AS
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY loan_id ORDER BY ingested_at DESC) AS rn
    FROM bronze_loans
    WHERE loan_id IS NOT NULL
) t WHERE rn = 1;

INSERT INTO silver_loans (loan_id, customer_id, book_id, loan_date, due_date, return_date, days_overdue, overdue_category)
SELECT loan_id, customer_id, book_id, loan_date, due_date, return_date,
       days_overdue,
       CASE
           WHEN days_overdue = 0 THEN 'ON TIME'
           WHEN days_overdue <= 7 THEN 'MILD'
           WHEN days_overdue <= 30 THEN 'SEVERE'
           ELSE 'CRITICAL'
       END AS overdue_category
FROM (
    SELECT l.*,
        CASE
            WHEN l.return_date IS NULL AND CURRENT_DATE > l.due_date THEN (CURRENT_DATE - l.due_date)
            WHEN l.return_date > l.due_date THEN (l.return_date - l.due_date)
            ELSE 0
        END AS days_overdue
    FROM dedup_loans l
    JOIN silver_customers c ON c.customer_id = l.customer_id
    JOIN silver_books b ON b.book_id = l.book_id
    WHERE l.due_date > l.loan_date
) enriched
ON CONFLICT (loan_id) DO NOTHING;

INSERT INTO silver_rejected_rows (table_name, source_id, rejection_reason)
SELECT 'bronze_loans', l.loan_id::text,
    CASE
        WHEN l.due_date <= l.loan_date THEN 'due_date not after loan_date'
        WHEN NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = l.customer_id) THEN 'invalid customer_id FK'
        WHEN NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = l.book_id) THEN 'invalid book_id FK'
    END
FROM dedup_loans l
WHERE l.due_date <= l.loan_date
   OR NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = l.customer_id)
   OR NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = l.book_id);

-- ---------- REVIEWS: dedup + check(rating 1-5, FK valid) ----------
CREATE TEMP TABLE dedup_reviews AS
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY ingested_at DESC) AS rn
    FROM bronze_reviews
    WHERE review_id IS NOT NULL
) t WHERE rn = 1;

INSERT INTO silver_reviews (review_id, customer_id, book_id, rating, review_text, created_at)
SELECT r.review_id, r.customer_id, r.book_id, r.rating, TRIM(r.review_text), r.created_at
FROM dedup_reviews r
JOIN silver_customers c ON c.customer_id = r.customer_id
JOIN silver_books b ON b.book_id = r.book_id
WHERE r.rating BETWEEN 1 AND 5
ON CONFLICT (review_id) DO NOTHING;

INSERT INTO silver_rejected_rows (table_name, source_id, rejection_reason)
SELECT 'bronze_reviews', r.review_id::text,
    CASE
        WHEN r.rating IS NULL OR r.rating NOT BETWEEN 1 AND 5 THEN 'rating out of 1-5 range'
        WHEN NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = r.customer_id) THEN 'invalid customer_id FK'
        WHEN NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = r.book_id) THEN 'invalid book_id FK'
    END
FROM dedup_reviews r
WHERE r.rating IS NULL OR r.rating NOT BETWEEN 1 AND 5
   OR NOT EXISTS (SELECT 1 FROM silver_customers c WHERE c.customer_id = r.customer_id)
   OR NOT EXISTS (SELECT 1 FROM silver_books b WHERE b.book_id = r.book_id);

-- ---------- Summary: accepted vs rejected per table ----------
SELECT 'books' AS tbl, (SELECT COUNT(*) FROM silver_books) AS accepted, 0 AS rejected
UNION ALL
SELECT 'customers', (SELECT COUNT(*) FROM silver_customers),
       (SELECT COUNT(*) FROM silver_rejected_rows WHERE table_name = 'bronze_customers')
UNION ALL
SELECT 'orders', (SELECT COUNT(*) FROM silver_orders),
       (SELECT COUNT(*) FROM silver_rejected_rows WHERE table_name = 'bronze_orders')
UNION ALL
SELECT 'loans', (SELECT COUNT(*) FROM silver_loans),
       (SELECT COUNT(*) FROM silver_rejected_rows WHERE table_name = 'bronze_loans')
UNION ALL
SELECT 'reviews', (SELECT COUNT(*) FROM silver_reviews),
       (SELECT COUNT(*) FROM silver_rejected_rows WHERE table_name = 'bronze_reviews');