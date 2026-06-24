# Giant Eagle POC - Business Context & Demo Guide

## Who is Giant Eagle?

**Giant Eagle** is a major grocery chain with **distribution centers (DCs)** across multiple regions.

They use **Manhattan WMS (Warehouse Management System)** to manage:
- Inventory across 6+ distribution centers
- Item receiving from vendors
- Order picking and packing
- Shipping to retail stores
- Inventory adjustments and cycle counts

## The Business Problem

Giant Eagle currently has their warehouse data in **Snowflake** with 51 pre-built views that Power BI dashboards use.

**They're migrating to Databricks**, and need to decide:
- **Version A (Lift-and-Shift)**: Port 51 Snowflake views as-is → Fast to build, but maintenance nightmare
- **Version B (Lakehouse-Native)**: Rebuild with dimensional modeling → Takes longer, but sustainable long-term

**This POC proves both approaches work**, so Giant Eagle can make an informed decision.

---

## What Do All These Tables Mean? (Business Translation)

### BRONZE LAYER (Source Data from Manhattan WMS)

Think of Bronze as **raw data exported from Manhattan's warehouse system**:

| Table | Business Meaning |
|-------|------------------|
| **item_master_ite_item** | Product catalog: SKUs, descriptions, dimensions, weight |
| **item_master_ite_item_package** | Packaging details: How items are packed (UNIT, PACK, CASE) |
| **dcinventory_dci_inventory** | **Live inventory**: How many units of each item are in each DC, on each shelf |
| **dcinventory_dci_location** | Warehouse locations: Aisle A, Bay 3, Level 2 (where items are physically stored) |
| **pix_pix_pix_entry** | **Inventory adjustments**: Every time inventory changes (damage, cycle count, receiving, shipping) |
| **inventory_management_inm_adjustment_reason_code** | Why inventory changed: "Damaged", "Cycle Count Variance", "Receiving Adjustment" |
| **receiving_rcv_asn** | **Advance Ship Notices**: Expected deliveries from vendors |
| **receiving_rcv_asn_line** | Line items in each ASN: "Expecting 500 units of SKU-12345" |
| **receiving_rcv_purchase_order** | Purchase orders: What we ordered from vendors |
| **receiving_rcv_receipt** | **Actual receipts**: What we actually received (may differ from PO) |
| **pickpack_ppk_olpn** | **Outbound LPNs**: Pallets/cases being picked for store orders |
| **pickpack_ppk_olpn_detail** | Line items: "Picked 24 units of SKU-67890 for store #123" |
| **task_tsk_task** | **Warehouse tasks**: "Pick item X from location Y", "Replenish shelf Z" |
| **dcorder_dco_order** | **Store orders**: Retail stores ordering from the DC |
| **dcorder_dco_order_line** | Line items: "Store #456 wants 100 units of SKU-99999" |
| **shipment_shp_shipment** | **Outbound shipments**: Trucks leaving the DC to deliver to stores |
| **facility_fac_facility** | DC master data: DC01 = "Pittsburgh DC", DC44 = "Columbus DC" |
| **carrier_car_carrier** | Shipping carriers: FedEx, UPS, private fleet |

### GOLD LAYER - What Business Users See

#### Version A Views (51 total - Direct Snowflake Port)

These are **pre-built reports** that Power BI uses. Giant Eagle's business has 8 divisions (business units):

| Business Unit Code | What It Is | Example DCs |
|-------------------|------------|-------------|
| **BICEPS** | General retail groceries | D0001, D0044, D0050, D0061, D0070, D0080 (6 DCs) |
| **HBC** | Health, Beauty, Cosmetics, Pharmacy | D0080 |
| **ASF** | American Seafood | D0061 |
| **BRM** | Beverage / Beer / Wine | D0050 |
| **FFM** | Fresh Fruit / Meat | D0070 |
| **OKG** | OK Grocery | D0001, D0008 |
| **OKP** | OK Produce | D0044 |
| **CCS** | Corporate / Cross-facility analytics | ALL DCs combined |

**Common View Patterns:**

