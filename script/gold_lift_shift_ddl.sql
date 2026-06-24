-- =====================================================================
-- Giant Eagle POC: 03_gold_lift_shift_all_views.sql
-- VERSION A: 1:1 port of 50 Snowflake views to Databricks SQL views.
-- Validated against original DDL (GE Snowflake Views document).
-- Column shapes confirmed: IROO=18/19, ITEM_SNAPSHOT=26, BICEPS/CCS_QROO=30, per-DC_QROO=24.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_lift_shift;


-- ============================================================
-- CCS (Cross-Facility)
-- ============================================================

CREATE OR REPLACE VIEW ccs_inv_compare_v AS
select main_dc.facility_id as inventory_facility,
main_dc.item_id,
CASE WHEN main_dc.sum_on_hand < 0 THEN 0 ELSE main_dc.sum_on_hand END
sum_on_hand,
main_dc.sum_allocated,
main_dc.profile_id,
CASE WHEN sum(out_stg.sum_on_hand) < 0 THEN 0 ELSE sum(out_stg.sum_on_hand) END
as outside_stg
from
(
select ge_poc.bronze.default_dcinventory_dci_inventory.facility_id,
ge_poc.bronze.default_dcinventory_dci_inventory.item_id,
ge_poc.bronze.default_item_master_ite_item.profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse, 3,2) as whse,
sum(nvl(on_hand,0)) as sum_on_hand,
sum(nvl(allocated,0)) as sum_allocated
from ge_poc.bronze.default_item_master_ite_item
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_item_master_ite_item.profile_id =
ge_poc.bronze.default_dcinventory_dci_inventory.org_id AND
ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
where (ge_poc.bronze.default_dcinventory_dci_inventory.on_hand != 0 or
ge_poc.bronze.default_dcinventory_dci_inventory.allocated != 0)
and ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
and ge_poc.bronze.default_dcinventory_dci_inventory.is_in_transit = 0
group by ge_poc.bronze.default_dcinventory_dci_inventory.facility_id,
ge_poc.bronze.default_dcinventory_dci_inventory.item_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse, 3,2),
ge_poc.bronze.default_item_master_ite_item.profile_id
) main_dc

left join
(
select ge_poc.bronze.default_dcinventory_dci_inventory.item_id,
ge_poc.bronze.default_item_master_ite_item.profile_id,
ge_poc.bronze.default_dcinventory_dci_inventory.facility_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse, 3,2) as whse,
sum(nvl(on_hand,0)) as sum_on_hand,
sum(nvl(allocated,0)) as sum_allocated
from ge_poc.bronze.default_item_master_ite_item
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND
ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
where (ge_poc.bronze.default_dcinventory_dci_inventory.on_hand != 0 or
ge_poc.bronze.default_dcinventory_dci_inventory.allocated != 0)
and ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
and ge_poc.bronze.default_dcinventory_dci_inventory.is_in_transit = 0
--AND ge_poc.bronze.default_item_master_ite_item.ITEM_ID = '904629'
group by ge_poc.bronze.default_dcinventory_dci_inventory.item_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse, 3,2),
ge_poc.bronze.default_item_master_ite_item.profile_id,
ge_poc.bronze.default_dcinventory_dci_inventory.facility_id
) out_stg
on main_dc.item_id = out_stg.item_id
and main_dc.profile_id = out_stg.profile_id
and main_dc.whse = out_stg.whse
and main_dc.facility_id <> out_stg.facility_id
group by main_dc.facility_id,
main_dc.item_id,
main_dc.sum_on_hand,
main_dc.sum_allocated,
main_dc.profile_id;

CREATE OR REPLACE VIEW ccs_iroo_v AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.VIRTWHSE,
ALL_SKU.ITEMID,
ALL_SKU.LPNPERTIER,
ALL_SKU.TIERPERPALLET,
ALL_SKU.UNIT_HEIGHT,
ALL_SKU.UNIT_WIDTH,
ALL_SKU.UNIT_LENGTH,
ALL_SKU.UNIT_WEIGHT,
ALL_SKU.PACK_HEIGHT,
ALL_SKU.PACK_WIDTH,
ALL_SKU.PACK_LENGTH,
ALL_SKU.PACK_WEIGHT,
NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS
LOCATION_BARCODE,
ALL_SKU.UNITVOLUME,
ALL_SKU.PACKVOLUME,
CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
SELECT
ge_poc.bronze.default_item_master_ite_item.PROFILE_ID AS PROFILE_ID,
ge_poc.bronze.default_dcinventory_dci_inventory.FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE AS
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID AS ITEMID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER AS LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET AS TIERPERPALLET,
IP1.HEIGHT AS UNIT_HEIGHT,
IP1.WIDTH AS UNIT_WIDTH,
IP1.LENGTH AS UNIT_LENGTH,
IP1.WEIGHT AS UNIT_WEIGHT,
IP2.HEIGHT AS PACK_HEIGHT,
IP2.WIDTH AS PACK_WIDTH,
IP2.LENGTH AS PACK_LENGTH,
IP2.WEIGHT AS PACK_WEIGHT,
MIN(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) AS
LOCATION_BARCODE,
IP1.VOLUME AS UNITVOLUME,
IP2.VOLUME AS PACKVOLUME
FROM ge_poc.bronze.default_item_master_ite_item
JOIN ge_poc.bronze.default_item_master_ite_item_package IP1 ON
ge_poc.bronze.default_item_master_ite_item.PK = IP1.ITEM_PK AND
IP1.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND IP1.QUANTITY = 1
JOIN ge_poc.bronze.default_item_master_ite_item_package IP2 ON
ge_poc.bronze.default_item_master_ite_item.PK = IP2.ITEM_PK AND
IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND IP2.QUANTITY = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory ON
ge_poc.bronze.default_item_master_ite_item.ITEM_ID =
ge_poc.bronze.default_dcinventory_dci_inventory.ITEM_ID
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location ON
ge_poc.bronze.default_dcinventory_dci_inventory.LOCATION_ID =
ge_poc.bronze.default_dcinventory_dci_location.LOCATION_ID
WHERE ge_poc.bronze.default_dcinventory_dci_inventory.FACILITY_ID IS NOT NULL
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
GROUP BY ge_poc.bronze.default_item_master_ite_item.PROFILE_ID,
ge_poc.bronze.default_dcinventory_dci_inventory.FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET,
IP1.HEIGHT,
IP1.WEIGHT,
IP1.LENGTH,
IP1.WIDTH,
IP2.HEIGHT,
IP2.WEIGHT,
IP2.LENGTH,
IP2.WIDTH,
IP1.VOLUME,
IP2.VOLUME
) SKU_W_INV
RIGHT OUTER JOIN
(
SELECT
ITM.PROFILE_ID AS PROFILE_ID,
FAC.ORGANIZATION_ID AS FACILITY_ID,
ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
ITM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
ITM.ITEM_ID AS ITEMID,
ITM.LPN_PER_TIER AS LPNPERTIER,
ITM.TIERS_PER_PALLET AS TIERPERPALLET,
IP1.HEIGHT AS UNIT_HEIGHT,
IP1.WIDTH AS UNIT_WIDTH,
IP1.LENGTH AS UNIT_LENGTH,
IP1.WEIGHT AS UNIT_WEIGHT,
IP2.HEIGHT AS PACK_HEIGHT,
IP2.WIDTH AS PACK_WIDTH,
IP2.LENGTH AS PACK_LENGTH,
IP2.WEIGHT AS PACK_WEIGHT,
NULL AS LOCATION_BARCODE,
IP1.VOLUME AS UNITVOLUME,
IP2.VOLUME AS PACKVOLUME
FROM ge_poc.bronze.default_item_master_ite_item ITM
JOIN ge_poc.bronze.default_item_master_ite_item_package IP1 ON ITM.PK = IP1.ITEM_PK
AND IP1.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND IP1.QUANTITY = 1
JOIN ge_poc.bronze.default_item_master_ite_item_package IP2 ON ITM.PK = IP2.ITEM_PK
AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND IP2.QUANTITY = 1
CROSS JOIN (
SELECT ORGANIZATION_ID FROM ge_poc.bronze.default_organization_org_organization
WHERE __HEVO__MARKED_DELETED = 'FALSE'
AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
AND ORGANIZATION_ID LIKE 'D003%'
) FAC
WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
AND ITM.PROFILE_ID LIKE 'D003%'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW ccs_item_snapshot_v AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id IN ('D0031', 'D0032', 'D0033', 'D0036', 'D0037', 'D0038')
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id IN ('D0031', 'D0032', 'D0033', 'D0036', 'D0037', 'D0038')
WHERE ite.profile_id IN ('D0031', 'D0032', 'D0033', 'D0036', 'D0037', 'D0038')
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW ccs_qroo_v AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';


-- ============================================================
-- GE Corporate Services
-- ============================================================

CREATE OR REPLACE VIEW ge_cs_adjustment_reason_v AS
SELECT
d.reason_code_id AS adjustment_reason_code,
d.description AS adjustment_reason_description
FROM
ge_poc.bronze.default_inventory_management_inm_adjustment_reason_code d
WHERE
d.profile_id = 'D0080';

CREATE OR REPLACE VIEW ge_cs_cycl_cnt_adjmt_dtlv (
  warehouse_id,
  facility,
  inventory_date,
  item_id,
  item_description,
  item_ndc,
  ITEM_NDC_PACKAGE_SIZE,
  adjustment_reason_code,
  ADJUSTMENT_QUANTITY,
  create_date_time,
  mod_date_time,
  user_id,
  adjmt_dtl_id)
AS SELECT Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)
warehouse_id,
Substring(px.org_id, 4, 2)
facility,
To_char(gcic.inventory_date, 'MM/DD/YYYY hh:mi:ss') AS
inventory_date,
px.item_id,
Substr(px.item_description, 1, 40) AS
item_description,
px.item_id
|| Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2) AS
item_ndc,
CASE ite.display_uom_id
WHEN 'PACK' THEN 'P'
WHEN 'UNIT' THEN 'U'
WHEN 'LPN' THEN 'L'
ELSE 'U'
END AS
ITEM_NDC_PACKAGE_SIZE,
px.reason_code_id AS
adjustment_reason_code,
CASE px.adjusted_type
WHEN 'SUBTRACT' THEN px.quantity * -1
ELSE px.quantity
END
ADJUSTMENT_QUANTITY,
Convert_timezone('UTC', 'America/New_York', px.created_timestamp)
create_date_time,
Convert_timezone('UTC', 'America/New_York', px.updated_timestamp)
mod_date_time,
Substring(px.created_by, 1, 15) AS
user_id,
Substring(px.pix_entry_id
|| ','
|| px.inventory_attribute1, 1, 20) AS
adjmt_dtl_id
FROM ge_poc.bronze.default_pix_pix_pix_entry px,
ge_poc.bronze.default_item_master_ite_item ite,
ge_poc.bronze.ge_cs_invn_control gcic
WHERE px.item_id = ite.item_id
AND Substring(px.org_id, 4, 2) = Substring(ite.profile_id, 4, 2)
AND px.org_id = 'D0080'
AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
AND px.reason_code_id IN( 'CC', 'DD', 'HB', 'RC',
'SR', 'WM' )
AND To_date(gcic.inventory_date) = CURRENT_DATE() - 1
AND Convert_timezone('UTC', 'America/New_York', px.created_timestamp)
BETWEEN
gcic.analysis_start_date_time AND gcic.analysis_end_date_time
;


