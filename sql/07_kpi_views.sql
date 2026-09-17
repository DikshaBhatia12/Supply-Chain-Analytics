-- ============================================================
-- VIEW 1: vw_kpi_summary (MySQL version)
-- Purpose: Top-level KPI cards for Power BI dashboard
--
-- NOTE ON OTIF: otif_rate_pct will equal otd_rate_pct in this
-- dataset. OTIF = on-time AND fully-shipped, but this dataset
-- doesn't track a separate "quantity shipped" field, so
-- is_qty_fulfilled is set to 1 for every row (documented
-- assumption in the cleaning notebook, Step 6). See README
-- "Data & Modeling Notes" for the full explanation.
-- ============================================================

USE supplychaindb;

DROP VIEW IF EXISTS vw_kpi_summary;

CREATE VIEW vw_kpi_summary AS
SELECT
    COUNT(*)                                            AS total_line_items,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(order_qty)                                      AS total_units_sold,
    ROUND(SUM(sales), 2)                                AS total_revenue,
    ROUND(SUM(profit), 2)                               AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales),0) * 100, 1) AS profit_margin_pct,
    ROUND(AVG(CAST(is_on_time       AS FLOAT))*100, 1) AS otd_rate_pct,
    ROUND(AVG(CAST(is_otif          AS FLOAT))*100, 1) AS otif_rate_pct,
    ROUND(AVG(CAST(is_sla_breach    AS FLOAT))*100, 1) AS sla_breach_pct,
    ROUND(AVG(CAST(is_perfect_order AS FLOAT))*100, 1) AS perfect_order_pct,
    ROUND(AVG(CAST(is_complete      AS FLOAT))*100, 1) AS complete_order_pct,
    ROUND(AVG(CAST(days_shipping_real AS FLOAT)), 1)    AS avg_days_to_ship,
    ROUND(AVG(CAST(days_variance      AS FLOAT)), 1)    AS avg_days_variance
FROM fact_orders;

SELECT * FROM vw_kpi_summary;


-- ============================================================
-- VIEW 2: vw_kpi_by_shippingmode
-- Purpose: Performance breakdown by shipping mode
-- Powers: The "First Class = 100% SLA breach" finding
-- ============================================================

DROP VIEW IF EXISTS vw_kpi_by_shippingmode;

CREATE VIEW vw_kpi_by_shippingmode AS
SELECT
    sh.shipping_mode,
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales), 2)                               AS total_revenue,
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,
    ROUND(AVG(CAST(f.days_shipping_real      AS FLOAT)),1) AS avg_actual_days,
    ROUND(AVG(CAST(f.days_shipping_scheduled AS FLOAT)),1) AS avg_promised_days,
    ROUND(AVG(CAST(f.days_variance           AS FLOAT)),1) AS avg_days_variance,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)   AS pct_of_total_orders
FROM fact_orders f
JOIN dim_shipping sh ON sh.shipping_key = f.shipping_key
GROUP BY sh.shipping_mode;

SELECT * FROM vw_kpi_by_shippingmode ORDER BY sla_breach_pct DESC;


-- ============================================================
-- VIEW 3: vw_kpi_by_region
-- Purpose: Regional performance — surfaces South of USA story
-- Powers: Regional map/bar chart, with year + shipping-mode slicers
-- ============================================================

DROP VIEW IF EXISTS vw_kpi_by_region;

CREATE VIEW vw_kpi_by_region AS
SELECT
    r.order_region,
    r.market,
    f.order_year,
    sh.shipping_mode,
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,
    ROUND(AVG(CAST(f.days_shipping_real AS FLOAT)),1)   AS avg_days_to_ship,
    ROUND(AVG(CAST(f.days_variance      AS FLOAT)),1)   AS avg_days_variance,
    RANK() OVER (ORDER BY AVG(CAST(f.is_on_time AS FLOAT)) ASC) AS otd_rank_worst_first
