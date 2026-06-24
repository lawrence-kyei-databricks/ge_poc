-- Databricks notebook source
-- =====================================================================
-- Giant Eagle: 04_gold_native_dimensions.sql
-- VERSION B (lakehouse-native), part 1: CONFORMED DIMENSIONS
-- The de facto Gold layer designed for the lakehouse.
-- Covers all dimensional needs of the 50 Snowflake views.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_native;

-- =====================================================================
-- dim_business_unit
-- Replaces the BICEPS / HBC / ASF / BRM / FFM / OKG / OKP / CCS view-name
-- duplication. Business unit becomes a column.
-- =====================================================================
CREATE OR REPLACE TABLE dim_business_unit (
  business_unit_sk               BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  business_unit_code             STRING NOT NULL,    -- 'BICEPS', 'HBC', 'ASF', 'BRM', 'FFM', 'OKG', 'OKP', 'CCS'
  business_unit_name             STRING,
  primary_facility_id            STRING,
  facility_id_pattern            STRING,             -- e.g. 'D0033,D0031,D0032' for BICEPS general
  description                    STRING
) USING DELTA;

INSERT INTO dim_business_unit (business_unit_code, business_unit_name, primary_facility_id, facility_id_pattern, description) VALUES
  ('BICEPS', 'BICEPS General Retail',           'D0033', 'D0031,D0032,D0033,D0034,D0036,D0037,D0038', 'BICEPS general retail DCs'),
  ('HBC',    'HBC Pharmacy / Health & Beauty', 'D0080', 'D0080',                                       'Health Beauty Cosmetics and pharmacy'),
  ('ASF',    'ASF Seafood',                    'D0061', 'D0061',                                       'American Seafood'),
  ('BRM',    'BRM Beverage',                   'D0050', 'D0050',                                       'Beverage / Beer / Wine'),
  ('FFM',    'FFM Fresh',                      'D0070', 'D0070',                                       'Fresh fruit / meat'),
  ('OKG',    'OKG Grocery',                    'D0001', 'D0001,D0008',                                 'OK Grocery'),
  ('OKP',    'OKP Produce',                    'D0044', 'D0044',                                       'OK Produce'),
  ('CCS',    'CCS Corporate (cross-facility)', NULL,    'ALL',                                         'Corporate / cross-facility analytical');

-- =====================================================================
-- dim_facility
-- Conformed facility dimension. Includes the substring-derived "facility short"
-- used heavily in GE_CS_* views.
-- =====================================================================
CREATE OR REPLACE TABLE dim_facility (
  facility_sk                    BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  facility_id                    STRING NOT NULL,    -- natural key, e.g. 'D0080'
  facility_short                 STRING,             -- last 2 chars, e.g. '80'
  facility_name                  STRING,
  virtual_warehouse_group        STRING,             -- e.g. 'DC80-85'
  region                         STRING,
  business_unit_code             STRING,             -- denormalized for query convenience
  is_active                      BOOLEAN
) USING DELTA;

