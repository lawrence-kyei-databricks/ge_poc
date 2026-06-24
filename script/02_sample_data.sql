-- Databricks notebook source
-- =====================================================================
-- Giant Eagle: 02_sample_data.sql
-- Generates synthetic data using sequence-based generators so all 12 facts
-- have rows to load. Volumes chosen to be small enough to run on a Serverless
-- Small but large enough that liquid clustering and benchmarks produce signal.
--
-- Roughly:
--   ~10,000 items across all 8 BUs
--   ~50,000 inventory rows
--   ~250,000 PIX transactions (including SHIPCONFIRM / RECEIVING transaction types)
--   ~5,000 ASNs and lines
--   ~5,000 OLPNs and details
--   ~1,000 ILPNs
--   ~500 shipments
--   ~10,000 task completions
--
-- Adjust SCALE variable below to run smaller/larger.
-- =====================================================================

USE CATALOG ge_poc;

USE SCHEMA bronze;

-- ---------------------------------------------------------------------
-- Reason codes (small dim, real GE values, all profiles)
-- ---------------------------------------------------------------------
INSERT INTO default_inventory_management_inm_adjustment_reason_code
SELECT * FROM VALUES
  ('CC','D0001','Cycle Count Adjustment','AUDIT',     current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()),
  ('DD','D0001','Damaged / Destroyed','LOSS',         current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()),
  ('HB','D0001','Hold for Buyer','HOLD',              current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()),
  ('RC','D0001','Reclass / Recategorize','TRANSFER',  current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()),
  ('SR','D0001','Short Receipt','RECEIVING',          current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()),
  ('WM','D0001','Wrong Manifest','RECEIVING',         current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp());

-- Same set replicated for the other facilities (HBC/BICEPS/ASF/BRM/FFM/OKG/OKP)
INSERT INTO default_inventory_management_inm_adjustment_reason_code
SELECT 'CC', fac, 'Cycle Count Adjustment', 'AUDIT', current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()
FROM (SELECT explode(array('D0033','D0044','D0050','D0061','D0070','D0080','D0008')) AS fac);

INSERT INTO default_inventory_management_inm_adjustment_reason_code
SELECT 'DD', fac, 'Damaged / Destroyed', 'LOSS', current_timestamp(),current_timestamp(),current_timestamp(),current_timestamp(),'FALSE',current_timestamp()
FROM (SELECT explode(array('D0033','D0044','D0050','D0061','D0070','D0080','D0008')) AS fac);

-- ---------------------------------------------------------------------
-- Locations: 100 per facility across 14 facilities = ~1,400 rows
-- ---------------------------------------------------------------------
INSERT INTO default_dcinventory_dci_location (location_id, facility_id, profile_id, location_barcode, location_type, aisle, bay, level, __hevo__marked_deleted)
SELECT
  concat('LOC-', fac, '-', lpad(cast(loc_n AS STRING), 4, '0'))            AS location_id,
  fac                                                                       AS facility_id,
  fac                                                                       AS profile_id,
  concat('BC-', fac, '-', lpad(cast(loc_n AS STRING), 4, '0'))             AS location_barcode,
  CASE WHEN loc_n % 10 = 0 THEN 'STAGING'
       WHEN loc_n % 5 = 0  THEN 'RESERVE'
       ELSE 'PICK' END                                                      AS location_type,
  concat('A', cast(loc_n / 100 AS INT))                                     AS aisle,
  cast(((loc_n / 10) % 10) + 1 AS STRING)                                   AS bay,
  CASE WHEN loc_n % 3 = 0 THEN 'A' WHEN loc_n % 3 = 1 THEN 'B' ELSE 'C' END AS level,
  'FALSE'                                                                   AS __hevo__marked_deleted
FROM (
  SELECT exploded_fac AS fac, exploded_loc + 1 AS loc_n FROM (
    SELECT explode(array('D0001','D0008','D0033','D0044','D0050','D0061','D0070','D0080')) AS exploded_fac
  ) f
  CROSS JOIN (SELECT explode(sequence(0, 99)) AS exploded_loc)
);

