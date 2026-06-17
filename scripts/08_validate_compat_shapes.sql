-- =====================================================================
-- Giant Eagle POC: 08_validate_compat_shapes.sql
-- Column-by-column shape comparison between Version A and Version B.
--
-- The result-fidelity diff in 07_benchmark_queries.sql catches row differences
-- but won't surface a column drifting from DECIMAL to STRING if both sides are
-- empty. This script does the metadata-level check.
--
-- Run AFTER all of 03-06 have completed.
-- Expected result: every row's column_diff and type_diff columns return 0.
-- =====================================================================

USE CATALOG ge_poc;

-- ---------------------------------------------------------------------
-- Mapping table: Snowflake view -> Version A view -> Version B compat view
-- Add rows as new compat views are built. NULL b_view means "intentionally
-- not migrated" (currently: misha_test_v only).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY VIEW compat_mapping AS
SELECT * FROM VALUES
  ('GE_CS_INVN_DLY_TOTAL_V',         'gold_lift_shift.ge_cs_invn_dly_total_v',         'gold_native.v_ge_cs_invn_dly_total'),
  ('GE_CS_ADJUSTMENT_REASON_V',      'gold_lift_shift.ge_cs_adjustment_reason_v',      'gold_native.v_ge_cs_adjustment_reason'),
  ('GE_CS_CYCL_CNT_ADJMT_DTLV',      'gold_lift_shift.ge_cs_cycl_cnt_adjmt_dtlv',      'gold_native.v_ge_cs_cycl_cnt_adjmt_dtlv'),
  ('GE_CS_TRANSACTION_DTL_V',        'gold_lift_shift.ge_cs_transaction_dtl_v',        'gold_native.v_ge_cs_transaction_dtl'),
  ('CCS_INV_COMPARE_V',              'gold_lift_shift.ccs_inv_compare_v',              'gold_native.v_ccs_inv_compare'),
  ('CCS_IROO_V',                     'gold_lift_shift.ccs_iroo_v',                     'gold_native.v_ccs_iroo'),
  ('CCS_QROO_V',                     'gold_lift_shift.ccs_qroo_v',                     'gold_native.v_ccs_qroo'),
  ('CCS_ITEM_SNAPSHOT_V',            'gold_lift_shift.ccs_item_snapshot_v',            'gold_native.v_ccs_item_snapshot'),
  ('BICEPS_IROO_V',                  'gold_lift_shift.biceps_iroo_v',                  'gold_native.v_biceps_iroo'),
  ('BICEPS_IROO_V_D0001',            'gold_lift_shift.biceps_iroo_v_d0001',            'gold_native.v_biceps_iroo_d0001'),
  ('BICEPS_IROO_V_D0044',            'gold_lift_shift.biceps_iroo_v_d0044',            'gold_native.v_biceps_iroo_d0044'),
  ('BICEPS_IROO_V_D0050',            'gold_lift_shift.biceps_iroo_v_d0050',            'gold_native.v_biceps_iroo_d0050'),
  ('BICEPS_IROO_V_D0061',            'gold_lift_shift.biceps_iroo_v_d0061',            'gold_native.v_biceps_iroo_d0061'),
  ('BICEPS_IROO_V_D0070',            'gold_lift_shift.biceps_iroo_v_d0070',            'gold_native.v_biceps_iroo_d0070'),
  ('BICEPS_IROO_V_D0080',            'gold_lift_shift.biceps_iroo_v_d0080',            'gold_native.v_biceps_iroo_d0080'),
  ('BICEPS_QROO_V',                  'gold_lift_shift.biceps_qroo_v',                  'gold_native.v_biceps_qroo'),
  ('BICEPS_QROO_V_D0001',            'gold_lift_shift.biceps_qroo_v_d0001',            'gold_native.v_biceps_qroo_d0001'),
  ('BICEPS_QROO_V_D0044',            'gold_lift_shift.biceps_qroo_v_d0044',            'gold_native.v_biceps_qroo_d0044'),
  ('BICEPS_QROO_V_D0050',            'gold_lift_shift.biceps_qroo_v_d0050',            'gold_native.v_biceps_qroo_d0050'),
  ('BICEPS_QROO_V_D0061',            'gold_lift_shift.biceps_qroo_v_d0061',            'gold_native.v_biceps_qroo_d0061'),
  ('BICEPS_QROO_V_D0070',            'gold_lift_shift.biceps_qroo_v_d0070',            'gold_native.v_biceps_qroo_d0070'),
  ('BICEPS_QROO_V_D0080',            'gold_lift_shift.biceps_qroo_v_d0080',            'gold_native.v_biceps_qroo_d0080'),
  ('HBC_IROO_V_D0080',               'gold_lift_shift.hbc_iroo_v_d0080',               'gold_native.v_hbc_iroo_d0080'),
  ('HBC_QROO_V_D0080',               'gold_lift_shift.hbc_qroo_v_d0080',               'gold_native.v_hbc_qroo_d0080'),
  ('HBC_ITEM_SNAPSHOT_V_D0080',      'gold_lift_shift.hbc_item_snapshot_v_d0080',      'gold_native.v_hbc_item_snapshot_d0080'),
  ('HBC_PHARMACY_TRANSPORTION_OH_V', 'gold_lift_shift.hbc_pharmacy_transportion_oh_v', 'gold_native.v_hbc_pharmacy_transport_oh'),
  ('HBC_PHARMACY_TRANSPORTION_PA_V', 'gold_lift_shift.hbc_pharmacy_transportion_pa_v', 'gold_native.v_hbc_pharmacy_transport_pa'),
  ('HBC_TASK_GROUP_DESC',            'gold_lift_shift.hbc_task_group_desc',            'gold_native.v_hbc_task_group_desc'),
  ('ASF_IROO_V_D0061',               'gold_lift_shift.asf_iroo_v_d0061',               'gold_native.v_asf_iroo_d0061'),
  ('ASF_QROO_V_D0061',               'gold_lift_shift.asf_qroo_v_d0061',               'gold_native.v_asf_qroo_d0061'),
  ('ASF_ITEM_SNAPSHOT_V_D0061',      'gold_lift_shift.asf_item_snapshot_v_d0061',      'gold_native.v_asf_item_snapshot_d0061'),
  ('BRM_IROO_V_D0050',               'gold_lift_shift.brm_iroo_v_d0050',               'gold_native.v_brm_iroo_d0050'),
  ('BRM_QROO_V_D0050',               'gold_lift_shift.brm_qroo_v_d0050',               'gold_native.v_brm_qroo_d0050'),
  ('BRM_ITEM_SNAPSHOT_V_D0050',      'gold_lift_shift.brm_item_snapshot_v_d0050',      'gold_native.v_brm_item_snapshot_d0050'),
  ('FFM_IROO_V_D0070',               'gold_lift_shift.ffm_iroo_v_d0070',               'gold_native.v_ffm_iroo_d0070'),
  ('FFM_QROO_V_D0070',               'gold_lift_shift.ffm_qroo_v_d0070',               'gold_native.v_ffm_qroo_d0070'),
  ('FFM_ITEM_SNAPSHOT_V_D0070',      'gold_lift_shift.ffm_item_snapshot_v_d0070',      'gold_native.v_ffm_item_snapshot_d0070'),
  ('OKG_IROO_V_D0001',               'gold_lift_shift.okg_iroo_v_d0001',               'gold_native.v_okg_iroo_d0001'),
  ('OKG_QROO_V_D0001',               'gold_lift_shift.okg_qroo_v_d0001',               'gold_native.v_okg_qroo_d0001'),
  ('OKG_ITEM_SNAPSHOT_V_D0001',      'gold_lift_shift.okg_item_snapshot_v_d0001',      'gold_native.v_okg_item_snapshot_d0001'),
  ('OKP_IROO_V_D0044',               'gold_lift_shift.okp_iroo_v_d0044',               'gold_native.v_okp_iroo_d0044'),
  ('OKP_QROO_V_D0044',               'gold_lift_shift.okp_qroo_v_d0044',               'gold_native.v_okp_qroo_d0044'),
  ('OKP_ITEM_SNAPSHOT_V_D0044',      'gold_lift_shift.okp_item_snapshot_v_d0044',      'gold_native.v_okp_item_snapshot_d0044'),
  ('V_GESC_CLOSED_LOADS',            'gold_lift_shift.v_gesc_closed_loads',             'gold_native.v_gesc_closed_loads'),
  ('V_GESC_WM_INVENTORY',            'gold_lift_shift.v_gesc_wm_inventory',             'gold_native.v_gesc_wm_inventory'),
  ('V_LOAD_SHEETS',                  'gold_lift_shift.v_load_sheets',                   'gold_native.v_load_sheets'),
  ('PSE_CASE_V',                     'gold_lift_shift.pse_case_v',                      'gold_native.v_pse_case'),
  ('SIS_V',                          'gold_lift_shift.sis_v',                           'gold_native.v_sis'),
  ('ITEM_FIRST_RCPT',                'gold_lift_shift.item_first_rcpt',                 'gold_native.v_item_first_rcpt'),
  ('TIME_DIFF',                      'gold_lift_shift.time_diff',                       'gold_native.v_time_diff'),
  ('MISHA_TEST_V',                   'gold_lift_shift.misha_test_v',                    NULL)   -- intentionally not migrated
  AS t(snowflake_view, a_view, b_view);

