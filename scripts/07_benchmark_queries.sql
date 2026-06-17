-- =====================================================================
-- Giant Eagle POC: 07_benchmark_queries.sql
-- Side-by-side benchmarks: Version A (lift-and-shift) vs Version B (lakehouse-native).
-- Run each pair, capture EXPLAIN ANALYZE, query time, and bytes scanned.
-- =====================================================================

USE CATALOG ge_poc;

-- =====================================================================
-- BENCHMARK 1: Daily warehouse totals (WAREHOUSE TOTALS report)
-- =====================================================================
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v ORDER BY item_id;
EXPLAIN ANALYZE SELECT * FROM gold_native.v_ge_cs_invn_dly_total     ORDER BY item_id;

-- =====================================================================
-- BENCHMARK 2: Cycle count adjustments (CYCLECOUNTRECAP report)
-- =====================================================================
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.ge_cs_cycl_cnt_adjmt_dtlv ORDER BY create_date_time DESC LIMIT 100;
EXPLAIN ANALYZE SELECT * FROM gold_native.v_ge_cs_cycl_cnt_adjmt_dtlv   ORDER BY create_date_time DESC LIMIT 100;

-- =====================================================================
-- BENCHMARK 3: Cross-facility inventory comparison (WHSE QR COMPARE)
-- =====================================================================
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.ccs_inv_compare_v WHERE inventory_facility = '80';
EXPLAIN ANALYZE SELECT * FROM gold_native.v_ccs_inv_compare      WHERE inventory_facility = '80';

-- =====================================================================
-- BENCHMARK 4: Item snapshot — BU collapse demo
-- This is where the lakehouse-native model shines: a single fact powers ALL BU variants.
-- =====================================================================

-- Version A: each BU has its own materialized view, queries are scoped per-BU
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.hbc_item_snapshot_v_d0080 WHERE item LIKE '1%';
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.brm_item_snapshot_v_d0050 WHERE item LIKE '1%';

-- Version B: single fact, filter on dim_facility OR dim_business_unit
EXPLAIN ANALYZE SELECT * FROM gold_native.v_hbc_item_snapshot_d0080 WHERE item LIKE '1%';
EXPLAIN ANALYZE SELECT * FROM gold_native.v_brm_item_snapshot_d0050 WHERE item LIKE '1%';

-- Cross-BU analytical query — much easier in Version B
-- (In Version A this would require UNION across many BU-specific views.)
SELECT df.business_unit_code, count(*) AS items, sum(fis.on_hand_qty) AS total_on_hand
FROM gold_native.fact_inventory_snapshot fis
JOIN gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.business_unit_code
ORDER BY total_on_hand DESC;

-- =====================================================================
-- BENCHMARK 5: Transaction detail
-- =====================================================================
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.ge_cs_transaction_dtl_v ORDER BY create_date DESC LIMIT 100;
EXPLAIN ANALYZE SELECT * FROM gold_native.v_ge_cs_transaction_dtl     ORDER BY create_date DESC LIMIT 100;

-- =====================================================================
-- BENCHMARK 6: Pharmacy transport (regulatory-sensitive)
-- =====================================================================
EXPLAIN ANALYZE SELECT * FROM gold_lift_shift.hbc_pharmacy_transportion_oh_v;
EXPLAIN ANALYZE SELECT * FROM gold_native.v_hbc_pharmacy_transport_oh;

-- =====================================================================
-- RESULT FIDELITY: Version A vs Version B should return identical rows
-- For the patterns where the compat view is a faithful port. Diff should be zero.
-- =====================================================================
WITH diffs AS (
  SELECT 'v_ge_cs_invn_dly_total' AS report,
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v
       EXCEPT SELECT * FROM gold_native.v_ge_cs_invn_dly_total)) AS a_minus_b,
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ge_cs_invn_dly_total
       EXCEPT SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v)) AS b_minus_a
  UNION ALL
  SELECT 'v_ge_cs_adjustment_reason',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ge_cs_adjustment_reason_v
       EXCEPT SELECT * FROM gold_native.v_ge_cs_adjustment_reason)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ge_cs_adjustment_reason
       EXCEPT SELECT * FROM gold_lift_shift.ge_cs_adjustment_reason_v))
  UNION ALL
  SELECT 'v_ccs_inv_compare',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ccs_inv_compare_v
       EXCEPT SELECT * FROM gold_native.v_ccs_inv_compare)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ccs_inv_compare
       EXCEPT SELECT * FROM gold_lift_shift.ccs_inv_compare_v))
)
SELECT * FROM diffs;