-- ---------------------------------------------------------------------
-- Item master: ~10,000 items spread across the 8 BU facilities
-- ---------------------------------------------------------------------
INSERT INTO default_item_master_ite_item (pk, item_id, profile_id, short_description, description, long_description, style_suffix, display_uom_id, lpn_per_tier, tiers_per_pallet, unit_price, catch_weight_item, average_weight, ext_gegl_dcxx_virtual_whse, ext_gegl_dc33_virtual_whse, ext_gegl_department, ext_gegl_product_size, created_timestamp, updated_timestamp, __hevo__ingested_at, __hevo__loaded_at, __hevo__marked_deleted, __hevo__source_modified_at)
SELECT
  cast(item_n AS BIGINT)                                                                          AS pk,
  lpad(cast(100000 + item_n AS STRING), 6, '0')                                                   AS item_id,
  fac                                                                                              AS profile_id,
  concat('Item ', cast(item_n AS STRING), ' ', dept)                                              AS short_description,
  concat('Item ', cast(item_n AS STRING), ' ', dept, ' detailed description')                     AS description,
  concat('Item ', cast(item_n AS STRING), ' long description for ', dept)                         AS long_description,
  CASE WHEN item_n % 200 = 0 THEN '99' ELSE '01' END                                              AS style_suffix,
  CASE WHEN item_n % 3 = 0 THEN 'PACK' WHEN item_n % 3 = 1 THEN 'UNIT' ELSE 'LPN' END             AS display_uom_id,
  cast(8 + (item_n % 12) AS INT)                                                                  AS lpn_per_tier,
  cast(4 + (item_n % 8) AS INT)                                                                   AS tiers_per_pallet,
  cast(2.50 + (item_n % 50) AS DECIMAL(18,4))                                                     AS unit_price,
  CASE WHEN item_n % 7 = 0 THEN 'Y' ELSE 'N' END                                                  AS catch_weight_item,
  cast(0.5 + (item_n % 5) AS DECIMAL(18,4))                                                       AS average_weight,
  concat('DC', substring(fac, 4, 2), '-', cast(85 + (item_n % 3) AS STRING))                      AS ext_gegl_dcxx_virtual_whse,
  concat('DC33-', CASE WHEN item_n % 2 = 0 THEN 'AA' ELSE 'AB' END)                               AS ext_gegl_dc33_virtual_whse,
  dept                                                                                             AS ext_gegl_department,
  CASE WHEN item_n % 4 = 0 THEN 'SMALL' WHEN item_n % 4 = 1 THEN 'MEDIUM' WHEN item_n % 4 = 2 THEN 'LARGE' ELSE 'XL' END AS ext_gegl_product_size,
  current_timestamp() - cast((item_n % 365) AS INT) * INTERVAL 1 DAY,
  current_timestamp() - cast((item_n % 30) AS INT) * INTERVAL 1 DAY,
  current_timestamp(),
  current_timestamp(),
  'FALSE',
  current_timestamp()
FROM (
  SELECT
    f.exploded_fac AS fac,
    n.exploded_n + 1 AS item_n,
    CASE n.exploded_n % 6
      WHEN 0 THEN 'PHARMACY'
      WHEN 1 THEN 'GROCERY'
      WHEN 2 THEN 'PRODUCE'
      WHEN 3 THEN 'BEVERAGE'
      WHEN 4 THEN 'WELLNESS'
      ELSE 'FIRST_AID' END AS dept
  FROM (SELECT explode(array('D0001','D0008','D0033','D0044','D0050','D0061','D0070','D0080')) AS exploded_fac) f
  CROSS JOIN (SELECT explode(sequence(0, 1249)) AS exploded_n) n
);

-- Item packages: UNIT + PACK for each item = ~20,000 rows
INSERT INTO default_item_master_ite_item_package (item_pk, standard_quantity_uom_id, quantity, height, width, length, weight, volume, __hevo__marked_deleted)
SELECT pk, 'UNIT', 1,
  cast(0.5 + (pk % 5) AS DECIMAL(18,4)),
  cast(0.3 + (pk % 3) AS DECIMAL(18,4)),
  cast(0.4 + (pk % 4) AS DECIMAL(18,4)),
  cast(0.2 + (pk % 2) AS DECIMAL(18,4)),
  cast(0.06 + (pk % 5) * 0.01 AS DECIMAL(18,4)),
  'FALSE'
FROM default_item_master_ite_item;

