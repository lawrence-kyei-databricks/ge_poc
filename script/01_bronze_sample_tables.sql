-- Databricks notebook source
-- DBTITLE 1,Bronze Sample Tables
-- =====================================================================
-- Giant Eagle: 01_bronze_sample_tables.sql
-- Manhattan WMS base tables (35 tables) referenced by the 50 gold views.
-- Column shapes derived from view DDLs and Manhattan ODM conventions.
-- Superseded by Lakeflow Connect Bronze when production pipeline lands.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA bronze;

-- ---------------------------------------------------------------------
-- ITEM_MASTER and packaging
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_item_master_ite_item (
  pk                             BIGINT,
  item_id                        STRING NOT NULL,
  profile_id                     STRING NOT NULL,
  short_description              STRING,
  description                    STRING,
  long_description               STRING,
  style_suffix                   STRING,
  display_uom_id                 STRING,
  lpn_per_tier                   INT,
  tiers_per_pallet               INT,
  unit_price                     DECIMAL(18,4),
  catch_weight_item              STRING,
  average_weight                 DECIMAL(18,4),
  ext_gegl_dcxx_virtual_whse     STRING,
  ext_gegl_dc33_virtual_whse     STRING,
  ext_gegl_department            STRING,
  ext_gegl_product_size          STRING,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  __hevo__ingested_at            TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING,
  __hevo__source_modified_at     TIMESTAMP,
  process                        STRING,
  product_class                  STRING,
  unit_cost                      DECIMAL(18,4)
) USING DELTA;

