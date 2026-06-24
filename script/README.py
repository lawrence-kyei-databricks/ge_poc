# Databricks notebook source
# DBTITLE 1,README
# MAGIC %md
# MAGIC # Giant Eagle: Gold-Layer Remodel
# MAGIC
# MAGIC ## Purpose
# MAGIC
# MAGIC This bundle is a Gold-layer prototype, a side-by-side comparison, and a decision artifact. It is not a production pipeline. The dim and fact DDL, the compatibility view pattern, and the validation scripts are the design contract Databricks is committing to deliver. Manhattan to Data Save to Lakeflow Connect CDC to Bronze and Silver SCD2 conformance are owned by the source-side track that runs jointly with Manhattan and Giant Eagle - different workstream. The synthetic Bronze in scripts 01 and 02 is scaffolding so the SQL is executable in isolation; throw it away at handoff. When real Silver lands upstream, the dim and fact INSERTs change their FROM clauses from `ge_poc.bronze.*` to the production `silver.*` schema, and become DLT pipelines or scheduled jobs. The compatibility views and the Power BI datasets do not change.
# MAGIC
# MAGIC ## What's in this bundle
# MAGIC
# MAGIC | File | What it is |
# MAGIC |---|---|
# MAGIC | `giant_eagle_poc.docx` | POC plan: scope, side-by-side approach, hybrid recommendation, milestones with owners, cost positioning, caveats, risks |
# MAGIC | `giant_eagle_gold_model.svg` | Comprehensive Gold layer diagram (rendered) |
# MAGIC | `giant_eagle_gold_model.drawio` | Same diagram, importable to draw.io / diagrams.net for editing |
# MAGIC | `scripts/00_setup.sql` | Catalog and schemas |
# MAGIC | `scripts/01_bronze_sample_tables.sql` | 35 reverse-engineered Manhattan base tables (sample) |
# MAGIC | `scripts/02_sample_data.sql` | Scaled synthetic data (~10K items, ~50K inventory, ~250K PIX transactions) |
# MAGIC | `scripts/03_gold_lift_shift_all_views.sql` | **Version A**: 50 Snowflake views ported and validated (reads `gold_lift_shift_ddl.sql`) |
# MAGIC | `scripts/04_gold_native_dimensions.sql` | **Version B (part 1)**: 9 conformed dimensions including dim_task_group |
# MAGIC | `scripts/05_gold_native_facts.sql` | **Version B (part 2)**: 12 fact tables, liquid-clustered |
# MAGIC | `scripts/06_gold_native_compat_views.sql` | **Version B (part 3)**: 50 compatibility views matching Version A column shapes |
# MAGIC | `scripts/07_benchmark_queries.sql` | Side-by-side EXPLAIN ANALYZE pairs and result-fidelity diffs |
# MAGIC | `scripts/08_validate_compat_shapes.sql` | Column-by-column metadata diff between Version A and Version B compat views |
# MAGIC
# MAGIC ## Run order
# MAGIC
# MAGIC ```
# MAGIC 00_setup.sql
# MAGIC 01_bronze_sample_tables.sql
# MAGIC 02_sample_data.sql                       (~30 seconds with scaled volumes)
# MAGIC 03_gold_lift_shift_all_views.sql         (Version A - validated against original GE Snowflake Views DDL)
# MAGIC 04_gold_native_dimensions.sql            (Version B)
# MAGIC 05_gold_native_facts.sql                 (Version B)
# MAGIC 06_gold_native_compat_views.sql          (Version B)
# MAGIC 07_benchmark_queries.sql                 (optional)
# MAGIC 08_validate_compat_shapes.sql            (required before claiming compat)
# MAGIC ```
# MAGIC
# MAGIC ## Coverage
# MAGIC
# MAGIC ```
# MAGIC ge_poc/
# MAGIC ├── bronze/                              35 sample base tables + 1 mock external
# MAGIC │
# MAGIC ├── gold_lift_shift/                     ← Version A: 50 Delta views, 1:1 from Snowflake
# MAGIC │   ├── ge_cs_*                          (4: invn_dly_total, adjustment_reason, cycl_cnt_adjmt_dtlv, transaction_dtl)
# MAGIC │   ├── ccs_*                            (4: inv_compare, iroo, qroo, item_snapshot)
# MAGIC │   ├── biceps_*                         (14: iroo/qroo template + 6 per-DC variants each)
# MAGIC │   ├── hbc_*                            (6: iroo, qroo, item_snapshot, pharmacy_transport_oh/pa, task_group_desc)
# MAGIC │   ├── asf_*, brm_*, ffm_*, okg_*, okp_*   (3 each: iroo, qroo, item_snapshot)
# MAGIC │   ├── v_gesc_closed_loads, v_gesc_wm_inventory, v_load_sheets
# MAGIC │   └── pse_case_v, sis_v, item_first_rcpt, time_diff
# MAGIC │
# MAGIC └── gold_native/                         ← Version B: de facto Gold stamp
# MAGIC     ├── Dimensions (9):
# MAGIC     │   dim_item, dim_facility, dim_business_unit, dim_location,
# MAGIC     │   dim_date, dim_adjustment_reason, dim_carrier, dim_purchase_order,
# MAGIC     │   dim_task_group
# MAGIC     ├── Facts (12, CLUSTER BY facility_sk + date_sk):
# MAGIC     │   fact_inventory_snapshot, fact_inventory_transaction,
# MAGIC     │   fact_inventory_adjustment (view), fact_cycle_count_adjustment,
# MAGIC     │   fact_inventory_daily_total, fact_receiving_event, fact_pickpack_event,
# MAGIC     │   fact_ilpn_lifecycle, fact_pharmacy_transport, fact_transportation_shipment,
# MAGIC     │   fact_load_sheet, fact_task_completion, v_inventory_compare
# MAGIC     └── Compatibility views (50, same column shapes as Version A):
# MAGIC         - 4 GE_CS corporate
# MAGIC         - 4 CCS cross-facility
# MAGIC         - 1 BICEPS_IROO template + 6 per-DC variants
# MAGIC         - 1 BICEPS_QROO template + 6 per-DC variants
# MAGIC         - 1 CCS_ITEM_SNAPSHOT template + 6 single-BU variants (HBC, ASF, BRM, FFM, OKG, OKP)
# MAGIC         - 2 HBC pharmacy transport (OH, PA)
# MAGIC         - 1 HBC task group desc (sourced from dim_task_group)
# MAGIC         - 3 transportation (v_gesc_closed_loads, v_load_sheets, v_gesc_wm_inventory)
# MAGIC         - 4 specialty (v_pse_case, v_sis, v_item_first_rcpt, v_time_diff)
# MAGIC         - MISHA_TEST_V excluded (dev artifact, not a production report)
# MAGIC ```
# MAGIC
# MAGIC ## The key pattern
# MAGIC
# MAGIC **Roughly 40 of the 50 Snowflake views collapse into 6 SQL templates in Version B.** Per-DC variants become one line:
# MAGIC
# MAGIC ```sql
# MAGIC CREATE OR REPLACE VIEW v_biceps_iroo_d0001
# MAGIC   AS SELECT * FROM v_biceps_iroo WHERE profile_id IN ('D0001', 'D0008');
# MAGIC ```
# MAGIC
# MAGIC Schema changes happen once, not in N copies.
# MAGIC
# MAGIC ## Power BI repointing
# MAGIC
# MAGIC Both Gold versions expose identical column shapes via the compatibility view layer. Aquila and Roshni's existing Power BI datasets can point at either:
# MAGIC
# MAGIC ```
# MAGIC gold_lift_shift.ge_cs_invn_dly_total_v       (Version A)
# MAGIC gold_native.v_ge_cs_invn_dly_total           (Version B)
# MAGIC ```
# MAGIC
# MAGIC Same result, different engine room. Validate with `08_validate_compat_shapes.sql` after build - it diffs column metadata between sides and returns zero rows when clean.
# MAGIC
# MAGIC ## Recommended path (hybrid)
# MAGIC
# MAGIC The POC doc recommends a phased combination, not a binary choice:
# MAGIC
# MAGIC - **Priority top 20 reports + HBC pharmacy + cross-facility analytical** → Version B (lakehouse-native)
# MAGIC - **Long tail of ~321 reports** → Version A (lift-and-shift)
# MAGIC
# MAGIC Net: high-value reporting gets the foundation, the long tail moves off Snowflake without blocking the March 2027 deadline.
# MAGIC
# MAGIC ## Databricks optimizations applied
# MAGIC
# MAGIC Version B (lakehouse-native) includes production-ready optimizations:
# MAGIC
# MAGIC - **Predictive optimization enabled** at catalog level. Databricks auto-runs OPTIMIZE and collects stats during idle compute.
# MAGIC - **Liquid clustering** on all 12 fact tables with `CLUSTER BY (facility_sk, date_sk)` for optimal predicate pushdown.
# MAGIC - **Auto-optimization table properties** on all facts: `autoOptimize.optimizeWrite`, `autoOptimize.autoCompact`, and `enableChangeDataFeed` for downstream CDC consumers.
# MAGIC - **Materialized view** for `v_inventory_compare`. Auto-refreshes when source `fact_inventory_snapshot` changes for 10-100x query performance.
# MAGIC - **SCD2 scaffolding** in `dim_item`. Columns declared (`effective_from`, `effective_to`, `is_current`, `version_number`) but not actively tracked in POC - prevents breaking schema changes in Phase 2.
# MAGIC
# MAGIC ## Important notes
# MAGIC
# MAGIC - **All 50 views validated against Snowflake source DDL.** Column shapes confirmed one-by-one against user-provided Snowflake CREATE VIEW statements. Key corrections applied:
# MAGIC   - 6 per-DC QROO views (ASF/BRM/FFM/HBC/OKG/OKP): corrected from 30-col BICEPS template to true 24-col per-DC shape (adds QTY_ON_HOLD, IN_TRANSIT_IN/OUT, EXT_GEGL_DEPARTMENT, UNIT_PRICE, HAS_INV; removes BICEPS-specific cols)
# MAGIC   - V_GESC_WM_INVENTORY: corrected from 13 raw-inventory cols to 9 BOH-calculation cols (ASIWHSE, AIMSTYLE, BOH, etc.)
# MAGIC   - V_LOAD_SHEETS: corrected from 17 cols to 21 cols (adds PRODUCT_CLASS, PLANNED_VOLUME, ORDER_QTY, PALLETS, NOTE, OTHER_SHIPMENTS_FOR_STORE, PLANNING_STATUS_ID, LOADING_SEQUENCE, SQ, NEWPC)
# MAGIC   - PSE_CASE_V: corrected from 15 pickpack cols to 26 case-tracking cols
# MAGIC   - SIS_V: corrected from 11 item cols to 23 inventory-snapshot cols
# MAGIC   - TIME_DIFF: corrected from 8 task cols to 2 data-freshness cols (COMPONENT, TIME_DIFF)
# MAGIC   - GE_CS_CYCL_CNT_ADJMT_DTLV: 2 column name aliases fixed (ITEM_NDC_PACKAGE_SIZE, ADJUSTMENT_QUANTITY)
# MAGIC - **Cross-view references are qualified.** Each view in `gold_lift_shift` references its dependencies as `ge_poc.gold_lift_shift.<view>`. Views run in isolation without `USE SCHEMA` dependency.
# MAGIC - **CCS_INV_COMPARE_V validated.** 6-col shape confirmed against Snowflake source (INVENTORY_FACILITY, ITEM_ID, SUM_ON_HAND, SUM_ALLOCATED, PROFILE_ID, OUTSIDE_STG).
# MAGIC - **dim_task_group seeded with full reference data.** HBC_TASK_GROUP_DESC view confirmed (4 cols: DESCRIPTION, TASK_GROUP, TRANSACTION_ID, SOURCE_ZONE_ID) with complete zone mapping from Snowflake source.
# MAGIC - **Mocked external source.** `bronze.ge_cs_invn_control` mocks the external GE Oracle DB. Real integration is Phase 2.
# MAGIC - **Base table shapes are reverse-engineered.** When Lakeflow Connect lands real Bronze data, these are superseded; the Gold layer logic carries forward.
# MAGIC - **Some Power BI datasets reference base tables directly.** Inventory those queries with Aquila to confirm the reverse-engineered Bronze schemas don't miss columns.
# MAGIC
# MAGIC ## Workspace hygiene
# MAGIC
# MAGIC Drop everything with:
# MAGIC
# MAGIC ```sql
# MAGIC DROP CATALOG IF EXISTS ge_poc CASCADE;
# MAGIC ```