INSERT INTO default_item_master_ite_item_package (item_pk, standard_quantity_uom_id, quantity, height, width, length, weight, volume, __hevo__marked_deleted)
SELECT pk, 'PACK', 12,
  cast(6 + (pk % 6) AS DECIMAL(18,4)),
  cast(4 + (pk % 4) AS DECIMAL(18,4)),
  cast(5 + (pk % 5) AS DECIMAL(18,4)),
  cast(3 + (pk % 3) AS DECIMAL(18,4)),
  cast(0.72 + (pk % 5) * 0.12 AS DECIMAL(18,4)),
  'FALSE'
FROM default_item_master_ite_item;

-- ---------------------------------------------------------------------
-- Inventory: ~50,000 rows (each item gets ~5 inventory rows on average across containers/locations)
-- ---------------------------------------------------------------------
INSERT INTO default_dcinventory_dci_inventory (inventory_id, item_id, org_id, facility_id, location_id, inventory_container_id, inventory_container_type_id, on_hand, allocated, to_be_filled, is_in_transit, inventory_attribute1, created_timestamp, updated_timestamp, __hevo__loaded_at, __hevo__marked_deleted)
SELECT
  concat('INV-', i.item_id, '-', cast(c.n AS STRING))                                               AS inventory_id,
  i.item_id, i.profile_id,
  i.profile_id                                                                                       AS facility_id,
  concat('LOC-', i.profile_id, '-', lpad(cast((i.pk + c.n) % 100 AS STRING), 4, '0'))                AS location_id,
  concat('CON-', i.item_id, '-', cast(c.n AS STRING))                                                AS inventory_container_id,
  CASE c.n WHEN 0 THEN 'LOCATION' WHEN 1 THEN 'ILPN' WHEN 2 THEN 'LOCATION' WHEN 3 THEN 'OLPN' ELSE 'LOCATION' END AS inventory_container_type_id,
  cast(50 + (i.pk + c.n * 7) % 500 AS DECIMAL(18,4))                                                 AS on_hand,
  cast((i.pk + c.n * 3) % 50 AS DECIMAL(18,4))                                                       AS allocated,
  cast((i.pk + c.n) % 20 AS DECIMAL(18,4))                                                           AS to_be_filled,
  '0'                                                                                                AS is_in_transit,
  concat('LOT-', substring(i.item_id, 4, 3), '-', cast(c.n AS STRING))                               AS inventory_attribute1,
  current_timestamp() - cast(((i.pk + c.n) % 30) AS INT) * INTERVAL 1 DAY,
  current_timestamp() - cast(((i.pk + c.n) % 7) AS INT) * INTERVAL 1 HOUR,
  current_timestamp(),
  'FALSE'
FROM default_item_master_ite_item i
CROSS JOIN (SELECT explode(sequence(0, 4)) AS n) c
WHERE i.pk % 2 = 0;

-- Add a second pass for the other half so all items have at least some inventory
INSERT INTO default_dcinventory_dci_inventory (inventory_id, item_id, org_id, facility_id, location_id, inventory_container_id, inventory_container_type_id, on_hand, allocated, to_be_filled, is_in_transit, inventory_attribute1, created_timestamp, updated_timestamp, __hevo__loaded_at, __hevo__marked_deleted)
SELECT
  concat('INV2-', i.item_id, '-', cast(c.n AS STRING))                                              AS inventory_id,
  i.item_id, i.profile_id, i.profile_id,
  concat('LOC-', i.profile_id, '-', lpad(cast((i.pk + c.n + 50) % 100 AS STRING), 4, '0')),
  concat('CON2-', i.item_id, '-', cast(c.n AS STRING)),
  CASE c.n WHEN 0 THEN 'LOCATION' WHEN 1 THEN 'ILPN' ELSE 'LOCATION' END,
  cast(20 + (i.pk + c.n * 11) % 200 AS DECIMAL(18,4)),
  cast((i.pk + c.n) % 30 AS DECIMAL(18,4)),
  cast((i.pk + c.n) % 10 AS DECIMAL(18,4)),
  '0',
  concat('LOT2-', substring(i.item_id, 4, 3)),
  current_timestamp(),
  current_timestamp(),
  current_timestamp(),
  'FALSE'
FROM default_item_master_ite_item i
CROSS JOIN (SELECT explode(sequence(0, 2)) AS n) c
WHERE i.pk % 2 = 1;

