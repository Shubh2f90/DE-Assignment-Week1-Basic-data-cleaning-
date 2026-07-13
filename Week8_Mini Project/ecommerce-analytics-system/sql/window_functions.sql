-- 7. running total of revenue per region, ordered by date
WITH daily_rev AS (
    SELECT
        o.region_code,
        DATE(o.order_date) AS order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.quantity > 0
    GROUP BY o.region_code, DATE(o.order_date)
)
SELECT
    region_code,
    order_date,
    ROUND(daily_revenue, 2) AS daily_revenue,
    ROUND(SUM(daily_revenue) OVER (
        PARTITION BY region_code ORDER BY order_date
    ), 2) AS running_total
FROM daily_rev
ORDER BY region_code, order_date;


-- 8. rank products by total revenue within each category (dense rank so ties share rank)
WITH product_rev AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS total_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE oi.quantity > 0
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    ROUND(total_revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rank_in_category
FROM product_rev
ORDER BY category, rank_in_category;


-- 9. days between consecutive orders per customer, flag "At Risk" if avg gap > 30 days
WITH order_gaps AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM orders
    WHERE customer_id IS NOT NULL
),
gaps_with_days AS (
    SELECT
        customer_id,
        order_date,
        previous_order_date,
        CASE WHEN previous_order_date IS NOT NULL
             THEN JULIANDAY(order_date) - JULIANDAY(previous_order_date)
             ELSE NULL END AS days_gap
    FROM order_gaps
)
SELECT
    g.customer_id,
    g.order_date,
    g.previous_order_date,
    g.days_gap,
    CASE WHEN avg_gap.avg_days > 30 THEN 'At Risk' ELSE 'Normal' END AS risk_flag
FROM gaps_with_days g
JOIN (
    SELECT customer_id, AVG(days_gap) AS avg_days
    FROM gaps_with_days
    WHERE days_gap IS NOT NULL
    GROUP BY customer_id
) avg_gap ON g.customer_id = avg_gap.customer_id
ORDER BY g.customer_id, g.order_date;


-- 11. NTILE - divide customers into 4 quartiles based on lifetime value
WITH customer_value AS (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS total_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.quantity > 0
    GROUP BY c.customer_id
)
SELECT
    customer_id,
    ROUND(total_value, 2) AS total_value,
    NTILE(4) OVER (ORDER BY total_value DESC) AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_value DESC)
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        ELSE 'Bronze'
    END AS quartile_label
FROM customer_value
ORDER BY total_value DESC;


-- 12. year over year revenue comparison, month by month
WITH monthly_rev AS (
    SELECT
        CAST(strftime('%Y', o.order_date) AS INTEGER) AS year,
        CAST(strftime('%m', o.order_date) AS INTEGER) AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.quantity > 0
    GROUP BY year, month
)
SELECT
    curr.year,
    curr.month,
    ROUND(curr.revenue, 2) AS revenue,
    ROUND(prev.revenue, 2) AS prev_year_revenue,
    CASE WHEN prev.revenue IS NOT NULL AND prev.revenue != 0
         THEN ROUND((curr.revenue - prev.revenue) * 100.0 / prev.revenue, 2)
         ELSE NULL END AS yoy_growth_percent
FROM monthly_rev curr
LEFT JOIN monthly_rev prev
    ON curr.month = prev.month AND curr.year = prev.year + 1
ORDER BY curr.year, curr.month;


-- 13. first purchased category vs most recent purchased category per customer
WITH ordered_categories AS (
    SELECT
        o.customer_id,
        o.order_date,
        p.category,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS first_rank,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS last_rank
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.customer_id IS NOT NULL
)
SELECT
    f.customer_id,
    f.category AS first_category,
    l.category AS latest_category,
    CASE WHEN f.category != l.category THEN 'Yes' ELSE 'No' END AS category_shift
FROM (SELECT * FROM ordered_categories WHERE first_rank = 1) f
JOIN (SELECT * FROM ordered_categories WHERE last_rank = 1) l
    ON f.customer_id = l.customer_id;


-- 14. cumulative revenue distribution - what % of revenue comes from top customers
WITH customer_rev AS (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE oi.quantity > 0
    GROUP BY c.customer_id
),
total_rev AS (
    SELECT SUM(revenue) AS grand_total FROM customer_rev
)
SELECT
    customer_id,
    ROUND(revenue, 2) AS revenue,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC), 2) AS cumulative_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0 / (SELECT grand_total FROM total_rev), 2) AS cumulative_percent
FROM customer_rev
ORDER BY revenue DESC;


-- 16. products frequently bought together (self join on order_id, avoid duplicate pairs)
SELECT
    a.product_id AS product_a,
    b.product_id AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items a
JOIN order_items b
    ON a.order_id = b.order_id
    AND a.product_id < b.product_id   -- avoids (A,B) and (B,A) both showing up, and A-A pairs
GROUP BY a.product_id, b.product_id
ORDER BY times_bought_together DESC;