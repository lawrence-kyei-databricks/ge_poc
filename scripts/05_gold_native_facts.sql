-- =====================================================================
-- Giant Eagle POC: 05_gold_native_facts.sql
-- VERSION B (lakehouse-native), part 2: CONFORMED FACTS
-- 12 fact tables covering the full domain space of the 51 Snowflake views.
-- All clustered on (facility_sk, date_sk) for predicate pushdown.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_native;

-- =====================================================================
-- fact_inventory_snapshot
-- Daily inventory snapshot, replaces all *_IROO_V and *_ITEM_SNAPSHOT_V patterns.
-- Business unit becomes a column, not a view-name suffix.
-- =====================================================================
CREATE OR REPLACE TABLE fact_inventory_snapshot (
  inventory_snapshot_sk          BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT NOT NULL,
  location_sk                    BIGINT,
  business_unit_sk               BIGINT,
  date_sk                        BIGINT NOT NULL,
  inventory_container_type_id    STRING,
  on_hand_qty                    DECIMAL(18,4),
  allocated_qty                  DECIMAL(18,4),
  available_qty                  DECIMAL(18,4),
  to_be_filled_qty               DECIMAL(18,4),
  outside_staging_qty            DECIMAL(18,4),
  pick_location_qty              DECIMAL(18,4),
  ilpn_qty                       DECIMAL(18,4),
  has_inventory                  BOOLEAN,
  snapshot_taken_at              TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Daily inventory snapshot fact. Source of truth for IROO, QROO snapshot, ITEM_SNAPSHOT views.';

INSERT INTO fact_inventory_snapshot (item_sk, facility_sk, location_sk, business_unit_sk, date_sk,
  inventory_container_type_id, on_hand_qty, allocated_qty, available_qty, to_be_filled_qty,
  outside_staging_qty, pick_location_qty, ilpn_qty, has_inventory, snapshot_taken_at)
SELECT
  di.item_sk, df.facility_sk, dl.location_sk, dbu.business_unit_sk,
  cast(date_format(current_date(), 'yyyyMMdd') AS BIGINT),
  dci.inventory_container_type_id,
  sum(dci.on_hand),
  sum(dci.allocated),
  sum(dci.on_hand) - sum(dci.allocated),
  sum(dci.to_be_filled),
  sum(CASE WHEN dl.location_type = 'STAGING' THEN dci.on_hand ELSE 0 END),
  sum(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN dci.on_hand ELSE 0 END),
  sum(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN dci.on_hand ELSE 0 END),
  (sum(dci.on_hand) > 0),
  current_timestamp()
FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
JOIN dim_item     di  ON dci.item_id = di.item_id
JOIN dim_facility df  ON dci.org_id  = df.facility_id
LEFT JOIN dim_location      dl  ON dci.location_id = dl.location_id
LEFT JOIN dim_business_unit dbu ON df.business_unit_code = dbu.business_unit_code
WHERE dci.__hevo__marked_deleted = 'FALSE'
  AND dci.is_in_transit = '0'
GROUP BY di.item_sk, df.facility_sk, dl.location_sk, dbu.business_unit_sk, dci.inventory_container_type_id;

-- =====================================================================
-- fact_inventory_transaction
-- Every PIX entry. Replaces *_QROO_V transaction aggregates.
-- Adjustments, receipts, shipments — everything that moves quantity.
-- =====================================================================
CREATE OR REPLACE TABLE fact_inventory_transaction (
  transaction_sk                 BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  pix_entry_id                   STRING NOT NULL,
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT NOT NULL,
  date_sk                        BIGINT NOT NULL,
  reason_sk                      BIGINT,
  source_transaction_type        STRING,
  grouping_tag                   STRING,
  quantity                       DECIMAL(18,4),
  signed_quantity                DECIMAL(18,4),
  purchase_order_id              STRING,
  purchase_order_line_id         STRING,
  inventory_attribute1           STRING,
  user_id                        STRING,
  created_at_utc                 TIMESTAMP,
  created_at_local               TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Every PIX transaction. Adjustments, receipts, shipments. Replaces *_QROO_V transaction patterns.';

INSERT INTO fact_inventory_transaction (pix_entry_id, item_sk, facility_sk, date_sk, reason_sk,
  source_transaction_type, grouping_tag, quantity, signed_quantity,
  purchase_order_id, purchase_order_line_id, inventory_attribute1, user_id, created_at_utc, created_at_local)
SELECT
  px.pix_entry_id, di.item_sk, df.facility_sk,
  cast(date_format(px.created_timestamp, 'yyyyMMdd') AS BIGINT),
  dar.reason_sk,
  px.source_transaction_type, px.grouping_tag,
  px.quantity,
  CASE px.adjusted_type WHEN 'SUBTRACT' THEN px.quantity * -1 ELSE px.quantity END,
  px.purchase_order_id, px.purchase_order_line_id, px.inventory_attribute1,
  coalesce(px.created_by, px.updated_by),
  px.created_timestamp,
  from_utc_timestamp(px.created_timestamp, 'America/New_York')
FROM ge_poc.bronze.default_pix_pix_pix_entry px
JOIN dim_item     di  ON px.item_id = di.item_id
JOIN dim_facility df  ON px.org_id  = df.facility_id
LEFT JOIN dim_adjustment_reason dar ON px.reason_code_id = dar.reason_code AND dar.profile_id = px.org_id
WHERE px.__hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- fact_inventory_adjustment
-- Adjustment-specific subset of transactions. View on top of fact_inventory_transaction
-- pre-filtered by grouping_tag = 'InventoryAdjustment'.
-- =====================================================================
CREATE OR REPLACE VIEW fact_inventory_adjustment
COMMENT 'Adjustments-only subset of fact_inventory_transaction.'
AS
SELECT * FROM fact_inventory_transaction WHERE grouping_tag = 'InventoryAdjustment';

-- =====================================================================
-- fact_cycle_count_adjustment
-- Cycle count specific. Filtered by reason codes in (CC, DD, HB, RC, SR, WM) and
-- joined to the GE invn_control analysis window.
-- =====================================================================
CREATE OR REPLACE TABLE fact_cycle_count_adjustment (
  cycle_count_sk                 BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  pix_entry_id                   STRING NOT NULL,
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT NOT NULL,
  date_sk                        BIGINT NOT NULL,
  reason_sk                      BIGINT,
  adjustment_qty                 DECIMAL(18,4),
  user_id                        STRING,
  count_session_id               STRING,
  inventory_attribute1           STRING,
  created_at_utc                 TIMESTAMP,
  created_at_local               TIMESTAMP,
  modified_at_utc                TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Cycle count audit detail. Filtered to cycle-count reason codes within the invn_control analysis window.';

INSERT INTO fact_cycle_count_adjustment (pix_entry_id, item_sk, facility_sk, date_sk, reason_sk,
  adjustment_qty, user_id, count_session_id, inventory_attribute1, created_at_utc, created_at_local, modified_at_utc)
SELECT
  px.pix_entry_id, di.item_sk, df.facility_sk,
  cast(date_format(px.created_timestamp, 'yyyyMMdd') AS BIGINT),
  dar.reason_sk,
  CASE px.adjusted_type WHEN 'SUBTRACT' THEN px.quantity * -1 ELSE px.quantity END,
  coalesce(px.created_by, px.updated_by),
  gcic.cycle_count_session_id,
  px.inventory_attribute1,
  px.created_timestamp,
  from_utc_timestamp(px.created_timestamp, 'America/New_York'),
  px.updated_timestamp
FROM ge_poc.bronze.default_pix_pix_pix_entry px
JOIN dim_item     di  ON px.item_id = di.item_id
JOIN dim_facility df  ON px.org_id  = df.facility_id
LEFT JOIN dim_adjustment_reason dar ON px.reason_code_id = dar.reason_code AND dar.profile_id = px.org_id
LEFT JOIN ge_poc.bronze.ge_cs_invn_control gcic
  ON gcic.facility_id = df.facility_id
  AND from_utc_timestamp(px.created_timestamp, 'America/New_York')
        BETWEEN gcic.analysis_start_date_time AND gcic.analysis_end_date_time
WHERE px.__hevo__marked_deleted = 'FALSE'
  AND px.reason_code_id IN ('CC', 'DD', 'HB', 'RC', 'SR', 'WM');

-- =====================================================================
-- fact_inventory_daily_total
-- Pre-aggregated daily on-hand totals. Replaces GE_CS_INVN_DLY_TOTAL_V.
-- =====================================================================
CREATE OR REPLACE TABLE fact_inventory_daily_total (
  daily_total_sk                 BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT NOT NULL,
  date_sk                        BIGINT NOT NULL,
  total_on_hand                  DECIMAL(18,4),
  snapshot_taken_at              TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Daily aggregated on-hand totals. Pre-computed daily snapshot for warehouse totals reporting.';

-- Join from inventory (not dim_item) so we aggregate over every facility the item has stock in,
-- not just each item's home profile_id facility. Prior version only counted home-facility inventory.
INSERT INTO fact_inventory_daily_total (item_sk, facility_sk, date_sk, total_on_hand, snapshot_taken_at)
SELECT
  di.item_sk,
  df.facility_sk,
  cast(date_format(current_date(), 'yyyyMMdd') AS BIGINT),
  coalesce(sum(dci.on_hand), 0),
  current_timestamp()
FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
JOIN dim_item     di ON dci.item_id = di.item_id
JOIN dim_facility df ON dci.org_id  = df.facility_id
WHERE dci.is_in_transit = '0'
  AND dci.__hevo__marked_deleted = 'FALSE'
  AND dci.inventory_container_type_id IN ('ILPN', 'LOCATION', 'OLPN')
  AND coalesce(di.style_suffix, '01') != '99'
GROUP BY di.item_sk, df.facility_sk;

-- =====================================================================
-- fact_receiving_event
-- Receiving lifecycle: ASN, PO, receipt. Covers ITEM_FIRST_RCPT and others.
-- =====================================================================
CREATE OR REPLACE TABLE fact_receiving_event (
  receiving_event_sk             BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  asn_id                         STRING,
  asn_line_id                    STRING,
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT,
  purchase_order_sk              BIGINT,
  date_sk                        BIGINT NOT NULL,
  ordered_qty                    DECIMAL(18,4),
  received_qty                   DECIMAL(18,4),
  short_qty                      DECIMAL(18,4),
  received_at_utc                TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Receiving lifecycle events. ASN line grain.';

INSERT INTO fact_receiving_event (asn_id, asn_line_id, item_sk, facility_sk, purchase_order_sk,
  date_sk, ordered_qty, received_qty, short_qty, received_at_utc)
SELECT
  asn.asn_id, asnl.asn_line_id,
  di.item_sk, df.facility_sk, dpo.purchase_order_sk,
  cast(date_format(asn.updated_timestamp, 'yyyyMMdd') AS BIGINT),
  asnl.ordered_quantity, asnl.received_quantity,
  asnl.ordered_quantity - coalesce(asnl.received_quantity, 0),
  asn.updated_timestamp
FROM ge_poc.bronze.default_receiving_rcv_asn asn
JOIN ge_poc.bronze.default_receiving_rcv_asn_line asnl
  ON asn.asn_id = asnl.asn_id
JOIN dim_item     di  ON asnl.item_id = di.item_id
LEFT JOIN dim_facility df  ON asn.org_id = df.facility_id
LEFT JOIN dim_purchase_order dpo ON asn.purchase_order_id = dpo.purchase_order_id
WHERE asn.__hevo__marked_deleted = 'FALSE'
  AND asnl.__hevo__marked_deleted = 'FALSE';

-- =====================================================================
-- fact_pickpack_event
-- Outbound pick/pack at OLPN-detail grain.
-- =====================================================================
CREATE OR REPLACE TABLE fact_pickpack_event (
  pickpack_event_sk              BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  olpn_id                        STRING NOT NULL,
  item_sk                        BIGINT NOT NULL,
  facility_sk                    BIGINT,
  date_sk                        BIGINT NOT NULL,
  order_id                       STRING,
  order_line_id                  STRING,
  packed_qty                     DECIMAL(18,4),
  status                         STRING,
  destination_facility_id        STRING,
  destination_address_state      STRING,
  destination_address_city       STRING,
  created_at                     TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Outbound pick/pack events. OLPN-detail grain.';

-- (INSERT deferred until sample OLPN data is loaded)

-- =====================================================================
-- fact_ilpn_lifecycle
-- ILPN (inbound LPN) lifecycle. Covers PSE_CASE_V pattern.
-- =====================================================================
CREATE OR REPLACE TABLE fact_ilpn_lifecycle (
  ilpn_event_sk                  BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  ilpn_id                        STRING NOT NULL,
  facility_sk                    BIGINT,
  item_sk                        BIGINT,
  date_sk                        BIGINT NOT NULL,
  asn_id                         STRING,
  purchase_order_id              STRING,
  current_location_id            STRING,
  previous_location_id           STRING,
  destination_location_id        STRING,
  ch_stat_code                   STRING,
  status                         STRING,
  on_hand_qty                    DECIMAL(18,4),
  received_at                    TIMESTAMP,
  updated_at                     TIMESTAMP,
  updated_by                     STRING
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'ILPN (inbound license plate) lifecycle. Replaces PSE_CASE_V style reporting.';

-- =====================================================================
-- fact_pharmacy_transport
-- HBC pharmacy controlled-substance transport. Replaces HBC_PHARMACY_TRANSPORTION_*_V.
-- OH = On Hand variant, PA = Picked/Allocated variant via transport_variant column.
-- =====================================================================
CREATE OR REPLACE TABLE fact_pharmacy_transport (
  pharmacy_transport_sk          BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  transport_variant              STRING,                 -- 'OH' or 'PA'
  olpn_id                        STRING,
  item_sk                        BIGINT,
  facility_sk                    BIGINT,
  date_sk                        BIGINT NOT NULL,
  destination_facility_id        STRING,
  destination_address_address1   STRING,
  destination_address_city       STRING,
  destination_address_state      STRING,
  destination_postalcode         STRING,
  appl_code                      STRING,
  ext_pharmacy_routeid           STRING,
  ext_pharmacy_stop_id           STRING,
  run_date                       DATE,
  created_at                     TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'HBC pharmacy controlled-substance transport. Regulatory-sensitive.';

-- =====================================================================
-- fact_transportation_shipment
-- Outbound shipment header. Replaces V_LOAD_SHEETS shipment header portion.
-- =====================================================================
CREATE OR REPLACE TABLE fact_transportation_shipment (
  shipment_sk                    BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  shipment_id                    STRING NOT NULL,
  origin_facility_sk             BIGINT,
  destination_facility_id        STRING,
  carrier_sk                     BIGINT,
  date_sk                        BIGINT NOT NULL,
  transportation_order_id        STRING,
  pickup_start_dttm              TIMESTAMP,
  product_class                  STRING,
  protection_level               STRING,
  planned_volume                 DECIMAL(18,4),
  pallets_on_shipment            DECIMAL(18,4),
  loading_sequence               INT,
  position_code                  STRING                   -- 'NOSE', 'TAIL', or ''
)
USING DELTA
CLUSTER BY (origin_facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Outbound transportation shipments. Replaces V_LOAD_SHEETS header.';

-- =====================================================================
-- fact_load_sheet
-- Load sheet line items. V_LOAD_SHEETS detail portion + V_GESC_CLOSED_LOADS.
-- =====================================================================
CREATE OR REPLACE TABLE fact_load_sheet (
  load_sheet_sk                  BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  shipment_sk                    BIGINT,
  shipment_id                    STRING NOT NULL,
  item_sk                        BIGINT,
  order_id                       STRING,
  order_seg_id                   STRING,
  stop_sequence                  INT,
  ship_qty                       DECIMAL(18,4),
  order_qty                      DECIMAL(18,4),
  pallets                        DECIMAL(18,4),
  date_sk                        BIGINT NOT NULL
)
USING DELTA
CLUSTER BY (date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Load sheet line items. Replaces V_LOAD_SHEETS detail + V_GESC_CLOSED_LOADS.';

-- =====================================================================
-- fact_task_completion
-- Task labor performance. Used by TIME_DIFF freshness diagnostics.
-- =====================================================================
CREATE OR REPLACE TABLE fact_task_completion (
  task_completion_sk             BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1),
  task_id                        STRING NOT NULL,
  task_detail_id                 STRING,
  item_sk                        BIGINT,
  facility_sk                    BIGINT,
  date_sk                        BIGINT NOT NULL,
  task_type_id                   STRING,
  status                         STRING,
  quantity                       DECIMAL(18,4),
  task_completed_at              TIMESTAMP
)
USING DELTA
CLUSTER BY (facility_sk, date_sk)
TBLPROPERTIES (
  'delta.autoOptimize.optimizeWrite' = 'true',
  'delta.autoOptimize.autoCompact' = 'true',
  'delta.enableChangeDataFeed' = 'true'
)
COMMENT 'Task completion events for labor productivity reporting.';

-- =====================================================================
-- v_inventory_compare (materialized view; replaces CCS_INV_COMPARE_V)
-- Materialized view for cross-facility inventory comparison.
-- Auto-refreshes when source fact_inventory_snapshot changes.
-- Manual refresh: REFRESH MATERIALIZED VIEW v_inventory_compare;
-- =====================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS v_inventory_compare
COMMENT 'Cross-facility inventory comparison. Replaces CCS_INV_COMPARE_V semantics.'
AS
SELECT
  df.facility_short                                                AS inventory_facility,
  di.item_id,
  sum(fis.on_hand_qty)                                             AS sum_on_hand,
  sum(fis.allocated_qty)                                           AS sum_allocated,
  df.facility_id                                                   AS profile_id,
  sum(coalesce(fis.outside_staging_qty, 0))                        AS outside_stg
FROM fact_inventory_snapshot fis
JOIN dim_item     di ON fis.item_sk     = di.item_sk
JOIN dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.facility_short, di.item_id, df.facility_id;

SHOW TABLES IN gold_native;
