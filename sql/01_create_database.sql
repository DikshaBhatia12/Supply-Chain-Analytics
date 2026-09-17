-- ============================================================
-- CREATE DATABASE (MySQL version)
-- ============================================================

DROP DATABASE IF EXISTS supplychaindb;
CREATE DATABASE supplychaindb
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE supplychaindb;

SELECT 'SupplyChainDB created successfully' AS status;