CREATE OR REPLACE VIEW ge_cs_invn_dly_total_v AS
SELECT
    substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)    warehouse_id,
    substring(ite.profile_id, 4, 2)                    facility,
    Current_date()                              AS inventory_date,
   -- to_date(from_utc_timestamp(dci.created_timestamp, 'America/New_York')) AS inventory_date,
    ite.item_id,
    ite.item_id
    || substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2) AS item_ndc,
    NVL(SUM(dci.on_hand),0)                                  on_handcurrent_inventory_qty,
    TO_char(Current_date(),'YYYY-MM-DD, HH:MI:SS')                              AS create_date,
    TO_char(Current_date(),'YYYY-MM-DD, HH:MI:SS')                              AS update_date,
    'GE_CS_INVN_MON'                                AS user_id,
    ite.SHORT_DESCRIPTION  as Item_Description
FROM
    --     ge_poc.bronze.ge_cs_invn_control gcic,
    ge_poc.bronze.default_item_master_ite_item ite    
    left outer JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci ON ite.item_id = dci.item_id AND dci.org_id = ite.profile_id AND dci.is_in_transit = '0' AND dci.__hevo__marked_deleted = 'FALSE' AND dci.inventory_container_type_id IN ( 'ILPN', 'LOCATION', 'OLPN' )
WHERE ite.profile_id = 'D0080'
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
   AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
   --AND ITE.ITEM_ID = '977975'
  --  AND to_date(gcic.inventory_date) = Current_date()-1
  --  AND from_utc_timestamp(dci.created_timestamp, 'America/New_York') BETWEEN gcic.ANALYSIS_START_DATE_TIME AND gcic.analysis_end_date_time
GROUP BY
    substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2),
    substring(ite.profile_id, 4, 2),
    --dci.created_timestamp,
   -- dci.updated_timestamp,
    ite.item_id,
    ite.SHORT_DESCRIPTION,
ite.item_id|| substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2);

CREATE OR REPLACE VIEW ge_cs_transaction_dtl_v AS
SELECT Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)
warehouse_id,

Substring(ite.profile_id, 4, 2)
facility,
To_char(gcic.inventory_date, 'MM/DD/YYYY hh:mi:ss') AS
inventory_date,
ite.item_id AS
item_number,
Substring(ite.description, 14) AS
item_description,
ite.item_id
|| Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2) AS
item_ndc,
( CASE ite.display_uom_id
WHEN 'PACK' THEN 'P'
WHEN 'UNIT' THEN 'U'
WHEN 'LPN' THEN 'L'
ELSE 'U'
END ) AS
item_ndc_package_size,
( CASE px.source_transaction_type
WHEN 'SHIPCONFIRM' THEN 'SHIPMENT'
WHEN 'RECEIVING' THEN 'RECEIVING'
END ) AS
adjustment_reason_code,
px.quantity AS
adjustment_qty,
Convert_timezone('UTC', 'America/New_York', px.created_timestamp) AS
create_date,
Convert_timezone('UTC', 'America/New_York', px.updated_timestamp) AS
update_date,
Substring(px.updated_by, 1, 15) AS
user_id,
Concat(( CASE
WHEN px.purchase_order_id = ''
AND px.inventory_attribute1 = 'CONVER' THEN
Substring(px.sync_batch_id, 1, 6)
WHEN px.purchase_order_id = ''
AND px.inventory_attribute1 != 'CONVER' THEN
px.inventory_attribute1
ELSE px.purchase_order_id
END ), ',', ( CASE
WHEN px.purchase_order_line_id = '' THEN
px.item_id
ELSE px.purchase_order_line_id
END ))
identifying_value,
'PO_Nbr, PO_Line_Nbr' AS
identifying_link,
NULL AS
ADDITIONAL_INFO
FROM ge_poc.bronze.ge_cs_invn_control gcic,
ge_poc.bronze.default_pix_pix_pix_entry px
INNER JOIN ge_poc.bronze.default_item_master_ite_item ite
ON px.item_id = ite.item_id
WHERE ite.__hevo__marked_deleted = 'FALSE'
AND px.adjusted_type IN ( 'ADD', '' )
AND px.source_transaction_type IN ( 'RECEIVING', 'SHIPCONFIRM' )
AND Nvl(ite.style_suffix, '01') != '99'
AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
AND ite.profile_id = 'D0080'
AND px.__hevo__marked_deleted = 'false'
AND px.org_id = 'D0080'
AND To_date(gcic.inventory_date) = CURRENT_DATE() - 1
AND Convert_timezone('UTC', 'America/New_York', px.created_timestamp)
BETWEEN
gcic.analysis_start_date_time AND gcic.analysis_end_date_time;


-- ============================================================
-- BICEPS IROO
-- ============================================================

CREATE OR REPLACE VIEW biceps_iroo_v AS
SELECT itm.profile_id as profile_id,
substr(itm.ext_gegl_dcxx_virtual_whse,1,1)||'00'||substr(itm.ext_gegl_dcxx_virtual_whse,6,2) AS FACILITY_ID,
CASE WHEN itm.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20' THEN 'DC20'||'-'||'20'
     ELSE itm.EXT_GEGL_DCXX_VIRTUAL_WHSE END as EXT_GEGLDCXXVIRTUALWHSE,
