# Giant Eagle POC - Data Model Diagrams (dbdiagram.io)

## Quick Start

### Option 1: Import DBML into dbdiagram.io (RECOMMENDED)

**For Demos/Presentations (Simplified):**
1. Go to https://dbdiagram.io
2. Click **"Create New Diagram"**
3. Delete any default content in the editor
4. Open one of these files in a text editor:
   - `version_a_demo.dbml` - Version A (6 Bronze tables + 20 key views)
   - `version_b_demo.dbml` - Version B (6 Bronze + 5 Dims + 2 Facts + 15 views)
5. Copy the entire DBML code
6. Paste into the dbdiagram.io editor
7. The diagram generates automatically!
8. Click **Auto Arrange** (top menu) to organize layout
9. Export as PNG/SVG for presentations

**For Complete Documentation (All tables/views):**
- Use `version_a_full_model.dbml` (36 Bronze + 51 views)
- Use `version_b_full_model.dbml` (36 Bronze + 9 Dims + 12 Facts + 51 views)
- These are comprehensive but may be overwhelming for initial demos

### Option 2: Import SVG into draw.io

If you prefer the existing SVG diagrams:

1. Go to https://app.diagrams.net
2. Click **File** → **Import from** → **Device**
3. Select:
   - `version_a_architecture_corrected.svg`
   - `version_b_star_schema_corrected.svg`
4. Edit as needed

---

## File Inventory

| File | Description | Use Case |
|------|-------------|----------|
| **DBML Files (For dbdiagram.io)** | | |
| `version_a_demo.dbml` | **RECOMMENDED FOR DEMOS**: Simplified Version A (6 Bronze + 20 views) | Clear, focused diagram showing the duplication problem |
| `version_b_demo.dbml` | **RECOMMENDED FOR DEMOS**: Simplified Version B (6 Bronze + 5 Dims + 2 Facts + 15 views) | Clear, focused diagram showing the star schema solution |
| `version_a_full_model.dbml` | Complete Version A: 36 Bronze tables + 51 views | Comprehensive documentation (may be overwhelming) |
| `version_b_full_model.dbml` | Complete Version B: 36 Bronze + 9 Dimensions + 12 Facts + 51 views | Comprehensive documentation (may be overwhelming) |
| **SVG Files (For draw.io or quick viewing)** | | |
| `version_a_architecture_corrected.svg` | Visual diagram of Version A architecture | Quick visual for presentations |
| `version_b_star_schema_corrected.svg` | Visual diagram of Version B star schema | Quick visual for presentations |

---

## What's in Each DBML File?

### Demo Files (RECOMMENDED FOR PRESENTATIONS)

#### Version A Demo (`version_a_demo.dbml`)

**Bronze Layer (6 core tables):**
- `item_master_ite_item` - Item master
- `item_master_ite_item_package` - UNIT/PACK dimensions
- `dcinventory_dci_inventory` - Inventory quantities
- `dcinventory_dci_location` - Warehouse locations
- `pix_pix_pix_entry` - Inventory adjustments
- `inventory_management_inm_adjustment_reason_code` - Reason codes

**Gold Layer (~20 representative views showing the pattern):**
- **CCS views (3)**: `ccs_iroo_v`, `ccs_qroo_v`, `ccs_item_snapshot_v`
- **GE_CS views (2)**: `ge_cs_cycl_cnt_adjmt_dtlv`, `ge_cs_transaction_dtl_v`
- **BICEPS IROO (4)**: `biceps_iroo_v` + 3 variants (d0001, d0044, d0080)
- **BICEPS QROO (4)**: `biceps_qroo_v` + 3 variants
- **HBC views (2)**: `hbc_iroo_v`, `hbc_qroo_v` (showing same pattern)

**Key Features:**
- Uses **Table Groups** to organize Bronze vs Gold visually
- Extensive **Notes** explaining the duplication problem
- Shows relationships between Bronze tables and views
- Comments highlight: "Change 1 column = update 40+ views"

#### Version B Demo (`version_b_demo.dbml`)

**Bronze Layer (6 core tables - same as Version A):**

**Dimensions (5 key conformed dimensions):**
- `dim_item` - Item master with UNIT/PACK denormalized + SCD2 scaffolding
- `dim_facility` - Facilities with business_unit denormalized
- `dim_location` - Warehouse locations
- `dim_business_unit` - Replaces BICEPS/HBC/ASF view duplication
- `dim_adjustment_reason` - Reason codes

