CREATE OR REPLACE VIEW gold_pipeline_health AS
SELECT
    m.table_name,
    m.last_loaded_at,
    b.row_count AS rows_in_bronze,
    s.row_count AS rows_in_silver,
    COALESCE(r.rejected_count, 0) AS rows_rejected,
    ROUND(100.0 * COALESCE(r.rejected_count, 0) / NULLIF(b.row_count, 0), 2) AS rejection_rate_pct,
    CASE
        WHEN ROUND(100.0 * COALESCE(r.rejected_count, 0) / NULLIF(b.row_count, 0), 2) > 5.0
        THEN 'DEGRADED' ELSE 'HEALTHY'
    END AS pipeline_status
FROM pipeline_metadata m
JOIN (
    SELECT 'bronze_books' AS table_name, COUNT(*) AS row_count FROM bronze_books
    UNION ALL SELECT 'bronze_customers', COUNT(*) FROM bronze_customers
    UNION ALL SELECT 'bronze_orders', COUNT(*) FROM bronze_orders
    UNION ALL SELECT 'bronze_loans', COUNT(*) FROM bronze_loans
    UNION ALL SELECT 'bronze_reviews', COUNT(*) FROM bronze_reviews
) b ON b.table_name = m.table_name
JOIN (
    SELECT 'bronze_books' AS table_name, COUNT(*) AS row_count FROM silver_books
    UNION ALL SELECT 'bronze_customers', COUNT(*) FROM silver_customers
    UNION ALL SELECT 'bronze_orders', COUNT(*) FROM silver_orders
    UNION ALL SELECT 'bronze_loans', COUNT(*) FROM silver_loans
    UNION ALL SELECT 'bronze_reviews', COUNT(*) FROM silver_reviews
) s ON s.table_name = m.table_name
LEFT JOIN (
    SELECT table_name, COUNT(*) AS rejected_count
    FROM silver_rejected_rows
    GROUP BY table_name
) r ON r.table_name = m.table_name;

-- overall health verdict
SELECT
    ROUND(AVG(rejection_rate_pct), 2) AS overall_rejection_rate_pct,
    CASE WHEN MAX(rejection_rate_pct) > 5.0 THEN 'DEGRADED' ELSE 'HEALTHY' END AS overall_verdict
FROM gold_pipeline_health;