| View Name | What It Tells You |
|-----------|-------------------|
| **biceps_iroo_v** | "**I**tem **R**eference **O**n-hand **O**nly" - All BICEPS items with current inventory across all 6 DCs |
| **biceps_iroo_v_d0001** | Same as above, but ONLY for DC D0001 (one specific warehouse) |
| **biceps_iroo_v_d0044** | Same, but ONLY for DC D0044 |
| **biceps_iroo_v_d0080** | Same, but ONLY for DC D0080 |
| ... | *(3 more variants for d0050, d0061, d0070)* |
| **biceps_qroo_v** | "**Q**uick **R**eference **O**n-hand **O**nly" - Simplified version: just item ID and quantity |
| **biceps_qroo_v_d0001** | QROO for DC D0001 only |
| ... | *(6 more QROO variants)* |
| **hbc_iroo_v** | Same pattern for HBC business unit |
| **asf_iroo_v** | Same pattern for ASF business unit |
| **ccs_iroo_v** | Corporate view: ALL business units, ALL DCs combined |
| **ccs_item_snapshot_v** | Daily inventory snapshot across all DCs |
| **ge_cs_invn_dly_total_v** | "Giant Eagle Corporate Services Daily Inventory Total" - High-level daily totals by DC |
| **ge_cs_cycl_cnt_adjmt_dtlv** | "Cycle Count Adjustment Detail View" - Every inventory adjustment from cycle counts |
| **ge_cs_transaction_dtl_v** | "Transaction Detail View" - Every inventory movement (adjustments, receipts, shipments) |

**The Problem with Version A:**
- BICEPS has 14 views (7 IROO + 7 QROO)
- HBC has 14 views
- ASF has 14 views
- Total: **51 views**, but 40+ have **duplicated SQL logic**
- Change item description column? Update 40+ view definitions manually
- Fix a JOIN bug? Copy-paste to 40+ views

---

#### Version B Dimensions + Facts (Lakehouse-Native)

Instead of 51 separate views with duplicated logic, Version B builds **reusable building blocks**:

**DIMENSIONS (Reusable Reference Data):**

| Dimension | Business Meaning | Why It Exists |
|-----------|------------------|---------------|
| **dim_item** | Master item catalog with all package dimensions denormalized | Every fact table needs item details. Define once, reuse everywhere. |
| **dim_facility** | DC master data (D0001 = "Pittsburgh DC", business_unit = "BICEPS") | Every fact needs to know which warehouse. |
| **dim_location** | Warehouse locations (Aisle A, Bay 3, Level 2) | Track where items are physically stored. |
| **dim_business_unit** | Business unit master (BICEPS, HBC, ASF, etc.) | Replaces 40+ view names with 1 column filter. |
| **dim_date** | Calendar dimension with fiscal periods | Time-based reporting (daily, weekly, monthly snapshots). |
| **dim_adjustment_reason** | Why inventory changed ("Damaged", "Cycle Count", "Receiving") | Track root causes of inventory variances. |
| **dim_user** | Warehouse workers who execute tasks/adjustments | Attribution: "Who made this change?" |
| **dim_carrier** | Shipping carriers (FedEx, UPS, private fleet) | Track outbound shipment logistics. |
| **dim_organization** | Org hierarchy (stores, warehouses, vendors) | Corporate structure. |

**FACTS (Transactional/Snapshot Data):**

| Fact Table | Business Meaning | Replaces Which Views? |
|------------|------------------|----------------------|
| **fact_inventory_snapshot** | **Daily inventory snapshot**: How many units of each item in each location, every day | ALL *_IROO_V views, ALL *_ITEM_SNAPSHOT_V views |
| **fact_inventory_transaction** | **Every inventory movement**: PIX entries (adjustments, receipts, shipments, cycle counts) | ge_cs_transaction_dtl_v, ALL *_QROO_V transaction aggregates |
| **fact_cycle_count_adjustment** | **Cycle count details**: Expected vs actual qty, variances, who counted | ge_cs_cycl_cnt_adjmt_dtlv |
| **fact_receiving_event** | **Receipts from vendors**: ASN → PO → what was received, variances | (Not in original 51 views, but needed for future analytics) |
| **fact_pick_event** | **Picking activity**: Which items picked from which locations, by whom, how long | (Future analytics) |
| **fact_pack_event** | **Packing activity**: Packing station productivity | (Future analytics) |
| **fact_ship_event** | **Outbound shipments**: Trucks leaving the DC with store orders | (Future analytics) |
| **fact_order_line** | **Store orders**: What stores ordered, what was allocated, picked, shipped | (Future analytics) |
| **fact_purchase_order_line** | **Inbound POs**: What we ordered from vendors vs what arrived | (Future analytics) |
| **fact_task_completion** | **Warehouse task metrics**: Pick/putaway/replenish task execution time | (Future analytics) |
| **fact_location_capacity** | **Location utilization**: % full for each warehouse location | (Future analytics) |
| **fact_ilpn_movement** | **Inbound LPN tracking**: From receiving to putaway | (Future analytics) |