**Facts (2 core fact tables, liquid clustered):**
- `fact_inventory_snapshot` - Daily inventory (replaces *_IROO_V, *_ITEM_SNAPSHOT_V)
- `fact_inventory_transaction` - PIX entries (replaces *_QROO_V, GE_CS_TRANSACTION_DTL_V)

**Compatibility Views (~15 showing template pattern):**
- **CCS views (2)**: `ccs_iroo_v`, `ccs_qroo_v`
- **BICEPS IROO (4)**: `v_biceps_iroo` (template) + 3 variants (d0001, d0044, d0080)
- **BICEPS QROO (3)**: `v_biceps_qroo` (template) + 2 variants
- **GE_CS views (1)**: `ge_cs_cycl_cnt_adjmt_dtlv`

**Key Features:**
- **1:∞ relationships** clearly marked (Dimensions → Facts via surrogate keys)
- **Table Groups** organize layers: Bronze → Dimensions → Facts → Views
- **Notes** explain: "Change dim_item → all 51 views inherit"
- **Template pattern** highlighted: 1 base view → 6 one-line variants
- Shows **liquid clustering** indexes for performance

---

### Full Files (FOR COMPREHENSIVE DOCUMENTATION)

#### Version A (`version_a_full_model.dbml`)

**Bronze Layer (36 tables):**
- `item_master_ite_item` + 35 other Manhattan tables
- All marked as synthetic/placeholder POC data

**Gold Layer (51 views):**
- **CCS views (4)**: `ccs_inv_compare_v`, `ccs_iroo_v`, `ccs_item_snapshot_v`, `ccs_qroo_v`
- **GE_CS views (4)**: `ge_cs_adjustment_reason_v`, `ge_cs_cycl_cnt_adjmt_dtlv`, etc.
- **BICEPS views (14)**: `biceps_iroo_v` + 6 variants, `biceps_qroo_v` + 6 variants
- **HBC views (14)**: Same pattern as BICEPS
- **ASF views (14)**: Same pattern
- **BRM views (2)**: Only 1 DC, no variants
- **Top-level views (2)**: `iroo_v`, `qroo_v`

**Problem Highlighted:**
- Every view directly queries Bronze with duplicated SQL
- Change 1 column? Update 40+ views
- Fix 1 JOIN bug? Copy-paste to 40+ views

---

### Version B (`version_b_full_model.dbml`)

**Bronze Layer (36 tables):**
- Same as Version A (placeholder data)
- In production, Dimensions/Facts source from `manhattan_prod.silver.*`

**Dimensions (9 conformed dimensions):**
1. `dim_item` - Item master with UNIT/PACK denormalized + SCD2 scaffolding
2. `dim_facility` - Facility with business unit denormalized
3. `dim_location` - Warehouse locations (aisle/bay/level)
4. `dim_date` - Date dimension with fiscal calendar
5. `dim_business_unit` - Replaces BICEPS/HBC/ASF view duplication
6. `dim_adjustment_reason` - PIX adjustment reasons
7. `dim_user` - User attribution
8. `dim_organization` - Org hierarchy
9. `dim_carrier` - Shipment carriers

**Facts (12 fact tables, all liquid clustered):**
1. `fact_inventory_snapshot` - Daily inventory (replaces *_IROO_V, *_ITEM_SNAPSHOT_V)
2. `fact_inventory_transaction` - PIX entries (replaces *_QROO_V, GE_CS_TRANSACTION_DTL_V)
3. `fact_cycle_count_adjustment` - Cycle count details (replaces GE_CS_CYCL_CNT_ADJMT_DTLV)
4. `fact_receiving_event` - ASN receipts
5. `fact_pick_event` - Pick task execution
6. `fact_pack_event` - Pack station activity
7. `fact_ship_event` - Outbound shipments
8. `fact_order_line` - Customer orders
9. `fact_purchase_order_line` - Inbound POs
10. `fact_task_completion` - Warehouse task metrics
11. `fact_location_capacity` - Location utilization
12. `fact_ilpn_movement` - ILPN tracking

**Compatibility Views (51 views, same names as Version A):**
- Use **template pattern**: 1 base view → N filtered variants
- Example: `v_biceps_iroo` (full SQL logic) → 6 one-line variants (WHERE profile_id = ...)
- Power BI datasets require **zero changes** when switching from Version A to Version B