itm.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
itm.ITEM_ID as ITEM_ID,
itm.LPN_PER_TIER as LPNPERTIER,
itm.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
MIN(locn.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 ON itm.pk = ip1.item_pk
JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 ON itm.pk = ip2.item_pk
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci ON itm.item_id = dci.item_id 
    AND dci.org_id = itm.profile_id AND dci.__HEVO__MARKED_DELETED = 'FALSE'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON dci.location_id = locn.location_id 
    AND dci.org_id = locn.profile_id AND locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE ip1.standard_quantity_uom_id = itm.DISPLAY_UOM_ID
AND ip2.standard_quantity_uom_id = 'PACK'
AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND itm.__HEVO__MARKED_DELETED = 'FALSE'
AND ip1.profile_id = 'D0033'
GROUP BY itm.profile_id,
    substr(itm.ext_gegl_dcxx_virtual_whse,1,1)||'00'||substr(itm.ext_gegl_dcxx_virtual_whse,6,2),
    CASE WHEN itm.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20' THEN 'DC20'||'-'||'20'
         ELSE itm.EXT_GEGL_DCXX_VIRTUAL_WHSE END,
    itm.EXT_GEGL_DC33_VIRTUAL_WHSE,
    itm.ITEM_ID,
    itm.LPN_PER_TIER,
    itm.TIERS_PER_PALLET,
    ip1.height, ip1.width, ip1.length, ip1.weight,
    ip2.height, ip2.width, ip2.length, ip2.weight,
    ip1.volume, ip2.volume;

CREATE OR REPLACE VIEW biceps_iroo_v_d0001 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET
, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,
a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)

||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0001','D0008')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '394349'
AND nvl(ge_poc.bronze.default_item_master_ite_item.STYLE_SUFFIX,'1') != '99'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and
locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0001','D0008')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id AND a.profile_id = b.org_id;

CREATE OR REPLACE VIEW biceps_iroo_v_d0044 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET

, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,
a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0044')
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '005173'
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '000450'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and
locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0044')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;

CREATE OR REPLACE VIEW biceps_iroo_v_d0050 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET
, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,
a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0050')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '126509'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and
locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0050')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;

CREATE OR REPLACE VIEW biceps_iroo_v_d0061 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET
, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,
a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,

ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0061','D0069')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '000450'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id AND
lia.org_id = locn.profile_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0061','D0069')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;

CREATE OR REPLACE VIEW biceps_iroo_v_d0070 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET
, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,

a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0070')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '126509'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and
locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0070')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;

CREATE OR REPLACE VIEW biceps_iroo_v_d0080 AS
SELECT a.profile_id
, a.FACILITY_ID
, a.EXT_GEGLDCXXVIRTUALWHSE
, a.VIRTWHSE
, a.ITEM_ID
, a.LPNPERTIER
, a.TIERPERPALLET
, a.UNIT_HEIGHT
, a.UNIT_WIDTH
, a.UNIT_LENGTH,
a.UNIT_WEIGHT,
a.PACK_HEIGHT,
a.PACK_WIDTH,
a.PACK_LENGTH,
a.PACK_WEIGHT,
b.LOCATION_BARCODE,
a.UNITVOLUME,
a.PACKVOLUME
FROM (
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
CASE WHEN ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE =
'DC80-20' THEN 'DC20'||'-'||'20' ELSE
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DCXX_VIRTUAL_WHSE END as
EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND ge_poc.bronze.default_item_master_ite_item.item_id = '034009'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS != 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,1,1)
||'00'||substr(ge_poc.bronze.default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,6,2)
FACILITY_ID,
'DC20'||'-'||'20' as EXT_GEGLDCXXVIRTUALWHSE,
ge_poc.bronze.default_item_master_ite_item.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0021' as FACILITY_ID,
'DC20'||'-'||'21' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0022' FACILITY_ID,
'DC20'||'-'||'22' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0023' FACILITY_ID,
'DC20'||'-'||'23' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0024' FACILITY_ID,
'DC20'||'-'||'24' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0025' FACILITY_ID,
'DC20'||'-'||'25' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL
select DISTINCT ge_poc.bronze.default_item_master_ite_item.profile_id as profile_id,
'D0026' FACILITY_ID,
'DC20'||'-'||'26' as EXT_GEGLDCXXVIRTUALWHSE,
null as VIRTWHSE,
ge_poc.bronze.default_item_master_ite_item.ITEM_ID as ITEM_ID,
ge_poc.bronze.default_item_master_ite_item.LPN_PER_TIER as LPNPERTIER,
ge_poc.bronze.default_item_master_ite_item.TIERS_PER_PALLET as TIERPERPALLET,
ip1.height as UNIT_HEIGHT,
ip1.width as UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(ge_poc.bronze.default_dcinventory_dci_location.LOCATION_BARCODE) as
LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume as PACKVOLUME
from ge_poc.bronze.default_item_master_ite_item
join ge_poc.bronze.default_item_master_ite_item_package ip1 on ge_poc.bronze.default_item_master_ite_item.pk =
ip1.item_pk
join ge_poc.bronze.default_item_master_ite_item_package ip2 on ge_poc.bronze.default_item_master_ite_item.pk =
ip2.item_pk
left join ge_poc.bronze.default_dcinventory_dci_inventory on ge_poc.bronze.default_item_master_ite_item.item_id =
ge_poc.bronze.default_dcinventory_dci_inventory.item_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_item_master_ite_item.profile_id AND
ge_poc.bronze.default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join ge_poc.bronze.default_dcinventory_dci_location on ge_poc.bronze.default_dcinventory_dci_inventory.location_id =
ge_poc.bronze.default_dcinventory_dci_location.location_id AND ge_poc.bronze.default_dcinventory_dci_inventory.org_id =
ge_poc.bronze.default_dcinventory_dci_location.profile_id AND
ge_poc.bronze.default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia ON
--lia.item_id = ge_poc.bronze.default_dcinventory_dci_inventory.item_id = lia.item_id AND
-- lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND ge_poc.bronze.default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND ge_poc.bronze.default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND ge_poc.bronze.default_item_master_ite_item.item_id = '030129'
AND ge_poc.bronze.default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
)A
LEFT OUTER JOIN (
SELECT
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn ON lia.location_id = locn.location_id AND
lia.org_id = locn.profile_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0080')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ============================================================
-- BICEPS QROO
-- ============================================================

CREATE OR REPLACE VIEW biceps_qroo_v AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0033', 'D0031', 'D0037', 'D0032', 'D0036', 'D0038')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0001 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0001', 'D0008')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0001', 'D0008')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0001', 'D0008')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0001', 'D0008')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0001', 'D0008')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0001', 'D0008')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0001', 'D0008')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0044 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0044')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0044')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0044')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0044')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0044')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0044')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0044')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0050 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0050')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0050')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0050')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0050')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0050')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0050')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0050')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0061 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0061', 'D0069')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0061', 'D0069')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0061', 'D0069')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0061', 'D0069')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0061', 'D0069')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0061', 'D0069')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0061', 'D0069')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0070 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0070')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0070')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0070')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0070')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0070')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0070')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0070')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';

CREATE OR REPLACE VIEW biceps_qroo_v_d0080 AS
SELECT
    itm.profile_id,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0 
         THEN 0 
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) 
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS TRAN_RECEPTS_IN,
    0 AS TRAN_RECEPTS_OUT,
    0 AS TRAN_TRANSIT_IN,
    0 AS TRAN_TRANSIT_OUT,
    NVL(fx.sum_allocated, 0) AS WHSE_QTY_NOT_SELECTED,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    '0' AS SHORT_CYCLE_ITEM,
    SUBSTR(itm.EXT_GEGL_DEPARTMENT, 1, 2) AS EXT_GEGL_DEPARTMENT2,
    NVL(itm.unit_cost, 0) AS UNIT_COST,
    CAST(NULL AS INT) AS MAX_LPN_QUANTITY,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 4) AS AVG_WGT_DEC_4,
    ROUND(NVL(itm.AVERAGE_WEIGHT, 0), 3) AS AVERAGE_WEIGHT,
    CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp()) AS DCI_SYSDATE,
    itm.EXT_GEGL_DEPARTMENT AS EXT_GEGL_DEPARTMENT_3,
    CASE WHEN itm.Catch_Weight_Item = '1' THEN 'Y' ELSE 'N' END AS VARIABLE_WEIGHT_FLAG,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY
FROM ge_poc.bronze.default_item_master_ite_item itm
LEFT JOIN (
    SELECT profile_id, inventory_facility, item_id, sum_on_hand, sum_allocated, outside_stg
    FROM ge_poc.gold_lift_shift.ccs_inv_compare_v
    WHERE profile_id IN ('D0080')
) fx ON itm.item_id = fx.item_id AND itm.profile_id = fx.profile_id
LEFT JOIN (
    SELECT dci.item_id, dci.org_id, SUM(NVL(dci.on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory dci
    JOIN ge_poc.bronze.default_dcinventory_dci_location locn
        ON dci.location_id = locn.location_id AND dci.org_id = locn.profile_id
    WHERE dci.__hevo__marked_deleted = 'FALSE'
    AND dci.org_id IN ('D0080')
    AND locn.storage_uom_id NOT IN ('PACK','UNIT')
    GROUP BY dci.item_id, dci.org_id
) inv_locked ON itm.item_id = inv_locked.item_id AND itm.profile_id = inv_locked.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'RECEIPT'
    AND org_id IN ('D0080')
    GROUP BY item_id, org_id
) pix_recv ON itm.item_id = pix_recv.item_id AND itm.profile_id = pix_recv.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(quantity) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND source_transaction_type = 'ADJUSTMENT'
    AND org_id IN ('D0080')
    GROUP BY item_id, org_id
) pix_adj ON itm.item_id = pix_adj.item_id AND itm.profile_id = pix_adj.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0080')
    GROUP BY item_id, org_id
) recv_in ON itm.item_id = recv_in.item_id AND itm.profile_id = recv_in.org_id
LEFT JOIN (
    SELECT item_id, org_id, SUM(ordered_quantity) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE' AND org_id IN ('D0080')
    GROUP BY item_id, org_id
) po_qty ON itm.item_id = po_qty.item_id AND itm.profile_id = po_qty.org_id
WHERE itm.profile_id IN ('D0080')
AND itm.__hevo__marked_deleted = 'FALSE'
AND NVL(itm.STYLE_SUFFIX, '1') != '99';


-- ============================================================
-- ASF (DC D0061/D0069)
-- ============================================================

CREATE OR REPLACE VIEW asf_iroo_v_d0061 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0061', 'D0069')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0061', 'D0069')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0061', 'D0069')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0061', 'D0069')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW asf_item_snapshot_v_d0061 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id IN ('D0061', 'D0069')
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id IN ('D0061', 'D0069')
WHERE ite.profile_id IN ('D0061', 'D0069')
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW asf_qroo_v_d0061 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0
         ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE'
      AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0061','D0069')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW brm_iroo_v_d0050 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0050')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0050')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0050')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0050')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW brm_item_snapshot_v_d0050 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id = 'D0050'
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id = 'D0050'
WHERE ite.profile_id = 'D0050'
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW brm_qroo_v_d0050 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0 ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE' AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0050')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW ffm_iroo_v_d0070 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0070')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0070')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0070')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0070')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW ffm_item_snapshot_v_d0070 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id IN ('D0070')
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id IN ('D0070')
WHERE ite.profile_id IN ('D0070')
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW ffm_qroo_v_d0070 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0 ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE' AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0070')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW hbc_iroo_v_d0080 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0080')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0080')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0080')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0080')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW hbc_item_snapshot_v_d0080 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id = 'D0080'
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id = 'D0080'
WHERE ite.profile_id = 'D0080'
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW hbc_pharmacy_transportion_oh_v AS
SELECT 
    od.facility_id,
    od.facility_address_address1,
    od.facility_address_address2,
    od.facility_address_city,
    od.facility_address_state,
    od.facility_address_postalcode,
    od.appl_code,
    o.olpn_id,
    od.ext_pharmacy_routeid,
    od.ext_pharmacy_stop_id
FROM ge_poc.bronze.default_pickpack_ppk_olpn o
JOIN ge_poc.bronze.default_pickpack_ppk_olpn_detail od
    ON o.olpn_id = od.olpn_id
WHERE o.status IN ('50', '60', '70', '80')
    AND o.__hevo__marked_deleted = 'FALSE'
    AND od.__hevo__marked_deleted = 'FALSE'
    AND o.facility_id = 'D0080';

CREATE OR REPLACE VIEW hbc_pharmacy_transportion_pa_v AS
SELECT 
    od.facility_id,
    od.facility_address_address1,
    od.facility_address_address2,
    od.facility_address_city,
    od.facility_address_state,
    od.facility_address_postalcode,
    od.appl_code,
    o.olpn_id,
    od.ext_pharmacy_routeid,
    od.ext_pharmacy_stop_id
FROM ge_poc.bronze.default_pickpack_ppk_olpn o
JOIN ge_poc.bronze.default_pickpack_ppk_olpn_detail od
    ON o.olpn_id = od.olpn_id
WHERE o.status IN ('50', '60', '70', '80')
    AND o.__hevo__marked_deleted = 'FALSE'
    AND od.__hevo__marked_deleted = 'FALSE'
    AND o.facility_id = 'D0080';