-- ---------------------------------------------------------------------
-- Pull column metadata from information_schema for both sides.
-- Then surface any view where:
--   - column count differs
--   - column names differ (in position)
--   - data types differ for same-position columns
-- ---------------------------------------------------------------------
WITH a_cols AS (
  SELECT lower(c.table_schema || '.' || c.table_name) AS qualified_view,
         c.column_name, c.data_type, c.ordinal_position
  FROM information_schema.columns c
  WHERE c.table_catalog = 'ge_poc' AND c.table_schema = 'gold_lift_shift'
),
b_cols AS (
  SELECT lower(c.table_schema || '.' || c.table_name) AS qualified_view,
         c.column_name, c.data_type, c.ordinal_position
  FROM information_schema.columns c
  WHERE c.table_catalog = 'ge_poc' AND c.table_schema = 'gold_native'
),
matched AS (
  SELECT m.snowflake_view, m.a_view, m.b_view,
         a.column_name AS a_col, a.data_type AS a_type,
         b.column_name AS b_col, b.data_type AS b_type,
         a.ordinal_position AS pos
  FROM compat_mapping m
  LEFT JOIN a_cols a ON a.qualified_view = lower(m.a_view)
  LEFT JOIN b_cols b ON b.qualified_view = lower(m.b_view) AND b.ordinal_position = a.ordinal_position
  WHERE m.b_view IS NOT NULL
)
SELECT snowflake_view,
       count(*)                                                    AS columns_in_a,
       count(CASE WHEN b_col IS NULL THEN 1 END)                   AS missing_in_b,
       count(CASE WHEN lower(a_col) != lower(b_col) THEN 1 END)    AS name_mismatches,
       count(CASE WHEN a_type != b_type THEN 1 END)                AS type_mismatches,
       collect_list(CASE WHEN lower(a_col) != lower(b_col) OR a_type != b_type
                         THEN concat(pos, ': ', a_col, '(', a_type, ') vs ', coalesce(b_col, '<missing>'), '(', coalesce(b_type, ''), ')') END) AS diffs
FROM matched
GROUP BY snowflake_view, a_view, b_view
HAVING missing_in_b + name_mismatches + type_mismatches > 0
ORDER BY type_mismatches DESC, name_mismatches DESC, missing_in_b DESC, snowflake_view;

-- A clean run returns ZERO rows.
-- Any row returned is a compat view that needs adjustment to match its Version A counterpart.

-- ---------------------------------------------------------------------
-- Bonus: count of compat coverage
-- ---------------------------------------------------------------------
SELECT
  count(*) AS total_snowflake_views,
  count(CASE WHEN b_view IS NULL THEN 1 END) AS intentionally_not_migrated,
  count(CASE WHEN b_view IS NOT NULL THEN 1 END) AS expected_compat_count
FROM compat_mapping;
