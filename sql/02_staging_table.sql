-- ============================================================
-- STEP 2: CREATE STAGING TABLE (MySQL version)
-- Why: Staging table mirrors the cleaned CSV's columns and types
--      exactly (see python/...ipynb Step 8) — pandas has already
--      validated and coerced every type before export, so this
--      table is typed directly rather than landing everything as
--      VARCHAR first. That does mean a badly-formed row would
--      throw a conversion error during LOAD DATA INFILE rather
--      than loading silently as text; validation happens on the
--      Python side instead of here.
-- ============================================================

USE supplychaindb;

DROP TABLE IF EXISTS stg_supplychain;

CREATE TABLE stg_supplychain (
    payment_type              VARCHAR(50),
    days_shipping_real        INT,
    days_shipping_scheduled   INT,
    late_delivery_risk        INT,
    delivery_status           VARCHAR(50),
    shipping_mode              VARCHAR(50),
    order_region               VARCHAR(100),
    order_status               VARCHAR(50),
    order_id                   INT,
    order_item_id              INT,
    order_qty                  INT,
    unit_price                 FLOAT,
    sales                      FLOAT,
    discount                   FLOAT,
    profit                     FLOAT,
    customer_city              VARCHAR(100),
    customer_country           VARCHAR(100),
    customer_segment           VARCHAR(50),
    customer_state             VARCHAR(100),
    product_name               VARCHAR(200),
    category_name              VARCHAR(100),
    department_name            VARCHAR(100),
    market                     VARCHAR(100),
    order_date                 DATETIME,
    ship_date                  DATETIME,
    order_year                 INT,
    order_month                INT,
    order_quarter              INT,
    order_dow                  VARCHAR(20),
    is_full_year               INT,
    is_on_time                 INT,
    is_complete                INT,
    is_qty_fulfilled           INT,
    is_otif                    INT,
    is_sla_breach              INT,
    days_variance              INT,
    is_perfect_order           INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT 'Staging table created — 37 columns ready for import' AS status;