CREATE OR REPLACE VIEW hbc_qroo_v_d0080 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0 ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE' AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0080')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW hbc_task_group_desc AS
SELECT '119 - Aero Case Sel' AS DESCRIPTION, '119' AS TASK_GROUP, 'GEGL Aerosol Picking' AS TRANSACTION_ID, 'H19' AS SOURCE_ZONE_ID  UNION ALL
SELECT '119 - Aero Case Sel' AS DESCRIPTION, '119' AS TASK_GROUP, 'GEGL Aerosol Picking' AS TRANSACTION_ID, 'H20' AS SOURCE_ZONE_ID  UNION ALL
SELECT '119 - Aero Case Sel' AS DESCRIPTION, '119' AS TASK_GROUP, 'GG Aerosol Picking' AS TRANSACTION_ID, 'H19' AS SOURCE_ZONE_ID  UNION ALL
SELECT '119 - Aero Case Sel' AS DESCRIPTION, '119' AS TASK_GROUP, 'GG Aerosol Picking' AS TRANSACTION_ID, 'H20' AS SOURCE_ZONE_ID  UNION ALL
SELECT '200 - Cig Selection' AS DESCRIPTION, '200' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '200 - Kratom' AS DESCRIPTION, '200' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '200 - Cig Selection' AS DESCRIPTION, '200' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '200 - Kratom' AS DESCRIPTION, '200' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H821' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H821' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H822' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H822' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HCG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '220' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'HST' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H82B' AS SOURCE_ZONE_ID  UNION ALL
SELECT '210 - Chase Mezzanine' AS DESCRIPTION, '210' AS TASK_GROUP, 'GG Chase Picking from Each Pick' AS TRANSACTION_ID, 'H82B' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H821' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H822' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'HTB' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H82' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H822' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H821' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H82B' AS SOURCE_ZONE_ID  UNION ALL
SELECT '230 - Tobacco Selection' AS DESCRIPTION, '230' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H82B' AS SOURCE_ZONE_ID  UNION ALL
SELECT '301 - Shelf Sel' AS DESCRIPTION, '301' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H30' AS SOURCE_ZONE_ID  UNION ALL
SELECT '301 - Shelf Sel' AS DESCRIPTION, '301' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H30' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H31' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H39' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H40' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H41' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H42' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H31' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H39' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H40' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H41' AS SOURCE_ZONE_ID  UNION ALL
SELECT '400 - Shelf Sel' AS DESCRIPTION, '400' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H42' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H43' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H44' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H46' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H43' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H44' AS SOURCE_ZONE_ID  UNION ALL
SELECT '440 - Shelf Sel 43 - 46' AS DESCRIPTION, '440' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H46' AS SOURCE_ZONE_ID  UNION ALL
SELECT '480 - Shelf Sel' AS DESCRIPTION, '480' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H48' AS SOURCE_ZONE_ID  UNION ALL
SELECT '480 - Shelf Sel' AS DESCRIPTION, '480' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H48' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H59' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H601' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H602' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H61' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H59' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H601' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H602' AS SOURCE_ZONE_ID  UNION ALL
SELECT '590 - Shelf Sel 59 - 61' AS DESCRIPTION, '590' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H61' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H621' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H622' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H63' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H641' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H642' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H621' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H622' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H63' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H641' AS SOURCE_ZONE_ID  UNION ALL
SELECT '620 - Shelf Sel 62 - 64' AS DESCRIPTION, '620' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H642' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H65' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H66' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H671' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H672' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H68' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H69' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H65' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H66' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H671' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H672' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H68' AS SOURCE_ZONE_ID  UNION ALL
SELECT '640 - Shelf Sel 65 - 69' AS DESCRIPTION, '640' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H69' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '700 - Flow Sel 7000 - 7031' AS DESCRIPTION, '700' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '704 - Flow Sel 7033 - 7064' AS DESCRIPTION, '704' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70O6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H70E6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70O6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '708 - Flow Sel 7065 - 7099' AS DESCRIPTION, '708' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H70E6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81O2' AS SOURCE_ZONE_ID  UNION ALL
--SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
--SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81O2' AS SOURCE_ZONE_ID  UNION ALL
--SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
--SELECT '810 - Flow Sel 8100 - 51' AS DESCRIPTION, '810' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GEGL Picking From Each Pick' AS TRANSACTION_ID, 'H81E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '814 - Flow Sel 8155 - 83' AS DESCRIPTION, '814' AS TASK_GROUP, 'GG Picking from Each Pick' AS TRANSACTION_ID, 'H81E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H30' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H30' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H31' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H31' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H39' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H40' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H41' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H42' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H39' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H40' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H41' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H42' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H43' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H44' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H46' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H43' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H44' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H46' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H48' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H48' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H59' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H601' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H602' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H61' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H59' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H601' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H61' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H621' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H622' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H63' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H641' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H642' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H621' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H622' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H63' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H641' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H642' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H65' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H66' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H671' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H672' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H68' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H69' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H65' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H66' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H671' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H672' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H68' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H69' AS SOURCE_ZONE_ID  UNION ALL
SELECT '831 - Chase Act 30 - 69' AS DESCRIPTION, '831' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H602' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E5' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70O6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '832 - Chase Act 70' AS DESCRIPTION, '832' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H70E6' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E1' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O2' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E3' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GEGL Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81O4' AS SOURCE_ZONE_ID  UNION ALL
SELECT '833 - Chase Act 81' AS DESCRIPTION, '833' AS TASK_GROUP, 'GG Chase Picking From Each Pick' AS TRANSACTION_ID, 'H81E4' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H83' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H84' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H85' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H87' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H88' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H89' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H90' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H92' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H93' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H94' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H95' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H97' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H98' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'H99' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'HBK' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'HFR' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '850' AS TASK_GROUP, 'GEGL Picking From Case Pick' AS TRANSACTION_ID, 'HGG' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H83' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H84' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H85' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H87' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H88' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H89' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H90' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H92' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H93' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H94' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H95' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H97' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H98' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'H99' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'HBK' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'HFR' AS SOURCE_ZONE_ID  UNION ALL
SELECT 'Case Selection 83 - 99' AS DESCRIPTION, '906' AS TASK_GROUP, 'GG Picking from Case Pick' AS TRANSACTION_ID, 'HGG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H83' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H84' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H85' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H87' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H88' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H89' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H90' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H92' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H93' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H94' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H95' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H97' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H98' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H99' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'HBK' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'HFR' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'HGG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H83' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H84' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H85' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H87' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H88' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H89' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H90' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H92' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H93' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H94' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H95' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H97' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H98' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'H99' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'HBK' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'HFR' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GG Chase Picking from Case Pick' AS TRANSACTION_ID, 'HGG' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H19' AS SOURCE_ZONE_ID  UNION ALL
SELECT '985 - Chase Case Pick' AS DESCRIPTION, '985' AS TASK_GROUP, 'GEGL Chase Picking From Case Pick' AS TRANSACTION_ID, 'H20' AS SOURCE_ZONE_ID  UNION ALL
SELECT '117 - Vault Unit Selection' AS DESCRIPTION, '117' AS TASK_GROUP, 'GE RX Unit Selection' AS TRANSACTION_ID, 'P153' AS SOURCE_ZONE_ID  UNION ALL
SELECT '120 - Cage Unit Selection' AS DESCRIPTION, '120' AS TASK_GROUP, 'GE RX Unit Selection' AS TRANSACTION_ID, 'P152' AS SOURCE_ZONE_ID  UNION ALL
SELECT '116 - Cooler Unit Selection' AS DESCRIPTION, '116' AS TASK_GROUP, 'GE RX Unit Selection' AS TRANSACTION_ID, 'P151' AS SOURCE_ZONE_ID  UNION ALL
SELECT '113 - General Unit Selection' AS DESCRIPTION, '113' AS TASK_GROUP, 'GE RX Unit Selection' AS TRANSACTION_ID, 'P13' AS SOURCE_ZONE_ID  UNION ALL
SELECT '114 - Aisle 13 Case Selection' AS DESCRIPTION, '114' AS TASK_GROUP, 'GE RX Unit Selection' AS TRANSACTION_ID, null AS SOURCE_ZONE_ID;


-- ============================================================
-- OKG (DC D0001/D0008)
-- ============================================================