-- ---------------------------------------------------------------------
-- PIX entries: ~250K transactions over the past 90 days, with realistic
-- distribution of source_transaction_type (so v_ge_cs_transaction_dtl has rows)
-- ---------------------------------------------------------------------
INSERT INTO default_pix_pix_pix_entry
SELECT
  concat('PIX-', cast(row_n AS STRING))                                                                                         AS pix_entry_id,
  i.item_id, i.profile_id,
  i.description,
  cast(1 + (row_n % 50) AS DECIMAL(18,4))                                                                                       AS quantity,
  CASE row_n % 3 WHEN 0 THEN 'SUBTRACT' ELSE 'ADD' END                                                                          AS adjusted_type,
  CASE row_n % 6 WHEN 0 THEN 'CC' WHEN 1 THEN 'DD' WHEN 2 THEN 'HB' WHEN 3 THEN 'RC' WHEN 4 THEN 'SR' ELSE 'WM' END             AS reason_code_id,
  CASE row_n % 4
    WHEN 0 THEN 'SHIPCONFIRM'
    WHEN 1 THEN 'RECEIVING'
    WHEN 2 THEN 'CYCLE_COUNT'
    ELSE 'ADJUSTMENT' END                                                                                                       AS source_transaction_type,
  CASE WHEN row_n % 5 = 0 THEN '' ELSE concat('PO-', cast(row_n % 1000 AS STRING)) END                                          AS purchase_order_id,
  CASE WHEN row_n % 5 = 0 THEN '' ELSE concat('POL-', cast(row_n % 5000 AS STRING)) END                                         AS purchase_order_line_id,
  concat('LOT-', cast(row_n % 100 AS STRING))                                                                                   AS inventory_attribute1,
  CASE row_n % 4 WHEN 0 THEN 'Shipment' WHEN 1 THEN 'Receipt' WHEN 2 THEN 'CycleCount' ELSE 'InventoryAdjustment' END           AS grouping_tag,
  concat('SB-', cast(row_n % 1000 AS STRING))                                                                                   AS sync_batch_id,
  concat('user_', cast(row_n % 50 AS STRING))                                                                                   AS created_by,
  concat('user_', cast(row_n % 50 AS STRING))                                                                                   AS updated_by,
  current_timestamp() - cast((row_n % 90) AS INT) * INTERVAL 1 DAY - cast((row_n % 24) AS INT) * INTERVAL 1 HOUR                AS created_timestamp,
  current_timestamp() - cast((row_n % 90) AS INT) * INTERVAL 1 DAY - cast((row_n % 24) AS INT) * INTERVAL 1 HOUR                AS updated_timestamp,
  current_timestamp(),
  'FALSE'
FROM (
  SELECT i.*, r.exploded AS row_n
  FROM default_item_master_ite_item i
  CROSS JOIN (SELECT explode(sequence(0, 24)) AS exploded) r   -- 25 transactions per item = ~250K
) i;

-- ---------------------------------------------------------------------
-- Receiving: ~5,000 ASNs with lines
-- ---------------------------------------------------------------------
INSERT INTO default_receiving_rcv_asn (asn_id, org_id, purchase_order_id, asn_status, created_timestamp, updated_timestamp, __hevo__marked_deleted)
SELECT
  concat('ASN-', cast(n AS STRING))                                                                AS asn_id,
  CASE WHEN n % 8 = 0 THEN 'D0001' WHEN n % 8 = 1 THEN 'D0008' WHEN n % 8 = 2 THEN 'D0033'
       WHEN n % 8 = 3 THEN 'D0044' WHEN n % 8 = 4 THEN 'D0050' WHEN n % 8 = 5 THEN 'D0061'
       WHEN n % 8 = 6 THEN 'D0070' ELSE 'D0080' END                                                 AS org_id,
  concat('PO-', cast(n % 500 AS STRING))                                                            AS purchase_order_id,
  CASE n % 4 WHEN 0 THEN 'OPEN' WHEN 1 THEN 'RECEIVING' WHEN 2 THEN 'CLOSED' ELSE 'CANCELLED' END   AS asn_status,
  current_timestamp() - cast((n % 60) AS INT) * INTERVAL 1 DAY,
  current_timestamp() - cast((n % 60) AS INT) * INTERVAL 1 DAY + INTERVAL 4 HOURS,
  'FALSE'