FROM fact_orders f
JOIN dim_region   r  ON r.region_key    = f.region_key
JOIN dim_shipping sh ON sh.shipping_key = f.shipping_key
GROUP BY r.order_region, r.market, f.order_year, sh.shipping_mode;

SELECT order_region, order_year, shipping_mode, total_orders, otd_rate_pct
FROM vw_kpi_by_region
ORDER BY order_region, order_year, shipping_mode
LIMIT 10;


-- ============================================================
-- VIEW 4: vw_sla_heatmap
-- Purpose: Cross analysis of region vs shipping mode
-- ============================================================

DROP VIEW IF EXISTS vw_sla_heatmap;

CREATE VIEW vw_sla_heatmap AS
SELECT
    r.order_region,
    sh.shipping_mode,
    COUNT(*)                                             AS total_orders,
    ROUND(AVG(CAST(f.is_sla_breach AS FLOAT))*100, 1)  AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_on_time    AS FLOAT))*100, 1)  AS otd_rate_pct,
    ROUND(AVG(CAST(f.days_variance AS FLOAT)),    1)    AS avg_days_late,
    CASE
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.80 THEN 'Critical'
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.60 THEN 'High Risk'
        WHEN AVG(CAST(f.is_sla_breach AS FLOAT)) >= 0.40 THEN 'Moderate'
        ELSE 'Acceptable'
    END                                                  AS risk_category
FROM fact_orders f
JOIN dim_region   r  ON r.region_key   = f.region_key
JOIN dim_shipping sh ON sh.shipping_key = f.shipping_key
GROUP BY r.order_region, sh.shipping_mode;

SELECT * FROM vw_sla_heatmap ORDER BY sla_breach_pct DESC LIMIT 10;


-- ============================================================
-- VIEW 5: vw_monthly_trend
-- Purpose: Month over month KPI trends. Full years only (excl. 2018)
-- ============================================================

DROP VIEW IF EXISTS vw_monthly_trend;

CREATE VIEW vw_monthly_trend AS
SELECT
    f.order_year,
    f.order_month,
    d.month_name,
    f.order_quarter,
    CONCAT(f.order_year, '-', LPAD(f.order_month, 2, '0')) AS `year_month`,
    COUNT(*)                                             AS total_orders,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_otif          AS FLOAT))*100,1) AS otif_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct,
    ROUND(AVG(CAST(f.days_variance    AS FLOAT)),    1)  AS avg_days_variance
FROM fact_orders f
JOIN dim_date d ON d.date_key = f.date_key
WHERE f.is_full_year = 1
GROUP BY f.order_year, f.order_month, d.month_name, f.order_quarter;

SELECT * FROM vw_monthly_trend ORDER BY order_year, order_month LIMIT 10;


-- ============================================================
-- VIEW 6: vw_kpi_by_category
-- Purpose: Which product categories have worst delivery?
-- ============================================================

DROP VIEW IF EXISTS vw_kpi_by_category;

CREATE VIEW vw_kpi_by_category AS
SELECT
    p.department_name,
    p.category_name,
    COUNT(*)                                             AS total_orders,
    SUM(f.order_qty)                                     AS total_units,
    ROUND(SUM(f.sales),  2)                              AS total_revenue,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(SUM(f.profit)/NULLIF(SUM(f.sales),0)*100, 1)  AS margin_pct,
    ROUND(AVG(CAST(f.is_on_time       AS FLOAT))*100,1) AS otd_rate_pct,
    ROUND(AVG(CAST(f.is_sla_breach    AS FLOAT))*100,1) AS sla_breach_pct,
    ROUND(AVG(CAST(f.is_perfect_order AS FLOAT))*100,1) AS perfect_order_pct
FROM fact_orders f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.department_name, p.category_name;

SELECT * FROM vw_kpi_by_category ORDER BY total_revenue DESC LIMIT 10;
