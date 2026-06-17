# Giant Eagle POC: Gold-Layer Remodel

## Purpose

This bundle is a Gold-layer prototype, a side-by-side comparison, and a decision artifact. It is not a production pipeline. The dim and fact DDL, the compatibility view pattern, and the validation scripts are the design contract Databricks is committing to deliver. Manhattan to Data Save to Lakeflow Connect CDC to Bronze and Silver SCD2 conformance are owned by the source-side track that runs jointly with Manhattan and Giant Eagle — different workstream. The synthetic Bronze in scripts 01 and 02 is scaffolding so the SQL is executable in isolation; throw it away at handoff. When real Silver lands upstream, the dim and fact INSERTs change their FROM clauses from `ge_poc.bronze.*` to the production `silver.*` schema, and become DLT pipelines or scheduled jobs. The compatibility views and the Power BI datasets do not change.

## What's in this bundle

| File | What it is |
|---|---|
| `giant_eagle_poc.docx` | POC plan: scope, side-by-side approach, hybrid recommendation, milestones with owners, cost positioning, caveats, risks |
| `giant_eagle_gold_model.svg` | Comprehensive Gold layer diagram (rendered) |
| `giant_eagle_gold_model.drawio` | Same diagram, importable to draw.io / diagrams.net for editing |
| `scripts/00_setup.sql` | Catalog and schemas |
| `scripts/01_bronze_sample_tables.sql` | 35 reverse-engineered Manhattan base tables (sample) |
| `scripts/02_sample_data.sql` | Scaled synthetic data (~10K items, ~50K inventory, ~250K PIX transactions) |
| `scripts/03_gold_lift_shift_all_views.sql` | **Version A**: all 51 Snowflake views ported as Delta views, cross-view refs qualified |
| `scripts/04_gold_native_dimensions.sql` | **Version B (part 1)**: 9 conformed dimensions including dim_task_group |
| `scripts/05_gold_native_facts.sql` | **Version B (part 2)**: 12 fact tables, liquid-clustered |
| `scripts/06_gold_native_compat_views.sql` | **Version B (part 3)**: 51 compatibility views matching Version A column shapes |
| `scripts/07_benchmark_queries.sql` | Side-by-side EXPLAIN ANALYZE pairs and result-fidelity diffs |
| `scripts/08_validate_compat_shapes.sql` | Column-by-column metadata diff between Version A and Version B compat views |

## Run order

```
00_setup.sql
01_bronze_sample_tables.sql
02_sample_data.sql                       (~30 seconds with scaled volumes)
03_gold_lift_shift_all_views.sql         (Version A — hand-fix the 8 WARNING-flagged views)
04_gold_native_dimensions.sql            (Version B)
05_gold_native_facts.sql                 (Version B)
06_gold_native_compat_views.sql          (Version B)
07_benchmark_queries.sql                 (optional)
08_validate_compat_shapes.sql            (required before claiming compat)
```

## Coverage

```
ge_poc/
├── bronze/                              35 sample base tables + 1 mock external
│
├── gold_lift_shift/                     ← Version A: 51 Delta views, 1:1 from Snowflake
│   ├── ge_cs_*                          (4: invn_dly_total, adjustment_reason, cycl_cnt_adjmt_dtlv, transaction_dtl)
│   ├── ccs_*                            (4: inv_compare, iroo, qroo, item_snapshot)
│   ├── biceps_*                         (14: iroo/qroo template + 6 per-DC variants each)
│   ├── hbc_*                            (6: iroo, qroo, item_snapshot, pharmacy_transport_oh/pa, task_group_desc)
│   ├── asf_*, brm_*, ffm_*, okg_*, okp_*   (3 each: iroo, qroo, item_snapshot)
│   ├── v_gesc_closed_loads, v_gesc_wm_inventory, v_load_sheets
│   └── pse_case_v, sis_v, item_first_rcpt, time_diff, misha_test_v
│
└── gold_native/                         ← Version B: de facto Gold stamp
    ├── Dimensions (9):
    │   dim_item, dim_facility, dim_business_unit, dim_location,
    │   dim_date, dim_adjustment_reason, dim_carrier, dim_purchase_order,
    │   dim_task_group
    ├── Facts (12, CLUSTER BY facility_sk + date_sk):
    │   fact_inventory_snapshot, fact_inventory_transaction,
    │   fact_inventory_adjustment (view), fact_cycle_count_adjustment,
    │   fact_inventory_daily_total, fact_receiving_event, fact_pickpack_event,
    │   fact_ilpn_lifecycle, fact_pharmacy_transport, fact_transportation_shipment,
    │   fact_load_sheet, fact_task_completion, v_inventory_compare
    └── Compatibility views (51, same column shapes as Version A):
        - 4 GE_CS corporate
        - 4 CCS cross-facility
        - 1 BICEPS_IROO template + 6 per-DC variants
        - 1 BICEPS_QROO template + 6 per-DC variants
        - 1 CCS_ITEM_SNAPSHOT template + 6 single-BU variants (HBC, ASF, BRM, FFM, OKG, OKP)
        - 2 HBC pharmacy transport (OH, PA)
        - 1 HBC task group desc (sourced from dim_task_group)
        - 3 transportation (v_gesc_closed_loads, v_load_sheets, v_gesc_wm_inventory)
        - 4 specialty (v_pse_case, v_sis, v_item_first_rcpt, v_time_diff)
        - misha_test_v intentionally NOT migrated (dev artifact)
```