FROM (SELECT explode(sequence(1, 5000)) AS n);

INSERT INTO default_receiving_rcv_asn_line (asn_id, asn_line_id, item_id, ordered_quantity, received_quantity, __hevo__marked_deleted)
SELECT
  a.asn_id, concat(a.asn_id, '-L', cast(l.n AS STRING)),
  lpad(cast(100000 + ((cast(substring(a.asn_id, 5) AS BIGINT) + l.n) % 10000) AS STRING), 6, '0'),
  cast(100 + l.n * 10 AS DECIMAL(18,4)),
  cast(80  + l.n * 8  AS DECIMAL(18,4)),
  'FALSE'
FROM default_receiving_rcv_asn a
CROSS JOIN (SELECT explode(sequence(1, 3)) AS n) l;

-- Purchase orders
INSERT INTO default_receiving_rcv_purchase_order (purchase_order_id, org_id, purchase_order_status, vendor_id, __hevo__marked_deleted)
SELECT
  concat('PO-', cast(n AS STRING)),
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  CASE n % 4 WHEN 0 THEN '10' WHEN 1 THEN '20' WHEN 2 THEN '30' ELSE '40' END,
  concat('VENDOR-', cast(n % 100 AS STRING)),
  'FALSE'
FROM (SELECT explode(sequence(1, 500)) AS n);

INSERT INTO default_receiving_rcv_purchase_order_status VALUES
  ('10', 'Open'), ('20', 'Acknowledged'), ('30', 'Shipped'), ('40', 'Received'), ('50', 'Closed');

INSERT INTO default_receiving_rcv_purchase_order_line
SELECT po.purchase_order_id, concat(po.purchase_order_id, '-L', cast(l.n AS STRING)),
  lpad(cast(100000 + (cast(substring(po.purchase_order_id, 4) AS BIGINT) * 7 + l.n) % 10000 AS STRING), 6, '0'),
  cast(50 + l.n * 5 AS DECIMAL(18,4)),
  'FALSE'
FROM default_receiving_rcv_purchase_order po
CROSS JOIN (SELECT explode(sequence(1, 3)) AS n) l;

-- ---------------------------------------------------------------------
-- OLPNs (outbound license plates): 5,000 OLPNs + details
-- ---------------------------------------------------------------------
INSERT INTO default_pickpack_ppk_olpn (olpn_id, org_id, status, facility_id, destination_facility_id, order_planning_run_id, ext_pharmacy_routeid, ext_pharmacy_stop_id, created_timestamp, __hevo__marked_deleted)
SELECT
  concat('OLPN-', cast(n AS STRING)),
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  CASE n % 4 WHEN 0 THEN '8000' WHEN 1 THEN '7000' WHEN 2 THEN '6000' ELSE '5000' END,
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  concat('STORE-', cast(n % 200 AS STRING)),
  concat('PR-', cast(n % 100 AS STRING)),
  concat('RT-', cast(n % 50 AS STRING)),
  cast(n % 30 AS STRING),
  current_timestamp() - cast((n % 30) AS INT) * INTERVAL 1 DAY,
  'FALSE'
FROM (SELECT explode(sequence(1, 5000)) AS n);

INSERT INTO default_pickpack_ppk_olpn_detail (olpn_id, org_id, item_id, order_id, order_line_id, packed_quantity, facility_id, facility_address_address1, facility_address_address2, facility_address_city, facility_address_state, facility_address_postalcode, appl_code, status, created_timestamp, ext_pharmacy_routeid, ext_pharmacy_stop_id, __hevo__marked_deleted)
SELECT
  o.olpn_id, o.org_id,
  lpad(cast(100000 + (cast(substring(o.olpn_id, 6) AS BIGINT) * 13 + l.n) % 10000 AS STRING), 6, '0'),
  concat('ORD-', cast(cast(substring(o.olpn_id, 6) AS BIGINT) % 1000 AS STRING)),
  concat('OL-', cast(l.n AS STRING)),
  cast(10 + l.n * 2 AS DECIMAL(18,4)),
  o.destination_facility_id,
  concat(cast(100 + (cast(substring(o.olpn_id, 6) AS BIGINT) % 9000) AS STRING), ' Main St'),
  NULL,
  CASE cast(substring(o.olpn_id, 6) AS BIGINT) % 4 WHEN 0 THEN 'Pittsburgh' WHEN 1 THEN 'Cleveland' WHEN 2 THEN 'Erie' ELSE 'Akron' END,
  CASE cast(substring(o.olpn_id, 6) AS BIGINT) % 4 WHEN 0 THEN 'PA' WHEN 1 THEN 'OH' WHEN 2 THEN 'PA' ELSE 'OH' END,
  lpad(cast(15000 + cast(substring(o.olpn_id, 6) AS BIGINT) % 5000 AS STRING), 5, '0'),
  'WM',
  o.status,
  o.created_timestamp,
  o.ext_pharmacy_routeid,
  o.ext_pharmacy_stop_id,
  'FALSE'