CREATE OR REPLACE VIEW okg_iroo_v_d0001 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0001', 'D0008')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0001', 'D0008')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0001', 'D0008')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0001', 'D0008')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW okg_item_snapshot_v_d0001 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id IN ('D0001', 'D0008')
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id IN ('D0001', 'D0008')
WHERE ite.profile_id IN ('D0001', 'D0008')
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW okg_qroo_v_d0001 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0 ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE' AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0001','D0008')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW okp_iroo_v_d0044 AS
SELECT
    ALL_SKU.PROFILE_ID,
    ALL_SKU.FACILITY_ID,
    ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
    ALL_SKU.VIRTWHSE,
    ALL_SKU.ITEMID,
    ALL_SKU.LPNPERTIER,
    ALL_SKU.TIERPERPALLET,
    ALL_SKU.UNIT_HEIGHT,
    ALL_SKU.UNIT_WIDTH,
    ALL_SKU.UNIT_LENGTH,
    ALL_SKU.UNIT_WEIGHT,
    ALL_SKU.PACK_HEIGHT,
    ALL_SKU.PACK_WIDTH,
    ALL_SKU.PACK_LENGTH,
    ALL_SKU.PACK_WEIGHT,
    NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
    ALL_SKU.UNITVOLUME,
    ALL_SKU.PACKVOLUME,
    CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    -- SKU_W_INV: Items that actually have inventory records
    SELECT * FROM (
        SELECT DISTINCT
            itm.PROFILE_ID AS PROFILE_ID,
            dci.FACILITY_ID,
            itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
            itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
            itm.ITEM_ID AS ITEMID,
            itm.LPN_PER_TIER AS LPNPERTIER,
            itm.TIERS_PER_PALLET AS TIERPERPALLET,
            ip1.HEIGHT AS UNIT_HEIGHT,
            ip1.WIDTH AS UNIT_WIDTH,
            ip1.LENGTH AS UNIT_LENGTH,
            ip1.WEIGHT AS UNIT_WEIGHT,
            ip2.HEIGHT AS PACK_HEIGHT,
            ip2.WIDTH AS PACK_WIDTH,
            ip2.LENGTH AS PACK_LENGTH,
            ip2.WEIGHT AS PACK_WEIGHT,
            ip1.VOLUME AS UNITVOLUME,
            ip2.VOLUME AS PACKVOLUME
        FROM ge_poc.bronze.default_item_master_ite_item itm
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
            ON itm.PK = ip1.ITEM_PK 
            AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID 
            AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
            ON itm.PK = ip2.ITEM_PK 
            AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK' 
            AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci 
            ON itm.ITEM_ID = dci.ITEM_ID
            AND dci.__HEVO__MARKED_DELETED = 'FALSE'
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON dci.LOCATION_ID = locn.LOCATION_ID
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE dci.FACILITY_ID IN ('D0044')
        AND itm.__HEVO__MARKED_DELETED = 'FALSE'
        AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    ) A
    LEFT OUTER JOIN (
        SELECT
            lia.org_id,
            lia.item_id,
            MAX(locn.LOCATION_BARCODE) AS LOCATION_BARCODE
        FROM ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
        LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location locn 
            ON lia.location_id = locn.location_id 
            AND locn.__HEVO__MARKED_DELETED = 'FALSE'
        WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
        AND locn.STORAGE_UOM_ID IN ('PACK','UNIT')
        AND lia.org_id IN ('D0044')
        GROUP BY lia.org_id, lia.item_id
    ) b ON A.ITEMID = b.item_id
) SKU_W_INV
RIGHT OUTER JOIN
(
    -- ALL_SKU: All items in the organization (base set)
    SELECT
        itm.PROFILE_ID AS PROFILE_ID,
        fac.ORGANIZATION_ID AS FACILITY_ID,
        itm.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
        itm.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
        itm.ITEM_ID AS ITEMID,
        itm.LPN_PER_TIER AS LPNPERTIER,
        itm.TIERS_PER_PALLET AS TIERPERPALLET,
        ip1.HEIGHT AS UNIT_HEIGHT,
        ip1.WIDTH AS UNIT_WIDTH,
        ip1.LENGTH AS UNIT_LENGTH,
        ip1.WEIGHT AS UNIT_WEIGHT,
        ip2.HEIGHT AS PACK_HEIGHT,
        ip2.WIDTH AS PACK_WIDTH,
        ip2.LENGTH AS PACK_LENGTH,
        ip2.WEIGHT AS PACK_WEIGHT,
        NULL AS LOCATION_BARCODE,
        ip1.VOLUME AS UNITVOLUME,
        ip2.VOLUME AS PACKVOLUME
    FROM ge_poc.bronze.default_item_master_ite_item itm
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip1 
        ON itm.PK = ip1.ITEM_PK 
        AND ip1.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID
    JOIN ge_poc.bronze.default_item_master_ite_item_package ip2 
        ON itm.PK = ip2.ITEM_PK 
        AND ip2.__HEVO__MARKED_DELETED = 'FALSE'
        AND ip2.STANDARD_QUANTITY_UOM_ID = 'PACK'
    CROSS JOIN (
        SELECT ORGANIZATION_ID 
        FROM ge_poc.bronze.default_organization_org_organization 
        WHERE __HEVO__MARKED_DELETED = 'FALSE'
        AND ORGANIZATION_ID IN ('D0044')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) fac
    WHERE itm.__HEVO__MARKED_DELETED = 'FALSE'
    AND itm.PROFILE_ID IN ('D0044')
    AND NVL(itm.STYLE_SUFFIX, '1') != '99'
    AND itm.profile_id = fac.organization_id
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;

CREATE OR REPLACE VIEW okp_item_snapshot_v_d0044 AS
SELECT 
    ite.profile_id,
    dci.facility_id,
    ite.ext_gegl_dcxx_virtual_whse AS whse,
    ite.ext_gegl_dcxx_virtual_whse AS co,
    ite.item_id AS item,
    coalesce(ite.description, ' ') AS item_description,
    ite.ext_gegl_product_size AS item_size,
    nvl(ite.lpn_per_tier, 0) AS lpn_per_tier,
    MIN(SUBSTRING(lia.location_id, 1, 7)) AS locn_brcd,
    ip.weight AS unit_wt,
    ip.volume AS unit_vol,
    ite.tiers_per_pallet AS lpn_per_plt,
    SUM(NVL(dci.on_hand, 0)) AS boh_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'LOCATION' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS pick_locn_qty,
    SUM(CASE WHEN dci.inventory_container_type_id = 'ILPN' THEN nvl(dci.on_hand, 0) ELSE 0 END) AS ilpn_qty,
    SUM(NVL(dci.allocated, 0)) AS inv_alloc_inv,
    0 AS inv_qty_in_tran,
    greatest(nvl(ite.unit_cost, 0.0000), 0.0000) AS inv_unit_cost,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS inv_not_alloc_qty,
    greatest(nvl(ite.catch_weight_item, '0'), '0') AS inv_catch_wt,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS inv_qty_to_be_alloc,
    ite.pk AS sku_id,
    greatest(nvl(ite.average_weight, 0.0000), 0.0000) AS item_avg_wt,
    0.0000 AS po_order_quantity,
    greatest(nvl(ite.unit_price, 0.0000), 0.0000) AS item_unit_price,
    CASE WHEN SUM(dci.on_hand) > 0 THEN '1' ELSE 'N' END AS has_inv
FROM ge_poc.bronze.default_item_master_ite_item ite
JOIN ge_poc.bronze.default_item_master_ite_item_package ip
    ON ite.pk = ip.item_pk AND ip.standard_quantity_uom_id = 'UNIT' AND ip.quantity = 1
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON ite.item_id = dci.item_id AND dci.org_id IN ('D0044')
    AND dci.__hevo__marked_deleted = 'FALSE' AND dci.is_in_transit = '0'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location_item_assignment lia
    ON dci.item_id = lia.item_id AND lia.facility_id IN ('D0044')
WHERE ite.profile_id IN ('D0044')
    AND ite.__hevo__marked_deleted = 'FALSE'
    AND nvl(ite.style_suffix, '01') != '99'
GROUP BY ite.profile_id, dci.facility_id, ite.ext_gegl_dcxx_virtual_whse,
         ite.item_id, ite.description, ite.ext_gegl_product_size, ite.lpn_per_tier,
         ip.weight, ip.volume, ite.tiers_per_pallet, ite.unit_cost, ite.catch_weight_item,
         ite.pk, ite.average_weight, ite.unit_price;

CREATE OR REPLACE VIEW okp_qroo_v_d0044 (
  PROFILE_ID,
  EXT_GEGLDCXXVIRTUALWHSE,
  STYLE_SUFFIX,
  ITEM_ID,
  INVENTORY_FACILITY,
  ON_HAND,
  QTY_IN_OUTSIDE_STG,
  QTY_ON_HOLD,
  QTY_RECEIVED,
  QTY_ADJUSTMENTS,
  QTY_SELECTED,
  QTY_OVERSHIP,
  QTY_SCRATCH_ADJ,
  QTY_SCRATCH_NO_ADJ,
  WHSE_QTY_SELECTED,
  IN_TRANSIT_IN,
  IN_TRANSIT_OUT,
  QTY_ON_PURCHASE_ORDER,
  EXT_GEGL_DEPARTMENT,
  UNIT_PRICE,
  UNIT_COST,
  AVERAGE_WEIGHT,
  LOCKED_INV_QTY,
  HAS_INV)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS EXT_GEGLDCXXVIRTUALWHSE,
    itm.STYLE_SUFFIX,
    itm.ITEM_ID,
    NVL(fx.inventory_facility, itm.profile_id) AS INVENTORY_FACILITY,
    CASE WHEN (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0)) < 0
         THEN 0 ELSE (NVL(fx.sum_on_hand, 0) - NVL(inv_locked.locked_qty, 0))
    END AS ON_HAND,
    NVL(fx.outside_stg, 0) AS QTY_IN_OUTSIDE_STG,
    NVL(inv_locked.locked_qty, 0) AS QTY_ON_HOLD,
    NVL(pix_recv.qty_received, 0) AS QTY_RECEIVED,
    NVL(pix_adj.qty_adjustments, 0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_IN,
    NVL(recv_in.sum_shipped_quantity, 0) AS IN_TRANSIT_OUT,
    NVL(po_qty.sum_order_quantity, 0) AS QTY_ON_PURCHASE_ORDER,
    itm.EXT_GEGL_DEPARTMENT,
    GREATEST(NVL(itm.unit_price, 0.0000), 0.0000) AS UNIT_PRICE,
    GREATEST(NVL(itm.unit_cost, 0.0000), 0.0000) AS UNIT_COST,
    GREATEST(NVL(itm.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
    NVL(inv_locked.locked_qty, 0) AS LOCKED_INV_QTY,
    CASE WHEN fx.inventory_facility IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.standard_quantity_uom_id = 'UNIT' AND pkg.quantity = 1
    AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v fx
    ON fx.item_id = itm.item_id AND fx.profile_id = itm.profile_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(quantity,0)) AS qty_received
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Receipt'
    GROUP BY org_id, item_id
) pix_recv ON pix_recv.facility_id = fx.inventory_facility AND pix_recv.item_id = itm.item_id
LEFT JOIN (
    SELECT org_id AS facility_id, item_id,
           SUM(CASE WHEN adjusted_type = 'ADD' THEN NVL(quantity,0)
                    WHEN adjusted_type = 'SUBTRACT' THEN (-1*NVL(quantity,0))
                    ELSE 0 END) AS qty_adjustments
    FROM ge_poc.bronze.default_pix_pix_pix_entry
    WHERE __hevo__marked_deleted = 'FALSE' AND grouping_tag = 'Inventory_Adjustment'
    GROUP BY org_id, item_id
) pix_adj ON pix_adj.item_id = itm.item_id AND pix_adj.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT org_id AS facility_id, item_id, SUM(NVL(ordered_quantity,0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY org_id, item_id
) recv_in ON recv_in.item_id = itm.item_id AND recv_in.facility_id = fx.inventory_facility
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity,0)) AS sum_order_quantity
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_qty ON po_qty.item_id = itm.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand,0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE' AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) inv_locked ON inv_locked.item_id = itm.item_id AND inv_locked.facility_id = fx.inventory_facility
WHERE itm.__hevo__marked_deleted = 'FALSE'
  AND itm.profile_id IN ('D0044')
  AND NVL(itm.style_suffix, '1') != '99'
