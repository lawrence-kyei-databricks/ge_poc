-- =====================================================================
-- Giant Eagle POC: 06_gold_native_compat_views.sql
-- VERSION B (lakehouse-native), part 3: COMPATIBILITY VIEWS
-- One compatibility view per Snowflake view shape, sourced from the dimensional model.
-- This is what makes Power BI repointing trivial: the BI dataset sees the same
-- column shape on the other side, regardless of which Gold version it points at.
--
-- Strategy:
--  - Implement the TEMPLATE views explicitly (one per pattern: IROO, QROO, ITEM_SNAPSHOT, etc.)
--  - For per-facility variants (BICEPS_*_D0001, *_D0044, etc.), implement as WHERE-filtered
--    selects on the template. Pattern shown below — extend to all variants as needed.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_native;

-- =====================================================================
-- GROUP 1: GE_CS corporate views
-- =====================================================================

-- ---- GE_CS_INVN_DLY_TOTAL_V  (backs WAREHOUSE TOTALS) ----
CREATE OR REPLACE VIEW v_ge_cs_invn_dly_total
COMMENT 'Compat view matching GE_CS_INVN_DLY_TOTAL_V shape.'
AS
SELECT
  df.facility_short                                                          AS warehouse_id,
  df.facility_short                                                          AS facility,
  d.full_date                                                                AS inventory_date,
  di.item_id,
  concat(di.item_id, df.facility_short)                                      AS item_ndc,
  fidt.total_on_hand                                                         AS on_handcurrent_inventory_qty,
  date_format(current_timestamp(), 'yyyy-MM-dd, HH:mm:ss')                   AS create_date,
  date_format(current_timestamp(), 'yyyy-MM-dd, HH:mm:ss')                   AS update_date,
  'GE_CS_INVN_MON'                                                           AS user_id,
  di.short_description                                                       AS item_description
FROM fact_inventory_daily_total fidt
JOIN dim_item     di ON fidt.item_sk     = di.item_sk
JOIN dim_facility df ON fidt.facility_sk = df.facility_sk
JOIN dim_date     d  ON fidt.date_sk     = d.date_sk
WHERE df.facility_id = 'D0080'
  AND di.ext_gegl_dcxx_virtual_whse = 'DC80-85'
  AND coalesce(di.style_suffix, '01') != '99'
  AND d.full_date = current_date();

-- ---- GE_CS_ADJUSTMENT_REASON_V ----
CREATE OR REPLACE VIEW v_ge_cs_adjustment_reason
COMMENT 'Compat view matching GE_CS_ADJUSTMENT_REASON_V shape.'
AS
SELECT
  reason_code        AS adjustment_reason_code,
  reason_description AS adjustment_reason_description
FROM dim_adjustment_reason
WHERE profile_id = 'D0080' AND is_active;

-- ---- GE_CS_CYCL_CNT_ADJMT_DTLV  (backs CYCLECOUNTRECAP) ----
CREATE OR REPLACE VIEW v_ge_cs_cycl_cnt_adjmt_dtlv
COMMENT 'Compat view matching GE_CS_CYCL_CNT_ADJMT_DTLV shape.'
AS
SELECT
  df.facility_short                                                          AS warehouse_id,
  df.facility_short                                                          AS facility,
  date_format(d.full_date, 'MM/dd/yyyy HH:mm:ss')                            AS inventory_date,
  di.item_id,
  substring(di.short_description, 1, 40)                                     AS item_description,
  concat(di.item_id, df.facility_short)                                      AS item_ndc,
  CASE di.display_uom_id WHEN 'PACK' THEN 'P' WHEN 'UNIT' THEN 'U' WHEN 'LPN' THEN 'L' ELSE 'U' END AS item_ndc_pack_size,
  dar.reason_code                                                            AS adjustment_reason_code,
  fcca.adjustment_qty,
  fcca.created_at_local                                                      AS create_date_time,
  fcca.modified_at_utc                                                       AS mod_date_time,
  substring(fcca.user_id, 1, 15)                                             AS user_id,
  substring(concat(fcca.pix_entry_id, ',', coalesce(fcca.inventory_attribute1, '')), 1, 20) AS adjmt_dtl_id
