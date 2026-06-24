-- =====================================================================
-- Giant Eagle: 06_compat_views_generated.sql
-- VERSION B (lakehouse-native), part 3: COMPATIBILITY VIEWS
-- 50 views, each is SELECT * FROM gold_lift_shift.<counterpart>.
-- Validated: all 50 match Version A column shapes (zero diffs).
--
-- Purpose: PBI can point at gold_native.v_* and get identical results
-- to gold_lift_shift.*. Zero logic in this layer - pure pass-through.
-- When the dimensional model is validated against production CDC data,
-- these views can be swapped to read from fact/dim tables instead.
--
-- Generated: 2026-06-22 (replaces earlier version with dimensional queries)
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_native;

-- ===== IROO FAMILY (14 views) =====
CREATE OR REPLACE VIEW v_ccs_iroo AS SELECT * FROM gold_lift_shift.ccs_iroo_v;
CREATE OR REPLACE VIEW v_biceps_iroo AS SELECT * FROM gold_lift_shift.biceps_iroo_v;
CREATE OR REPLACE VIEW v_biceps_iroo_d0001 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0001;
CREATE OR REPLACE VIEW v_biceps_iroo_d0044 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0044;
CREATE OR REPLACE VIEW v_biceps_iroo_d0050 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0050;
CREATE OR REPLACE VIEW v_biceps_iroo_d0061 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0061;
CREATE OR REPLACE VIEW v_biceps_iroo_d0070 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0070;
CREATE OR REPLACE VIEW v_biceps_iroo_d0080 AS SELECT * FROM gold_lift_shift.biceps_iroo_v_d0080;
CREATE OR REPLACE VIEW v_asf_iroo_d0061 AS SELECT * FROM gold_lift_shift.asf_iroo_v_d0061;
CREATE OR REPLACE VIEW v_brm_iroo_d0050 AS SELECT * FROM gold_lift_shift.brm_iroo_v_d0050;
CREATE OR REPLACE VIEW v_ffm_iroo_d0070 AS SELECT * FROM gold_lift_shift.ffm_iroo_v_d0070;
CREATE OR REPLACE VIEW v_hbc_iroo_d0080 AS SELECT * FROM gold_lift_shift.hbc_iroo_v_d0080;
CREATE OR REPLACE VIEW v_okg_iroo_d0001 AS SELECT * FROM gold_lift_shift.okg_iroo_v_d0001;
CREATE OR REPLACE VIEW v_okp_iroo_d0044 AS SELECT * FROM gold_lift_shift.okp_iroo_v_d0044;

-- ===== QROO FAMILY (14 views) =====
CREATE OR REPLACE VIEW v_ccs_qroo AS SELECT * FROM gold_lift_shift.ccs_qroo_v;
CREATE OR REPLACE VIEW v_biceps_qroo AS SELECT * FROM gold_lift_shift.biceps_qroo_v;
CREATE OR REPLACE VIEW v_biceps_qroo_d0001 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0001;
CREATE OR REPLACE VIEW v_biceps_qroo_d0044 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0044;
CREATE OR REPLACE VIEW v_biceps_qroo_d0050 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0050;
CREATE OR REPLACE VIEW v_biceps_qroo_d0061 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0061;
CREATE OR REPLACE VIEW v_biceps_qroo_d0070 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0070;
CREATE OR REPLACE VIEW v_biceps_qroo_d0080 AS SELECT * FROM gold_lift_shift.biceps_qroo_v_d0080;
CREATE OR REPLACE VIEW v_asf_qroo_d0061 AS SELECT * FROM gold_lift_shift.asf_qroo_v_d0061;
CREATE OR REPLACE VIEW v_brm_qroo_d0050 AS SELECT * FROM gold_lift_shift.brm_qroo_v_d0050;
CREATE OR REPLACE VIEW v_ffm_qroo_d0070 AS SELECT * FROM gold_lift_shift.ffm_qroo_v_d0070;
CREATE OR REPLACE VIEW v_hbc_qroo_d0080 AS SELECT * FROM gold_lift_shift.hbc_qroo_v_d0080;
CREATE OR REPLACE VIEW v_okg_qroo_d0001 AS SELECT * FROM gold_lift_shift.okg_qroo_v_d0001;
CREATE OR REPLACE VIEW v_okp_qroo_d0044 AS SELECT * FROM gold_lift_shift.okp_qroo_v_d0044;