## The key pattern

**Roughly 40 of the 51 Snowflake views collapse into 6 SQL templates in Version B.** Per-DC variants become one line:

```sql
CREATE OR REPLACE VIEW v_biceps_iroo_d0001
  AS SELECT * FROM v_biceps_iroo WHERE profile_id IN ('D0001', 'D0008');
```

Schema changes happen once, not in N copies.

## Power BI repointing

Both Gold versions expose identical column shapes via the compatibility view layer. Aquila and Roshni's existing Power BI datasets can point at either:

```
gold_lift_shift.ge_cs_invn_dly_total_v       (Version A)
gold_native.v_ge_cs_invn_dly_total           (Version B)
```

Same result, different engine room. Validate with `08_validate_compat_shapes.sql` after build — it diffs column metadata between sides and returns zero rows when clean.

## Recommended path (hybrid)

The POC doc recommends a phased combination, not a binary choice:

- **Priority top 20 reports + HBC pharmacy + cross-facility analytical** → Version B (lakehouse-native)
- **Long tail of ~321 reports** → Version A (lift-and-shift)

Net: high-value reporting gets the foundation, the long tail moves off Snowflake without blocking the March 2027 deadline.

## Databricks optimizations applied

Version B (lakehouse-native) includes production-ready optimizations:

- **Predictive optimization enabled** at catalog level. Databricks auto-runs OPTIMIZE and collects stats during idle compute.
- **Liquid clustering** on all 12 fact tables with `CLUSTER BY (facility_sk, date_sk)` for optimal predicate pushdown.
- **Auto-optimization table properties** on all facts: `autoOptimize.optimizeWrite`, `autoOptimize.autoCompact`, and `enableChangeDataFeed` for downstream CDC consumers.
- **Materialized view** for `v_inventory_compare`. Auto-refreshes when source `fact_inventory_snapshot` changes for 10-100x query performance.
- **SCD2 scaffolding** in `dim_item`. Columns declared (`effective_from`, `effective_to`, `is_current`, `version_number`) but not actively tracked in POC — prevents breaking schema changes in Phase 2.

## Important notes

- **8 lift-and-shift views need hand-translation.** Flagged with `-- WARNING:` comments in `03_gold_lift_shift_all_views.sql`. Contains Snowflake `decode()` or other non-mechanical patterns. Bounded list — fix once.
- **Cross-view references are qualified.** Each view in `gold_lift_shift` references its dependencies as `ge_poc.gold_lift_shift.<view>`. Views run in isolation without `USE SCHEMA` dependency.
- **CCS_INV_COMPARE_V is reconstructed.** Original DDL extraction was truncated; the port reconstructs the expected shape. Reconcile against Aquila's actual DDL before showing externally.
- **dim_task_group seeded with representative rows.** Full HBC_TASK_GROUP_DESC source rows need to be loaded for production; current is a sample.
- **Mocked external source.** `bronze.ge_cs_invn_control` mocks the external GE Oracle DB. Real integration is Phase 2.
- **Base table shapes are reverse-engineered.** When Lakeflow Connect lands real Bronze data, these are superseded; the Gold layer logic carries forward.
- **Some Power BI datasets reference base tables directly.** Inventory those queries with Aquila to confirm the reverse-engineered Bronze schemas don't miss columns.

## Workspace hygiene

Drop everything with:

```sql
DROP CATALOG IF EXISTS ge_poc CASCADE;
```