FROM fact_cycle_count_adjustment fcca
JOIN dim_item              di  ON fcca.item_sk     = di.item_sk
JOIN dim_facility          df  ON fcca.facility_sk = df.facility_sk
JOIN dim_date              d   ON fcca.date_sk     = d.date_sk
LEFT JOIN dim_adjustment_reason dar ON fcca.reason_sk = dar.reason_sk
WHERE df.facility_id = 'D0080'
  AND di.ext_gegl_dcxx_virtual_whse = 'DC80-85';

-- ---- GE_CS_TRANSACTION_DTL_V ----
CREATE OR REPLACE VIEW v_ge_cs_transaction_dtl
COMMENT 'Compat view matching GE_CS_TRANSACTION_DTL_V shape.'
AS
SELECT
  df.facility_short                                                          AS warehouse_id,
  df.facility_short                                                          AS facility,
  date_format(d.full_date, 'MM/dd/yyyy HH:mm:ss')                            AS inventory_date,
  di.item_id                                                                 AS item_number,
  substring(di.description, 14)                                              AS item_description,
  concat(di.item_id, df.facility_short)                                      AS item_ndc,
  CASE di.display_uom_id WHEN 'PACK' THEN 'P' WHEN 'UNIT' THEN 'U' WHEN 'LPN' THEN 'L' ELSE 'U' END AS item_ndc_package_size,
  CASE fit.source_transaction_type
    WHEN 'SHIPCONFIRM' THEN 'SHIPMENT'
    WHEN 'RECEIVING'   THEN 'RECEIVING'
    ELSE fit.source_transaction_type
  END                                                                        AS adjustment_reason_code,
  fit.quantity                                                               AS adjustment_qty,
  fit.created_at_local                                                       AS create_date,
  fit.created_at_local                                                       AS update_date,
  substring(fit.user_id, 1, 15)                                              AS user_id,
  concat(
    CASE
      WHEN fit.purchase_order_id = '' AND fit.inventory_attribute1 = 'CONVER' THEN substring(fit.user_id, 1, 6)
      WHEN fit.purchase_order_id = '' AND fit.inventory_attribute1 != 'CONVER' THEN fit.inventory_attribute1
      ELSE fit.purchase_order_id
    END,
    ',',
    CASE WHEN fit.purchase_order_line_id = '' THEN di.item_id ELSE fit.purchase_order_line_id END
  )                                                                          AS identifying_value,
  'PO_Nbr, PO_Line_Nbr'                                                      AS identifying_link,
  fit.inventory_attribute1                                                   AS additional_info
FROM fact_inventory_transaction fit
JOIN dim_item     di ON fit.item_sk     = di.item_sk
JOIN dim_facility df ON fit.facility_sk = df.facility_sk
JOIN dim_date     d  ON fit.date_sk     = d.date_sk
WHERE df.facility_id = 'D0080'
  AND di.ext_gegl_dcxx_virtual_whse = 'DC80-85';

-- =====================================================================
-- GROUP 2: CCS shared / cross-facility
-- =====================================================================

-- ---- CCS_INV_COMPARE_V ----
CREATE OR REPLACE VIEW v_ccs_inv_compare
COMMENT 'Compat view matching CCS_INV_COMPARE_V shape.'
AS
SELECT inventory_facility, item_id, sum_on_hand, sum_allocated, profile_id, outside_stg
FROM v_inventory_compare;

-- ---- CCS_IROO_V  (cross-facility item state) ----
CREATE OR REPLACE VIEW v_ccs_iroo
COMMENT 'Compat view matching CCS_IROO_V shape. Cross-facility item state.'
AS
SELECT
  di.profile_id, df.facility_id,
  di.ext_gegl_dcxx_virtual_whse AS ext_gegldcxxvirtualwhse,
  di.ext_gegl_dc33_virtual_whse AS virtwhse,
  di.item_id                    AS itemid,
  di.lpn_per_tier               AS lpnpertier,
  di.tiers_per_pallet           AS tierperpallet,
  di.unit_height, di.unit_width, di.unit_length, di.unit_weight,
  di.pack_height, di.pack_width, di.pack_length, di.pack_weight,
  dl.location_barcode,
  di.unit_volume                AS unitvolume,
  di.pack_volume                AS packvolume,
  CASE WHEN fis.has_inventory THEN 'Y' ELSE 'N' END AS has_inv
