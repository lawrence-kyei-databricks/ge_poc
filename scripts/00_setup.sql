-- =====================================================================
-- Giant Eagle POC: 00_setup.sql
-- Catalog and schema provisioning for the Gold-layer remodel POC
-- Run order: 00 → 01 → 02 → 03 → 04 → 05 (benchmark queries optional)
-- =====================================================================

-- Replace <CATALOG_NAME> with your target catalog before running.
-- For example: USE CATALOG ge_poc;

-- Catalog (create only if you don't already have one for this work)
CREATE CATALOG IF NOT EXISTS ge_poc
  COMMENT 'Giant Eagle Manhattan WMS POC: Gold layer remodel track';

-- Enable predictive optimization for automatic OPTIMIZE and stats collection
ALTER CATALOG ge_poc SET TBLPROPERTIES (
  'delta.feature.predictiveOptimization' = 'Supported'
);

USE CATALOG ge_poc;

-- Schemas
CREATE SCHEMA IF NOT EXISTS bronze
  COMMENT 'Reverse-engineered Manhattan base tables (sample). Superseded by real Lakeflow Connect Bronze when source pipeline lands.';

CREATE SCHEMA IF NOT EXISTS gold_lift_shift
  COMMENT 'Version A: 1:1 Delta-view ports of the Snowflake views.';

CREATE SCHEMA IF NOT EXISTS gold_native
  COMMENT 'Version B: lakehouse-native dimensional model. Conformed dimensions + facts + compatibility views.';

-- Confirm
SHOW SCHEMAS IN ge_poc;
