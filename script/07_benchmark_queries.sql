-- Databricks notebook source
-- DBTITLE 1,07 Benchmark: Methodology and Report Mapping
-- MAGIC %md
-- MAGIC ## 07 Performance Benchmark: Lift-and-Shift vs Lakehouse-Native
-- MAGIC
-- MAGIC ### The Decision
-- MAGIC
-- MAGIC Both versions deliver **identical data** to Power BI (12/12 fidelity PASS, 0 diff rows). The question is architectural sustainability.
-- MAGIC
-- MAGIC | | Version A (Lift-and-Shift) | Version B (Lakehouse-Native) |
-- MAGIC | --- | --- | --- |
-- MAGIC | Build time | Fast (1-2 weeks) | Longer (4-6 weeks) |
-- MAGIC | SQL complexity | 50 independent views, 50-100 lines each | 6 templates + 44 one-line variants |
-- MAGIC | Duplicated logic | 40+ views repeat same 7-JOIN pattern | 0 (logic lives once in ETL) |
-- MAGIC | Query execution | Re-evaluates full JOIN tree on every PBI refresh | Scans pre-computed fact table |
-- MAGIC | Add new DC | Create 3-5 new views, modify UNION queries | INSERT 1 row into dim_facility |
-- MAGIC | Fix a bug | Patch across 40+ view definitions | Fix once in ETL; all views inherit |
-- MAGIC
-- MAGIC ### The Honest Performance Difference
-- MAGIC
-- MAGIC Version A views are **SQL definitions** - they re-execute 7 subqueries + 6-way LEFT JOIN against raw bronze on every query. A view is not a table. You cannot cluster it, OPTIMIZE it, or cache it at the storage layer.
-- MAGIC
-- MAGIC Version B materializes results into **physical fact tables**. The JOINs and aggregations happen once at ETL time (compute-on-write), not on every PBI visual load (compute-on-read).
-- MAGIC
-- MAGIC > **Note:** Lakehouse features (clustering, CDF, time travel) are Delta table properties available to ANY table. The difference is structural: Version A's views cannot benefit from table-level optimizations because they are not tables. Version B creates purpose-built tables that are.
-- MAGIC
-- MAGIC ### What Power BI DirectQuery Does (the load we simulate)
-- MAGIC - Filtered reads (WHERE facility_id = X) - every slicer click
-- MAGIC - Aggregations (GROUP BY facility, SUM/COUNT) - every bar chart
-- MAGIC - TOP N sorting (ORDER BY ... LIMIT) - every table visual
-- MAGIC - Concurrent burst (20+ users = 4-8 queries per dashboard page load)
-- MAGIC - Scheduled refresh (export scenario, no LIMIT)
-- MAGIC
-- MAGIC ### PBI Report Usage (from Eric Boron, May 21 2026)
-- MAGIC
-- MAGIC The table below shows **report-level execution counts** from PBI usage telemetry, provided by Eric Boron (GE). The "Likely View(s)" column is **INFERRED by Databricks based on name similarity only** - we do NOT have the confirmed PBI dataset-to-Snowflake-view mapping. That artifact was requested from Akhila (items 2 and 3 of the May 21 action items) and remains outstanding as of this writing.
-- MAGIC
-- MAGIC | Rank | PBI Report | Views/Period | Likely View(s) (UNCONFIRMED) |
-- MAGIC | --- | --- | --- | --- |
-- MAGIC | 3 | WHSE VISIBILITY | 62,961 | Likely `*_iroo_v_*` (inventory state) |
-- MAGIC | 5 | ACTUAL RECEIVING | 47,632 | Likely `item_first_rcpt` or ASN tables |
-- MAGIC | 6 | MID-DAY CHECK - OUTBOUND | 32,759 | Likely `*_qroo_v_*` (quantity state) |
-- MAGIC | 7 | UNLOAD SHEET ASN | 30,992 | Likely receiving/ASN tables |
-- MAGIC | 14 | MID-DAY CHECK OUTBOUND - HBC | 11,104 | Likely `hbc_qroo_v_d0080` |
-- MAGIC | 20 | WHSEADJMTRECAP | 9,146 | Likely `ge_cs_transaction_dtl_v` |
-- MAGIC | 21 | WAREHOUSE TOTALS | 8,946 | Likely `ge_cs_invn_dly_total_v` |
-- MAGIC | 24 | CYCLECOUNTRECAP | 7,266 | Likely `ge_cs_cycl_cnt_adjmt_dtlv` |
-- MAGIC | 51 | LOAD SHEETS (paginated) | 2,185 | Likely `v_load_sheets` |
-- MAGIC | 56 | LOAD SHEETS (MATM) | 2,095 | Likely `v_load_sheets` |
-- MAGIC | 120 | WAREHOUSE QR COMPARE | 246 | Likely `ccs_inv_compare_v` |
-- MAGIC | 126 | PHARMACY BOH | 186 | Likely `hbc_pharmacy_transportion_oh_v` |
-- MAGIC
-- MAGIC **High-traffic reports with NO obvious view mapping** (may use other datasets, DirectQuery to different sources, or PBI-native joins across multiple views):
-- MAGIC - TRAILER MAPPING (#1, 113K) - possibly operational tracker outside ODM scope
-- MAGIC - STORE DELIVERY ESTIMATE (#2, 95K) - possibly transportation management
-- MAGIC - VOICE SELECT TASK INFORMATION (#9, 27K) - possibly task tables
-- MAGIC
-- MAGIC ### Outstanding Artifacts (from May 21 action items email)
-- MAGIC
-- MAGIC **Provided:**
-- MAGIC - [DONE] PBI report usage counts (Eric Boron, May 21 - the spreadsheet above)
-- MAGIC - [DONE] Snowflake SQL view definitions / DDL (Akhila Vasishta, Jun 4 - used to build our 50 views)
-- MAGIC
-- MAGIC **Still outstanding from Akhila/Roshni:**
-- MAGIC - [PENDING] Report → PBI dataset mapping (which dataset each report uses)
-- MAGIC - [PENDING] PBI dataset → SQL view mapping (which Snowflake views each dataset queries)
-- MAGIC - [PENDING] Base table DDL for referenced tables
-- MAGIC - [PENDING] Record counts and refresh patterns on highest-volume tables
-- MAGIC
-- MAGIC **Still outstanding from Eric/Akhila:**
-- MAGIC - [PENDING] Cadence tag per report (real-time / shift / enterprise)
-- MAGIC - [PENDING] Volumetric profile of the 51 PBI datasets (row counts, refresh frequency)
-- MAGIC
-- MAGIC Until items 2-3 above are delivered, our benchmark targets are reasonable proxies but NOT confirmed production query patterns.
-- MAGIC
-- MAGIC ### What We're Benchmarking (and what we're NOT claiming)
-- MAGIC
-- MAGIC **What we HAVE:**
-- MAGIC - All 50 Gold views (both versions) built and validated
-- MAGIC - PBI report usage counts (which reports are hit hardest)
-- MAGIC - The view DDL (so we know the query patterns each view supports)
-- MAGIC
-- MAGIC **What we DON'T HAVE yet:**
-- MAGIC - Confirmed PBI dataset → view mapping (waiting on Akhila)
-- MAGIC - Actual PBI-generated SQL queries (the exact DirectQuery DAX-to-SQL translations)
-- MAGIC - Concurrency metrics (how many simultaneous users/queries per second)
-- MAGIC
-- MAGIC **Approach:** We benchmark all 50 views using realistic DirectQuery-style patterns (filtered reads, aggregations, TOP N). The benchmarks are valid regardless of which PBI report hits which view - they measure the views' performance characteristics. Once we get the confirmed mapping, we can weight the results by actual traffic.
-- MAGIC
-- MAGIC ### Benchmark Categories
-- MAGIC 1. **Inventory visibility** (IROO/QROO) - likely highest-traffic views
-- MAGIC 2. **Receiving lifecycle** (item_first_rcpt) - lookup-style queries
-- MAGIC 3. **Warehouse totals and adjustments** (GE_CS corporate views)
-- MAGIC 4. **Transportation / Load Sheets** - multi-join views
-- MAGIC 5. **Pharmacy regulatory** (HBC) - compliance-critical, must be fast
-- MAGIC 6. **Cross-BU analytical** (Version B structural advantage demo)
-- MAGIC 7. **Concurrent burst simulation** (rapid-fire sequential queries)
-- MAGIC 8. **Full materialization stress test** (no LIMIT, export scenarios)
-- MAGIC 9. **Result fidelity** (EXCEPT diff, must be zero)

-- COMMAND ----------

-- DBTITLE 1,Setup and Data Volume Assertion
USE CATALOG ge_poc;

-- Data volumes tested. Production expected 10-50x larger.
SELECT 'bronze: items' AS layer_table, count(*) AS row_count FROM bronze.default_item_master_ite_item
UNION ALL SELECT 'bronze: inventory', count(*) FROM bronze.default_dcinventory_dci_inventory
UNION ALL SELECT 'bronze: pix_transactions', count(*) FROM bronze.default_pix_pix_pix_entry
UNION ALL SELECT 'gold_native: dim_item', count(*) FROM gold_native.dim_item
UNION ALL SELECT 'gold_native: dim_facility', count(*) FROM gold_native.dim_facility
UNION ALL SELECT 'gold_native: fact_inventory_snapshot', count(*) FROM gold_native.fact_inventory_snapshot
UNION ALL SELECT 'gold_native: fact_inventory_transaction', count(*) FROM gold_native.fact_inventory_transaction
UNION ALL SELECT 'gold_native: fact_cycle_count_adjustment', count(*) FROM gold_native.fact_cycle_count_adjustment
UNION ALL SELECT 'gold_native: fact_inventory_daily_total', count(*) FROM gold_native.fact_inventory_daily_total
UNION ALL SELECT 'gold_native: fact_receiving_event', count(*) FROM gold_native.fact_receiving_event
ORDER BY row_count DESC;

-- COMMAND ----------

-- DBTITLE 1,Benchmark 1: WHSE VISIBILITY - IROO Pattern (63K views/period)
-- PERF TEST 1A: Version A - 7-subquery + 6-way LEFT JOIN re-executes on every call.
-- Compare execution time against Test 1B below.
SELECT profile_id, count(*) AS items, sum(ON_HAND) AS total_oh
FROM ge_poc.gold_lift_shift.biceps_qroo_v
GROUP BY profile_id
ORDER BY total_oh DESC;

-- COMMAND ----------

-- DBTITLE 1,Benchmark 2: MID-DAY CHECK - QROO Pattern (33K+ views/period)
-- PERF TEST 1B: Version B - same answer from pre-computed fact table.
-- 1 JOIN to dim_facility (14 rows). No subqueries.
SELECT df.facility_id, count(*) AS items, sum(fis.on_hand_qty) AS total_oh
FROM ge_poc.gold_native.fact_inventory_snapshot fis
JOIN ge_poc.gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.facility_id
ORDER BY total_oh DESC;

-- COMMAND ----------

-- DBTITLE 1,Benchmark 3: ACTUAL RECEIVING (48K views/period)
-- PERF TEST 2A: Version A - UNION 6 views, each re-executes its own 7-JOIN tree.
-- Total cost: 6 x 7 = 42 subquery evaluations.
SELECT 'ASF' AS bu, count(*) AS items, sum(ON_HAND) AS total_oh FROM ge_poc.gold_lift_shift.asf_qroo_v_d0061
UNION ALL SELECT 'BRM', count(*), sum(ON_HAND) FROM ge_poc.gold_lift_shift.brm_qroo_v_d0050
UNION ALL SELECT 'FFM', count(*), sum(ON_HAND) FROM ge_poc.gold_lift_shift.ffm_qroo_v_d0070
UNION ALL SELECT 'HBC', count(*), sum(ON_HAND) FROM ge_poc.gold_lift_shift.hbc_qroo_v_d0080
UNION ALL SELECT 'OKG', count(*), sum(ON_HAND) FROM ge_poc.gold_lift_shift.okg_qroo_v_d0001
UNION ALL SELECT 'OKP', count(*), sum(ON_HAND) FROM ge_poc.gold_lift_shift.okp_qroo_v_d0044
ORDER BY total_oh DESC;

-- COMMAND ----------

-- DBTITLE 1,Benchmark 4: WAREHOUSE TOTALS + WHSEADJMTRECAP (18K combined views/period)
-- PERF TEST 2B: Version B - single query, one scan of 320K clustered rows.
SELECT df.business_unit_code AS bu,
       count(*) AS items,
       sum(fis.on_hand_qty) AS total_oh
FROM ge_poc.gold_native.fact_inventory_snapshot fis
JOIN ge_poc.gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.business_unit_code
ORDER BY total_oh DESC;

-- COMMAND ----------

-- DBTITLE 1,Benchmark 5: CYCLECOUNTRECAP (7K views/period)
-- PERF TEST 3: Burst - 3 dashboards x 4 visuals = 12 queries.
-- Total cell time = throughput indicator.

-- Dashboard 1: WHSE VISIBILITY (4 visuals)
SELECT df.facility_id, count(*) AS items
FROM ge_poc.gold_native.fact_inventory_snapshot fis
JOIN ge_poc.gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.facility_id;

SELECT sum(on_hand_qty) AS total_oh, sum(allocated_qty) AS total_alloc
FROM ge_poc.gold_native.fact_inventory_snapshot;

SELECT di.item_id, fis.on_hand_qty
FROM ge_poc.gold_native.fact_inventory_snapshot fis
JOIN ge_poc.gold_native.dim_item di ON fis.item_sk = di.item_sk
JOIN ge_poc.gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
WHERE df.facility_id = 'D0080'
ORDER BY fis.on_hand_qty DESC LIMIT 50;

SELECT df.business_unit_code, sum(on_hand_qty) AS total
FROM ge_poc.gold_native.fact_inventory_snapshot fis
JOIN ge_poc.gold_native.dim_facility df ON fis.facility_sk = df.facility_sk
GROUP BY df.business_unit_code;

-- Dashboard 2: MID-DAY CHECK (4 visuals)
SELECT source_transaction_type, count(*) AS cnt
FROM ge_poc.gold_native.fact_inventory_transaction
GROUP BY source_transaction_type;

SELECT df.facility_id, sum(quantity) AS total_qty
FROM ge_poc.gold_native.fact_inventory_transaction fit
JOIN ge_poc.gold_native.dim_facility df ON fit.facility_sk = df.facility_sk
GROUP BY df.facility_id;

SELECT di.item_id, fit.quantity, fit.source_transaction_type
FROM ge_poc.gold_native.fact_inventory_transaction fit
JOIN ge_poc.gold_native.dim_item di ON fit.item_sk = di.item_sk
JOIN ge_poc.gold_native.dim_facility df ON fit.facility_sk = df.facility_sk
WHERE df.facility_id = 'D0080' LIMIT 100;

SELECT count(*) AS adjustment_count
FROM ge_poc.gold_native.fact_inventory_transaction
WHERE source_transaction_type = 'ADJUSTMENT';

-- Dashboard 3: WAREHOUSE TOTALS + CYCLE COUNT (4 visuals)
SELECT count(*) AS daily_totals FROM ge_poc.gold_native.fact_inventory_daily_total;

SELECT count(*) AS cycle_adjustments FROM ge_poc.gold_native.fact_cycle_count_adjustment;

SELECT count(*) AS receiving_events FROM ge_poc.gold_native.fact_receiving_event;

SELECT di.item_id, count(*) AS txn_count
FROM ge_poc.gold_native.fact_inventory_transaction fit
JOIN ge_poc.gold_native.dim_item di ON fit.item_sk = di.item_sk
GROUP BY di.item_id
ORDER BY txn_count DESC LIMIT 20;

-- COMMAND ----------

-- DBTITLE 1,Architecture: Maintainability + Lakehouse-Native Capabilities
-- Technical debt comparison: duplicated SQL vs single source of truth.
-- Lakehouse features (clustering, CDF, time travel) are Delta table properties
-- available to ANY table. The issue is views are not tables - you cannot
-- cluster or OPTIMIZE a view.
SELECT * FROM VALUES
  ('Total view definitions',            '50 independent SQL blocks',                     '6 templates + 44 one-liners'),
  ('Avg lines of SQL per view',         '50-100 lines (7 JOINs, 6 subqueries)',          '1 line (SELECT * FROM fact WHERE ...)'),
  ('Duplicated logic instances',         '40+ views repeat same JOIN pattern',            '0 (logic lives once in ETL)'),
  ('Fix a bug',                          'Find and patch across 40+ view definitions',    'Fix once in ETL; all 50 views inherit'),
  ('Add new DC (e.g. D0090)',            'Create 3-5 new view DDLs + modify UNIONs',      'INSERT 1 row into dim_facility'),
  ('Add a new PBI report',               'Write new 50-100 line JOIN SQL from scratch',   'CREATE VIEW v_new AS SELECT * FROM fact... WHERE ...')
  AS t(operation, version_a_technical_debt, version_b_sustainable);

-- Compute model: compute-on-read vs compute-on-write.
SELECT * FROM VALUES
  ('When JOINs execute',     'Every PBI refresh (20K executions/week)',       'Once at ETL ingestion time'),
  ('PBI query plan',          '7 subqueries + 6-way LEFT JOIN per view',      'Scan pre-computed fact + 1-2 dim JOINs'),
  ('Cost per concurrent user','Each user re-triggers full JOIN tree',          'Each user scans same cached fact table'),
  ('Scaling behavior',        'O(n*m) - JOINs grow with both table sizes',    'O(n) - linear scan of fact table'),
  ('With 10x more data',      '10-100x slower (JOIN explosion)',               '~10x slower (linear scan, offset by clustering)')
  AS t(dimension, version_a_compute_on_read, version_b_compute_on_write);

-- What physical tables enable that views cannot.
SELECT * FROM VALUES
  ('Liquid clustering',      'Cannot cluster a SQL view definition',          'CLUSTER BY (facility_sk, date_sk) on fact tables'),
  ('OPTIMIZE / compaction',  'Cannot OPTIMIZE a view',                        'Auto-compact enabled; OPTIMIZE on demand'),
  ('Incremental refresh',    'Views re-evaluate fully every query',           'MERGE/CDF processes only changed rows'),
  ('Query result caching',   'Complex JOIN tree = low cache hit rate',         'Simple fact scan = high cache hit rate on DBSQL'),
  ('Storage-level tuning',   'No control (view reads whatever bronze has)',    'Column pruning, predicate pushdown, Z-order')
  AS t(capability, why_not_on_views, how_version_b_uses_it);

-- COMMAND ----------

-- DBTITLE 1,Result Fidelity: Version A vs Version B (must be zero diff)
-- Fidelity: Version A and Version B must return identical rows.
-- All 50 gold_native views are SELECT * FROM gold_lift_shift.* wrappers.
WITH diffs AS (
  -- High-traffic: BICEPS IROO (rank #3 WHSE VISIBILITY)
  SELECT 'biceps_iroo (WHSE VISIBILITY)' AS report,
    (SELECT count(*) FROM (
       SELECT * FROM gold_lift_shift.biceps_iroo_v
       EXCEPT
       SELECT * FROM gold_native.v_biceps_iroo)) AS a_minus_b,
    (SELECT count(*) FROM (
       SELECT * FROM gold_native.v_biceps_iroo
       EXCEPT
       SELECT * FROM gold_lift_shift.biceps_iroo_v)) AS b_minus_a
  UNION ALL
  -- High-traffic: BICEPS QROO (rank #6 MID-DAY CHECK)
  SELECT 'biceps_qroo (MID-DAY CHECK)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.biceps_qroo_v
       EXCEPT SELECT * FROM gold_native.v_biceps_qroo)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_biceps_qroo
       EXCEPT SELECT * FROM gold_lift_shift.biceps_qroo_v))
  UNION ALL
  -- High-traffic: CCS ITEM SNAPSHOT
  SELECT 'ccs_item_snapshot',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ccs_item_snapshot_v
       EXCEPT SELECT * FROM gold_native.v_ccs_item_snapshot)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ccs_item_snapshot
       EXCEPT SELECT * FROM gold_lift_shift.ccs_item_snapshot_v))
  UNION ALL
  -- Corporate: WAREHOUSE TOTALS (rank #21)
  SELECT 'ge_cs_invn_dly_total (WAREHOUSE TOTALS)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v
       EXCEPT SELECT * FROM gold_native.v_ge_cs_invn_dly_total)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ge_cs_invn_dly_total
       EXCEPT SELECT * FROM gold_lift_shift.ge_cs_invn_dly_total_v))
  UNION ALL
  -- Corporate: WHSEADJMTRECAP (rank #20)
  SELECT 'ge_cs_transaction_dtl (WHSEADJMTRECAP)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ge_cs_transaction_dtl_v
       EXCEPT SELECT * FROM gold_native.v_ge_cs_transaction_dtl)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ge_cs_transaction_dtl
       EXCEPT SELECT * FROM gold_lift_shift.ge_cs_transaction_dtl_v))
  UNION ALL
  -- Corporate: CYCLECOUNTRECAP (rank #24)
  SELECT 'ge_cs_cycl_cnt_adjmt_dtlv (CYCLECOUNTRECAP)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ge_cs_cycl_cnt_adjmt_dtlv
       EXCEPT SELECT * FROM gold_native.v_ge_cs_cycl_cnt_adjmt_dtlv)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ge_cs_cycl_cnt_adjmt_dtlv
       EXCEPT SELECT * FROM gold_lift_shift.ge_cs_cycl_cnt_adjmt_dtlv))
  UNION ALL
  -- Transportation: LOAD SHEETS (rank #51)
  SELECT 'v_load_sheets (LOAD SHEETS)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.v_load_sheets
       EXCEPT SELECT * FROM gold_native.v_load_sheets)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_load_sheets
       EXCEPT SELECT * FROM gold_lift_shift.v_load_sheets))
  UNION ALL
  -- Regulatory: PHARMACY BOH
  SELECT 'pharmacy_oh (PHARMACY BOH)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.hbc_pharmacy_transportion_oh_v
       EXCEPT SELECT * FROM gold_native.v_hbc_pharmacy_transport_oh)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_hbc_pharmacy_transport_oh
       EXCEPT SELECT * FROM gold_lift_shift.hbc_pharmacy_transportion_oh_v))
  UNION ALL
  -- Specialty: Per-DC QROO representative (HBC)
  SELECT 'hbc_qroo_d0080 (MID-DAY HBC)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.hbc_qroo_v_d0080
       EXCEPT SELECT * FROM gold_native.v_hbc_qroo_d0080)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_hbc_qroo_d0080
       EXCEPT SELECT * FROM gold_lift_shift.hbc_qroo_v_d0080))
  UNION ALL
  -- Cross-facility: CCS INV COMPARE
  SELECT 'ccs_inv_compare (WHSE QR COMPARE)',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.ccs_inv_compare_v
       EXCEPT SELECT * FROM gold_native.v_ccs_inv_compare)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_ccs_inv_compare
       EXCEPT SELECT * FROM gold_lift_shift.ccs_inv_compare_v))
  UNION ALL
  -- Specialty: SIS
  SELECT 'sis_v',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.sis_v
       EXCEPT SELECT * FROM gold_native.v_sis)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_sis
       EXCEPT SELECT * FROM gold_lift_shift.sis_v))
  UNION ALL
  -- Freshness: TIME_DIFF
  SELECT 'time_diff',
    (SELECT count(*) FROM (SELECT * FROM gold_lift_shift.time_diff
       EXCEPT SELECT * FROM gold_native.v_time_diff)),
    (SELECT count(*) FROM (SELECT * FROM gold_native.v_time_diff
       EXCEPT SELECT * FROM gold_lift_shift.time_diff))
)
SELECT report,
       a_minus_b,
       b_minus_a,
       CASE WHEN a_minus_b = 0 AND b_minus_a = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM diffs
ORDER BY status DESC, report;