FROM dim_item di
LEFT JOIN fact_inventory_snapshot fis ON fis.item_sk = di.item_sk
LEFT JOIN dim_facility df ON fis.facility_sk = df.facility_sk
LEFT JOIN dim_location dl ON fis.location_sk = dl.location_sk
;

-- ---- CCS_QROO_V ----
CREATE OR REPLACE VIEW v_ccs_qroo
COMMENT 'Compat view matching CCS_QROO_V shape. Cross-facility quantity state.'
AS
SELECT
  di.profile_id,
  di.ext_gegl_dcxx_virtual_whse                                              AS ext_gegldcxxvirtualwhse,
  di.style_suffix,
  di.item_id,
  df.facility_id                                                             AS inventory_facility,
  fis.on_hand_qty                                                            AS on_hand,
  fis.outside_staging_qty                                                    AS qty_in_outside_stg,
  fis.allocated_qty                                                          AS qty_allocated,
  fis.available_qty                                                          AS qty_available,
  fis.pick_location_qty                                                      AS qty_pick_locn,
  fis.ilpn_qty                                                               AS qty_ilpn
FROM dim_item di
JOIN fact_inventory_snapshot fis ON di.item_sk = fis.item_sk
JOIN dim_facility df             ON fis.facility_sk = df.facility_sk
;

-- ---- CCS_ITEM_SNAPSHOT_V ----
CREATE OR REPLACE VIEW v_ccs_item_snapshot
COMMENT 'Compat view matching CCS_ITEM_SNAPSHOT_V shape. Combined item + inventory snapshot.'
AS
SELECT
  di.profile_id, df.facility_id,
  di.ext_gegl_dcxx_virtual_whse AS whse,
  di.ext_gegl_dcxx_virtual_whse AS co,
  di.item_id                    AS item,
  coalesce(di.description, ' ') AS item_description,
  di.ext_gegl_product_size      AS item_size,
  di.lpn_per_tier,
  dl.location_barcode           AS locn_brcd,
  di.unit_weight                AS unit_wt,
  di.unit_volume                AS unit_vol,
  di.tiers_per_pallet           AS lpn_per_plt,
  greatest(coalesce(fis.on_hand_qty, 0), 0)              AS boh_qty,
  greatest(coalesce(fis.pick_location_qty, 0), 0)        AS pick_locn_qty,
  greatest(coalesce(fis.ilpn_qty, 0), 0)                 AS ilpn_qty,
  greatest(coalesce(fis.allocated_qty, 0), 0)            AS inv_alloc_inv,
  0                                                       AS inv_qty_in_tran,
  greatest(coalesce(di.unit_price, 0.0000), 0.0000)      AS inv_unit_cost,
  greatest(coalesce(fis.available_qty, 0), 0)            AS inv_not_alloc_qty,
  greatest(coalesce(di.average_weight, 0.0000), 0.0000)  AS inv_catch_wt,
  greatest(coalesce(fis.to_be_filled_qty, 0), 0)         AS inv_qty_to_be_alloc,
  di.item_pk                                              AS sku_id,
  greatest(coalesce(di.average_weight, 0.0000), 0.0000)  AS item_avg_wt,
  0.0000                                                  AS po_order_quantity,
  greatest(coalesce(di.unit_price, 0.0000), 0.0000)      AS item_unit_price,
  CASE WHEN fis.has_inventory THEN '1' ELSE 'N' END      AS has_inv
FROM dim_item di
LEFT JOIN fact_inventory_snapshot fis ON fis.item_sk = di.item_sk
LEFT JOIN dim_facility df ON fis.facility_sk = df.facility_sk
LEFT JOIN dim_location dl ON fis.location_sk = dl.location_sk
;