FROM default_pickpack_ppk_olpn o
CROSS JOIN (SELECT explode(sequence(1, 2)) AS n) l;

-- ---------------------------------------------------------------------
-- ILPNs (inbound license plates): 1,000 ILPNs
-- ---------------------------------------------------------------------
INSERT INTO default_dcinventory_dci_ilpn
SELECT
  concat('ILPN-', cast(n AS STRING)),
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  concat('ASN-', cast(n % 5000 + 1 AS STRING)),
  concat('PO-', cast(n % 500 + 1 AS STRING)),
  concat('LOC-D0080-', lpad(cast(n % 100 AS STRING), 4, '0')),
  concat('LOC-D0080-', lpad(cast((n + 1) % 100 AS STRING), 4, '0')),
  concat('LOC-D0080-', lpad(cast((n + 2) % 100 AS STRING), 4, '0')),
  CASE n % 4 WHEN 0 THEN '1000' WHEN 1 THEN '9000' WHEN 2 THEN '5000' ELSE '8000' END,
  current_timestamp() + INTERVAL 90 DAYS,
  current_timestamp() - cast((n % 14) AS INT) * INTERVAL 1 DAY,
  current_timestamp() - cast((n % 7) AS INT) * INTERVAL 1 HOUR,
  concat('user_', cast(n % 50 AS STRING)),
  'FALSE'
FROM (SELECT explode(sequence(1, 1000)) AS n);

-- ---------------------------------------------------------------------
-- Shipments + transportation
-- ---------------------------------------------------------------------
INSERT INTO default_carrier_car_carrier VALUES
  ('CAR-001', 'Atlas Freight',     'FALSE'),
  ('CAR-002', 'Penske Logistics',  'FALSE'),
  ('CAR-003', 'Werner Enterprises','FALSE'),
  ('CAR-004', 'Ryder',             'FALSE'),
  ('CAR-005', 'XPO Logistics',     'FALSE');

INSERT INTO default_shipment_shp_shipment (pk, shipment_id, org_id, origin_planned_arr_start_dttm, climate_control_id, planned_size1_value, ass_carrier_id, __hevo__marked_deleted)
SELECT
  cast(n AS BIGINT),
  concat('SHIP-', cast(n AS STRING)),
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  current_timestamp() + cast((n % 7) AS INT) * INTERVAL 1 DAY,
  CASE n % 3 WHEN 0 THEN 'AMBIENT' WHEN 1 THEN 'REFRIGERATED' ELSE 'FROZEN' END,
  cast(20 + (n % 24) AS DECIMAL(18,4)),
  concat('CAR-', lpad(cast(((n % 5) + 1) AS STRING), 3, '0')),
  'FALSE'
FROM (SELECT explode(sequence(1, 500)) AS n);

-- ---------------------------------------------------------------------
-- Facility master
-- ---------------------------------------------------------------------
INSERT INTO default_facility_fac_facility VALUES
  ('D0001', 'OK Grocery Distribution Center',         '1 Distribution Way', 'Pittsburgh',  'PA', '15203', 'FALSE'),
  ('D0008', 'OK Grocery Annex',                       '2 Annex Rd',         'Pittsburgh',  'PA', '15203', 'FALSE'),
  ('D0033', 'BICEPS Main',                            '33 BICEPS Pkwy',     'Pittsburgh',  'PA', '15238', 'FALSE'),
  ('D0044', 'OK Produce',                             '44 Produce Ln',      'Pittsburgh',  'PA', '15116', 'FALSE'),
  ('D0050', 'BRM Beverage',                           '50 Beverage Dr',     'Pittsburgh',  'PA', '15205', 'FALSE'),
  ('D0061', 'ASF Seafood',                            '61 Seafood Ave',     'Cleveland',   'OH', '44144', 'FALSE'),
  ('D0070', 'FFM Fresh',                              '70 Fresh St',        'Pittsburgh',  'PA', '15212', 'FALSE'),
  ('D0080', 'HBC Pharmacy / Health and Beauty',       '80 Pharmacy Blvd',   'Pittsburgh',  'PA', '15233', 'FALSE');