**The 51 Compatibility Views:**
- These are **thin wrappers** that query dimensions/facts
- **Same names, same columns** as Version A (Power BI doesn't change)
- Example: `v_biceps_iroo` = SELECT from fact_inventory_snapshot JOIN dimensions WHERE business_unit = 'BICEPS'
- **Template pattern**: `v_biceps_iroo` (full SQL) → 6 variants (1-line: SELECT * FROM base WHERE profile_id = ...)

**The Win with Version B:**
- Change item description? Update `dim_item` → all 51 views inherit instantly
- Fix JOIN bug? Fix `fact_inventory_snapshot` → all 51 views inherit
- Add new business unit? Insert 1 row in `dim_business_unit`, not create 14 new views

---

## How to Demo This to a Customer

### Setup (Before the Demo)

1. Import `version_a_demo.dbml` into dbdiagram.io
2. Click **Auto Arrange** → **Left-Right**
3. Export as PNG: "version_a_demo.png"
4. Import `version_b_demo.dbml` into dbdiagram.io
5. Click **Auto Arrange** → **Snowflake**
6. Export as PNG: "version_b_demo.png"

### Demo Script (10-minute version)

**Slide 1: The Context**

> "Giant Eagle is a grocery chain with 6+ distribution centers managing inventory, receiving, picking, packing, and shipping. They use Manhattan WMS as their source system, and currently have 51 pre-built reports in Snowflake that Power BI uses. They're migrating to Databricks and need to decide: fast lift-and-shift vs sustainable redesign."

**Slide 2: Version A - The Lift-and-Shift Approach**

*Show `version_a_demo.png`*

> "Version A is a direct port of their 51 Snowflake views. Here's what it looks like:
>
> - **Bronze tables (left)**: Raw data from Manhattan - items, inventory, locations, transactions
> - **Gold views (right)**: 51 pre-built reports
>
> Notice the pattern:
> - `ccs_iroo_v` queries Bronze directly with full JOIN logic
> - `biceps_iroo_v` duplicates that same JOIN logic, just adds a business unit filter
> - `biceps_iroo_v_d0001` duplicates it again with a facility filter
> - `biceps_iroo_v_d0044` duplicates it again
> - ...and 40+ more views with duplicated SQL
>
> **The problem:** Change the item description column name? You have to update 40+ view definitions manually. Fix a JOIN bug? Copy-paste the fix to 40+ places."

**Slide 3: Version B - The Lakehouse-Native Approach**

*Show `version_b_demo.png`*

> "Version B rebuilds this with dimensional modeling. Here's the architecture:
>
> - **Bronze (left)**: Same raw Manhattan data
> - **Dimensions (gold boxes, middle-left)**: Reusable reference data
>   - `dim_item`: Item master with package dimensions denormalized
>   - `dim_facility`: Distribution center master data
>   - `dim_business_unit`: Replaces BICEPS/HBC/ASF view duplication
>   - `dim_location`: Warehouse aisle/bay/level
> - **Facts (green boxes, center)**: Transactional/snapshot data
>   - `fact_inventory_snapshot`: Daily inventory across all DCs (replaces ALL *_IROO_V views)
>   - `fact_inventory_transaction`: Every inventory movement (replaces ALL *_QROO_V views)
> - **Compatibility Views (blue boxes, right)**: Same 51 view names, same columns
>   - Power BI datasets require **zero changes**
>
> Notice the relationships:
> - `dim_item` (1) → `fact_inventory_snapshot` (∞) via item_sk
> - `dim_facility` (1) → `fact_inventory_snapshot` (∞) via facility_sk
>
> **The template pattern:**
> - `v_biceps_iroo` (base template): 15 lines of SQL querying fact + dimensions
> - `v_biceps_iroo_d0001` (variant): 1 line: `SELECT * FROM v_biceps_iroo WHERE profile_id IN ('D0001','D0008')`
> - 5 more variants, all 1-line filters
>
> **The wins:**
> - Change item description? Update `dim_item` dimension → all 51 views inherit instantly
> - Fix JOIN bug? Fix `fact_inventory_snapshot` → all 51 views inherit
> - **Performance:** Facts are liquid clustered on (facility_sk, date_sk) for 10-100x query speedup
> - **Scalability:** Add new business unit? Insert 1 row, not create 14 new views"

**Slide 4: The Decision**

> "Both versions work. Both deliver the same 51 views to Power BI with identical column shapes.
>
> **Version A:**
> - Faster to build (1-2 weeks)
> - Maintenance nightmare (change 1 thing = update 40+ views)
> - No performance optimization
>
> **Version B:**
> - Takes longer to build (4-6 weeks)
> - Sustainable long-term (change 1 dimension = all views inherit)
> - 10-100x faster queries (liquid clustering)
> - Extensible (add 12 more fact tables for future analytics)
>
> **Our recommendation:** Start with Version A to get Power BI working fast, then incrementally migrate to Version B one business unit at a time. Both can coexist during the transition."

---

## Quick Reference: Common Questions

**Q: "What's Bronze vs Silver vs Gold?"**
- **Bronze** = Raw data from source systems (Manhattan WMS)
- **Silver** = Cleaned, conformed, deduplicated (SCD2, CDC) - **not in this POC**
- **Gold** = Business-friendly transformations (dimensions, facts, views for Power BI)

**Q: "What does IROO mean?"**
- **IROO** = "Item Reference On-hand Only" = Detailed inventory report with item details + locations
- **QROO** = "Quick Reference On-hand Only" = Simplified version, just item ID + quantity

**Q: "Why 6 variants per business unit?"**
- Giant Eagle has 6 distribution centers (D0001, D0044, D0050, D0061, D0070, D0080)
- Each business unit (BICEPS, HBC, etc.) needs separate reports per DC
- Version A: 14 views per BU (7 IROO + 7 QROO)
- Version B: 2 templates + 12 one-line variants

**Q: "What's liquid clustering?"**
- Databricks optimization that physically co-locates data on disk
- `CLUSTER BY (facility_sk, date_sk)` means "group all DC D0001 data together, sorted by date"
- Queries filtering on DC + date are 10-100x faster (no full table scan)

**Q: "Can Power BI use both versions?"**
- Yes! The 51 compatibility views have identical names and columns in both versions
- Switch Power BI dataset connection from `gold_lift_shift.ccs_iroo_v` to `gold_native.v_ccs_iroo`
- Zero changes to Power BI reports

**Q: "What's the template pattern?"**
- **Base template**: Full SQL logic (15-20 lines)
- **Variants**: One-line filters: `SELECT * FROM base WHERE condition`
- Fix bug in base? All variants inherit instantly
- Version A: 40+ views with duplicated full SQL
- Version B: 6 templates + 40+ one-line variants

---

## For the Demo: Key Talking Points

1. **"Same Power BI, different engine room"** - Both versions deliver identical outputs
2. **"40+ views collapse into 6 templates"** - The template pattern reduces duplication
3. **"Change once, inherit everywhere"** - Dimensions are single source of truth
4. **"10-100x faster queries"** - Liquid clustering optimizes data layout
5. **"Add new BU? Insert 1 row, not create 14 views"** - Scalability advantage

**Visual Props:**
- Show both dbdiagram.io diagrams side-by-side
- Point to the "spaghetti" of relationships in Version A (Bronze → 51 views)
- Point to the "clean star" in Version B (Dimensions → Facts → Views)

**Closing:**
> "This POC proves both approaches deliver. The question isn't 'Can we do it?' but 'Which path sets Giant Eagle up for long-term success?' Our recommendation: Start fast with Version A, then migrate to Version B incrementally as you prove the value."