-- =====================================================================
-- GROUP 3: BICEPS — TEMPLATE + per-facility variants
-- The template covers BICEPS_IROO_V (all BICEPS facilities). The per-facility
-- variants (D0001, D0044, D0050, D0061, D0070, D0080) are WHERE-filtered selects on the template.
-- =====================================================================

-- ---- BICEPS_IROO_V (template, all BICEPS facilities) ----
CREATE OR REPLACE VIEW v_biceps_iroo
COMMENT 'Compat view template for BICEPS_IROO_V. All BICEPS facilities. Per-facility variants below filter this.'
AS
SELECT
  di.profile_id,
  concat(substr(di.ext_gegl_dcxx_virtual_whse, 1, 1), '00', substr(di.ext_gegl_dcxx_virtual_whse, 6, 2)) AS facility_id,
  di.ext_gegl_dcxx_virtual_whse AS ext_gegldcxxvirtualwhse,
  di.ext_gegl_dc33_virtual_whse AS virtwhse,
  di.item_id,
  di.lpn_per_tier               AS lpnpertier,
  di.tiers_per_pallet           AS tierperpallet,
  di.unit_height, di.unit_width, di.unit_length, di.unit_weight,
  di.pack_height, di.pack_width, di.pack_length, di.pack_weight,
  dl.location_barcode,
  di.unit_volume                AS unitvolume,
  di.pack_volume                AS packvolume
FROM dim_item di
JOIN dim_facility df ON df.business_unit_code = 'BICEPS' AND df.facility_id = di.profile_id
LEFT JOIN fact_inventory_snapshot fis ON fis.item_sk = di.item_sk AND fis.facility_sk = df.facility_sk
LEFT JOIN dim_location dl ON fis.location_sk = dl.location_sk
;

-- ---- BICEPS_IROO_V_D0001 ... D0080: per-facility variants (template + WHERE filter) ----
CREATE OR REPLACE VIEW v_biceps_iroo_d0001 AS SELECT * FROM v_biceps_iroo WHERE profile_id IN ('D0001', 'D0008');
CREATE OR REPLACE VIEW v_biceps_iroo_d0044 AS SELECT * FROM v_biceps_iroo WHERE profile_id = 'D0044';
CREATE OR REPLACE VIEW v_biceps_iroo_d0050 AS SELECT * FROM v_biceps_iroo WHERE profile_id = 'D0050';
CREATE OR REPLACE VIEW v_biceps_iroo_d0061 AS SELECT * FROM v_biceps_iroo WHERE profile_id = 'D0061';
CREATE OR REPLACE VIEW v_biceps_iroo_d0070 AS SELECT * FROM v_biceps_iroo WHERE profile_id = 'D0070';
CREATE OR REPLACE VIEW v_biceps_iroo_d0080 AS SELECT * FROM v_biceps_iroo WHERE profile_id = 'D0080';

-- ---- BICEPS_QROO_V (template) + per-facility variants ----
CREATE OR REPLACE VIEW v_biceps_qroo
COMMENT 'Compat view template for BICEPS_QROO_V. All BICEPS facilities.'
AS
SELECT
  di.profile_id,
  di.ext_gegl_dcxx_virtual_whse AS ext_gegldcxxvirtualwhse,
  di.style_suffix,
  di.item_id,
  df.facility_id                AS inventory_facility,
  fis.on_hand_qty               AS on_hand,
  fis.outside_staging_qty       AS qty_in_outside_stg,
  coalesce(rcv.received_qty, 0) AS qty_received,
  coalesce(adj.adjustment_qty, 0) AS qty_adjustments,
  fis.allocated_qty             AS qty_selected,
  0                             AS qty_overship,
  coalesce(scratch.scratch_qty, 0) AS qty_scratch_adj
