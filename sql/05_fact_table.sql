-- ============================================================
-- BUILD FACT_Orders (MySQL version)
-- Why: One row per order line item, with foreign keys to every
--      dimension table built in 04_dimension_tables.sql.
-- ============================================================

USE supplychaindb;

DROP TABLE IF EXISTS fact_orders;

CREATE TABLE fact_orders (
    fact_key                INT AUTO_INCREMENT PRIMARY KEY,
    order_id                INT,
    order_item_id           INT,

    -- Foreign keys
    shipping_key            INT,
    region_key              INT,
    geo_key                 INT,
    product_key             INT,
    customer_key            INT,
    date_key                INT,

    -- Dates
    order_date              DATETIME,
    ship_date               DATETIME,
    order_year              INT,
    order_month             INT,
    order_quarter           INT,
    order_dow               VARCHAR(20),
    is_full_year             INT,

    -- Shipping details
    payment_type             VARCHAR(50),
    days_shipping_real       INT,
    days_shipping_scheduled  INT,
    days_variance            INT,
    late_delivery_risk       INT,
    delivery_status          VARCHAR(50),
    order_status             VARCHAR(50),

    -- KPI flags
    is_on_time               INT,
    is_complete               INT,
    is_qty_fulfilled         INT,
    is_otif                  INT,
    is_sla_breach             INT,
    is_perfect_order         INT,

    -- Financial measures
    order_qty                INT,
    unit_price                FLOAT,
    sales                     FLOAT,
    discount                  FLOAT,
    profit                    FLOAT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO fact_orders (
    order_id, order_item_id,
    shipping_key, region_key, geo_key, product_key, customer_key, date_key,
    order_date, ship_date, order_year, order_month, order_quarter,
    order_dow, is_full_year, payment_type,
    days_shipping_real, days_shipping_scheduled, days_variance,
    late_delivery_risk, delivery_status, order_status,
    is_on_time, is_complete, is_qty_fulfilled,
    is_otif, is_sla_breach, is_perfect_order,
    order_qty, unit_price, sales, discount, profit
)
SELECT
    s.order_id,
    s.order_item_id,
    sh.shipping_key,
    r.region_key,
    g.geo_key,
    p.product_key,
    c.customer_key,
    CAST(DATE_FORMAT(s.order_date, '%Y%m%d') AS UNSIGNED),
    s.order_date, s.ship_date,
    s.order_year, s.order_month, s.order_quarter,
    s.order_dow, s.is_full_year, s.payment_type,
    s.days_shipping_real, s.days_shipping_scheduled, s.days_variance,
    s.late_delivery_risk, s.delivery_status, s.order_status,
    s.is_on_time, s.is_complete, s.is_qty_fulfilled,
    s.is_otif, s.is_sla_breach, s.is_perfect_order,
    s.order_qty, s.unit_price, s.sales, s.discount, s.profit

FROM stg_supplychain s
JOIN dim_shipping  sh ON sh.shipping_mode    = s.shipping_mode
JOIN dim_region    r  ON r.order_region      = s.order_region
                      AND r.market           = s.market
JOIN dim_geography g  ON g.customer_city     = s.customer_city
                      AND g.customer_state   = s.customer_state
                      AND g.customer_country = s.customer_country
JOIN dim_product   p  ON p.product_name      = s.product_name
                      AND p.category_name    = s.category_name
                      AND p.department_name  = s.department_name
JOIN dim_customer  c  ON c.customer_segment  = s.customer_segment;

-- Verify
SELECT
    COUNT(*)                 AS total_fact_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 2)     AS total_revenue,
    ROUND(SUM(profit), 2)    AS total_profit
FROM fact_orders;
