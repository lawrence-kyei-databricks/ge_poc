# Giant Eagle: Manhattan WMS → Databricks Gold-Layer Remodel

## Purpose

This bundle is a Gold-layer prototype, a side-by-side comparison, and a decision artifact. It is **not a production pipeline**. The dim and fact DDL, the compatibility view pattern, and the validation scripts are the design contract Databricks is committing to deliver.

Manhattan → Data Save → Lakeflow Connect CDC → Bronze and Silver SCD2 conformance are owned by the source-side track that runs jointly with Manhattan and Giant Eagle (different workstream). The synthetic Bronze in scripts 01 and 02 is scaffolding so the SQL is executable in isolation — throw it away at handoff. When real Silver lands upstream, the dim and fact INSERTs change their `FROM` clauses from `ge_poc.bronze.*` to the production `silver.*` schema and become DLT pipelines or scheduled jobs. The compatibility views and the Power BI datasets do not change.

---

## What's in this bundle

| File | What it is |
|---|---|
| `script/00_setup.sql` | Catalog and schemas |
| `script/01_bronze_sample_tables.sql` | 35 reverse-engineered Manhattan base tables (sample) |
| `script/02_sample_data.sql` | Scaled synthetic data (~10K items, ~50K inventory, ~250K PIX transactions) |
| `script/03_gold_lift_shift_all_views.sql` | **Version A**: calls `gold_lift_shift_ddl.sql` to create all 50 views |
| `script/gold_lift_shift_ddl.sql` | Full DDL for all 50 Snowflake views ported to Databricks |
| `script/04_gold_native_dimensions.sql` | **Version B (part 1)**: 9 conformed dimensions including dim_task_group |
| `script/05_gold_native_facts.sql` | **Version B (part 2)**: 12 fact tables, liquid-clustered |
| `script/06_gold_native_compat_views.sql` | **Version B (part 3)**: notebook calling the generated compat view DDL |
| `script/06_compat_views_generated.sql` | Generated DDL for all 50 compatibility views |
| `script/07_benchmark_queries.sql` | Side-by-side EXPLAIN ANALYZE pairs and result-fidelity diffs |
| `script/08_validate_compat_shapes.sql` | Column-by-column metadata diff between Version A and Version B compat views |
| `BUSINESS_CONTEXT.md` | Business unit reference: BICEPS, HBC, ASF, BRM, FFM, OKG, OKP, CCS — DC locations, table glossary |
| `GROCERY_RETAIL_CONTEXT.md` | Grocery retail domain context for the WMS data model |
| `data_model/demo version/` | Simplified DBML diagrams for presentations (Version A + B) |
| `data_model/full version/` | Full DBML data model files (Version A + B) + README |

---

## Run order

```
00_setup.sql
01_bronze_sample_tables.sql
02_sample_data.sql                       (~30 seconds with scaled volumes)
03_gold_lift_shift_all_views.sql         (Version A — validated against original GE Snowflake Views DDL)
04_gold_native_dimensions.sql            (Version B)
05_gold_native_facts.sql                 (Version B)
06_gold_native_compat_views.sql          (Version B)
07_benchmark_queries.sql                 (optional)
08_validate_compat_shapes.sql            (required before claiming compat)
```

---

## Coverage

```
ge_poc/
├── bronze/                              35 sample base tables + 1 mock external
│
├── gold_lift_shift/                     ← Version A: 50 Delta views, 1:1 from Snowflake
│   ├── ge_cs_*                          (4 views)
│   ├── ccs_*                            (4 views)
│   ├── biceps_*                         (14: iroo/qroo template + 6 per-DC variants each)
│   ├── hbc_*                            (6 views)
│   ├── asf_*, brm_*, ffm_*, okg_*, okp_*   (3 each: iroo, qroo, item_snapshot)
│   ├── v_gesc_closed_loads, v_gesc_wm_inventory, v_load_sheets
│   └── pse_case_v, sis_v, item_first_rcpt, time_diff
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
    └── Compatibility views (50, same column shapes as Version A)
```

---

## The key pattern

**Roughly 40 of the 50 Snowflake views collapse into 6 SQL templates in Version B.** Per-DC variants become one line:

```sql
CREATE OR REPLACE VIEW v_biceps_iroo_d0001
  AS SELECT * FROM v_biceps_iroo WHERE profile_id IN ('D0001', 'D0008');
```

Schema changes happen once, not in N copies.

---

## Power BI repointing

Both Gold versions expose identical column shapes via the compatibility view layer. Existing Power BI datasets can point at either:

```
gold_lift_shift.ge_cs_invn_dly_total_v       (Version A)
gold_native.v_ge_cs_invn_dly_total           (Version B)
```

Validate with `08_validate_compat_shapes.sql` — returns zero rows when clean.

---

## Recommended path (hybrid)

- **Priority top 20 reports + HBC pharmacy + cross-facility analytical** → Version B (lakehouse-native)
- **Long tail of ~321 reports** → Version A (lift-and-shift)

High-value reporting gets the foundation; the long tail moves off Snowflake without blocking the March 2027 deadline.

---

## Databricks optimizations applied

- **Predictive optimization** at catalog level — auto OPTIMIZE + stats during idle compute
- **Liquid clustering** on all 12 facts: `CLUSTER BY (facility_sk, date_sk)`
- **Auto-optimization** table properties: `autoOptimize.optimizeWrite`, `autoOptimize.autoCompact`, `enableChangeDataFeed`
- **Materialized view** for `v_inventory_compare` — auto-refreshes on source change
- **SCD2 scaffolding** in `dim_item` — columns declared, not tracked in POC; prevents Phase 2 breaking changes

---

## Important notes

- All 50 views validated against Snowflake source DDL with column-by-column corrections applied
- Cross-view references qualified as `ge_poc.gold_lift_shift.<view>` — no `USE SCHEMA` dependency
- `bronze.ge_cs_invn_control` mocks the external GE Oracle DB — real integration is Phase 2
- Bronze table shapes are reverse-engineered; superseded when Lakeflow Connect lands real data

---

## Workspace cleanup

```sql
DROP CATALOG IF EXISTS ge_poc CASCADE;
```