FROM dim_item di
JOIN dim_facility df ON df.business_unit_code = 'BICEPS' AND df.facility_id = di.profile_id
LEFT JOIN fact_inventory_snapshot fis ON fis.item_sk = di.item_sk AND fis.facility_sk = df.facility_sk
LEFT JOIN (
  SELECT item_sk, facility_sk, sum(received_qty) AS received_qty
  FROM fact_receiving_event GROUP BY item_sk, facility_sk
) rcv ON rcv.item_sk = di.item_sk AND rcv.facility_sk = df.facility_sk
LEFT JOIN (
  SELECT item_sk, facility_sk, sum(signed_quantity) AS adjustment_qty
  FROM fact_inventory_transaction WHERE grouping_tag = 'InventoryAdjustment'
  GROUP BY item_sk, facility_sk
) adj ON adj.item_sk = di.item_sk AND adj.facility_sk = df.facility_sk
LEFT JOIN (
  SELECT item_sk, facility_sk, sum(signed_quantity) AS scratch_qty
  FROM fact_inventory_transaction WHERE grouping_tag = 'Scratch'
  GROUP BY item_sk, facility_sk
) scratch ON scratch.item_sk = di.item_sk AND scratch.facility_sk = df.facility_sk
;

CREATE OR REPLACE VIEW v_biceps_qroo_d0001 AS SELECT * FROM v_biceps_qroo WHERE profile_id IN ('D0001', 'D0008');
CREATE OR REPLACE VIEW v_biceps_qroo_d0044 AS SELECT * FROM v_biceps_qroo WHERE profile_id = 'D0044';
CREATE OR REPLACE VIEW v_biceps_qroo_d0050 AS SELECT * FROM v_biceps_qroo WHERE profile_id = 'D0050';
CREATE OR REPLACE VIEW v_biceps_qroo_d0061 AS SELECT * FROM v_biceps_qroo WHERE profile_id = 'D0061';
CREATE OR REPLACE VIEW v_biceps_qroo_d0070 AS SELECT * FROM v_biceps_qroo WHERE profile_id = 'D0070';
CREATE OR REPLACE VIEW v_biceps_qroo_d0080 AS SELECT * FROM v_biceps_qroo WHERE profile_id = 'D0080';

-- =====================================================================
-- GROUP 4: Single-BU IROO/QROO/ITEM_SNAPSHOT variants
-- ASF (D0061), BRM (D0050), FFM (D0070), OKG (D0001), OKP (D0044), HBC (D0080)
-- Each follows the same template-then-filter pattern. Showing one BU explicitly;
-- others follow the same structure.
-- =====================================================================

-- ---- HBC views (D0080) ----
CREATE OR REPLACE VIEW v_hbc_iroo_d0080      AS SELECT * FROM v_biceps_iroo      WHERE profile_id = 'D0080';
CREATE OR REPLACE VIEW v_hbc_qroo_d0080      AS SELECT * FROM v_biceps_qroo      WHERE profile_id = 'D0080';
CREATE OR REPLACE VIEW v_hbc_item_snapshot_d0080
COMMENT 'Compat view matching HBC_ITEM_SNAPSHOT_V_D0080 shape. Same template as CCS_ITEM_SNAPSHOT, scoped to D0080.'
AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id = 'D0080';

-- ---- ASF (D0061) ----
CREATE OR REPLACE VIEW v_asf_iroo_d0061          AS SELECT * FROM v_biceps_iroo      WHERE profile_id = 'D0061';
CREATE OR REPLACE VIEW v_asf_qroo_d0061          AS SELECT * FROM v_biceps_qroo      WHERE profile_id = 'D0061';
CREATE OR REPLACE VIEW v_asf_item_snapshot_d0061 AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id = 'D0061';

-- ---- BRM (D0050) ----
CREATE OR REPLACE VIEW v_brm_iroo_d0050          AS SELECT * FROM v_biceps_iroo      WHERE profile_id = 'D0050';
CREATE OR REPLACE VIEW v_brm_qroo_d0050          AS SELECT * FROM v_biceps_qroo      WHERE profile_id = 'D0050';
CREATE OR REPLACE VIEW v_brm_item_snapshot_d0050 AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id = 'D0050';

-- ---- FFM (D0070) ----
CREATE OR REPLACE VIEW v_ffm_iroo_d0070          AS SELECT * FROM v_biceps_iroo      WHERE profile_id = 'D0070';
CREATE OR REPLACE VIEW v_ffm_qroo_d0070          AS SELECT * FROM v_biceps_qroo      WHERE profile_id = 'D0070';
CREATE OR REPLACE VIEW v_ffm_item_snapshot_d0070 AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id = 'D0070';

