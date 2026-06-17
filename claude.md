# Giant Eagle POC - Gold Layer Remodel

## Project Overview
This is a proof-of-concept for migrating Giant Eagle's Manhattan WMS data warehouse from Snowflake to Databricks. It demonstrates two migration approaches side-by-side for comparison and decision-making.

## Architecture
- **Bronze Layer**: 35 reverse-engineered Manhattan base tables with synthetic data (~10K items, ~50K inventory, ~250K transactions)
- **Gold Layer - Version A (Lift & Shift)**: 51 Delta views ported 1:1 from Snowflake
- **Gold Layer - Version B (Native)**: Lakehouse-native dimensional model with 9 dimensions, 12 facts, and 51 compatibility views

## Key Components

### Version A: Lift-and-Shift
- Direct Delta view ports from Snowflake
- Minimal transformation, preserves original structure
- 8 views require manual translation (flagged with `-- WARNING:`)
- Located in `gold_lift_shift` schema

### Version B: Lakehouse-Native
**Dimensions (9)**: item (SCD2-ready), facility, business_unit, location, date, adjustment_reason, carrier, purchase_order, task_group

**Facts (12)**: All liquid-clustered by (facility_sk, date_sk) with auto-optimization enabled
- inventory_snapshot, inventory_transaction, inventory_adjustment, cycle_count_adjustment, inventory_daily_total, receiving_event, pickpack_event, ilpn_lifecycle, pharmacy_transport, transportation_shipment, load_sheet, task_completion
- **Materialized View**: inventory_compare (auto-refreshes on source changes)

**Compatibility Views (51)**: Match Version A column shapes exactly for Power BI compatibility

**Optimizations Applied**:
- Predictive optimization enabled at catalog level
- Auto-optimization table properties on all facts (optimizeWrite, autoCompact, CDC enabled)
- Liquid clustering for optimal query performance
- Materialized view for pre-computed aggregations

### Key Pattern
~40 of 51 Snowflake views collapse into 6 SQL templates. Per-DC variants become single-line filters, enabling schema changes in one place instead of N copies.

## Execution Order
1. `00_setup.sql` - Catalog and schemas
2. `01_bronze_sample_tables.sql` - Base tables
3. `02_sample_data.sql` - Synthetic data (~30s)
4. `03_gold_lift_shift_all_views.sql` - Version A
5. `04_gold_native_dimensions.sql` - Version B dimensions
6. `05_gold_native_facts.sql` - Version B facts (liquid-clustered by facility_sk + date_sk)
7. `06_gold_native_compat_views.sql` - Version B compatibility layer
8. `07_benchmark_queries.sql` - Performance comparison (optional)
9. `08_validate_compat_shapes.sql` - Metadata validation (required)

## Important Notes
- This is a prototype/decision artifact, NOT a production pipeline
- Bronze/Silver data ingestion is handled by a separate Manhattan/GE workstream
- Power BI datasets can point to either version via compatibility views
- Recommended hybrid approach: Priority reports → Version B, long tail → Version A
- Clean up: `DROP CATALOG IF EXISTS ge_poc CASCADE;`
