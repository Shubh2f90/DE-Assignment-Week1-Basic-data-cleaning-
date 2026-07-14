-- =========================================================
-- TASK 4: Gold layer — 5 KPI views + 2 analytical views
-- =========================================================

-- 1. Revenue Growth: MoM % change in DELIVERED revenue, target >= 5% (per month)
DROP VIEW IF EXISTS gold_kpi_revenue_growth;
DROP VIEW IF EXISTS gold_kpi_retention_rate;
DROP VIEW IF EXISTS gold_kpi_sell_through;
DROP VIEW IF EXISTS gold_kpi_return_compliance;
DROP VIEW IF EXISTS gold_kpi_review_coverage;
DROP VIEW IF EXISTS gold_top_books;
DROP VIEW IF EXISTS gold_customer_segments;

CREATE OR REPLACE VIEW gold_kpi_revenue_growth AS
WITH monthly_revenue AS (
    SELECT date_trunc('month', order_date)::date AS month,
           SUM(order_value) AS revenue
    FROM silver_orders
    WHERE status = 'DELIVERED'
    GROUP BY 1
)
SELECT
    month,
    revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS kpi_value,
    5.0 AS kpi_target,
    CASE WHEN ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
              / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) >= 5.0
         THEN 'PASS' ELSE 'FAIL' END AS status,
    NOW() AS calculated_at
FROM monthly_revenue
ORDER BY month;

-- 2. Retention Rate: % customers active in 2 consecutive calendar months, target >= 60%
CREATE OR REPLACE VIEW gold_kpi_retention_rate AS
WITH monthly_customers AS (
    SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month
    FROM silver_orders
),
retained AS (
    SELECT DISTINCT a.customer_id
    FROM monthly_customers a
    JOIN monthly_customers b
      ON b.customer_id = a.customer_id
     AND b.month = a.month + INTERVAL '1 month'
)
SELECT
    ROUND(100.0 * (SELECT COUNT(*) FROM retained)
          / NULLIF((SELECT COUNT(*) FROM silver_customers), 0), 2) AS kpi_value,
    60.0 AS kpi_target,
    CASE WHEN ROUND(100.0 * (SELECT COUNT(*) FROM retained)
              / NULLIF((SELECT COUNT(*) FROM silver_customers), 0), 2) >= 60.0
         THEN 'PASS' ELSE 'FAIL' END AS status,
    NOW() AS calculated_at;

-- 3. Sell-Through Rate: % of books with >=1 DELIVERED order, target >= 70%
CREATE OR REPLACE VIEW gold_kpi_sell_through AS
WITH delivered_books AS (
    SELECT DISTINCT book_id FROM silver_orders WHERE status = 'DELIVERED'
)
SELECT
    ROUND(100.0 * (SELECT COUNT(*) FROM delivered_books)
          / NULLIF((SELECT COUNT(*) FROM silver_books), 0), 2) AS kpi_value,
    70.0 AS kpi_target,
    CASE WHEN ROUND(100.0 * (SELECT COUNT(*) FROM delivered_books)
              / NULLIF((SELECT COUNT(*) FROM silver_books), 0), 2) >= 70.0
         THEN 'PASS' ELSE 'FAIL' END AS status,
    NOW() AS calculated_at;

-- 4. Return Compliance: % of *completed* loans returned on/before due_date, target >= 75%
CREATE OR REPLACE VIEW gold_kpi_return_compliance AS
SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= due_date)
          / NULLIF(COUNT(*), 0), 2) AS kpi_value,
    75.0 AS kpi_target,
    CASE WHEN ROUND(100.0 * COUNT(*) FILTER (WHERE return_date <= due_date)
              / NULLIF(COUNT(*), 0), 2) >= 75.0
         THEN 'PASS' ELSE 'FAIL' END AS status,
    NOW() AS calculated_at
FROM silver_loans
WHERE return_date IS NOT NULL;

-- 5. Review Coverage: % of DELIVERED orders with a matching review, target >= 40%
CREATE OR REPLACE VIEW gold_kpi_review_coverage AS
SELECT
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1 FROM silver_reviews r
            WHERE r.customer_id = d.customer_id AND r.book_id = d.book_id
        )
    ) / NULLIF(COUNT(*), 0), 2) AS kpi_value,
    40.0 AS kpi_target,
    CASE WHEN ROUND(100.0 * COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1 FROM silver_reviews r
            WHERE r.customer_id = d.customer_id AND r.book_id = d.book_id
        )
    ) / NULLIF(COUNT(*), 0), 2) >= 40.0
         THEN 'PASS' ELSE 'FAIL' END AS status,
    NOW() AS calculated_at
FROM silver_orders d
WHERE d.status = 'DELIVERED';

-- ---------- Analytical view 1: top 10 books by revenue, per genre ----------
CREATE OR REPLACE VIEW gold_top_books AS
WITH book_stats AS (
    SELECT
        b.book_id, b.title, b.genre,
        SUM(o.order_value) AS total_revenue,
        SUM(o.quantity) AS units_sold,
        AVG(r.rating) AS avg_rating
    FROM silver_books b
    JOIN silver_orders o ON o.book_id = b.book_id AND o.status = 'DELIVERED'
    LEFT JOIN silver_reviews r ON r.book_id = b.book_id
    GROUP BY b.book_id, b.title, b.genre
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY genre ORDER BY total_revenue DESC) AS rnk
    FROM book_stats
)
SELECT book_id, title, genre, total_revenue, ROUND(avg_rating, 2) AS avg_rating, units_sold
FROM ranked
WHERE rnk <= 10
ORDER BY genre, total_revenue DESC;

-- ---------- Analytical view 2: customer segments by total spend ----------
CREATE OR REPLACE VIEW gold_customer_segments AS
SELECT
    c.customer_id,
    COALESCE(SUM(o.order_value), 0) AS total_spend,
    CASE
        WHEN COALESCE(SUM(o.order_value), 0) > 20000 THEN 'HIGH VALUE'
        WHEN COALESCE(SUM(o.order_value), 0) >= 5000 THEN 'MID VALUE'
        ELSE 'LOW VALUE'
    END AS segment
FROM silver_customers c
LEFT JOIN silver_orders o ON o.customer_id = c.customer_id AND o.status = 'DELIVERED'
GROUP BY c.customer_id;