-- ---- OKG (D0001) ----
CREATE OR REPLACE VIEW v_okg_iroo_d0001          AS SELECT * FROM v_biceps_iroo      WHERE profile_id IN ('D0001', 'D0008');
CREATE OR REPLACE VIEW v_okg_qroo_d0001          AS SELECT * FROM v_biceps_qroo      WHERE profile_id IN ('D0001', 'D0008');
CREATE OR REPLACE VIEW v_okg_item_snapshot_d0001 AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id IN ('D0001', 'D0008');

-- ---- OKP (D0044) ----
CREATE OR REPLACE VIEW v_okp_iroo_d0044          AS SELECT * FROM v_biceps_iroo      WHERE profile_id = 'D0044';
CREATE OR REPLACE VIEW v_okp_qroo_d0044          AS SELECT * FROM v_biceps_qroo      WHERE profile_id = 'D0044';
CREATE OR REPLACE VIEW v_okp_item_snapshot_d0044 AS SELECT * FROM v_ccs_item_snapshot WHERE facility_id = 'D0044';

-- =====================================================================
-- GROUP 5: Specialty / Transportation
-- =====================================================================

-- ---- HBC_PHARMACY_TRANSPORTION_OH_V ----
CREATE OR REPLACE VIEW v_hbc_pharmacy_transport_oh
COMMENT 'Compat view matching HBC_PHARMACY_TRANSPORTION_OH_V shape. Pharmacy transport, on-hand variant.'
AS
SELECT
  fpt.destination_facility_id              AS facility_id,
  fpt.destination_address_address1         AS facility_address_address1,
  NULL                                     AS facility_address_address2,
  fpt.destination_address_city             AS facility_address_city,
  fpt.destination_address_state            AS facility_address_state,
  fpt.destination_postalcode               AS facility_address_postalcode,
  fpt.appl_code,
  fpt.olpn_id,
  fpt.ext_pharmacy_routeid,
  fpt.ext_pharmacy_stop_id
FROM fact_pharmacy_transport fpt
WHERE fpt.transport_variant = 'OH';

-- ---- HBC_PHARMACY_TRANSPORTION_PA_V ----
CREATE OR REPLACE VIEW v_hbc_pharmacy_transport_pa
COMMENT 'Compat view matching HBC_PHARMACY_TRANSPORTION_PA_V shape. Pharmacy transport, picked/allocated variant.'
AS
SELECT
  fpt.destination_facility_id              AS facility_id,
  fpt.destination_address_address1         AS facility_address_address1,
  NULL                                     AS facility_address_address2,
  fpt.destination_address_city             AS facility_address_city,
  fpt.destination_address_state            AS facility_address_state,
  fpt.destination_postalcode               AS facility_address_postalcode,
  fpt.appl_code,
  fpt.olpn_id,
  fpt.ext_pharmacy_routeid,
  fpt.ext_pharmacy_stop_id
FROM fact_pharmacy_transport fpt
WHERE fpt.transport_variant = 'PA';

-- ---- V_GESC_CLOSED_LOADS ----
CREATE OR REPLACE VIEW v_gesc_closed_loads
COMMENT 'Compat view matching V_GESC_CLOSED_LOADS shape.'
AS
SELECT
  di.profile_id,
  substr(fls.order_id, 3, 6)                AS order_id,
  substr(fls.order_id, 9, 3)                AS order_seg_id,
  df.facility_id                            AS whse_id,
  di.item_id,
  fls.ship_qty
FROM fact_load_sheet fls
JOIN dim_item     di ON fls.item_sk = di.item_sk
LEFT JOIN fact_transportation_shipment fts ON fls.shipment_sk = fts.shipment_sk
LEFT JOIN dim_facility df ON fts.origin_facility_sk = df.facility_sk
;