INSERT INTO dim_facility (facility_id, facility_short, facility_name, virtual_warehouse_group, region, business_unit_code) VALUES
  ('D0001', '01', 'OK Grocery Distribution Center',         'DC01-08', 'East', 'OKG'),
  ('D0008', '08', 'OK Grocery Annex',                        'DC01-08', 'East', 'OKG'),
  ('D0031', '31', 'BICEPS DC 31',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0032', '32', 'BICEPS DC 32',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0033', '33', 'BICEPS Main',                             'DC33-AA', 'East', 'BICEPS'),
  ('D0034', '34', 'BICEPS DC 34',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0036', '36', 'BICEPS DC 36',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0037', '37', 'BICEPS DC 37',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0038', '38', 'BICEPS DC 38',                            'DC33-AA', 'East', 'BICEPS'),
  ('D0044', '44', 'OK Produce',                              'DC44',    'East', 'OKP'),
  ('D0050', '50', 'BRM Beverage',                            'DC50',    'East', 'BRM'),
  ('D0061', '61', 'ASF Seafood',                             'DC61',    'East', 'ASF'),
  ('D0070', '70', 'FFM Fresh',                               'DC70',    'East', 'FFM'),
  ('D0080', '80', 'HBC Pharmacy / Health and Beauty',        'DC80-85', 'East', 'HBC');

-- =====================================================================
-- dim_item
-- Item master with all GE extensions, SCD2-ready
-- =====================================================================
CREATE OR REPLACE TABLE dim_item (
  item_sk                        BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  item_id                        STRING NOT NULL,
  item_pk                        BIGINT,
  profile_id                     STRING,
  short_description              STRING,
  description                    STRING,
  style_suffix                   STRING,
  display_uom_id                 STRING,
  lpn_per_tier                   INT,
  tiers_per_pallet               INT,
  unit_price                     DECIMAL(18,4),
  catch_weight_item              STRING,
  average_weight                 DECIMAL(18,4),
  ext_gegl_department            STRING,
  ext_gegl_product_size          STRING,
  ext_gegl_dcxx_virtual_whse     STRING,
  ext_gegl_dc33_virtual_whse     STRING,
  -- Item physical dimensions (denormalized from item_package for query speed)
  unit_height                    DECIMAL(18,4),
  unit_width                     DECIMAL(18,4),
  unit_length                    DECIMAL(18,4),
  unit_weight                    DECIMAL(18,4),
  unit_volume                    DECIMAL(18,4),
  pack_height                    DECIMAL(18,4),
  pack_width                     DECIMAL(18,4),
  pack_length                    DECIMAL(18,4),
  pack_weight                    DECIMAL(18,4),
  pack_volume                    DECIMAL(18,4),
  -- SCD2 tracking columns (scaffolding for Phase 2 - prevents breaking schema changes)
  effective_from                 TIMESTAMP,
  effective_to                   TIMESTAMP,
  is_current                     BOOLEAN,
  version_number                 INT
) USING DELTA
COMMENT 'Item master dimension. SCD2 columns declared but not actively tracked in POC.';

INSERT INTO dim_item (item_id, item_pk, profile_id, short_description, description, style_suffix,
                      display_uom_id, lpn_per_tier, tiers_per_pallet, unit_price, catch_weight_item, average_weight,
                      ext_gegl_department, ext_gegl_product_size, ext_gegl_dcxx_virtual_whse, ext_gegl_dc33_virtual_whse,
                      unit_height, unit_width, unit_length, unit_weight, unit_volume,
                      pack_height, pack_width, pack_length, pack_weight, pack_volume)
SELECT
  ite.item_id, ite.pk, ite.profile_id, ite.short_description, ite.description, ite.style_suffix,
  ite.display_uom_id, ite.lpn_per_tier, ite.tiers_per_pallet, ite.unit_price, ite.catch_weight_item, ite.average_weight,
  ite.ext_gegl_department, ite.ext_gegl_product_size, ite.ext_gegl_dcxx_virtual_whse, ite.ext_gegl_dc33_virtual_whse,
  ip1.height, ip1.width, ip1.length, ip1.weight, ip1.volume,
  ip2.height, ip2.width, ip2.length, ip2.weight, ip2.volume
FROM ge_poc.bronze.default_item_master_ite_item ite
LEFT JOIN (
  SELECT item_pk, height, width, length, weight, volume,
         ROW_NUMBER() OVER (PARTITION BY item_pk ORDER BY height) AS rn
  FROM ge_poc.bronze.default_item_master_ite_item_package
  WHERE standard_quantity_uom_id = 'UNIT' AND quantity = 1
) ip1 ON ite.pk = ip1.item_pk AND ip1.rn = 1
LEFT JOIN (
  SELECT item_pk, height, width, length, weight, volume,
         ROW_NUMBER() OVER (PARTITION BY item_pk ORDER BY height) AS rn
  FROM ge_poc.bronze.default_item_master_ite_item_package
  WHERE standard_quantity_uom_id = 'PACK' AND quantity = 1
) ip2 ON ite.pk = ip2.item_pk AND ip2.rn = 1
WHERE ite.__hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- dim_task_group
-- Replaces HBC_TASK_GROUP_DESC. Original is a hardcoded UNION ALL of constants
-- (task group description, transaction id, source zone id). Modeled as a static dim.
-- =====================================================================
CREATE OR REPLACE TABLE dim_task_group (
  task_group_sk                  BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  description                    STRING NOT NULL,
  task_group                     STRING NOT NULL,
  transaction_id                 STRING NOT NULL,
  source_zone_id                 STRING NOT NULL
) USING DELTA
COMMENT 'HBC task-group reference dimension. Static seed; replaces HBC_TASK_GROUP_DESC.';

-- Seed with a representative subset from the source UNION ALL. Reconcile against
-- the full list in HBC_TASK_GROUP_DESC.sql when productionalizing.
INSERT INTO dim_task_group (description, task_group, transaction_id, source_zone_id) VALUES
  ('119 - Aero Case Sel', '119', 'GEGL Aerosol Picking',          'H19'),
  ('119 - Aero Case Sel', '119', 'GEGL Aerosol Picking',          'H20'),
  ('119 - Aero Case Sel', '119', 'GG Aerosol Picking',            'H19'),
  ('119 - Aero Case Sel', '119', 'GG Aerosol Picking',            'H20'),
  ('200 - Cig Selection', '200', 'GEGL Picking From Each Pick',   'HCG'),
  ('200 - Kratom',        '200', 'GEGL Picking From Each Pick',   'HST'),
  ('200 - Cig Selection', '200', 'GG Picking from Each Pick',     'HCG'),
  ('200 - Kratom',        '200', 'GG Picking from Each Pick',     'HST');
-- TODO: extend with the remaining rows from HBC_TASK_GROUP_DESC source DDL.

-- =====================================================================
-- dim_location
-- =====================================================================
CREATE OR REPLACE TABLE dim_location (
  location_sk                    BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  location_id                    STRING NOT NULL,
  location_barcode               STRING,
  facility_id                    STRING,
  location_type                  STRING,
  aisle                          STRING,
  bay                            STRING,
  level                          STRING,
  is_active                      BOOLEAN
) USING DELTA;

INSERT INTO dim_location (location_id, location_barcode, facility_id, location_type, aisle, bay, level)
SELECT location_id, location_barcode, facility_id, location_type, aisle, bay, level
FROM ge_poc.bronze.default_dcinventory_dci_location
WHERE __hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- dim_date
-- =====================================================================
CREATE OR REPLACE TABLE dim_date (
  date_sk                        BIGINT NOT NULL,
  full_date                      DATE NOT NULL,
  day_of_week                    INT, day_name STRING,
  day_of_month                   INT, day_of_year INT, week_of_year INT,
  month_num                      INT, month_name STRING,
  quarter_num                    INT, year_num INT,
  is_weekend                     BOOLEAN
) USING DELTA;

INSERT INTO dim_date
SELECT
  cast(date_format(d, 'yyyyMMdd') AS BIGINT) AS date_sk, d AS full_date,
  dayofweek(d), date_format(d, 'EEEE'),
  day(d), dayofyear(d), weekofyear(d),
  month(d), date_format(d, 'MMMM'),
  quarter(d), year(d),
  (dayofweek(d) IN (1, 7))
FROM (SELECT explode(sequence(current_date() - INTERVAL 5 YEARS, current_date() + INTERVAL 1 YEAR, INTERVAL 1 DAY)) AS d);

-- =====================================================================
-- dim_adjustment_reason
-- =====================================================================
CREATE OR REPLACE TABLE dim_adjustment_reason (
  reason_sk                      BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  reason_code                    STRING NOT NULL,
  profile_id                     STRING,
  reason_description             STRING,
  category                       STRING,
  is_active                      BOOLEAN
) USING DELTA;

INSERT INTO dim_adjustment_reason (reason_code, profile_id, reason_description, category)
SELECT DISTINCT reason_code_id, profile_id, description, category
FROM ge_poc.bronze.default_inventory_management_inm_adjustment_reason_code
WHERE __hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- dim_carrier
-- =====================================================================
CREATE OR REPLACE TABLE dim_carrier (
  carrier_sk                     BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  carrier_id                     STRING NOT NULL,
  carrier_name                   STRING
) USING DELTA;

INSERT INTO dim_carrier (carrier_id, carrier_name)
SELECT carrier_id, description FROM ge_poc.bronze.default_carrier_car_carrier
WHERE __hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- dim_purchase_order (PO header reference dim, lightweight)
-- =====================================================================
CREATE OR REPLACE TABLE dim_purchase_order (
  purchase_order_sk              BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  purchase_order_id              STRING NOT NULL,
  org_id                         STRING,
  vendor_id                      STRING,
  status_id                      STRING,
  status_description             STRING
) USING DELTA;

INSERT INTO dim_purchase_order (purchase_order_id, org_id, vendor_id, status_id, status_description)
SELECT po.purchase_order_id, po.org_id, po.vendor_id, po.purchase_order_status, pos.description
FROM ge_poc.bronze.default_receiving_rcv_purchase_order po
LEFT JOIN ge_poc.bronze.default_receiving_rcv_purchase_order_status pos
  ON po.purchase_order_status = pos.purchase_order_status_id
WHERE po.__hevo__marked_deleted = 'FALSE';

SHOW TABLES IN gold_native;