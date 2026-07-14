-- =========================================================
-- TASK 2: Bronze incremental load using watermark pattern
-- Each table's watermark column (chosen per source):
--   orders    -> order_date
--   loans     -> loan_date
--   reviews   -> created_at
--   customers -> joined_on   (no created_at in source, using account creation date)
--   books     -> published_on (no created_at in source, using publish date)
-- =========================================================

BEGIN;

TRUNCATE TABLE bronze_books;

WITH new_rows AS (
    INSERT INTO bronze_books (book_id, title, author, genre, price, stock, published_on, ingested_at, batch_id)
    SELECT book_id, title, author, genre, price, stock, published_on,
           NOW(), 'BATCH_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
    FROM books
    RETURNING 1
)
UPDATE pipeline_metadata
SET last_loaded_at = NOW(), rows_loaded = (SELECT COUNT(*) FROM new_rows), status = 'SUCCESS'
WHERE table_name = 'bronze_books';

COMMIT;

BEGIN;

WITH new_rows AS (
    INSERT INTO bronze_customers (customer_id, name, email, city, joined_on, membership, ingested_at, batch_id)
    SELECT customer_id, name, email, city, joined_on, membership,
           NOW(), 'BATCH_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
    FROM customers
    WHERE joined_on > (SELECT last_loaded_at FROM pipeline_metadata WHERE table_name = 'bronze_customers')::date
    RETURNING 1
)
UPDATE pipeline_metadata
SET last_loaded_at = NOW(), rows_loaded = (SELECT COUNT(*) FROM new_rows), status = 'SUCCESS'
WHERE table_name = 'bronze_customers';

COMMIT;

BEGIN;

WITH new_rows AS (
    INSERT INTO bronze_orders (order_id, customer_id, book_id, order_date, quantity, status, ingested_at, batch_id)
    SELECT order_id, customer_id, book_id, order_date, quantity, status,
           NOW(), 'BATCH_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
    FROM orders
    WHERE order_date > (SELECT last_loaded_at FROM pipeline_metadata WHERE table_name = 'bronze_orders')::date
    RETURNING 1
)
UPDATE pipeline_metadata
SET last_loaded_at = NOW(), rows_loaded = (SELECT COUNT(*) FROM new_rows), status = 'SUCCESS'
WHERE table_name = 'bronze_orders';

COMMIT;

BEGIN;

WITH new_rows AS (
    INSERT INTO bronze_loans (loan_id, customer_id, book_id, loan_date, due_date, return_date, ingested_at, batch_id)
    SELECT loan_id, customer_id, book_id, loan_date, due_date, return_date,
           NOW(), 'BATCH_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
    FROM loans
    WHERE loan_date > (SELECT last_loaded_at FROM pipeline_metadata WHERE table_name = 'bronze_loans')::date
    RETURNING 1
)
UPDATE pipeline_metadata
SET last_loaded_at = NOW(), rows_loaded = (SELECT COUNT(*) FROM new_rows), status = 'SUCCESS'
WHERE table_name = 'bronze_loans';

COMMIT;

BEGIN;

WITH new_rows AS (
    INSERT INTO bronze_reviews (review_id, customer_id, book_id, rating, review_text, created_at, ingested_at, batch_id)
    SELECT review_id, customer_id, book_id, rating, review_text, created_at,
           NOW(), 'BATCH_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
    FROM reviews
    WHERE created_at > (SELECT last_loaded_at FROM pipeline_metadata WHERE table_name = 'bronze_reviews')
    RETURNING 1
)
UPDATE pipeline_metadata
SET last_loaded_at = NOW(), rows_loaded = (SELECT COUNT(*) FROM new_rows), status = 'SUCCESS'
WHERE table_name = 'bronze_reviews';

COMMIT;

-- quick check: row counts per bronze table
SELECT 'bronze_books' AS tbl, COUNT(*) FROM bronze_books
UNION ALL SELECT 'bronze_customers', COUNT(*) FROM bronze_customers
UNION ALL SELECT 'bronze_orders', COUNT(*) FROM bronze_orders
UNION ALL SELECT 'bronze_loans', COUNT(*) FROM bronze_loans
UNION ALL SELECT 'bronze_reviews', COUNT(*) FROM bronze_reviews;