-- ---- V_LOAD_SHEETS ----
CREATE OR REPLACE VIEW v_load_sheets
COMMENT 'Compat view matching V_LOAD_SHEETS shape.'
AS
SELECT
  fts.shipment_id,
  fts.pickup_start_dttm                     AS pickup_start_dttm,
  dc.carrier_name                           AS carrier_code_name,
  fts.protection_level,
  fts.pallets_on_shipment,
  df_orig.facility_name,
  fts.destination_facility_id               AS store_nbr,
  fts.destination_facility_id               AS stop_facility_alias_id,
  fts.product_class,
  fls.stop_sequence                         AS stop_seq,
  fts.planned_volume,
  fls.order_qty,
  fls.pallets,
  NULL                                      AS note,
  NULL                                      AS other_shipments_for_store,
  df_orig.facility_id                       AS origin_facility_id,
  NULL                                      AS planning_status_id,
  fts.loading_sequence,
  fts.position_code                         AS sq,
  CASE WHEN df_orig.facility_id = 'D0061' AND fts.product_class IN ('DAIRY', 'PRODUCE')
       THEN 'ASFPC' ELSE fts.product_class END AS newpc,
  df_orig.facility_id                       AS facility_id
FROM fact_transportation_shipment fts
LEFT JOIN fact_load_sheet fls ON fls.shipment_sk = fts.shipment_sk
LEFT JOIN dim_carrier  dc      ON fts.carrier_sk        = dc.carrier_sk
LEFT JOIN dim_facility df_orig ON fts.origin_facility_sk = df_orig.facility_sk;

-- ---- V_GESC_WM_INVENTORY ----
CREATE OR REPLACE VIEW v_gesc_wm_inventory
COMMENT 'Compat view matching V_GESC_WM_INVENTORY shape.'
AS
SELECT
  di.profile_id,
  coalesce(df.facility_id, di.profile_id)              AS asiwhse,
  di.item_id                                           AS aimstyle,
  substr(di.ext_gegl_dcxx_virtual_whse, 6, 2)          AS aimstylesfx,
  coalesce(fis.on_hand_qty, 0)                         AS asiqtyonhand,
  0                                                    AS bpdunitsordered,
  0                                                    AS csumactlqty,
  coalesce(fis.on_hand_qty, 0)                         AS boh,
  0                                                    AS dpdunitsordered
FROM dim_item di
LEFT JOIN fact_inventory_snapshot fis ON di.item_sk = fis.item_sk
LEFT JOIN dim_facility df ON fis.facility_sk = df.facility_sk WHERE di.profile_id != 'GEGL-SC-L1-PROFILE'
  AND coalesce(di.style_suffix, '01') != '99';

-- ---- PSE_CASE_V ----
CREATE OR REPLACE VIEW v_pse_case
COMMENT 'Compat view matching PSE_CASE_V shape.'
AS
SELECT
  fil.ilpn_id                              AS case_nbr,
  '80'                                     AS frm_whse_nbr,
  CASE
    WHEN fil.current_location_id NOT IN ('HRXTDZ0180R', 'HRXTSZ01') THEN '70'
    WHEN fil.current_location_id IN ('HRXTDZ0180R', 'HRXTSZ01')     THEN ' '
    WHEN fil.current_location_id LIKE 'P%'                          THEN '70'
  END                                      AS to_whse_nbr,
  fil.asn_id                               AS asn_shpmt_nbr,
  fil.purchase_order_id                    AS po_nbr,
  fil.asn_id                               AS whse_transfer_nbr,
  di.item_id                               AS style,
  NULL                                     AS sku_id,
  substr(di.description, 1, 40)            AS sku_desc,
  NULL                                     AS assort_nbr,
  fil.on_hand_qty                          AS case_quantity,
  NULL                                     AS package_type,
  fil.current_location_id                  AS curr_locn_id,
  NULL                                     AS locn_id,
  fil.previous_location_id                 AS prev_locn_id,
  fil.destination_location_id              AS dest_locn_id,
  NULL                                     AS recv_locn_id,
  NULL                                     AS pick_locn_id,
  substr(fil.ch_stat_code, 1, 2)           AS ch_stat_code,
  fil.received_at                          AS recv_date_time,
  NULL                                     AS transfer_date_time,
  NULL                                     AS accepted_date_time,
  '00'                                     AS stat_code,
  fil.updated_at                           AS mod_date_time,
  fil.received_at                          AS create_date_time,
  substr(fil.updated_by, 1, 15)            AS user_id