-- ---------------------------------------------------------------------
-- Tasks + task details
-- ---------------------------------------------------------------------
INSERT INTO default_task_tsk_task
SELECT
  concat('TSK-', cast(n AS STRING)),
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  CASE n % 3 WHEN 0 THEN 'PICK' WHEN 1 THEN 'REPLENISHMENT' ELSE 'PUT_AWAY' END,
  CASE n % 4 WHEN 0 THEN 'COMPLETED' WHEN 1 THEN 'IN_PROGRESS' WHEN 2 THEN 'CREATED' ELSE 'CANCELLED' END,
  current_timestamp() - cast((n % 14) AS INT) * INTERVAL 1 DAY,
  current_timestamp(),
  'FALSE'
FROM (SELECT explode(sequence(1, 10000)) AS n);

-- ---------------------------------------------------------------------
-- GE_CS_INVN_CONTROL mock with multiple recent analysis windows
-- ---------------------------------------------------------------------
INSERT INTO ge_cs_invn_control
SELECT
  n,
  CASE n % 8 WHEN 0 THEN 'D0001' WHEN 1 THEN 'D0033' WHEN 2 THEN 'D0044' WHEN 3 THEN 'D0050'
             WHEN 4 THEN 'D0061' WHEN 5 THEN 'D0070' WHEN 6 THEN 'D0080' ELSE 'D0008' END,
  current_date() - cast(n AS INT),
  current_timestamp() - cast(n AS INT) * INTERVAL 1 DAY - INTERVAL 8 HOURS,
  current_timestamp() - cast(n AS INT) * INTERVAL 1 DAY,
  concat('SESSION-', cast(n AS STRING))
FROM (SELECT explode(sequence(1, 30)) AS n);

-- ---------------------------------------------------------------------
-- Row count sanity check
-- ---------------------------------------------------------------------
SELECT 'item_master'      AS tbl, count(*) AS rows FROM default_item_master_ite_item
UNION ALL SELECT 'item_package',     count(*) FROM default_item_master_ite_item_package
UNION ALL SELECT 'inventory',        count(*) FROM default_dcinventory_dci_inventory
UNION ALL SELECT 'location',         count(*) FROM default_dcinventory_dci_location
UNION ALL SELECT 'ilpn',             count(*) FROM default_dcinventory_dci_ilpn
UNION ALL SELECT 'pix_entry',        count(*) FROM default_pix_pix_pix_entry
UNION ALL SELECT 'asn',              count(*) FROM default_receiving_rcv_asn
UNION ALL SELECT 'asn_line',         count(*) FROM default_receiving_rcv_asn_line
UNION ALL SELECT 'purchase_order',   count(*) FROM default_receiving_rcv_purchase_order
UNION ALL SELECT 'po_line',          count(*) FROM default_receiving_rcv_purchase_order_line
UNION ALL SELECT 'olpn',             count(*) FROM default_pickpack_ppk_olpn
UNION ALL SELECT 'olpn_detail',      count(*) FROM default_pickpack_ppk_olpn_detail
UNION ALL SELECT 'shipment',         count(*) FROM default_shipment_shp_shipment
UNION ALL SELECT 'task',             count(*) FROM default_task_tsk_task
UNION ALL SELECT 'reason_code',      count(*) FROM default_inventory_management_inm_adjustment_reason_code
UNION ALL SELECT 'invn_control',     count(*) FROM ge_cs_invn_control
UNION ALL SELECT 'facility',         count(*) FROM default_facility_fac_facility
UNION ALL SELECT 'carrier',          count(*) FROM default_carrier_car_carrier
ORDER BY rows DESC;