-- 1. total revenue per category
-- revenue = quantity * unit_price * (1 - discount_percent/100)
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.quantity > 0   -- excluding returns from revenue calc, they're negative anyway so this doesn't add revenue
GROUP BY p.category
ORDER BY total_revenue DESC;


-- 2. top 10 customers by total order value
SELECT
    c.customer_id,
    c.customer_name,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS total_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_value DESC
LIMIT 10;


-- 3. month wise order count for last 12 months
SELECT
    strftime('%Y-%m', order_date) AS order_month,
    COUNT(DISTINCT order_id) AS order_count
FROM orders
WHERE order_date >= date('now', '-12 months')
GROUP BY order_month
ORDER BY order_month;


-- 4. customers who placed orders but never had any item delivered
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id NOT IN (
    SELECT o2.customer_id
    FROM orders o2
    WHERE o2.status = 'DELIVERED'
);


-- 5. products that had more returns than purchases
-- purchases = positive quantity, returns = negative quantity (abs value)
SELECT
    p.product_id,
    p.product_name,
    SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END) AS total_purchased,
    SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END) AS total_returned
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING total_returned > total_purchased;


-- 6. return rate per category = returned items / total items
SELECT
    p.category,
    SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END) AS returned_items,
    SUM(ABS(oi.quantity)) AS total_items,
    ROUND(
        SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END) * 100.0
        / SUM(ABS(oi.quantity)), 2
    ) AS return_rate_percent
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_percent DESC;