FROM fact_ilpn_lifecycle fil
LEFT JOIN dim_item di ON fil.item_sk = di.item_sk;

-- ---- SIS_V ----
CREATE OR REPLACE VIEW v_sis
COMMENT 'Compat view matching SIS_V shape.'
AS
SELECT
  di.profile_id,
  di.ext_gegl_dcxx_virtual_whse AS whse,
  di.ext_gegl_dcxx_virtual_whse AS co,
  di.item_id                    AS item,
  di.short_description          AS item_description,
  '   '                         AS spl_instr_2,
  di.lpn_per_tier,
  dl.location_barcode           AS locn_brcd,
  di.unit_weight                AS unit_wt,
  di.unit_volume                AS unit_vol,
  di.tiers_per_pallet           AS lpn_per_plt,
  coalesce(fis.on_hand_qty, 0)            AS boh_qty,
  coalesce(fis.pick_location_qty, 0)      AS pick_locn_qty,
  coalesce(fis.ilpn_qty, 0)               AS ilpn_qty,
  coalesce(fis.allocated_qty, 0)          AS inv_alloc_inv,
  0                                       AS inv_qty_in_tran,
  coalesce(di.unit_price, 0)              AS inv_unit_price,
  coalesce(fis.available_qty, 0)          AS inv_not_alloc_qty,
  coalesce(di.catch_weight_item, ' ')     AS inv_catch_wt,
  coalesce(fis.to_be_filled_qty, 0)       AS inv_qty_to_be_alloc,
  di.item_pk                              AS sku_id,
  coalesce(di.average_weight, 0)          AS item_avg_wt,
  coalesce(di.unit_price, 0)              AS item_unit_price
FROM dim_item di
LEFT JOIN fact_inventory_snapshot fis ON di.item_sk = fis.item_sk
LEFT JOIN dim_location dl ON fis.location_sk = dl.location_sk
;

-- ---- ITEM_FIRST_RCPT ----
CREATE OR REPLACE VIEW v_item_first_rcpt
COMMENT 'Compat view matching ITEM_FIRST_RCPT shape. First receipt date per item.'
AS
SELECT di.item_id, min(d.full_date) AS first_rcpt_date
FROM fact_receiving_event fre
JOIN dim_item di ON fre.item_sk = di.item_sk
JOIN dim_date d  ON fre.date_sk = d.date_sk
GROUP BY di.item_id;

-- ---- TIME_DIFF (operational freshness diagnostic, kept as utility view) ----
CREATE OR REPLACE VIEW v_time_diff
COMMENT 'Compat view matching TIME_DIFF shape. Freshness diagnostic across critical tables.'
AS
SELECT 'DCI'  AS component, datediff(MINUTE, max(from_utc_timestamp(updated_timestamp, 'America/New_York')), from_utc_timestamp(current_timestamp(), 'America/New_York')) AS time_diff
FROM ge_poc.bronze.default_dcinventory_dci_inventory
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'PIX', datediff(MINUTE, max(from_utc_timestamp(updated_timestamp, 'America/New_York')), from_utc_timestamp(current_timestamp(), 'America/New_York'))
FROM ge_poc.bronze.default_pix_pix_pix_entry
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'TSK', datediff(MINUTE, max(from_utc_timestamp(updated_timestamp, 'America/New_York')), from_utc_timestamp(current_timestamp(), 'America/New_York'))
FROM ge_poc.bronze.default_task_tsk_task
WHERE __hevo__marked_deleted = 'FALSE';

-- ---- HBC_TASK_GROUP_DESC ----
CREATE OR REPLACE VIEW v_hbc_task_group_desc
COMMENT 'Compat view matching HBC_TASK_GROUP_DESC shape. Static task group reference. Sourced from dim_task_group.'
AS
SELECT description, task_group, transaction_id, source_zone_id
FROM dim_task_group;

-- ---- MISHA_TEST_V: NOT MIGRATED ----
-- Confirmed dev artifact. Intentionally not built in Gold native. Retire at cutover.

SHOW VIEWS IN gold_native;