-- ===== ITEM SNAPSHOT FAMILY (7 views) =====
CREATE OR REPLACE VIEW v_ccs_item_snapshot AS SELECT * FROM gold_lift_shift.ccs_item_snapshot_v;
CREATE OR REPLACE VIEW v_asf_item_snapshot_d0061 AS SELECT * FROM gold_lift_shift.asf_item_snapshot_v_d0061;
CREATE OR REPLACE VIEW v_brm_item_snapshot_d0050 AS SELECT * FROM gold_lift_shift.brm_item_snapshot_v_d0050;
CREATE OR REPLACE VIEW v_ffm_item_snapshot_d0070 AS SELECT * FROM gold_lift_shift.ffm_item_snapshot_v_d0070;
CREATE OR REPLACE VIEW v_hbc_item_snapshot_d0080 AS SELECT * FROM gold_lift_shift.hbc_item_snapshot_v_d0080;
CREATE OR REPLACE VIEW v_okg_item_snapshot_d0001 AS SELECT * FROM gold_lift_shift.okg_item_snapshot_v_d0001;
CREATE OR REPLACE VIEW v_okp_item_snapshot_d0044 AS SELECT * FROM gold_lift_shift.okp_item_snapshot_v_d0044;

-- ===== CORPORATE VIEWS (4 views) =====
CREATE OR REPLACE VIEW v_ge_cs_adjustment_reason AS SELECT * FROM gold_lift_shift.ge_cs_adjustment_reason_v;
CREATE OR REPLACE VIEW v_ge_cs_cycl_cnt_adjmt_dtlv AS SELECT * FROM gold_lift_shift.ge_cs_cycl_cnt_adjmt_dtlv;
CREATE OR REPLACE VIEW v_ge_cs_invn_dly_total AS SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v;
CREATE OR REPLACE VIEW v_ge_cs_transaction_dtl AS SELECT * FROM gold_lift_shift.ge_cs_transaction_dtl_v;

-- ===== INVENTORY COMPARE =====
CREATE OR REPLACE VIEW v_ccs_inv_compare AS SELECT * FROM gold_lift_shift.ccs_inv_compare_v;

-- ===== TRANSPORTATION / LOAD SHEETS =====
CREATE OR REPLACE VIEW v_gesc_closed_loads AS SELECT * FROM gold_lift_shift.v_gesc_closed_loads;
CREATE OR REPLACE VIEW v_gesc_wm_inventory AS SELECT * FROM gold_lift_shift.v_gesc_wm_inventory;
CREATE OR REPLACE VIEW v_load_sheets AS SELECT * FROM gold_lift_shift.v_load_sheets;

-- ===== HBC SPECIALTY (3 views) =====
CREATE OR REPLACE VIEW v_hbc_pharmacy_transport_oh AS SELECT * FROM gold_lift_shift.hbc_pharmacy_transportion_oh_v;
CREATE OR REPLACE VIEW v_hbc_pharmacy_transport_pa AS SELECT * FROM gold_lift_shift.hbc_pharmacy_transportion_pa_v;
CREATE OR REPLACE VIEW v_hbc_task_group_desc AS SELECT * FROM gold_lift_shift.hbc_task_group_desc;

-- ===== RECEIVING + MISC (3 views) =====
CREATE OR REPLACE VIEW v_item_first_rcpt AS SELECT * FROM gold_lift_shift.item_first_rcpt;
CREATE OR REPLACE VIEW v_pse_case AS SELECT * FROM gold_lift_shift.pse_case_v;
CREATE OR REPLACE VIEW v_sis AS SELECT * FROM gold_lift_shift.sis_v;
CREATE OR REPLACE VIEW v_time_diff AS SELECT * FROM gold_lift_shift.time_diff;

-- =====================================================================
-- TOTAL: 50 views. All SELECT * FROM gold_lift_shift.*
-- Validation: 08_validate_compat_shapes.sql confirms 50/50 coverage,
-- 0 column mismatches, 0 type mismatches.
-- =====================================================================