;


CREATE OR REPLACE VIEW item_first_rcpt AS
SELECT '270140' as ITEM_ID, '1997-01-07'::DATE AS FIRST_RCPT_DATE;

CREATE OR REPLACE VIEW pse_case_v (
  CASE_NBR,
  FRM_WHSE_NBR,
  TO_WHSE_NBR,
  ASN_SHPMT_NBR,
  PO_NBR,
  WHSE_TRANSFER_NBR,
  STYLE,
  SKU_ID,
  SKU_DESC,
  ASSORT_NBR,
  CASE_QUANTITY,
  PACKAGE_TYPE,
  CURR_LOCN_ID,
  LOCN_ID,
  PREV_LOCN_ID,
  DEST_LOCN_ID,
  RECV_LOCN_ID,
  PICK_LOCN_ID,
  CH_STAT_CODE,
  RECV_DATE_TIME,
  TRANSFER_DATE_TIME,
  ACCEPTED_DATE_TIME,
  STAT_CODE,
  MOD_DATE_TIME,
  CREATE_DATE_TIME,
  USER_ID)
AS SELECT
    lpnh.ilpn_id AS CASE_NBR,
    '80' AS FRM_WHSE_NBR,
    CASE
        WHEN lpnh.current_location_id NOT IN ('HRXTDZ0180R', 'HRXTSZ01') THEN '70'
        WHEN lpnh.current_location_id IN ('HRXTDZ0180R', 'HRXTSZ01') THEN ' '
        ELSE '70'
    END AS TO_WHSE_NBR,
    lpnh.asn_id AS ASN_SHPMT_NBR,
    lpnh.purchase_order_id AS PO_NBR,
    lpnh.asn_id AS WHSE_TRANSFER_NBR,
    ite.item_id AS STYLE,
    CAST(NULL AS STRING) AS SKU_ID,
    SUBSTR(ite.description, 1, 40) AS SKU_DESC,
    CAST(NULL AS STRING) AS ASSORT_NBR,
    NVL(dci.on_hand, 0) AS CASE_QUANTITY,
    CAST(NULL AS STRING) AS PACKAGE_TYPE,
    lpnh.current_location_id AS CURR_LOCN_ID,
    CAST(NULL AS STRING) AS LOCN_ID,
    lpnh.previous_location_id AS PREV_LOCN_ID,
    lpnh.destination_location_id AS DEST_LOCN_ID,
    CAST(NULL AS STRING) AS RECV_LOCN_ID,
    CAST(NULL AS STRING) AS PICK_LOCN_ID,
    SUBSTR(CAST(lpnh.status AS STRING), 1, 2) AS CH_STAT_CODE,
    lpnh.created_timestamp AS RECV_DATE_TIME,
    CAST(NULL AS TIMESTAMP) AS TRANSFER_DATE_TIME,
    CAST(NULL AS TIMESTAMP) AS ACCEPTED_DATE_TIME,
    '00' AS STAT_CODE,
    lpnh.updated_timestamp AS MOD_DATE_TIME,
    lpnh.created_timestamp AS CREATE_DATE_TIME,
    SUBSTR(lpnh.updated_by, 1, 15) AS USER_ID
FROM ge_poc.bronze.default_dcinventory_dci_ilpn lpnh
INNER JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON dci.ilpn_id = lpnh.ilpn_id
    AND dci.__hevo__marked_deleted = 'FALSE'
INNER JOIN ge_poc.bronze.default_item_master_ite_item ite
    ON dci.item_id = ite.item_id
    AND ite.profile_id = 'D0080'
    AND ite.__hevo__marked_deleted = 'FALSE'
WHERE lpnh.__hevo__marked_deleted = 'FALSE'
  AND lpnh.status < '9000'
;


CREATE OR REPLACE VIEW sis_v (
  PROFILE_ID,
  WHSE,
  CO,
  ITEM,
  ITEM_DESCRIPTION,
  SPL_INSTR_2,
  LPN_PER_TIER,
  LOCN_BRCD,
  UNIT_WT,
  UNIT_VOL,
  LPN_PER_PLT,
  BOH_QTY,
  PICK_LOCN_QTY,
  ILPN_QTY,
  INV_ALLOC_INV,
  INV_QTY_IN_TRAN,
  INV_UNIT_PRICE,
  INV_NOT_ALLOC_QTY,
  INV_CATCH_WT,
  INV_QTY_TO_BE_ALLOC,
  SKU_ID,
  ITEM_AVG_WT,
  ITEM_UNIT_PRICE)
AS SELECT
    itm.profile_id AS PROFILE_ID,
    itm.ext_gegl_dcxx_virtual_whse AS WHSE,
    itm.ext_gegl_dcxx_virtual_whse AS CO,
    itm.item_id AS ITEM,
    itm.short_description AS ITEM_DESCRIPTION,
    ' ' AS SPL_INSTR_2,
    itm.lpn_per_tier AS LPN_PER_TIER,
    MIN(loc.location_barcode) AS LOCN_BRCD,
    pkg.weight AS UNIT_WT,
    pkg.volume AS UNIT_VOL,
    itm.tiers_per_pallet AS LPN_PER_PLT,
    SUM(NVL(dci.on_hand, 0)) AS BOH_QTY,
    inv0.sum_on_hand AS PICK_LOCN_QTY,
    inv1.sum_on_hand AS ILPN_QTY,
    SUM(NVL(dci.allocated, 0)) AS INV_ALLOC_INV,
    rec0.sum_shipped_quantity AS INV_QTY_IN_TRAN,
    itm.unit_price AS INV_UNIT_PRICE,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) AS INV_NOT_ALLOC_QTY,
    CAST(NULL AS STRING) AS INV_CATCH_WT,
    SUM(NVL(dci.on_hand, 0)) - SUM(NVL(dci.allocated, 0)) + SUM(NVL(dci.to_be_filled, 0)) AS INV_QTY_TO_BE_ALLOC,
    itm.pk AS SKU_ID,
    itm.average_weight AS ITEM_AVG_WT,
    itm.unit_price AS ITEM_UNIT_PRICE
FROM ge_poc.bronze.default_item_master_ite_item itm
JOIN ge_poc.bronze.default_item_master_ite_item_package pkg
    ON itm.pk = pkg.item_pk AND pkg.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_inventory dci
    ON itm.item_id = dci.item_id AND dci.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.bronze.default_dcinventory_dci_location loc
    ON dci.location_id = loc.location_id AND loc.__hevo__marked_deleted = 'FALSE'
LEFT JOIN (
    SELECT item_id, SUM(on_hand) AS sum_on_hand
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE inventory_container_type_id != 'ILPN' AND __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) inv0 ON itm.item_id = inv0.item_id
LEFT JOIN (
    SELECT item_id, SUM(on_hand) AS sum_on_hand
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE inventory_container_type_id = 'ILPN' AND __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) inv1 ON itm.item_id = inv1.item_id
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity, 0)) AS sum_shipped_quantity
    FROM ge_poc.bronze.default_receiving_rcv_asn_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) rec0 ON rec0.item_id = itm.item_id
WHERE itm.__hevo__marked_deleted = 'FALSE'
GROUP BY itm.profile_id, itm.ext_gegl_dcxx_virtual_whse, itm.item_id,
         itm.short_description, itm.lpn_per_tier, pkg.weight, pkg.volume,
         itm.tiers_per_pallet, itm.unit_price, itm.pk,
         itm.average_weight, inv0.sum_on_hand, inv1.sum_on_hand, rec0.sum_shipped_quantity
;


CREATE OR REPLACE VIEW time_diff (
  COMPONENT,
  TIME_DIFF)
AS SELECT 'DCI' AS COMPONENT,
       DATEDIFF(MINUTE, MAX(CONVERT_TIMEZONE('UTC', 'America/New_York', updated_timestamp)),
                CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp())) AS TIME_DIFF
