-- 10. multi level CTE
-- step 1: monthly revenue per customer
-- step 2: categorize into High/Medium/Low
-- step 3: count of customers per category per month
WITH monthly_customer_rev AS (
    SELECT
        o.customer_id,
        strftime('%Y-%m', o.order_date) AS rev_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id IS NOT NULL AND oi.quantity > 0
    GROUP BY o.customer_id, rev_month
),
categorized AS (
    SELECT
        customer_id,
        rev_month,
        monthly_revenue,
        CASE
            WHEN monthly_revenue > 10000 THEN 'High'
            WHEN monthly_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM monthly_customer_rev
)
SELECT
    rev_month,
    revenue_category,
    COUNT(*) AS customer_count
FROM categorized
GROUP BY rev_month, revenue_category
ORDER BY rev_month, revenue_category;


-- 15. cohort analysis
-- group customers by registration month, track how many ordered in month 0,1,2,3 after registration
WITH cohorts AS (
    SELECT
        customer_id,
        strftime('%Y-%m', registration_date) AS cohort_month
    FROM customers
),
customer_orders AS (
    SELECT
        c.customer_id,
        c.cohort_month,
        o.order_date,
        -- month difference between order and registration
        (CAST(strftime('%Y', o.order_date) AS INTEGER) - CAST(strftime('%Y', c.cohort_month || '-01') AS INTEGER)) * 12
        + (CAST(strftime('%m', o.order_date) AS INTEGER) - CAST(strftime('%m', c.cohort_month || '-01') AS INTEGER)) AS month_number
    FROM cohorts c
    JOIN orders o ON c.customer_id = o.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS total_customers
    FROM cohorts
    GROUP BY cohort_month
),
activity_by_month AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM customer_orders
    WHERE month_number BETWEEN 0 AND 3
    GROUP BY cohort_month, month_number
)
SELECT
    a.cohort_month,
    a.month_number,
    a.active_customers,
    s.total_customers,
    ROUND(a.active_customers * 100.0 / s.total_customers, 2) AS retention_rate_percent
FROM activity_by_month a
JOIN cohort_size s ON a.cohort_month = s.cohort_month
ORDER BY a.cohort_month, a.month_number;