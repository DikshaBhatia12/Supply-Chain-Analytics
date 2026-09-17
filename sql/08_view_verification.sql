USE supplychaindb;

-- VERIFICATION 1: Confirm all 6 views exist
SELECT
    TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'supplychaindb'
ORDER BY TABLE_NAME;

-- VERIFICATION 2: Test every view returns data
SELECT 'vw_kpi_summary'         AS view_name, COUNT(*) AS rows_returned FROM vw_kpi_summary
UNION ALL
SELECT 'vw_kpi_by_shippingmode', COUNT(*) FROM vw_kpi_by_shippingmode
UNION ALL
SELECT 'vw_kpi_by_region',       COUNT(*) FROM vw_kpi_by_region
UNION ALL
SELECT 'vw_sla_heatmap',         COUNT(*) FROM vw_sla_heatmap
UNION ALL
SELECT 'vw_monthly_trend',       COUNT(*) FROM vw_monthly_trend
UNION ALL
SELECT 'vw_kpi_by_category',     COUNT(*) FROM vw_kpi_by_category;
