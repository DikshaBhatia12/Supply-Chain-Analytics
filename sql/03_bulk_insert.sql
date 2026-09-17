-- ============================================================
-- STEP 3: LOAD CLEAN CSV INTO STAGING TABLE (MySQL version)
-- Why: LOAD DATA INFILE is MySQL's equivalent of SQL Server's
--      BULK INSERT — loads 180,000+ rows in seconds.
-- ============================================================

USE supplychaindb;

-- Update the path below to wherever supplychain_clean.csv (from
-- Python/Supply chain - Data Cleaning and EDA.ipynb, Step 8) lives.
--
-- NOTE — MySQL's own version of the "first BULK INSERT attempt fails"
-- gotcha: LOAD DATA LOCAL INFILE requires local_infile to be enabled
-- on BOTH the server and the client, or it's rejected outright. If
-- your first attempt errors with something like "Loading local data
-- is disabled", run this once before connecting (server-side):
--     SET GLOBAL local_infile = 1;
-- ...and connect with `mysql --local-infile=1 ...` (or, in MySQL
-- Workbench, enable it under Edit > Preferences > SQL Editor >
-- "Allow loading of local infiles from client"). This isn't a sign
-- your script is wrong — it's MySQL's default security posture.
LOAD DATA LOCAL INFILE '/path/to/supplychain_clean.csv'
INTO TABLE stg_supplychain
CHARACTER SET utf8mb4              -- the notebook exports UTF-8; without
                                    -- this MySQL falls back to its
                                    -- connection's default charset and
                                    -- special characters can come out
                                    -- garbled — same concern as SQL
                                    -- Server's CODEPAGE option
FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'      -- MySQL's equivalent of FORMAT='CSV'
                                    -- + FIELDQUOTE — handles any field
                                    -- pandas quoted because it contains
                                    -- a comma, instead of silently
                                    -- shifting columns
LINES TERMINATED BY '\n'           -- matches the LF-only line endings
                                    -- the notebook's Step 8 now writes
                                    -- explicitly (newline="",
                                    -- lineterminator="\n") — if you ever
                                    -- re-export with a tool that writes
                                    -- CRLF instead, change this to '\r\n'
IGNORE 1 ROWS;                     -- skip the header row

-- Immediately verify the import worked
SELECT
    COUNT(*)                     AS total_rows,
    MIN(order_date)               AS earliest_order,
    MAX(order_date)               AS latest_order,
    COUNT(DISTINCT order_id)      AS unique_orders,
    COUNT(DISTINCT order_region)  AS unique_regions
FROM stg_supplychain;