**Solution Highlighted:**
- Change `dim_item.description`? Update 1 dimension → all 51 views inherit
- Fix JOIN bug? Fix 1 base view → all variants inherit
- Liquid clustering: 10-100x query speedup on `(facility_sk, date_sk)`

---

## Relationships in dbdiagram.io

### How to Read the Diagrams

**Version A:**
- Bronze tables (orange) → Gold views (blue)
- Relationships show direct foreign key references (item_id, location_id, etc.)
- No intermediate transformation layer

**Version B:**
- Bronze tables (orange) → Dimensions (gold) → Facts (green) → Compatibility Views (blue)
- Relationships marked as `1:∞` (one-to-many)
  - `dim_item (1)` → `fact_inventory_snapshot (∞)` via `item_sk`
  - `dim_facility (1)` → `fact_inventory_snapshot (∞)` via `facility_sk`
- Facts are **liquid clustered** on `(facility_sk, date_sk)` for performance

### Cardinality Notation

In dbdiagram.io:
- `ref: >` means "many-to-one" (foreign key)
- Example: `item_sk bigint [ref: > dim_item.item_sk]` means:
  - `fact_inventory_snapshot.item_sk` (many) → `dim_item.item_sk` (one)

---

## Exporting from dbdiagram.io

Once you've imported the DBML:

1. Click **Export** button (top right)
2. Choose format:
   - **PNG** - High-resolution image for presentations
   - **SVG** - Vector format (editable)
   - **PDF** - Print-ready document
3. Save and share with stakeholders

**Pro Tip:** Use the **Auto Arrange** button to clean up the layout if tables overlap.

---

## Key Differences: Version A vs Version B

| Aspect | Version A (Lift-and-Shift) | Version B (Star Schema) |
|--------|---------------------------|-------------------------|
| **Bronze → Gold** | Direct SELECT queries | Bronze → Dims → Facts → Views |
| **SQL Logic** | Duplicated in 40+ views | Centralized in dimensions/facts |
| **Business Unit** | 40+ separate view names | 1 column filter in `dim_business_unit` |
| **Maintenance** | Change 1 column = update 40+ views | Change 1 dimension = all views inherit |
| **Performance** | No clustering, full table scans | Liquid clustering: 10-100x speedup |
| **Schema Changes** | High risk, manual propagation | Low risk, automatic propagation |
| **Template Pattern** | None | 1 base view → 6 one-line variants |
| **Power BI Impact** | N/A (baseline) | Zero changes (same view names/shapes) |

---

## Production Migration Path

**Version A:**
```sql
-- POC (current):
CREATE VIEW biceps_iroo_v AS
SELECT ... FROM ge_poc.bronze.item_master_ite_item ...

-- Production (future):
CREATE VIEW biceps_iroo_v AS
SELECT ... FROM manhattan_prod.silver.item_master_ite_item ...
-- Change FROM clause only, same SQL logic
```

**Version B:**
```sql
-- POC (current):
CREATE TABLE dim_item AS
SELECT ... FROM ge_poc.bronze.item_master_ite_item ...

-- Production (future):
CREATE TABLE dim_item AS
SELECT ... FROM manhattan_prod.silver.item_master_ite_item ...
-- Or becomes a DLT pipeline / scheduled job
```

**Important:** The compatibility views and Power BI datasets **do not change** when switching from POC Bronze to production Silver.

---

## Questions?

- **"Why are there 51 views in both versions?"** - Power BI compatibility. Same names, same column shapes, zero dataset changes.
- **"What's a template view?"** - Base view with full SQL logic. Variants are one-line filters (WHERE profile_id = ...).
- **"What's liquid clustering?"** - Databricks optimization that physically orders data by `(facility_sk, date_sk)` for 10-100x query speedup.
- **"Is Bronze production data?"** - No. Bronze here is synthetic placeholder data (scripts 01-02). Real Bronze/Silver ingestion is a separate Manhattan workstream.

---

## Next Steps

1. **Import into dbdiagram.io** to see the full entity relationships
2. **Export as PNG/SVG** for presentations
3. **Share with stakeholders** to explain the architectural differences
4. **Use Version B DBML** as the blueprint for Phase 2 implementation

**Recommended:** Show stakeholders Version A first (the problem), then Version B (the solution).