CREATE OR REPLACE TABLE default_item_master_ite_item_package (
  item_pk                        BIGINT NOT NULL,
  standard_quantity_uom_id       STRING,
  quantity                       INT,
  height                         DECIMAL(18,4),
  width                          DECIMAL(18,4),
  length                         DECIMAL(18,4),
  weight                         DECIMAL(18,4),
  volume                         DECIMAL(18,4),
  __hevo__marked_deleted         STRING,
  profile_id                     STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- DCI: inventory state + location + ILPN + assignment + container
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_dcinventory_dci_inventory (
  inventory_id                   STRING NOT NULL,
  item_id                        STRING NOT NULL,
  org_id                         STRING NOT NULL,
  facility_id                    STRING,
  location_id                    STRING,
  inventory_container_id         STRING,
  inventory_container_type_id    STRING,
  on_hand                        DECIMAL(18,4),
  allocated                      DECIMAL(18,4),
  to_be_filled                   DECIMAL(18,4),
  is_in_transit                  STRING,
  inventory_attribute1           STRING,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING,
  ilpn_id                        STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_dcinventory_dci_location (
  location_id                    STRING NOT NULL,
  facility_id                    STRING,
  profile_id                     STRING,
  location_barcode               STRING,
  location_type                  STRING,
  aisle                          STRING, bay STRING, level STRING,
  __hevo__marked_deleted         STRING,
  storage_uom_id                 STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_dcinventory_dci_ilpn (
  ilpn_id                        STRING NOT NULL,
  org_id                         STRING,
  asn_id                         STRING,
  purchase_order_id              STRING,
  current_location_id            STRING,
  previous_location_id           STRING,
  destination_location_id        STRING,
  status                         STRING,
  purge_date                     TIMESTAMP,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  updated_by                     STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_dcinventory_dci_location_item_assignment (
  location_id                    STRING NOT NULL,
  item_id                        STRING NOT NULL,
  facility_id                    STRING,
  assignment_type                STRING,
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP,
  org_id                         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_dcinventory_dci_location_capacity_usage (
  location_id                    STRING NOT NULL,
  capacity_pct                   DECIMAL(18,4),
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TABLE default_dcinventory_dci_container_condition (
  inventory_container_id         STRING NOT NULL,
  condition_id                   STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- PIX entry (transaction log) + adjustment reason
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_pix_pix_pix_entry (
  pix_entry_id                   STRING NOT NULL,
  item_id                        STRING NOT NULL,
  org_id                         STRING NOT NULL,
  item_description               STRING,
  quantity                       DECIMAL(18,4),
  adjusted_type                  STRING,
  reason_code_id                 STRING,
  source_transaction_type        STRING,
  purchase_order_id              STRING,
  purchase_order_line_id         STRING,
  inventory_attribute1           STRING,
  grouping_tag                   STRING,
  sync_batch_id                  STRING,
  created_by                     STRING,
  updated_by                     STRING,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_inventory_management_inm_adjustment_reason_code (
  reason_code_id                 STRING NOT NULL,
  profile_id                     STRING NOT NULL,
  description                    STRING,
  category                       STRING,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  __hevo__ingested_at            TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING,
  __hevo__source_modified_at     TIMESTAMP
) USING DELTA;

-- ---------------------------------------------------------------------
-- Receiving: ASN, PO, Receipt, LPN
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_receiving_rcv_asn (
  asn_id                         STRING NOT NULL,
  org_id                         STRING,
  purchase_order_id              STRING,
  asn_status                     STRING,
  created_timestamp              TIMESTAMP,
  updated_timestamp              TIMESTAMP,
  __hevo__marked_deleted         STRING,
  asn_origin_type_id             STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_asn_line (
  asn_id                         STRING NOT NULL,
  asn_line_id                    STRING NOT NULL,
  item_id                        STRING,
  ordered_quantity               DECIMAL(18,4),
  received_quantity              DECIMAL(18,4),
  __hevo__marked_deleted         STRING,
  org_id                         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_purchase_order (
  purchase_order_id              STRING NOT NULL,
  org_id                         STRING,
  purchase_order_status          STRING,
  vendor_id                      STRING,
  __hevo__marked_deleted         STRING,
  closed                         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_purchase_order_line (
  purchase_order_id              STRING NOT NULL,
  purchase_order_line_id         STRING NOT NULL,
  item_id                        STRING,
  ordered_quantity               DECIMAL(18,4),
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_purchase_order_status (
  purchase_order_status_id       STRING NOT NULL,
  description                    STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_receipt (
  receipt_id                     STRING NOT NULL,
  asn_id                         STRING,
  item_id                        STRING,
  received_quantity              DECIMAL(18,4),
  received_at                    TIMESTAMP,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_receiving_rcv_lpn (
  lpn_id                         STRING NOT NULL,
  asn_id                         STRING,
  item_id                        STRING,
  quantity                       DECIMAL(18,4),
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- Pickpack: OLPN and task detail
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_pickpack_ppk_olpn (
  olpn_id                        STRING NOT NULL,
  org_id                         STRING,
  status                         STRING,
  facility_id                    STRING,
  destination_facility_id        STRING,
  order_planning_run_id          STRING,
  ext_pharmacy_routeid           STRING,
  ext_pharmacy_stop_id           STRING,
  created_timestamp              TIMESTAMP,
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TABLE default_pickpack_ppk_olpn_detail (
  olpn_id                        STRING NOT NULL,
  org_id                         STRING,
  item_id                        STRING,
  order_id                       STRING,
  order_line_id                  STRING,
  packed_quantity                DECIMAL(18,4),
  facility_id                    STRING,
  facility_address_address1      STRING,
  facility_address_address2      STRING,
  facility_address_city          STRING,
  facility_address_state         STRING,
  facility_address_postalcode    STRING,
  appl_code                      STRING,
  status                         STRING,
  created_timestamp              TIMESTAMP,
  ext_pharmacy_routeid           STRING,
  ext_pharmacy_stop_id           STRING,
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TABLE default_pickpack_tsk_task_detail (
  task_id                        STRING,
  source_container_id            STRING,
  item_id                        STRING,
  facility_id                    STRING,
  type_id                        STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- Task
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_task_tsk_task (
  task_id                        STRING NOT NULL,
  facility_id                    STRING,
  type_id                        STRING,
  status                         STRING,
  updated_timestamp              TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_task_tsk_task_detail (
  task_id                        STRING NOT NULL,
  task_detail_id                 STRING NOT NULL,
  item_id                        STRING,
  quantity                       DECIMAL(18,4),
  updated_timestamp              TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_dcorder_dco_order (
  order_id                       STRING NOT NULL,
  org_id                         STRING,
  status                         STRING,
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TABLE default_dcorder_dco_order_line (
  order_id                       STRING NOT NULL,
  order_line_id                  STRING NOT NULL,
  item_id                        STRING,
  quantity                       DECIMAL(18,4),
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TABLE default_dcorder_dco_original_order (
  order_id                       STRING NOT NULL,
  org_id                         STRING,
  updated_timestamp              TIMESTAMP,
  __hevo__loaded_at              TIMESTAMP,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_dcorder_dco_original_order_line (
  order_id                       STRING NOT NULL,
  order_line_id                  STRING NOT NULL,
  item_id                        STRING,
  __hevo__marked_deleted         STRING,
  updated_timestamp              TIMESTAMP
) USING DELTA;

-- ---------------------------------------------------------------------
-- Organization / Facility
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_organization_org_organization (
  org_id                         STRING NOT NULL,
  org_name                       STRING,
  org_type                       STRING,
  __hevo__marked_deleted         STRING,
  facility_id                    STRING,
  organization_id                STRING,
  json_store                     STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_facility_fac_facility (
  facility_id                    STRING NOT NULL,
  facility_name                  STRING,
  facility_address_address1      STRING,
  facility_address_city          STRING,
  facility_address_state         STRING,
  facility_address_postalcode    STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- Shipment / Transportation
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE default_shipment_shp_shipment (
  pk                             BIGINT,
  shipment_id                    STRING NOT NULL,
  org_id                         STRING,
  origin_planned_arr_start_dttm  TIMESTAMP,
  climate_control_id             STRING,
  planned_size1_value            DECIMAL(18,4),
  ass_carrier_id                 STRING,
  __hevo__marked_deleted         STRING,
  assigned_carrier_id            STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_shipment_shp_stop (
  stop_id                        STRING NOT NULL,
  shipment_pk                    BIGINT,
  org_id                         STRING,
  facility_id                    STRING,
  stop_sequence                  INT,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_shipment_shp_shipment_note (
  shipment_id                    STRING NOT NULL,
  note_value                     STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_shipment_transport_order_movement (
  shipment_id                    STRING NOT NULL,
  transportation_order_id        STRING,
  org_id                         STRING,
  delivery_stop_id               STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_routing_rtg_transportation_order (
  transportation_order_id        STRING NOT NULL,
  org_id                         STRING,
  origin_facility_id             STRING,
  destination_facility_id        STRING,
  planned_size1_value            DECIMAL(18,4),
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_routing_rtg_transportation_order_line (
  transportation_order_id        STRING NOT NULL,
  line_id                        STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

CREATE OR REPLACE TABLE default_carrier_car_carrier (
  carrier_id                     STRING NOT NULL,
  description                    STRING,
  __hevo__marked_deleted         STRING
) USING DELTA;

-- ---------------------------------------------------------------------
-- External (non-Manhattan) mock source
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE ge_cs_invn_control (
  control_id                     BIGINT NOT NULL,
  facility_id                    STRING NOT NULL,
  inventory_date                 DATE NOT NULL,
  analysis_start_date_time       TIMESTAMP,
  analysis_end_date_time         TIMESTAMP,
  cycle_count_session_id         STRING
) USING DELTA
COMMENT 'Mock of external GE Oracle source. Replace with real integration when available.';



SHOW TABLES IN bronze;