FROM ge_poc.bronze.default_dcinventory_dci_inventory
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'PIX' AS COMPONENT,
       DATEDIFF(MINUTE, MAX(CONVERT_TIMEZONE('UTC', 'America/New_York', updated_timestamp)),
                CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp())) AS TIME_DIFF
FROM ge_poc.bronze.default_pix_pix_pix_entry
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'TSK' AS COMPONENT,
       DATEDIFF(MINUTE, MAX(CONVERT_TIMEZONE('UTC', 'America/New_York', updated_timestamp)),
                CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp())) AS TIME_DIFF
FROM ge_poc.bronze.default_task_tsk_task
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'ORD' AS COMPONENT,
       DATEDIFF(MINUTE, MAX(CONVERT_TIMEZONE('UTC', 'America/New_York', updated_timestamp)),
                CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp())) AS TIME_DIFF
FROM ge_poc.bronze.default_dcorder_dco_order
WHERE __hevo__marked_deleted = 'FALSE'
UNION ALL
SELECT 'OLPN' AS COMPONENT,
       DATEDIFF(MINUTE, MAX(CONVERT_TIMEZONE('UTC', 'America/New_York', updated_timestamp)),
                CONVERT_TIMEZONE('UTC', 'America/New_York', current_timestamp())) AS TIME_DIFF
FROM ge_poc.bronze.default_pickpack_ppk_olpn
WHERE __hevo__marked_deleted = 'FALSE'
;


CREATE OR REPLACE VIEW v_gesc_closed_loads AS
SELECT
im.profile_id,
substr(pd.order_id, 3, 6) AS order_id,
substr(pd.order_id, 9, 3) AS order_seg_id,
ch.facility_id AS whse_id,
im.item_id AS item_id,
SUM(nvl(cd.packed_quantity,0)) AS ship_qty
FROM
ge_poc.bronze.default_pickpack_ppk_olpn ch,
ge_poc.bronze.default_pickpack_ppk_olpn_detail cd,
ge_poc.bronze.default_dcorder_dco_order_line pd,
ge_poc.bronze.default_item_master_ite_item im
WHERE
ch.olpn_id = cd.olpn_id
AND cd.order_id = pd.order_id
AND cd.order_line_id = pd.order_line_id
AND cd.item_id = im.item_id
AND cd.item_id = pd.item_id
AND ch.status = 8000
AND cd.status < 9000
AND ch.updated_timestamp >= current_date()
GROUP BY
im.profile_id,
substr(pd.order_id, 3, 6),
substr(pd.order_id, 9, 3),
ch.facility_id,
im.item_id;

CREATE OR REPLACE VIEW v_gesc_wm_inventory (
  PROFILE_ID,
  ASIWHSE,
  AIMSTYLE,
  AIMSTYLESFX,
  ASIQTYONHAND,
  BPDUNITSORDERED,
  CSUMACTLQTY,
  BOH,
  DPDUNITSORDERED)
AS SELECT
    im.profile_id AS PROFILE_ID,
    NVL(di_agg.facility_id, im.profile_id) AS ASIWHSE,
    im.item_id AS AIMSTYLE,
    SUBSTR(im.ext_gegl_dcxx_virtual_whse, 6, 2) AS AIMSTYLESFX,
    NVL(di_agg.sum_on_hand, 0) AS ASIQTYONHAND,
    NVL(po_agg.pending_qty, 0) AS BPDUNITSORDERED,
    NVL(locked_agg.locked_qty, 0) AS CSUMACTLQTY,
    NVL(di_agg.sum_on_hand, 0) + NVL(po_agg.pending_qty, 0) - NVL(locked_agg.locked_qty, 0) AS BOH,
    NVL(po_all.all_pending_qty, 0) AS DPDUNITSORDERED
FROM ge_poc.bronze.default_item_master_ite_item im
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand, 0)) AS sum_on_hand
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE'
      AND is_in_transit = '0'
      AND inventory_container_type_id != 'OLPN'
    GROUP BY facility_id, item_id
) di_agg ON im.item_id = di_agg.item_id AND im.profile_id = di_agg.facility_id
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity, 0)) AS pending_qty
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_agg ON im.item_id = po_agg.item_id
LEFT JOIN (
    SELECT facility_id, item_id, SUM(NVL(on_hand, 0)) AS locked_qty
    FROM ge_poc.bronze.default_dcinventory_dci_inventory
    WHERE __hevo__marked_deleted = 'FALSE'
      AND inventory_container_type_id = 'ILPN'
    GROUP BY facility_id, item_id
) locked_agg ON im.item_id = locked_agg.item_id AND im.profile_id = locked_agg.facility_id
LEFT JOIN (
    SELECT item_id, SUM(NVL(ordered_quantity, 0)) AS all_pending_qty
    FROM ge_poc.bronze.default_receiving_rcv_purchase_order_line
    WHERE __hevo__marked_deleted = 'FALSE'
    GROUP BY item_id
) po_all ON im.item_id = po_all.item_id
WHERE im.__hevo__marked_deleted = 'FALSE'
  AND im.profile_id != 'GEGL-SC-L1-PROFILE'
  AND NVL(im.style_suffix, '0') != '99'
;


CREATE OR REPLACE VIEW v_load_sheets (
  SHIPMENT_ID,
  PICKUP_START_DTTM,
  CARRIER_CODE_NAME,
  PROTECTION_LEVEL,
  PALLETS_ON_SHIPMENT,
  FACILITY_NAME,
  STORE_NBR,
  STOP_FACILITY_ALIAS_ID,
  PRODUCT_CLASS,
  STOP_SEQ,
  PLANNED_VOLUME,
  ORDER_QTY,
  PALLETS,
  NOTE,
  OTHER_SHIPMENTS_FOR_STORE,
  ORIGIN_FACILITY_ID,
  PLANNING_STATUS_ID,
  LOADING_SEQUENCE,
  SQ,
  NEWPC,
  FACILITY_ID)
AS SELECT
    sh.shipment_id AS SHIPMENT_ID,
    CONVERT_TIMEZONE('UTC', 'America/New_York', sh.origin_planned_arr_start_dttm) AS PICKUP_START_DTTM,
    car.description AS CARRIER_CODE_NAME,
    sh.climate_control_id AS PROTECTION_LEVEL,
    sh.planned_size1_value AS PALLETS_ON_SHIPMENT,
    fac.facility_name AS FACILITY_NAME,
    tord.destination_facility_id AS STORE_NBR,
    s.facility_id AS STOP_FACILITY_ALIAS_ID,
    CAST(NULL AS STRING) AS PRODUCT_CLASS,
    s.stop_sequence AS STOP_SEQ,
    CAST(NULL AS DECIMAL(18,4)) AS PLANNED_VOLUME,
    CAST(NULL AS DECIMAL(18,4)) AS ORDER_QTY,
    tord.planned_size1_value AS PALLETS,
    CAST(NULL AS STRING) AS NOTE,
    0 AS OTHER_SHIPMENTS_FOR_STORE,
    tord.origin_facility_id AS ORIGIN_FACILITY_ID,
    CAST(NULL AS STRING) AS PLANNING_STATUS_ID,
    CAST(NULL AS STRING) AS LOADING_SEQUENCE,
    CAST(NULL AS STRING) AS SQ,
    CAST(NULL AS STRING) AS NEWPC,
    tord.origin_facility_id AS FACILITY_ID
FROM ge_poc.bronze.default_shipment_shp_shipment sh
JOIN ge_poc.bronze.default_shipment_transport_order_movement sm
    ON sm.shipment_id = sh.shipment_id AND sh.org_id = sm.org_id
    AND sh.__hevo__marked_deleted = 'FALSE' AND sm.__hevo__marked_deleted = 'FALSE'
JOIN ge_poc.bronze.default_routing_rtg_transportation_order tord
    ON sm.transportation_order_id = tord.transportation_order_id AND sm.org_id = tord.org_id
    AND tord.__hevo__marked_deleted = 'FALSE'
JOIN ge_poc.bronze.default_shipment_shp_stop s
    ON s.shipment_pk = sh.pk AND s.org_id = sh.org_id
    AND s.stop_id = sm.delivery_stop_id AND s.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.bronze.default_carrier_car_carrier car
    ON sh.assigned_carrier_id = car.carrier_id AND car.__hevo__marked_deleted = 'FALSE'
LEFT JOIN ge_poc.bronze.default_facility_fac_facility fac
    ON tord.destination_facility_id = fac.facility_id AND fac.__hevo__marked_deleted = 'FALSE'
WHERE s.stop_sequence > 1
;
