-- =====================================================================
-- Giant Eagle POC: 03_gold_lift_shift_all_views.sql
-- VERSION A: 1:1 lift-and-shift port of ALL 51 Snowflake views to Delta views.
-- Dialect-translated from the original Snowflake DDLs Aquila shared.
-- Translations applied: schema refs, timezone fns, sysdate, DUAL removal.
-- Hand-review the views flagged with -- WARNING: comments.
-- =====================================================================

USE CATALOG ge_poc;
USE SCHEMA gold_lift_shift;

-- =====================================================================
-- CCS (shared)  (4 views)
-- =====================================================================

-- ---- CCS_INV_COMPARE_V ----
CREATE OR REPLACE VIEW ccs_inv_compare_v AS
select main_dc.facility_id as inventory_facility,
                main_dc.item_id,
                CASE WHEN main_dc.sum_on_hand  out_stg.facility_id
                group by main_dc.facility_id,
                main_dc.item_id,
                main_dc.sum_on_hand,
                main_dc.sum_allocated,
                main_dc.profile_id;


-- ---- CCS_IROO_V ----
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
NVL(SKU_W_INV.LOCATION_BARCODE, ALL_SKU.LOCATION_BARCODE) AS LOCATION_BARCODE,
ALL_SKU.UNITVOLUME,
ALL_SKU.PACKVOLUME,
CASE WHEN SKU_W_INV.ITEMID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(
    SELECT 
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IS NOT NULL
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = false
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK 
        AND IP1.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
        AND ORGANIZATION_ID LIKE 'D003%'
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
     AND ITM.PROFILE_ID LIKE 'D003%'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- CCS_ITEM_SNAPSHOT_V ----
CREATE OR REPLACE VIEW ccs_item_snapshot_v AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,0) AS LPN_PER_TIER,
          --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          MIN(SUBSTRING(lia.LOCATION_ID, 1,7)) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.PROFILE_ID 
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.profile_id AND DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.org_id AND DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_LOCATION.STORAGE_UOM_ID = 'PACK'
LEFT OUTER JOIN DEFAULT_DCINVENTORY_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.location_id AND lia.ORG_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.org_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN (SELECT pod.org_id, pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID AND l.ORG_ID = pod.org_id)
           GROUP BY pod.ITEM_ID,pod.org_id) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AND POV0.org_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID 
    LEFT JOIN (SELECT org_id, ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID,org_id) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID AND inv0.org_id = DEFAULT_ITEM_MASTER_ITE_ITEM.profile_id
    LEFT JOIN (select org_id, dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          AND dci.org_id = dcx.org_id
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000 AND dcl.ORG_ID = dci.ORG_ID))
               group by dcx.item_id,org_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID = A0QTY.org_id
    LEFT JOIN (SELECT org_id, ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID, org_id) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID AND inv1.org_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID 
    LEFT JOIN (SELECT org_id, ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0 AND DEFAULT_RECEIVING_RCV_ASN.org_id = DEFAULT_RECEIVING_RCV_ASN_LINE.org_id) GROUP BY ITEM_ID, org_id) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AND REC0.org_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID 
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0031'
,'D0032'
,'D0033'
,'D0036'
,'D0037'
,'D0038'
)
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX,0) != '99'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.profile_id IN ('D0031'
,'D0032'
,'D0033'
,'D0036'
,'D0037'
,'D0038'
)
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,0),
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    nvl(ITM.LPN_PER_TIER,0) AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND itm.profile_id = pkg.PROFILE_ID AND pkg.__HEVO__MARKED_DELETED = 'FALSE'
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	--AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    	AND ORGANIZATION_ID IN ('D0031'
,'D0032'
,'D0033'
,'D0036'
,'D0037'
,'D0038'
)
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND fac.ORGANIZATION_ID = itm.profile_id
    AND nvl(itm.STYLE_SUFFIX,0) != '99'
    AND itm.profile_id IN ('D0031'
,'D0032'
,'D0033'
,'D0036'
,'D0037'
,'D0038'
)
) ALL_SKU
ON SKU_W_INV.profile_id = SKU_W_INV.FACILITY_ID
AND ALL_SKU.profile_id = ALL_SKU.FACILITY_ID
AND SKU_W_INV.profile_id = ALL_SKU.profile_id
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID
AND SKU_W_INV.profile_id = ALL_SKU.FACILITY_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM;


-- ---- CCS_QROO_V ----
CREATE OR REPLACE VIEW ccs_qroo_v AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN /*
                    (SELECT FACILITY_ID
                    , ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV 
                    FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                    WHERE INVENTORY_CONTAINER_ID 
                    IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY */
                    (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id)  INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY            
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE' AND nvl(itm.STYLE_SUFFIX,'1') != '99'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
        AND ORGANIZATION_ID LIKE 'D003%'
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID LIKE 'D003%'
    AND nvl(itm.STYLE_SUFFIX,'1') != '99'
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- GE_CS (corporate)  (4 views)
-- =====================================================================

-- ---- GE_CS_ADJUSTMENT_REASON_V ----
CREATE OR REPLACE VIEW ge_cs_adjustment_reason_v AS
SELECT
    d.reason_code_id AS adjustment_reason_code,
    d.description    AS adjustment_reason_description
FROM
    default_inventory_management_inm_adjustment_reason_code d
WHERE
    d.profile_id = 'D0080';


-- ---- GE_CS_CYCL_CNT_ADJMT_DTLV ----
CREATE OR REPLACE VIEW ge_cs_cycl_cnt_adjmt_dtlv AS
SELECT Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)
       warehouse_id,
       Substring(px.org_id, 4, 2)
       facility,
       To_char(gcic.inventory_date, 'MM/DD/YYYY hh:mi:ss')               AS
       inventory_date,
       px.item_id,
       Substr(px.item_description, 1, 40)                                AS
       item_description,
       px.item_id
       || Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)                AS
       item_ndc,
       CASE ite.display_uom_id
         WHEN 'PACK' THEN 'P'
         WHEN 'UNIT' THEN 'U'
         WHEN 'LPN' THEN 'L'
         ELSE 'U'
       END                                                               AS
       item_ndc_pack_size,
       px.reason_code_id                                                 AS
       adjustment_reason_code,
       CASE px.adjusted_type
         WHEN 'SUBTRACT' THEN px.quantity * -1
         ELSE px.quantity
       END
       adjustment_qty,
       from_utc_timestamp(px.created_timestamp, 'America/New_York')
       create_date_time,
       from_utc_timestamp(px.updated_timestamp, 'America/New_York')
       mod_date_time,
       Substring(px.created_by, 1, 15)                                   AS
       user_id,
       Substring(px.pix_entry_id
                 || ','
                 || px.inventory_attribute1, 1, 20)                      AS
       adjmt_dtl_id
FROM   default_pix_pix_pix_entry px,
       default_item_master_ite_item ite,
       ge_poc.bronze.ge_cs_invn_control gcic
WHERE  px.item_id = ite.item_id
       AND Substring(px.org_id, 4, 2) = Substring(ite.profile_id, 4, 2)
       AND px.org_id = 'D0080'
       AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
       AND px.reason_code_id IN( 'CC', 'DD', 'HB', 'RC',
                                 'SR', 'WM' )
       AND To_date(gcic.inventory_date) = CURRENT_DATE() - 1
       AND from_utc_timestamp(px.created_timestamp, 'America/New_York')
           BETWEEN
           gcic.analysis_start_date_time AND gcic.analysis_end_date_time;


-- ---- GE_CS_INVN_DLY_TOTAL_V ----
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
    default_item_master_ite_item ite    
    left outer JOIN default_dcinventory_dci_inventory dci ON ite.item_id = dci.item_id AND dci.org_id = ite.profile_id AND dci.is_in_transit = '0' AND dci.__hevo__marked_deleted = 'FALSE' AND dci.inventory_container_type_id IN ( 'ILPN', 'LOCATION', 'OLPN' )
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


-- ---- GE_CS_TRANSACTION_DTL_V ----
CREATE OR REPLACE VIEW ge_cs_transaction_dtl_v AS
SELECT Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)
       warehouse_id,
       Substring(ite.profile_id, 4, 2)
       facility,
       To_char(gcic.inventory_date, 'MM/DD/YYYY hh:mi:ss')               AS
       inventory_date,
       ite.item_id                                                       AS
       item_number,
       Substring(ite.description, 14)                                    AS
       item_description,
       ite.item_id
       || Substring(ite.ext_gegl_dcxx_virtual_whse, 6, 2)                AS
       item_ndc,
       ( CASE ite.display_uom_id
           WHEN 'PACK' THEN 'P'
           WHEN 'UNIT' THEN 'U'
           WHEN 'LPN' THEN 'L'
           ELSE 'U'
         END )                                                           AS
       item_ndc_package_size,
       ( CASE px.source_transaction_type
           WHEN 'SHIPCONFIRM' THEN 'SHIPMENT'
           WHEN 'RECEIVING' THEN 'RECEIVING'
         END )                                                           AS
       adjustment_reason_code,
       px.quantity                                                       AS
       adjustment_qty,
       from_utc_timestamp(px.created_timestamp, 'America/New_York') AS
       create_date,
       from_utc_timestamp(px.updated_timestamp, 'America/New_York') AS
       update_date,
       Substring(px.updated_by, 1, 15)                                   AS
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
       'PO_Nbr, PO_Line_Nbr'                                             AS
       identifying_link,
       NULL                                                              AS
       ADDITIONAL_INFO
FROM   ge_poc.bronze.ge_cs_invn_control gcic,
       default_pix_pix_pix_entry px
       INNER JOIN default_item_master_ite_item ite
               ON px.item_id = ite.item_id
WHERE  ite.__hevo__marked_deleted = 'FALSE'
       AND px.adjusted_type IN ( 'ADD', '' )
       AND px.source_transaction_type IN ( 'RECEIVING', 'SHIPCONFIRM' )
       AND Nvl(ite.style_suffix, '01') != '99'
       AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
       AND ite.profile_id = 'D0080'
       AND px.__hevo__marked_deleted = 'false'
       AND px.org_id = 'D0080'
       AND To_date(gcic.inventory_date) = CURRENT_DATE() - 1
       AND from_utc_timestamp(px.created_timestamp, 'America/New_York')
           BETWEEN
           gcic.analysis_start_date_time AND gcic.analysis_end_date_time;


-- =====================================================================
-- BICEPS (D0033+)  (14 views)
-- =====================================================================

-- ---- BICEPS_IROO_V ----
CREATE OR REPLACE VIEW biceps_iroo_v AS select default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = 'UNIT'
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id = 'D0033'
--AND default_item_master_ite_item.item_id = '917419'
group by default_item_master_ite_item.profile_id,
FACILITY_ID, 
default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,
default_item_master_ite_item.ext_gegl_dc33_virtual_whse,
default_item_master_ite_item.item_id,
default_item_master_ite_item.lpn_per_tier,
default_item_master_ite_item.tiers_per_pallet,
ip1.height,
ip1.weight,
ip1.length,
ip1.width,
ip2.height,
ip2.weight,
ip2.length,
ip2.width,
ip1.volume,
ip2.VOLUME;


-- ---- BICEPS_IROO_V_D0001 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0001','D0008')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '394349'
AND nvl(default_item_master_ite_item.STYLE_SUFFIX,'1') != '99'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0001','D0008')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id AND a.profile_id = b.org_id;


-- ---- BICEPS_IROO_V_D0044 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0044')
--AND default_item_master_ite_item.item_id = '005173'
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '000450'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0044')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ---- BICEPS_IROO_V_D0050 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0050')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '126509'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0050')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ---- BICEPS_IROO_V_D0061 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0061','D0069')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '000450'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id AND lia.org_id = locn.profile_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0061','D0069')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ---- BICEPS_IROO_V_D0070 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0070')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '126509'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0070')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ---- BICEPS_IROO_V_D0080 ----
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
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          CASE WHEN DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20' THEN 'DC20'||'-'||'20' ELSE DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE END as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
--AND default_item_master_ite_item.item_id = '034009'
AND default_item_master_ite_item.PRODUCT_CLASS != 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,1,1) ||'00'||substr(DEFAULT_ITEM_MASTER_ITE_ITEM.ext_gegl_dcxx_virtual_whse,6,2) FACILITY_ID,    
          'DC20'||'-'||'20' as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0021' as FACILITY_ID,    
          'DC20'||'-'||'21' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0022' FACILITY_ID,    
          'DC20'||'-'||'22' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0023' FACILITY_ID,    
          'DC20'||'-'||'23' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0024' FACILITY_ID,    
          'DC20'||'-'||'24' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0025' FACILITY_ID,    
          'DC20'||'-'||'25' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
UNION ALL 
select DISTINCT default_item_master_ite_item.profile_id as profile_id,    
          'D0026' FACILITY_ID,    
          'DC20'||'-'||'26' as EXT_GEGLDCXXVIRTUALWHSE,
          null as VIRTWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPNPERTIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as TIERPERPALLET,
          ip1.height as UNIT_HEIGHT,
          ip1.width as  UNIT_WIDTH,
ip1.length as UNIT_LENGTH,
ip1.weight as UNIT_WEIGHT,
ip2.height as PACK_HEIGHT,
ip2.width as  PACK_WIDTH,
ip2.length as PACK_LENGTH,
ip2.weight as PACK_WEIGHT,
--min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
ip1.volume as UNITVOLUME,
ip2.volume  as PACKVOLUME
from default_item_master_ite_item
join default_item_master_ite_item_package ip1 on default_item_master_ite_item.pk = ip1.item_pk
join default_item_master_ite_item_package ip2 on default_item_master_ite_item.pk = ip2.item_pk
left join default_dcinventory_dci_inventory on default_item_master_ite_item.item_id = default_dcinventory_dci_inventory.item_id AND default_dcinventory_dci_inventory.org_id = default_item_master_ite_item.profile_id AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
left join default_dcinventory_dci_location on default_dcinventory_dci_inventory.location_id = default_dcinventory_dci_location.location_id AND default_dcinventory_dci_inventory.org_id = default_dcinventory_dci_location.profile_id AND default_dcinventory_dci_location.__HEVO__MARKED_DELETED = 'FALSE'
--LEFT OUTER JOIN default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia ON lia.item_id = default_dcinventory_dci_inventory.item_id = lia.item_id AND lia.__HEVO__MARKED_DELETED = 'FALSE'
where ip1.standard_quantity_uom_id = default_item_master_ite_item.DISPLAY_UOM_ID 
and ip2.standard_quantity_uom_id = 'PACK'
and ip1.__HEVO__MARKED_DELETED = 'FALSE'
and ip2.__HEVO__MARKED_DELETED = 'FALSE'
AND default_item_master_ite_item.__HEVO__MARKED_DELETED = 'FALSE'
and ip1.profile_id IN ('D0080')
--AND default_item_master_ite_item.DISPLAY_UOM_ID = 'UNIT'
----AND default_item_master_ite_item.item_id = '030129'
AND default_item_master_ite_item.PRODUCT_CLASS = 'CIGS'
)A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id AND lia.org_id = locn.profile_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0080')
GROUP BY lia.org_id
, lia.item_id)b ON a.item_id = b.item_id;


-- ---- BICEPS_QROO_V ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id != 'GEGL-SC-L1-PROFILE'
AND nvl(itm.STYLE_SUFFIX,'1') != '99'
--AND itm.item_id IN ('250749')
AND itm.profile_id LIKE 'D003%'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0033
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0033') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
        left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
        left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
        left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
        left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
        left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0033'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0033'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0038'
                 -- and itm.item_id in  ('930919')
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                    nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0001 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0001 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0001','D0008')
AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
--AND itm.item_id = '383099'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0001
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0001') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0001'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0001'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0008'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0008'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0008'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0008'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                    nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0044 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0044 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0044')
AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0044
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0044') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0044'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0044'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0044'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0044'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                   -- nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0050 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0050 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0050')
AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0050
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0050') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0050'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0050'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0050'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0050'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                   -- nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0061 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0061 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0061','D0069')
AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0061
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0061') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0061'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0061'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0069'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0069'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0069'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0069'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                   -- nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0070 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0070 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0070')
AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
)a
left  join (
--- D0070
select 
itm.profile_id,
itm.ext_gegl_dcxx_virtual_whse as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0070') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)))a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0070'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0070'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0070'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0070'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                   -- nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- ---- BICEPS_QROO_V_D0080 ----
-- WARNING: contains decode() which is Snowflake-specific. Hand-translate to CASE WHEN.
CREATE OR REPLACE VIEW biceps_qroo_v_d0080 AS
select c.*
from (
--Item Master Records
select  distinct itm.profile_id, itm.item_id
from default_item_master_ite_item itm
where itm.profile_id IN ('D0080')
AND nvl(itm.STYLE_SUFFIX,'01') != '99'
--AND substr(itm.ext_gegl_dcxx_virtual_whse, 6, 7) != '99'
  and itm.__HEVO__MARKED_DELETED = 'FALSE'
  --AND itm.item_id = '036719'
 --AND itm.PRODUCT_CLASS != 'CIGS'
)a
left  join (
--- D0080 ---- no CIGS
select 
itm.profile_id,
CASE WHEN itm.ext_gegl_dcxx_virtual_whse = 'DC80-20' THEN 'DC20-20' ELSE itm.ext_gegl_dcxx_virtual_whse END as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
NVL(fx.inventory_facility,'D0080') inventory_facility,--source warehouse for inventory comparison-- 
case when (nvl(fx.sum_on_hand ,0) - nvl(inv1.sum_locked_inv,0))  0
  --AND di.IS_IN_TRANSIT = '0'
  and di.item_id IN (select DISTINCT td.item_id
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'PICK/PACK')
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)) 
                 )a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0080'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0080'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0)  0
  --AND di.IS_IN_TRANSIT = '0'
  and di.item_id IN (select DISTINCT td.item_id
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'PICK/PACK') 
  and not  exists (select (1)
from  default_pickpack_TSK_task_detail td
where td.__hevo__marked_deleted = 'FALSE'
                  and  td.source_container_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)
                  and td.item_id = di.item_id
                and td.facility_id = di.org_id
                  and td.type_id = 'REPLENISHMENT')
 -- and decode(di.inventory_container_type_id,'ILPN','1','LOCATION','1','OLPN','2') = '1' -- type = ilpn & location only
 and not exists (select (1) from default_pickpack_ppk_olpn olpn 
where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE'
and  olpn.olpn_id = ( case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end) and olpn.org_id = di.org_id)
  and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE'
                 and ilpn.ilpn_id = (case when di.INVENTORY_CONTAINER_ID = di.location_id then NULL else di.INVENTORY_CONTAINER_ID end)) 
                 )a
  GROUP BY a.org_id,A.ITEM_ID)unselected on unselected.item_id = itm.item_id and unselected.org_id = fx.inventory_facility 
left join (select facility_id, item_id, sum(nvl(quantity,0)) as sum_received_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'Receipt' group by facility_id, item_id ) pix0 on pix0.facility_id = fx.inventory_facility and pix0.item_id = itm.item_id
left join (select facility_id, item_id, sum(case when adjusted_type = 'ADD' then nvl(quantity,0) when adjusted_type = 'SUBTRACT' then (-1*nvl(quantity,0)) else 0 end) as sum_adjustment_quantity from default_pix_pix_pix_entry where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and grouping_tag = 'InventoryAdjustment' group by facility_id, item_id) pix1 on pix1.item_id = itm.item_id and pix1.facility_id = fx.inventory_facility
left join (select facility_id, item_id, sum(nvl(shipped_quantity,0)) as sum_shipped_quantity from default_receiving_rcv_asn_line where default_receiving_rcv_asn_line.__HEVO__MARKED_DELETED = 'FALSE' and asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C') and asn_status = 1000 and canceled = 0) group by facility_id, item_id) rec0 on rec0.item_id = itm.item_id and rec0.facility_id = fx.inventory_facility
left join (SELECT facility_id, item_id, max(dci_sysdate) dci_sysdate FROM (
/*SELECT 'DCI' TRANSACTION_TYPE
, FACILITY_ID, item_id,
max((from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'))) as dci_sysdate 
           from default_dcinventory_dci_inventory 
                      WHERE default_dcinventory_dci_inventory.ORG_ID = 'D0080'
           AND default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE'
           GROUP BY facility_id, ITEM_ID
UNION all */
select 'PIX' TRANSACTION_TYPE 
, facility_id
, item_id
, max((from_utc_timestamp(created_timestamp, 'America/New_York'))) AS dci_sysdate 
from default_pix_pix_pix_entry 
where default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' 
AND org_id = 'D0080'
AND to_date(from_utc_timestamp(CREATED_TIMESTAMP, 'America/New_York')) >= to_date(current_timestamp())
AND SOURCE_EVENT_NAME NOT IN ('Order_Allocation'
,'CONDITION_CODE_CHANGES'
,'Order_Deallocation'
,'APPOINTMENT_CANCEL'
,'INVENTORY_DEALLOCATION'
,'APPOINTMENT_SCHEDULED'
,'Order_Status_Change'
,'APPOINTMENT_CHANGE'
,'CANCEL_ASN'
,'TRAILER_CHECKIN'
,'INVENTORY_ALLOCATION')
group by facility_id, item_id        
)
GROUP BY facility_id, item_id) pix2 on pix2.item_id = itm.item_id and pix2.facility_id = fx.inventory_facility        
left join (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0080'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) rec1 on rec1.item_id = itm.item_id and rec1.facility_id = itm.profile_id
        left join (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and UPPER(condition_code) in ('BH','QH','IC','DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) inv1 on inv1.item_id = itm.item_id and inv1.facility_id = fx.inventory_facility
                  where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND nvl(itm.PRODUCT_CLASS,'N') = 'CIGS'
                  --and itm.item_id = '494339'
                  group by itm.profile_id,
                    itm.ext_gegl_dcxx_virtual_whse,
                    itm.style_suffix,
                    itm.item_id,
                    itm.ext_gegl_department,
                    itm.unit_cost,
                    itm.max_lpn_quantity,
                    itm.Catch_Weight_Item,
                    itm.average_weight,
                    fx.inventory_facility, 
                    fx.sum_on_hand,
                    nvl(unselected.allocated,0),
                   -- nvl(tro.sum_shipped_quantity,0),
                    fx.sum_allocated,
                    pix0.sum_received_quantity,
                    pix1.sum_adjustment_quantity,
                    rec0.sum_shipped_quantity,
                    rec1.sum_order_quantity,
                    inv1.sum_locked_inv,
                    NVL(pix2.dci_sysdate,FX.dci_sysdate)
                    UNION ALL 
select 
itm.profile_id,
'DC20'||'-'||'21' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '038539')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
  UNION ALL
select 
itm.profile_id,
'DC20'||'-'||'22' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '038559')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
  UNION ALL 	
select 
itm.profile_id,
'DC20'||'-'||'23' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '035879')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
  UNION ALL
select 
itm.profile_id,
'DC20'||'-'||'24' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049159')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
  UNION ALL
select 
itm.profile_id,
'DC20'||'-'||'25' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049169')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
  UNION ALL
select 
itm.profile_id,
'DC20'||'-'||'26' as EXT_GEGLDCXXVIRTUALWHSE,
itm.STYLE_SUFFIX,
itm.ITEM_ID,     
'D0080' inventory_facility,--source warehouse for inventory comparison-- 
'0' as sum_on_hand, --on hand inventory at source warehouse--
--sum(nvl(f2.outside_stg,0)) outside_stg,
'0' as outside_stg,
'0' as quantity_received,
'0' as qty_adjustments,
'0' as qty_selected,
'0' as qty_overship,              
'0' as qty_scratch_adj,
'0' as qty_scratch_no_adj,
'0' whse_qty_selected,
'0' as in_transit_in,
--nvl(tro.sum_shipped_quantity,0) as in_transit_out,
'0' in_transit_out,
'0' as TRAN_TRANSIT_IN,
'0' as TRAN_TRANSIT_OUT,
'0' whse_qty_not_selected,
'0' as qty_on_purchase_order,
'0' as SHORT_CYCLE_ITEM,
substr(itm.EXT_GEGL_DEPARTMENT,1,2) EXT_GEGL_DEPARTMENT_2,
itm.unit_cost + i2.unit_cost unit_cost,
itm.max_lpn_quantity,
'0' AVG_WGT_DEC_4,
'0' AVG_WGT_DEC_3,
current_timestamp() dci_sysdate,
itm.EXT_GEGL_DEPARTMENT EXT_GEGL_DEPARTMENT_3,
'N' AS VARIABLE_WEIGHT_FLAG,
'0' as locked_inv_qty
from default_item_master_ite_item itm 
INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049209')i2 ON i2.profile_id = itm.profile_id
 where  itm.__HEVO__MARKED_DELETED = 'FALSE' 
  and itm.profile_id = 'D0080'
  AND itm.PRODUCT_CLASS = 'CIGS'
--and itm.item_id = '030129'
                    )c on a.item_id = c.item_id and a.profile_id = c.profile_id;


-- =====================================================================
-- HBC (D0080 pharmacy)  (6 views)
-- =====================================================================

-- ---- HBC_IROO_V_D0080 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID AND ip1.__HEVO__MARKED_DELETED = 'FALSE'--AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND ip2.__HEVO__MARKED_DELETED = 'FALSE' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX, 1) != 99
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '001149'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0080')
GROUP BY lia.org_id
, lia.item_id
)b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK AND ip1.__HEVO__MARKED_DELETED ='FALSE'
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1 
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK AND ip2.__HEVO__MARKED_DELETED ='FALSE'
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0080')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0080')
   AND nvl(itm.style_suffix,1) != 99
    AND itm.profile_id = fac.organization_id
   --and itm.item_id = '001149'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- HBC_ITEM_SNAPSHOT_V_D0080 ----
CREATE OR REPLACE VIEW hbc_item_snapshot_v_d0080 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
SKU_W_INV.WHSE,
SKU_W_INV.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(SKU_W_INV.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0080') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0080') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0080')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0080')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0080') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0080') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0080') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '000323'
    AND NVL(DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS,'N') != 'CIGS'
    AND NVL(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX,'01') != '99'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
    UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0080') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0080') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0080')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0080')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0080') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0080') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0080') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030429'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
    UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'21' AS WHSE,
          'DC80'||'-'||'21' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '038539')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    -----AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
          UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'22' AS WHSE,
          'DC80'||'-'||'22' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '038559')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    ---AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
          UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'23' AS WHSE,
          'DC80'||'-'||'23' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '035879')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    ---AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
          UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'24' AS WHSE,
          'DC80'||'-'||'24' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049159')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
--WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    ---AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
          UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'25' AS WHSE,
          'DC80'||'-'||'25' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049169')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
    --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    ---AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
          UNION ALL 
    SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID FACILITY_ID,
          'DC80'||'-'||'26' AS WHSE,
          'DC80'||'-'||'26' AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          '0' AS BOH_QTY,
          '0' AS PICK_LOCN_QTY,
          '0' AS ILPN_QTY,
          '0' AS INV_ALLOC_INV,
          '0' AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost AS INV_UNIT_COST,
          '0' AS INV_CATCH_WT,
          '0' AS INV_QTY_TO_BE_ALLOC,
          '0' AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          '0' AS ITEM_AVG_WT,
          '0' as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    INNER JOIN (SELECT * FROM DEFAULT_ITEM_MASTER_ITE_ITEM i2 WHERE i2."__HEVO__MARKED_DELETED" = 'FALSE'
AND i2.profile_id = 'D0080' AND i2.item_id = '049209')i2 ON i2.profile_id = DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0080') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0080')
   --WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0080')
    WHERE DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0080')
    ---AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '030129'
     AND DEFAULT_ITEM_MASTER_ITE_ITEM.PRODUCT_CLASS = 'CIGS'
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE = 'DC80-20'
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID ,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST + i2.unit_cost,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND PKG.__HEVO__MARKED_DELETED = 'FALSE' AND ITM.profile_id = PKG.PROFILE_ID 
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0080')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0080')
    AND nvl(itm.style_suffix,'N') != '99'
    --AND itm.item_id = '000323'
    --AND FAC.ORGANIZATION_ID = ITM.PROFILE_ID
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- HBC_PHARMACY_TRANSPORTION_OH_V ----
CREATE OR REPLACE VIEW hbc_pharmacy_transportion_oh_v AS
SELECT
facility_id,
facility_address_address1,
facility_address_address2,
facility_address_city,
facility_address_state,
facility_address_postalcode,
appl_code,
olpn_id,
ext_pharmacy_routeid,
ext_pharmacy_stop_id
from
(SELECT DISTINCT olpnd.facility_id,
                olpnd.facility_address_address1,
                olpnd.facility_address_address2,
                olpnd.facility_address_city,
                olpnd.facility_address_state,
                olpnd.facility_address_postalcode,
                olpnd.appl_code,
                olpnd.olpn_id,
                olpnd.ext_pharmacy_routeid,
                olpnd.ext_pharmacy_stop_id
FROM (SELECT olpnh.olpn_id,
      olpnd.item_id,
      olpnh.ext_pharmacy_routeid,
      olpnh.ext_pharmacy_stop_id,
      Substr(fac.facility_id,2,5) AS facility_id,
      fac.facility_address_address1,
      NULL AS facility_address_address2,
      fac.facility_address_city,
      fac.facility_address_state,
      fac.facility_address_postalcode,
      'WM' AS appl_code,
      olpnh.order_planning_run_id,
      Concat(Substr(order_planning_run_id, 7, 4), '-', Substr(order_planning_run_id, 3, 2), '-', Substr(order_planning_run_id, 5, 2)) run_date,
      To_date(from_utc_timestamp(olpnd.created_timestamp, 'America/New_York'))                                                           tcreated_timestamp
      FROM   default_pickpack_ppk_olpn_detail olpnd,
             default_pickpack_ppk_olpn olpnh,
             default_facility_fac_facility fac
      WHERE  olpnd.olpn_id = olpnh.olpn_id
      AND    fac.facility_id = olpnh.destination_facility_id
      AND    olpnh.__hevo__marked_deleted = 'false'
      AND    olpnd.__hevo__marked_deleted = 'false'
      AND    fac.__hevo__marked_deleted = 'false'
      AND    Concat(Substr(olpnh.order_planning_run_id, 7, 4), '-', Substr(olpnh.order_planning_run_id, 3, 2), '-', Substr(olpnh.order_planning_run_id, 5, 2)) = To_date(olpnh.created_timestamp)
      AND    olpnd.org_id = 'D0080'
      AND    olpnh.status IN ( '8000' )
      AND    olpnh.order_planning_run_id IS NOT NULL
      AND    olpnh.ext_pharmacy_routeid IS NOT NULL
      AND    olpnh.ext_pharmacy_stop_id IS NOT NULL
      AND    fac.JSON_STORE:"Fields"."extend::GEGLDistributionCenter" = '8165'
      AND    from_utc_timestamp(olpnd.created_timestamp, 'America/New_York') BETWEEN timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York')))-1,'YYYY-MM-DD HH:MI:SS'), to_time('08:00:00')) AND    timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York'))),'YYYY-MM-DD HH:MI:SS'), to_time('03:30:00')) ) olpnd
INNER JOIN(SELECT ite.item_id
             FROM default_item_master_ite_item ite
            WHERE ite.profile_id = 'D0080'
              AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
              AND ite.__HEVO__MARKED_DELETED = 'FALSE') item
ON olpnd.item_id = item.item_id)
UNION
(SELECT
Substr(fac.facility_id,2,5) AS facility_id,
fac.facility_address_address1,
NULL AS facility_address_address2,
fac.facility_address_city,
fac.facility_address_state,
fac.facility_address_postalcode,
'WM' AS appl_code,
olpnh.olpn_id,
olpnh.ext_pharmacy_routeid,
olpnh.ext_pharmacy_stop_id,
FROM default_pickpack_ppk_olpn olpnh,
     default_facility_fac_facility fac
WHERE  upper(fac.facility_id) = upper(olpnh.destination_facility_id)
AND    olpnh.org_id = 'D0080'
AND    olpnh.facility_id = 'D0080'
AND    fac.JSON_STORE:"Fields"."extend::GEGLDistributionCenter" = '8165'
AND    fac.__HEVO__MARKED_DELETED = 'FALSE'
AND    olpnh.__HEVO__MARKED_DELETED = 'FALSE'
AND    olpnh.container_type_id = 'MISC'
AND    olpnh.LPN_type = 'OLPN'
AND    olpnh.SHIPMENT_ID LIKE '80%'
AND    from_utc_timestamp(olpnh.created_timestamp, 'America/New_York')
BETWEEN timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York')))-1,'YYYY-MM-DD HH:MI:SS'), to_time('08:00:00'))
    AND timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York'))),'YYYY-MM-DD HH:MI:SS'), to_time('03:30:00')))
ORDER BY facility_id;


-- ---- HBC_PHARMACY_TRANSPORTION_PA_V ----
CREATE OR REPLACE VIEW hbc_pharmacy_transportion_pa_v AS
SELECT
facility_id,
facility_address_address1,
facility_address_address2,
facility_address_city,
facility_address_state,
facility_address_postalcode,
appl_code,
olpn_id,
ext_pharmacy_routeid,
ext_pharmacy_stop_id
from
(SELECT DISTINCT olpnd.facility_id,
                olpnd.facility_address_address1,
                olpnd.facility_address_address2,
                olpnd.facility_address_city,
                olpnd.facility_address_state,
                olpnd.facility_address_postalcode,
                olpnd.appl_code,
                olpnd.olpn_id,
                olpnd.ext_pharmacy_routeid,
                olpnd.ext_pharmacy_stop_id
FROM (SELECT olpnh.olpn_id,
      olpnd.item_id,
      olpnh.ext_pharmacy_routeid,
      olpnh.ext_pharmacy_stop_id,
      Substr(fac.facility_id,2,5) AS facility_id,
      fac.facility_address_address1,
      NULL AS facility_address_address2,
      fac.facility_address_city,
      fac.facility_address_state,
      fac.facility_address_postalcode,
      'WM' AS appl_code,
      olpnh.order_planning_run_id,
      Concat(Substr(order_planning_run_id, 7, 4), '-', Substr(order_planning_run_id, 3, 2), '-', Substr(order_planning_run_id, 5, 2)) run_date,
      To_date(from_utc_timestamp(olpnd.created_timestamp, 'America/New_York'))                                                           tcreated_timestamp
      FROM   default_pickpack_ppk_olpn_detail olpnd,
             default_pickpack_ppk_olpn olpnh,
             default_facility_fac_facility fac
      WHERE  olpnd.olpn_id = olpnh.olpn_id
      AND    fac.facility_id = olpnh.destination_facility_id
      AND    olpnh.__hevo__marked_deleted = 'false'
      AND    olpnd.__hevo__marked_deleted = 'false'
      AND    fac.__hevo__marked_deleted = 'false'
      AND    Concat(Substr(olpnh.order_planning_run_id, 7, 4), '-', Substr(olpnh.order_planning_run_id, 3, 2), '-', Substr(olpnh.order_planning_run_id, 5, 2)) = To_date(olpnh.created_timestamp)
      AND    olpnd.org_id = 'D0080'
      AND    olpnh.status IN ( '8000' )
      AND    olpnh.order_planning_run_id IS NOT NULL
      AND    olpnh.ext_pharmacy_routeid IS NOT NULL
      AND    olpnh.ext_pharmacy_stop_id IS NOT NULL
      AND    fac.JSON_STORE:"Fields"."extend::GEGLDistributionCenter" = '8164'
      AND    from_utc_timestamp(olpnd.created_timestamp, 'America/New_York') BETWEEN timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York')))-1,'YYYY-MM-DD HH:MI:SS'), to_time('08:00:00')) AND    timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York'))),'YYYY-MM-DD HH:MI:SS'), to_time('03:30:00')) ) olpnd
INNER JOIN(SELECT ite.item_id
             FROM default_item_master_ite_item ite
            WHERE ite.profile_id = 'D0080'
              AND ite.ext_gegl_dcxx_virtual_whse = 'DC80-85'
              AND ite.__HEVO__MARKED_DELETED = 'FALSE') item
ON olpnd.item_id = item.item_id)
UNION
(SELECT
Substr(fac.facility_id,2,5) AS facility_id,
fac.facility_address_address1,
NULL AS facility_address_address2,
fac.facility_address_city,
fac.facility_address_state,
fac.facility_address_postalcode,
'WM' AS appl_code,
olpnh.olpn_id,
olpnh.ext_pharmacy_routeid,
olpnh.ext_pharmacy_stop_id,
FROM default_pickpack_ppk_olpn olpnh,
     default_facility_fac_facility fac
WHERE  upper(fac.facility_id) = upper(olpnh.destination_facility_id)
AND    olpnh.org_id = 'D0080'
AND    olpnh.facility_id = 'D0080'
AND    fac.JSON_STORE:"Fields"."extend::GEGLDistributionCenter" = '8164'
AND    fac.__HEVO__MARKED_DELETED = 'FALSE'
AND    olpnh.__HEVO__MARKED_DELETED = 'FALSE'
AND    olpnh.container_type_id = 'MISC'
AND    olpnh.LPN_type = 'OLPN'
AND    olpnh.SHIPMENT_ID LIKE '80%'
AND    from_utc_timestamp(olpnh.created_timestamp, 'America/New_York')
BETWEEN timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York')))-1,'YYYY-MM-DD HH:MI:SS'), to_time('08:00:00'))
    AND timestamp_ntz_from_parts(to_char(to_date(from_utc_timestamp(sysdate(, 'America/New_York'))),'YYYY-MM-DD HH:MI:SS'), to_time('03:30:00')))
ORDER BY facility_id;


-- ---- HBC_QROO_V_D0080 ----
CREATE OR REPLACE VIEW hbc_qroo_v_d0080 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE INVENTORY_CONTAINER_ID IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0080')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0080')
    AND FAC.ORGANIZATION_ID = ITM.PROFILE_ID
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- ---- HBC_TASK_GROUP_DESC ----
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


-- =====================================================================
-- ASF (D0061 seafood)  (3 views)
-- =====================================================================

-- ---- ASF_IROO_V_D0061 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID AND ip1.__HEVO__MARKED_DELETED = 'FALSE'--AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND ip2.__HEVO__MARKED_DELETED = 'FALSE' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0061','D0069')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX, 1) != 99
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '001149'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0061','D0069')
GROUP BY lia.org_id
, lia.item_id
)b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK AND ip1.__HEVO__MARKED_DELETED ='FALSE'
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1 
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK AND ip2.__HEVO__MARKED_DELETED ='FALSE'
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0061','D0069')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0061','D0069')
   AND nvl(itm.style_suffix,1) != 99
    AND itm.profile_id = fac.organization_id
   --and itm.item_id = '001149'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- ASF_ITEM_SNAPSHOT_V_D0061 ----
CREATE OR REPLACE VIEW asf_item_snapshot_v_d0061 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0061','D0069') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0061','D0069')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0061','D0069') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0061','D0069') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0061','D0069')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0061','D0069')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0061','D0069') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0061','D0069') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0061','D0069') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0061','D0069')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0061','D0069')
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND PKG.__HEVO__MARKED_DELETED = 'FALSE' AND ITM.profile_id = PKG.PROFILE_ID 
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0061','D0069')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0061','D0069')
    --AND FAC.ORGANIZATION_ID = ITM.PROFILE_ID
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- ASF_QROO_V_D0061 ----
CREATE OR REPLACE VIEW asf_qroo_v_d0061 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE INVENTORY_CONTAINER_ID IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0061','D0069')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0061','D0069')
    AND FAC.ORGANIZATION_ID = ITM.PROFILE_ID
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- BRM (D0050 beverage)  (3 views)
-- =====================================================================

-- ---- BRM_IROO_V_D0050 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID AND ip1.__HEVO__MARKED_DELETED = 'FALSE'--AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND ip2.__HEVO__MARKED_DELETED = 'FALSE' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0050')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX, 1) != 99
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '001149'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0050')
GROUP BY lia.org_id
, lia.item_id
)b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK AND ip1.__HEVO__MARKED_DELETED ='FALSE'
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1 
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK AND ip2.__HEVO__MARKED_DELETED ='FALSE'
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0050')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0050')
   AND nvl(itm.style_suffix,1) != 99
    AND itm.profile_id = fac.organization_id
   --and itm.item_id = '001149'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- BRM_ITEM_SNAPSHOT_V_D0050 ----
CREATE OR REPLACE VIEW brm_item_snapshot_v_d0050 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0050') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0050')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0050') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0050') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0050')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0050')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0050') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0050') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0050') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0050')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0050')
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND pkg.__HEVO__MARKED_DELETED = 'FALSE'
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0050')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0050')
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- BRM_QROO_V_D0050 ----
CREATE OR REPLACE VIEW brm_qroo_v_d0050 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE INVENTORY_CONTAINER_ID IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0050')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0050')
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- FFM (D0070 fresh)  (3 views)
-- =====================================================================

-- ---- FFM_IROO_V_D0070 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID AND ip1.__HEVO__MARKED_DELETED = 'FALSE'--AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND ip2.__HEVO__MARKED_DELETED = 'FALSE' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0070')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX, 1) != 99
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '001149'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0070')
GROUP BY lia.org_id
, lia.item_id
)b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK AND ip1.__HEVO__MARKED_DELETED ='FALSE'
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1 
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK AND ip2.__HEVO__MARKED_DELETED ='FALSE'
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0070')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0070')
   AND nvl(itm.style_suffix,1) != 99
    AND itm.profile_id = fac.organization_id
   --and itm.item_id = '001149'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- FFM_ITEM_SNAPSHOT_V_D0070 ----
CREATE OR REPLACE VIEW ffm_item_snapshot_v_d0070 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0070') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0070')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0070') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0070') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0070')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0070')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0070') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0070') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0070') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0070')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0070')
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND pkg.__HEVO__MARKED_DELETED = 'FALSE'
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0070')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0070')
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- FFM_QROO_V_D0070 ----
CREATE OR REPLACE VIEW ffm_qroo_v_d0070 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE INVENTORY_CONTAINER_ID IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0070')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0070')
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- OKG (D0001 grocery)  (3 views)
-- =====================================================================

-- ---- OKG_IROO_V_D0001 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID --AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0001','D0008')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = FALSE
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '250739'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, locn.LOCATION_BARCODE 
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0001','D0008'))b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK 
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0001','D0008')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0001','D0008')
    AND itm.profile_id = fac.organization_id
    --AND itm.item_id = '662289'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- OKG_ITEM_SNAPSHOT_V_D0001 ----
CREATE OR REPLACE VIEW okg_item_snapshot_v_d0001 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0001','D0008') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0001','D0008')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0001','D0008') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0001','D0008') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0001','D0008')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0001','D0008')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0001','D0008') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0001','D0008') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0001','D0008') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0001','D0008')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0001','D0008')
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND pkg.__HEVO__MARKED_DELETED = 'FALSE'
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0001','D0008')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0001','D0008')
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- OKG_QROO_V_D0001 ----
CREATE OR REPLACE VIEW okg_qroo_v_d0001 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (select facility_id, item_id, sum(nvl(on_hand,0)) as sum_locked_inv from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0001','D0008')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0001','D0008')
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- OKP (D0044 produce)  (3 views)
-- =====================================================================

-- ---- OKP_IROO_V_D0044 ----
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
    SELECT * FROM (
    SELECT DISTINCT
    DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE AS VIRTWHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEMID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPNPERTIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS TIERPERPALLET,
    IP1.HEIGHT AS UNIT_HEIGHT,
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    --MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP1.ITEM_PK AND IP1.STANDARD_QUANTITY_UOM_ID = default_item_master_ite_item.DISPLAY_UOM_ID AND ip1.__HEVO__MARKED_DELETED = 'FALSE'--AND IP1.QUANTITY = 1
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = IP2.ITEM_PK AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' AND ip2.__HEVO__MARKED_DELETED = 'FALSE' --AND IP2.QUANTITY = 1
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0044')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND nvl(DEFAULT_ITEM_MASTER_ITE_ITEM.STYLE_SUFFIX, 1) != 99
    --AND DEFAULT_ITEM_MASTER_ITE_ITEM.item_id = '001149'
    /*GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DC33_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    IP1.HEIGHT,
    IP1.WEIGHT,
    IP1.LENGTH,
    IP1.WIDTH,
    IP2.HEIGHT,
    IP2.WEIGHT,
    IP2.LENGTH,
    IP2.WIDTH,
    IP1.VOLUME,
    IP2.VOLUME*/
    )A
LEFT OUTER JOIN (
SELECT 
lia.org_id
, lia.item_id
, max(locn.LOCATION_BARCODE) LOCATION_BARCODE
FROM default_dcinventory_DCI_LOCATION_ITEM_ASSIGNMENT lia
LEFT JOIN default_dcinventory_dci_location locn ON lia.location_id = locn.location_id and locn.__HEVO__MARKED_DELETED = 'FALSE'
WHERE lia.__HEVO__MARKED_DELETED = 'FALSE'
AND LOCN.STORAGE_UOM_ID IN ('PACK','UNIT')
AND lia.org_id IN ('D0044')
GROUP BY lia.org_id
, lia.item_id
)b ON a.itemid = b.item_id
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
    IP1.WIDTH AS  UNIT_WIDTH,
    IP1.LENGTH AS UNIT_LENGTH,
    IP1.WEIGHT AS UNIT_WEIGHT,
    IP2.HEIGHT AS PACK_HEIGHT,
    IP2.WIDTH AS  PACK_WIDTH,
    IP2.LENGTH AS PACK_LENGTH,
    IP2.WEIGHT AS PACK_WEIGHT,
    NULL AS LOCATION_BARCODE,
    IP1.VOLUME AS UNITVOLUME,
    IP2.VOLUME  AS PACKVOLUME
    FROM MAWM_ODM.DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP1 ON ITM.PK = IP1.ITEM_PK AND ip1.__HEVO__MARKED_DELETED ='FALSE'
        AND IP1.STANDARD_QUANTITY_UOM_ID = itm.DISPLAY_UOM_ID -- AND IP1.QUANTITY = 1 
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE IP2 ON ITM.PK = IP2.ITEM_PK AND ip2.__HEVO__MARKED_DELETED ='FALSE'
        AND IP2.STANDARD_QUANTITY_UOM_ID = 'PACK' --AND IP2.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0044')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0044')
   AND nvl(itm.style_suffix,1) != 99
    AND itm.profile_id = fac.organization_id
   --and itm.item_id = '001149'
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEMID = ALL_SKU.ITEMID
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- OKP_ITEM_SNAPSHOT_V_D0044 ----
CREATE OR REPLACE VIEW okp_item_snapshot_v_d0044 AS
SELECT
ALL_SKU.PROFILE_ID,
ALL_SKU.FACILITY_ID,
ALL_SKU.WHSE,
ALL_SKU.CO,
ALL_SKU.ITEM,
NVL(ALL_SKU.DESCRIPTION, ' ') AS ITEM_DESCRIPTION,
ALL_SKU.ITEM_SIZE,
ALL_SKU.LPN_PER_TIER,
NVL(SKU_W_INV.LOCN_BRCD, ALL_SKU.LOCN_BRCD) AS LOCN_BRCD,
ALL_SKU.UNIT_WT,
ALL_SKU.UNIT_VOL,
ALL_SKU.LPN_PER_PLT,
GREATEST(NVL(SKU_W_INV.BOH_QTY, ALL_SKU.BOH_QTY), 0) AS BOH_QTY,
GREATEST(NVL(SKU_W_INV.PICK_LOCN_QTY, ALL_SKU.PICK_LOCN_QTY), 0) AS PICK_LOCN_QTY,
GREATEST(NVL(SKU_W_INV.ILPN_QTY, ALL_SKU.ILPN_QTY), 0) AS ILPN_QTY,
GREATEST(NVL(SKU_W_INV.INV_ALLOC_INV, ALL_SKU.INV_ALLOC_INV), 0) AS INV_ALLOC_INV,
GREATEST(NVL(SKU_W_INV.INV_QTY_IN_TRAN, ALL_SKU.INV_QTY_IN_TRAN), 0) AS INV_QTY_IN_TRAN,
GREATEST(NVL(ALL_SKU.INV_UNIT_COST, 0.0000), 0.0000) AS INV_UNIT_COST,
GREATEST(NVL(SKU_W_INV.INV_NOT_ALLOC_QTY, ALL_SKU.INV_NOT_ALLOC_QTY), 0) AS INV_NOT_ALLOC_QTY,
GREATEST(NVL(ALL_SKU.INV_CATCH_WT, 0.0000), 0.0000) AS INV_CATCH_WT,
GREATEST(NVL(SKU_W_INV.INV_QTY_TO_BE_ALLOC, ALL_SKU.INV_QTY_TO_BE_ALLOC), 0) AS INV_QTY_TO_BE_ALLOC,
ALL_SKU.SKU_ID,
GREATEST(NVL(ALL_SKU.ITEM_AVG_WT, 0.0000), 0.0000) AS ITEM_AVG_WT,                                                   
GREATEST(NVL(po_order_quantity,000000000.0000),'000000000.0000') AS PO_ORDER_QUANTITY,
GREATEST(NVL(ALL_SKU.ITEM_UNIT_PRICE, 0.0000), 0.0000) AS ITEM_UNIT_PRICE,
CASE WHEN SKU_W_INV.ITEM IS NULL THEN 'N' ELSE '1' END AS HAS_INV
FROM
(
SELECT DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID AS PROFILE_ID,
          DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID AS ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION AS ITEM_DESCRIPTION,  
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER AS LPN_PER_TIER,
          MIN(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) AS LOCN_BRCD,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT AS UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME AS UNIT_VOL,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET AS LPN_PER_PLT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) AS BOH_QTY,
          INV0.SUM_ON_HAND AS PICK_LOCN_QTY,
          INV1.SUM_ON_HAND AS ILPN_QTY,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) AS INV_ALLOC_INV,
          REC0.SUM_SHIPPED_QUANTITY AS INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST AS INV_UNIT_COST,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
          SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + SUM(NVL(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) AS INV_QTY_TO_BE_ALLOC,
          A0QTY.SUM_INV_QTY_NOT_ALLOCATED AS INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK AS SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          pov0.SUM_order_quantity as po_order_quantity,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE ON DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK
            AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.QUANTITY = 1 AND DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.__HEVO__MARKED_DELETED = 'FALSE'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID and DEFAULT_DCINVENTORY_DCI_INVENTORY.__HEVO__MARKED_DELETED = 'FALSE' AND DEFAULT_DCINVENTORY_DCI_INVENTORY.ORG_ID IN ('D0044') AND DEFAULT_DCINVENTORY_DCI_INVENTORY.IS_IN_TRANSIT = '0'
    LEFT JOIN DEFAULT_DCINVENTORY_DCI_LOCATION ON DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID and DEFAULT_DCINVENTORY_DCI_LOCATION.__HEVO__MARKED_DELETED = 'FALSE'  AND DEFAULT_DCINVENTORY_DCI_LOCATION.PROFILE_ID IN ('D0044')
LEFT JOIN (SELECT pod.ITEM_ID, SUM(pod.order_quantity) AS SUM_order_quantity FROM default_receiving_rcv_purchase_order_line pod WHERE pod.__HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0044') and pod.CLOSED = 0 AND pod.CANCELED = 0 
           AND NOT EXISTS (SELECT L.PURCHASE_ORDER_ID FROM DEFAULT_RECEIVING_RCV_LPN L WHERE L.__HEVO__MARKED_DELETED = 'FALSE' AND L.PURCHASE_ORDER_ID = POD.PURCHASE_ORDER_ID)
           GROUP BY pod.ITEM_ID) POV0 ON POV0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE __HEVO__MARKED_DELETED = 'FALSE' AND ORG_ID IN ('D0044') and INVENTORY_CONTAINER_TYPE_ID != 'ILPN' GROUP BY ITEM_ID) INV0 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV0.ITEM_ID
    LEFT JOIN (select dcx.item_id, sum(nvl(dcx.on_hand,0)) AS SUM_INV_QTY_NOT_ALLOCATED 
                 from default_dcinventory_dci_inventory dcx
                 where dcx.__HEVO__MARKED_DELETED = 'FALSE' 
                 AND DCX.ORG_ID IN ('D0044')
                   and dcx.inventory_container_id in 
                      (select dci.inventory_container_id 
                         from default_dcinventory_dci_container_condition dci 
                        where dci.__HEVO__MARKED_DELETED = 'FALSE' 
                        AND DCI.ORG_ID IN ('D0044')
                          and dci.condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')
                          and dci.inventory_container_id in (select dcl.ilpn_id from default_dcinventory_dci_ilpn dcl where dcl.__hevo__marked_deleted = 'FALSE' and dcl.status < 11000))
               group by dcx.item_id) A0QTY ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = A0QTY.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(ON_HAND) AS SUM_ON_HAND 
                 FROM DEFAULT_DCINVENTORY_DCI_INVENTORY 
                 WHERE __HEVO__MARKED_DELETED = 'FALSE'AND ORG_ID IN ('D0044') and INVENTORY_CONTAINER_TYPE_ID = 'ILPN' GROUP BY ITEM_ID) INV1 ON DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = INV1.ITEM_ID
    LEFT JOIN (SELECT ITEM_ID, SUM(SHIPPED_QUANTITY) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE 
    WHERE __HEVO__MARKED_DELETED = 'FALSE'
               AND ORG_ID IN ('D0044') and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ORG_ID IN ('D0044') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY ITEM_ID) REC0 ON REC0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    WHERE DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID IN ('D0044')
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.__HEVO__MARKED_DELETED = 'FALSE'
    AND DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID IN ('D0044')
    GROUP BY DEFAULT_ITEM_MASTER_ITE_ITEM.PROFILE_ID,
    DEFAULT_DCINVENTORY_DCI_INVENTORY.FACILITY_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID,
    DEFAULT_ITEM_MASTER_ITE_ITEM.DESCRIPTION,
    DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_PRODUCT_SIZE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT,
    DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME,
    DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_COST,
    DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE,
    DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM,
    DEFAULT_ITEM_MASTER_ITE_ITEM.PK,
    DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT,
    INV0.SUM_ON_HAND,
    INV1.SUM_ON_HAND,
    REC0.SUM_SHIPPED_QUANTITY,
    pov0.SUM_order_quantity,
    A0QTY.SUM_INV_QTY_NOT_ALLOCATED
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PROFILE_ID,
    FAC.ORGANIZATION_ID AS FACILITY_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS WHSE,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS CO,
    ITM.ITEM_ID AS ITEM,
    ITM.DESCRIPTION,
    ITM.EXT_GEGL_PRODUCT_SIZE AS ITEM_SIZE,
    ITM.LPN_PER_TIER AS LPN_PER_TIER,
    NULL AS LOCN_BRCD,
    PKG.WEIGHT AS UNIT_WT,
    PKG.VOLUME AS UNIT_VOL,
    ITM.TIERS_PER_PALLET AS LPN_PER_PLT,
    0 AS BOH_QTY,
    0 AS PICK_LOCN_QTY,
    0 AS ILPN_QTY,
    0 AS INV_ALLOC_INV,
    0 AS INV_QTY_IN_TRAN,
    ITM.UNIT_COST AS INV_UNIT_COST,
    0 AS INV_NOT_ALLOC_QTY,
    ITM.CATCH_WEIGHT_ITEM AS INV_CATCH_WT,
    0 AS INV_QTY_TO_BE_ALLOC,
    ITM.PK AS SKU_ID,
    ITM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
    ITM.UNIT_PRICE AS ITEM_UNIT_PRICE
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK
                AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1 AND pkg.__HEVO__MARKED_DELETED = 'FALSE'
    CROSS JOIN (
    	SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
    	WHERE __HEVO__MARKED_DELETED = 'FALSE'
    	AND ORGANIZATION_ID IN ('D0044')
    	AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = 'FALSE'
    AND ITM.PROFILE_ID IN ('D0044')
) ALL_SKU
ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
AND SKU_W_INV.ITEM = ALL_SKU.ITEM
AND SKU_W_INV.FACILITY_ID = ALL_SKU.FACILITY_ID;


-- ---- OKP_QROO_V_D0044 ----
CREATE OR REPLACE VIEW okp_qroo_v_d0044 AS
SELECT DISTINCT
ALL_SKU.PROFILE_ID,
ALL_SKU.EXT_GEGLDCXXVIRTUALWHSE,
ALL_SKU.STYLE_SUFFIX,
ALL_SKU.ITEM_ID,
ALL_SKU.INVENTORY_FACILITY,
GREATEST(NVL(SKU_W_INV.ON_HAND, ALL_SKU.ON_HAND), 0) - GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS ON_HAND,
GREATEST(NVL(SKU_W_INV.QTY_IN_OUTSIDE_STG, ALL_SKU.QTY_IN_OUTSIDE_STG), 0) AS QTY_IN_OUTSIDE_STG,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS QTY_ON_HOLD,
GREATEST(NVL(SKU_W_INV.QTY_RECEIVED, ALL_SKU.QTY_RECEIVED), 0) AS QTY_RECEIVED,
GREATEST(NVL(SKU_W_INV.QTY_ADJUSTMENTS, ALL_SKU.QTY_ADJUSTMENTS), 0) AS QTY_ADJUSTMENTS,
GREATEST(NVL(SKU_W_INV.QTY_SELECTED, ALL_SKU.QTY_SELECTED), 0) AS QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.QTY_OVERSHIP, ALL_SKU.QTY_OVERSHIP), 0) AS QTY_OVERSHIP,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_ADJ, ALL_SKU.QTY_SCRATCH_ADJ), 0) AS QTY_SCRATCH_ADJ,
GREATEST(NVL(SKU_W_INV.QTY_SCRATCH_NO_ADJ, ALL_SKU.QTY_SCRATCH_NO_ADJ), 0) AS QTY_SCRATCH_NO_ADJ,
GREATEST(NVL(SKU_W_INV.WHSE_QTY_SELECTED, ALL_SKU.WHSE_QTY_SELECTED), 0) AS WHSE_QTY_SELECTED,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_IN, ALL_SKU.IN_TRANSIT_IN), 0) AS IN_TRANSIT_IN,
GREATEST(NVL(SKU_W_INV.IN_TRANSIT_OUT, ALL_SKU.IN_TRANSIT_OUT), 0) AS IN_TRANSIT_OUT,
GREATEST(NVL(SKU_W_INV.QTY_ON_PURCHASE_ORDER, ALL_SKU.QTY_ON_PURCHASE_ORDER), 0) AS QTY_ON_PURCHASE_ORDER,
ALL_SKU.EXT_GEGL_DEPARTMENT,
GREATEST(NVL(ALL_SKU.UNIT_PRICE, 0.0000), 0.0000) AS UNIT_PRICE,
GREATEST(NVL(ALL_SKU.UNIT_COST, 0.0000), 0.0000) AS UNIT_COST,
GREATEST(NVL(ALL_SKU.AVERAGE_WEIGHT, 0.0000), 0.0000) AS AVERAGE_WEIGHT,
GREATEST(NVL(SKU_W_INV.LOCKED_INV_QTY, ALL_SKU.LOCKED_INV_QTY), 0) AS LOCKED_INV_QTY,
CASE WHEN SKU_W_INV.ITEM_ID IS NULL THEN 'N' ELSE 'Y' END AS HAS_INV
FROM
(    SELECT DISTINCT
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,     
    FX.INVENTORY_FACILITY, --SOURCE WAREHOUSE FOR INVENTORY COMPARISON-- 
    NVL(FX.SUM_ON_HAND,0) AS ON_HAND, --ON HAND INVENTORY AT SOURCE WAREHOUSE--
    --SUM(NVL(FX.OUTSIDE_STG,0)) AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    '0' AS QTY_IN_OUTSIDE_STG, --ON HAND INVENTORY AT ALL OTHER WAREHOUSES NOT EQUAL TO SOURCE WAREHOUSE--
    NVL(FX.SUM_ON_HAND,0) - NVL(FX.SUM_ALLOCATED,0) AS QTY_ON_HAND_MINUS_ALLOCATED,
    NVL(PIX0.SUM_RECEIVED_QUANTITY,0) AS QTY_RECEIVED,
    NVL(PIX1.SUM_ADJUSTMENT_QUANTITY,0) AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,              
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_IN,
    NVL(REC0.SUM_SHIPPED_QUANTITY,0) AS IN_TRANSIT_OUT,
    NVL(REC1.SUM_ORDER_QUANTITY,0) AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    NVL(INV1.SUM_LOCKED_INV,0) AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    LEFT JOIN ge_poc.gold_lift_shift.ccs_inv_compare_v FX ON FX.ITEM_ID = ITM.ITEM_ID AND FX.PROFILE_ID = ITM.PROFILE_ID
    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(QUANTITY,0)) AS SUM_RECEIVED_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' and GROUPING_TAG = 'Receipt' GROUP BY FACILITY_ID, ITEM_ID) PIX0 ON PIX0.FACILITY_ID = FX.INVENTORY_FACILITY AND PIX0.ITEM_ID = ITM.ITEM_ID
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(CASE WHEN ADJUSTED_TYPE = 'ADD' THEN NVL(QUANTITY,0) WHEN ADJUSTED_TYPE = 'SUBTRACT' THEN (-1*NVL(QUANTITY,0)) ELSE 0 END) AS SUM_ADJUSTMENT_QUANTITY FROM DEFAULT_PIX_PIX_PIX_ENTRY WHERE default_pix_pix_pix_entry.__HEVO__MARKED_DELETED = 'FALSE' AND SOURCE_EVENT_NAME NOT IN ('CONDITION_CODE_CHANGES') and grouping_tag = 'Inventory_Adjustment' GROUP BY FACILITY_ID, ITEM_ID) PIX1 ON PIX1.ITEM_ID = ITM.ITEM_ID AND PIX1.FACILITY_ID = FX.INVENTORY_FACILITY
            LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(SHIPPED_QUANTITY,0)) AS SUM_SHIPPED_QUANTITY FROM DEFAULT_RECEIVING_RCV_ASN_LINE WHERE DEFAULT_RECEIVING_RCV_ASN_LINE.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ID IN (SELECT ASN_ID FROM DEFAULT_RECEIVING_RCV_ASN WHERE DEFAULT_RECEIVING_RCV_ASN.__HEVO__MARKED_DELETED = 'FALSE' and ASN_ORIGIN_TYPE_ID IN ('W','M','S','C') AND ASN_STATUS = 1000 AND CANCELED = 0) GROUP BY FACILITY_ID, ITEM_ID) REC0 ON REC0.ITEM_ID = ITM.ITEM_ID AND REC0.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID
, ITEM_ID
, NVL(SUM(to_be_recv),0) sum_order_quantity
FROM (
SELECT poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID 
, sum(rcv.QUANTITY) rcv_quantity
, CASE WHEN nvl(sum(rcv.QUANTITY),0) >= poli.order_quantity THEN '0'
WHEN nvl(sum(rcv.QUANTITY),0) = '0' THEN  poli.order_quantity
WHEN nvl(sum(rcv.QUANTITY),0) < poli.order_quantity THEN (poli.order_quantity - nvl(sum(rcv.QUANTITY),0)) 
ELSE '0' END to_be_recv
FROM default_receiving_rcv_purchase_order_line poli
LEFT OUTER JOIN DEFAULT_RECEIVING_RCV_RECEIPT rcv ON poli.PURCHASE_ORDER_ID = rcv.PURCHASE_ORDER_ID AND poli.PURCHASE_ORDER_LINE_ID = rcv.PURCHASE_ORDER_LINE_ID AND poli.FACILITY_ID = rcv.FACILITY_ID AND poli.ITEM_ID = rcv.ITEM_ID AND rcv.__HEVO__MARKED_DELETED = 'FALSE'
WHERE poli.__HEVO__MARKED_DELETED = 'FALSE'
--AND poli.FACILITY_ID = 'D0033'
AND poli.CANCELED = '0' 
AND poli.closed = '0'
AND poli.purchase_order_id in 
        (select purchase_order_id from default_receiving_rcv_purchase_order where 
        default_receiving_rcv_purchase_order.__HEVO__MARKED_DELETED = 'FALSE' and purchase_order_status < 10000 and canceled = 0 and closed = 0)
        GROUP BY poli.FACILITY_ID
, poli.item_id 
, poli.order_quantity 
, poli.PURCHASE_ORDER_ID 
, poli.PURCHASE_ORDER_LINE_ID
        )
        GROUP BY FACILITY_ID
, ITEM_ID) REC1 ON REC1.ITEM_ID = ITM.ITEM_ID AND REC1.FACILITY_ID = FX.INVENTORY_FACILITY
                    LEFT JOIN (SELECT FACILITY_ID, ITEM_ID, SUM(NVL(ON_HAND,0)) AS SUM_LOCKED_INV FROM DEFAULT_DCINVENTORY_DCI_INVENTORY WHERE INVENTORY_CONTAINER_ID IN (SELECT INVENTORY_CONTAINER_ID FROM DEFAULT_DCINVENTORY_DCI_CONTAINER_CONDITION WHERE CONDITION_CODE IN ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) AND INVENTORY_CONTAINER_ID IN (SELECT ILPN_ID FROM DEFAULT_DCINVENTORY_DCI_ILPN WHERE STATUS < 11000) AND __HEVO__MARKED_DELETED = 'FALSE' GROUP BY FACILITY_ID, ITEM_ID) INV1 ON INV1.ITEM_ID = ITM.ITEM_ID AND INV1.FACILITY_ID = FX.INVENTORY_FACILITY
    WHERE FX.INVENTORY_FACILITY IS NOT NULL
    AND ITM.__HEVO__MARKED_DELETED = 'FALSE'
                                GROUP BY ITM.PROFILE_ID,
                                ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE,
                                ITM.STYLE_SUFFIX,
                                ITM.ITEM_ID,
                                ITM.EXT_GEGL_DEPARTMENT,
                                ITM.UNIT_PRICE,
                                ITM.UNIT_COST,
                                ITM.AVERAGE_WEIGHT,
                                INVENTORY_FACILITY, 
                                FX.SUM_ON_HAND,
                                FX.SUM_ALLOCATED,
                                PIX0.SUM_RECEIVED_QUANTITY,
                                PIX1.SUM_ADJUSTMENT_QUANTITY,
                                REC0.SUM_SHIPPED_QUANTITY,
                                REC1.SUM_ORDER_QUANTITY,
                                INV1.SUM_LOCKED_INV
) SKU_W_INV
RIGHT OUTER JOIN
(
    SELECT
    ITM.PK,
    ITM.PROFILE_ID,
    ITM.EXT_GEGL_DCXX_VIRTUAL_WHSE AS EXT_GEGLDCXXVIRTUALWHSE,
    ITM.STYLE_SUFFIX,
    ITM.ITEM_ID,
    FAC.ORGANIZATION_ID AS INVENTORY_FACILITY,
    0 AS ON_HAND,
    0 AS QTY_IN_OUTSIDE_STG,
    0 AS QTY_ON_HAND_MINUS_ALLOCATED,
    0 AS QTY_RECEIVED,
    0 AS QTY_ADJUSTMENTS,
    0 AS QTY_SELECTED,
    0 AS QTY_OVERSHIP,
    0 AS QTY_SCRATCH_ADJ,
    0 AS QTY_SCRATCH_NO_ADJ,
    0 AS WHSE_QTY_SELECTED,
    0 AS IN_TRANSIT_IN,
    0 AS IN_TRANSIT_OUT,
    0 AS QTY_ON_PURCHASE_ORDER,
    ITM.EXT_GEGL_DEPARTMENT,
    ITM.UNIT_PRICE,
    ITM.UNIT_COST,
    ITM.AVERAGE_WEIGHT,
    0 AS LOCKED_INV_QTY
    FROM DEFAULT_ITEM_MASTER_ITE_ITEM ITM
    JOIN DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE PKG ON ITM.PK = PKG.ITEM_PK AND PKG.STANDARD_QUANTITY_UOM_ID = 'UNIT' AND PKG.QUANTITY = 1
    CROSS JOIN (
        SELECT ORGANIZATION_ID FROM DEFAULT_ORGANIZATION_ORG_ORGANIZATION
        WHERE __HEVO__MARKED_DELETED = FALSE
        AND ORGANIZATION_ID IN ('D0044')
        AND SUBSTR(ORGANIZATION_ID, 1, 1) IN ('C', 'D', 'W')
    ) FAC
    WHERE ITM.__HEVO__MARKED_DELETED = FALSE
    AND ITM.PROFILE_ID IN ('D0044')
)ALL_SKU
    ON SKU_W_INV.PROFILE_ID = ALL_SKU.PROFILE_ID
    AND SKU_W_INV.ITEM_ID = ALL_SKU.ITEM_ID
    AND SKU_W_INV.INVENTORY_FACILITY = ALL_SKU.INVENTORY_FACILITY;


-- =====================================================================
-- Transportation  (3 views)
-- =====================================================================

-- ---- V_GESC_CLOSED_LOADS ----
CREATE OR REPLACE VIEW v_gesc_closed_loads AS SELECT
    im.profile_id,
    substr(pd.order_id, 3, 6) AS order_id,
    substr(pd.order_id, 9, 3) AS order_seg_id,
    ch.facility_id    AS whse_id,
    im.item_id   AS item_id,
    SUM(nvl(cd.packed_quantity,0)) AS ship_qty
FROM
    default_pickpack_ppk_olpn    ch,
    default_pickpack_ppk_olpn_detail    cd,
    default_dcorder_dco_order_line       pd,
    default_item_master_ite_item   im
WHERE
    ch.olpn_id = cd.olpn_id
    AND cd.order_id = pd.order_id
    AND cd.order_line_id = pd.order_line_id
    AND cd.item_id = im.item_id
    AND cd.item_id = pd.item_id
    AND ch.status = 8000
    AND cd.status = current_date()
GROUP BY
    im.profile_id,
    substr(pd.order_id, 3, 6),
    substr(pd.order_id, 9, 3),
    ch.facility_id,
    im.item_id;


-- ---- V_GESC_WM_INVENTORY ----
CREATE OR REPLACE VIEW v_gesc_wm_inventory AS 
SELECT    a.profile_id, 
          nvL(a.asiwhse,a.profile_id) asiwhse,
          a.aimstyle,
          a.aimstylesxf,
          nvl(a.asiqtyonhand,0),
          nvl(b.bpdunitsordered,0),
          nvl(c.csumactlqty,0),
          nvl((  a.asiqtyonhand
           + NVL (b.bpdunitsordered, 0)
           - NVL (c.csumactlqty, 0)),0)
             BOH,
         /* nvl(sum(c.csumactlqty),0),
          nvl((  sum(a.asiqtyonhand)
           + NVL (sum(b.bpdunitsordered), 0)
           - NVL (sum(c.csumactlqty), 0)),0)
             BOH, */
          nvl(d.dpdunitsordered,0)
     FROM (SELECT im.profile_id
, nvl(di.asiwhse,im.profile_id) asiwhse
, im.aimstyle
, im.aimstylesxf
, sum(nvl(di.asiqtyonhand,0)) asiqtyonhand
FROM (
SELECT im.profile_id,
                    im.item_id aimstyle,
                    substr(im.ext_gegl_dcxx_virtual_whse,6,2) aimstylesxf
               FROM default_item_master_ite_item im
              WHERE im.__HEVO__MARKED_DELETED = 'FALSE'
              AND im.profile_id != 'GEGL-SC-L1-PROFILE'
              AND nvl(im.style_suffix,0) != '99')im
           LEFT OUTER JOIN 
           (SELECT si.facility_id asiwhse,
           si.item_id,
                    si.on_hand asiqtyonhand
               FROM default_dcinventory_dci_inventory si
              WHERE si.__HEVO__MARKED_DELETED = 'FALSE'
           AND si.IS_IN_TRANSIT = '0'
           --AND si.item_id = '000644'
           --AND si.org_id = 'D0044'
           --- Omitting Shipped oLPNs
                      AND si.iNVENTORY_CONTAINER_TYPE_ID != 'OLPN'
           --and not exists (select (1) from default_pickpack_ppk_olpn olpn 
--where olpn.status = '8000' and olpn.__HEVO__MARKED_DELETED = 'FALSE' 
--and  olpn.olpn_id = ( case when si.INVENTORY_CONTAINER_ID = si.location_id then NULL else si.INVENTORY_CONTAINER_ID end) and olpn.org_id = si.org_id)
                           -- iLPNs in Created Status
and not exists (select (1)
 from default_dcinventory_DCI_ILPN ilpn where ilpn.status in ('1000','9000') and ilpn.__HEVO__MARKED_DELETED = 'FALSE' AND ilpn.ORG_ID = si.facility_id
 AND ilpn.PURGE_DATE >= current_timestamp()
                 and ilpn.ilpn_id = (case when si.INVENTORY_CONTAINER_ID = si.location_id then NULL else si.INVENTORY_CONTAINER_ID end))
                 ) di ON im.aimstyle = di.item_id AND im.profile_id = di.asiwhse
           GROUP BY im.profile_id
, di.asiwhse
, im.aimstyle
, im.aimstylesxf
           ORDER BY di.asiwhse, im.aimstyle) A,
          (SELECT asn.org_id bphwhse
, asn.item_id bimstyle
, sum(nvl(asn.shipped_quantity,0)) - sum(nvl(rc.rec_qty,0)) bpdunitsordered
FROM (
SELECT DISTINCT po.ORG_ID 
, po.PURCHASE_ORDER_ID 
, po.PURCHASE_ORDER_STATUS Po_status
, ASN.ASN_ID
--, ASN.ESTIMATED_DELIVERY_DATE
, po.DELIVERY_END_DATE 
, CASE WHEN im.ext_gegl_dcxx_virtual_whse = 'DC61-61' THEN '0000' ELSE UPPER(po.ext_gegl_po_type) END po_type
, im.ext_gegl_dcxx_virtual_whse dimstylesxf
, POLI.ITEM_ID  
--, POLI.ORDER_QUANTITY 
, CASE  WHEN NVL(ASN.SHIPPED_QUANTITY,0) = 0 AND nvl(asn.asn_status,0) < 8000 THEN POLI.ORDER_QUANTITY  ELSE ASN.SHIPPED_QUANTITY END SHIPPED_QUANTITY
--, POLI.UN_SHIPPED_QUANTITY 
FROM DEFAULT_RECEIVING_RCV_PURCHASE_ORDER po
INNER JOIN DEFAULT_RECEIVING_RCV_PURCHASE_ORDER_LINE POLI ON PO.PURCHASE_ORDER_ID = POLI.PURCHASE_ORDER_ID AND PO.ORG_ID = POLI.ORG_ID AND POLI.__HEVO__MARKED_DELETED = 'FALSE'
INNER JOIN DEFAULT_ITEM_MASTER_ITE_ITEM IM ON IM.ITEM_ID = POLI.ITEM_ID AND IM.PROFILE_ID = POLI.ORG_ID AND IM.__HEVO__MARKED_DELETED = 'FALSE'
LEFT OUTER JOIN (
SELECT DISTINCT A.ORG_ID  
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, AL.PURCHASE_ORDER_ID 
, AL.ITEM_ID 
, AL.SHIPPED_QUANTITY 
FROM DEFAULT_RECEIVING_RCV_ASN a
INNER JOIN DEFAULT_RECEIVING_RCV_ASN_LINE AL ON A.ASN_ID = AL.ASN_ID AND A.ORG_ID = AL.ORG_ID AND AL.__HEVO__MARKED_DELETED = 'FALSE'
WHERE a.__HEVO__MARKED_DELETED = 'FALSE'
--AND a.ORG_ID = 'D0044'
AND a.ASN_LEVEL_ID = 'ITEM'
--AND al.PURCHASE_ORDER_ID = '185480'
--AND A.ASN_STATUS < 8000
UNION ALL 
SELECT DISTINCT A.ORG_ID 
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, ILPN.PURCHASE_ORDER_ID 
, DCI.ITEM_ID
, SUM(DCI.ON_HAND) SHIPPED_QUANTITY
--, IM.STYLE_SUFFIX 
FROM DEFAULT_RECEIVING_RCV_ASN a
INNER JOIN DEFAULT_DCINVENTORY_DCI_ILPN ilpn ON A.ASN_ID = ILPN.ASN_ID AND A.ORG_ID = ILPN.ORG_ID AND ILPN.__HEVO__MARKED_DELETED = 'FALSE'
INNER JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY DCI ON ILPN.ILPN_ID = DCI.ILPN_ID AND ILPN.ORG_ID = DCI.ORG_ID AND DCI.__HEVO__MARKED_DELETED = 'FALSE' --- ADDING DCI FOR "MIXED" ILPNS
INNER JOIN DEFAULT_ITEM_MASTER_ITE_ITEM IM ON DCI.ITEM_ID = IM.ITEM_ID AND DCI.ORG_ID = IM.PROFILE_ID AND IM.__HEVO__MARKED_DELETED = 'FALSE'
WHERE a.__HEVO__MARKED_DELETED = 'FALSE'
--AND a.ORG_ID = 'D0044'
AND a.ASN_LEVEL_ID = 'LPN'
--AND A.ASN_STATUS < 8000
--AND A.ASN_ID = 'TPM1854800'
AND NVL(IM.STYLE_SUFFIX,'999') != '99'
GROUP BY A.ORG_ID 
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, ILPN.PURCHASE_ORDER_ID 
, DCI.ITEM_ID
)asn ON po.PURCHASE_ORDER_ID = asn.PURCHASE_ORDER_ID AND POLI.ITEM_ID = ASN.ITEM_ID AND asn.org_id = po.org_id
WHERE po.__HEVO__MARKED_DELETED = 'FALSE'
--AND po.ORG_ID = 'D0044'
AND po.PURCHASE_ORDER_STATUS < 9000
aND po.DELIVERY_END_DATE <= current_date()
AND (CASE WHEN im.ext_gegl_dcxx_virtual_whse = 'DC61-61' THEN '0000' ELSE UPPER(po.ext_gegl_po_type) END ) = 'HOT'
--AND PO.PURCHASE_ORDER_ID = '162699'--'165294' 185480
AND NVL(ASN.ASN_STATUS,0) < 8000) asn 
LEFT OUTER JOIN (
SELECT rc.ORG_ID 
, rc.ASN_ID 
, rc.purchase_order_id
, rc.item_id 
, sum(rc.quantity) rec_qty
FROM default_receiving_rcv_receipt rc
WHERE __HEVO__MARKED_DELETED = 'FALSE'
GROUP BY rc.ORG_ID 
, rc.ASN_ID 
, rc.purchase_order_id
, rc.item_id)rc ON asn.org_id = rc.org_id AND asn.asn_id = rc.asn_id AND asn.item_id = rc.item_id AND asn.purchase_order_id = rc.purchase_order_id
GROUP BY asn.org_id
, asn.item_id
, asn.dimstylesxf) B,
          ( select facility_id cchwhse, item_id cimstyle, sum(nvl(on_hand,0)) csumactlqty from default_dcinventory_dci_inventory 
        where default_dcinventory_dci_inventory.__HEVO__MARKED_DELETED = 'FALSE' and inventory_container_id in 
         (select inventory_container_id from default_dcinventory_dci_container_condition where default_dcinventory_dci_container_condition.__HEVO__MARKED_DELETED = 'FALSE' and condition_code in ('DA','DM','DO','DV','FB','GH','TH','TR','VH')) and inventory_container_id in 
         (select ilpn_id from default_dcinventory_dci_ilpn where default_dcinventory_dci_ilpn.__HEVO__MARKED_DELETED = 'FALSE' and status < 11000) group by facility_id, item_id) C,
          (SELECT asn.org_id dphwhse
, asn.item_id dimstyle
, CASE WHEN (sum(nvl(asn.shipped_quantity,0)) - sum(nvl(rc.rec_qty,0))) < 0 THEN 0 ELSE (sum(nvl(asn.shipped_quantity,0)) - sum(nvl(rc.rec_qty,0))) end dpdunitsordered
FROM (
SELECT DISTINCT po.ORG_ID 
, po.PURCHASE_ORDER_ID 
, po.PURCHASE_ORDER_STATUS Po_status
, ASN.ASN_ID
--, ASN.ESTIMATED_DELIVERY_DATE
, po.DELIVERY_END_DATE 
, CASE WHEN im.ext_gegl_dcxx_virtual_whse = 'DC61-61' THEN '0000' ELSE UPPER(po.ext_gegl_po_type) END  po_type
, im.ext_gegl_dcxx_virtual_whse dimstylesxf
, POLI.ITEM_ID  
--, POLI.ORDER_QUANTITY 
, CASE  WHEN NVL(ASN.SHIPPED_QUANTITY,0) = 0 AND nvl(asn.asn_status,0) < 8000 THEN POLI.ORDER_QUANTITY  ELSE ASN.SHIPPED_QUANTITY END SHIPPED_QUANTITY
--, POLI.UN_SHIPPED_QUANTITY 
FROM DEFAULT_RECEIVING_RCV_PURCHASE_ORDER po
INNER JOIN DEFAULT_RECEIVING_RCV_PURCHASE_ORDER_LINE POLI ON PO.PURCHASE_ORDER_ID = POLI.PURCHASE_ORDER_ID AND PO.ORG_ID = POLI.ORG_ID AND POLI.__HEVO__MARKED_DELETED = 'FALSE'
INNER JOIN DEFAULT_ITEM_MASTER_ITE_ITEM IM ON IM.ITEM_ID = POLI.ITEM_ID AND IM.PROFILE_ID = POLI.ORG_ID AND IM.__HEVO__MARKED_DELETED = 'FALSE'
LEFT OUTER JOIN (
SELECT DISTINCT A.ORG_ID  
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, AL.PURCHASE_ORDER_ID 
, AL.ITEM_ID 
, AL.SHIPPED_QUANTITY 
FROM DEFAULT_RECEIVING_RCV_ASN a
INNER JOIN DEFAULT_RECEIVING_RCV_ASN_LINE AL ON A.ASN_ID = AL.ASN_ID AND A.ORG_ID = AL.ORG_ID AND AL.__HEVO__MARKED_DELETED = 'FALSE'
WHERE a.__HEVO__MARKED_DELETED = 'FALSE'
--AND a.ORG_ID = 'D0044'
AND a.ASN_LEVEL_ID = 'ITEM'
--AND al.PURCHASE_ORDER_ID = '185480'
--AND A.ASN_STATUS < 8000
UNION ALL 
SELECT DISTINCT A.ORG_ID 
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, ILPN.PURCHASE_ORDER_ID 
, DCI.ITEM_ID
, SUM(DCI.ON_HAND) SHIPPED_QUANTITY
--, IM.STYLE_SUFFIX 
FROM DEFAULT_RECEIVING_RCV_ASN a
INNER JOIN DEFAULT_DCINVENTORY_DCI_ILPN ilpn ON A.ASN_ID = ILPN.ASN_ID AND A.ORG_ID = ILPN.ORG_ID AND ILPN.__HEVO__MARKED_DELETED = 'FALSE'
INNER JOIN DEFAULT_DCINVENTORY_DCI_INVENTORY DCI ON ILPN.ILPN_ID = DCI.ILPN_ID AND ILPN.ORG_ID = DCI.ORG_ID AND DCI.__HEVO__MARKED_DELETED = 'FALSE' --- ADDING DCI FOR "MIXED" ILPNS
INNER JOIN DEFAULT_ITEM_MASTER_ITE_ITEM IM ON DCI.ITEM_ID = IM.ITEM_ID AND DCI.ORG_ID = IM.PROFILE_ID AND IM.__HEVO__MARKED_DELETED = 'FALSE'
WHERE a.__HEVO__MARKED_DELETED = 'FALSE'
--AND a.ORG_ID = 'D0044'
AND a.ASN_LEVEL_ID = 'LPN'
--AND A.ASN_STATUS < 8000
--AND A.ASN_ID = 'TPM1854800'
AND NVL(IM.STYLE_SUFFIX,'999') != '99'
GROUP BY A.ORG_ID 
, A.ASN_ID 
, a.ASN_STATUS 
, A.ESTIMATED_DELIVERY_DATE 
, ILPN.PURCHASE_ORDER_ID 
, DCI.ITEM_ID
)asn ON po.PURCHASE_ORDER_ID = asn.PURCHASE_ORDER_ID AND POLI.ITEM_ID = ASN.ITEM_ID AND asn.org_id = po.org_id
WHERE po.__HEVO__MARKED_DELETED = 'FALSE'
--AND po.ORG_ID = 'D0044'
AND po.PURCHASE_ORDER_STATUS < 9000
AND po.DELIVERY_END_DATE <= current_date()
--AND uPPER (po.ext_gegl_po_type) = 'HOT'
--AND PO.PURCHASE_ORDER_ID = '162699'--'165294' 185480
AND NVL(ASN.ASN_STATUS,0) < 8000) asn 
LEFT OUTER JOIN (
SELECT rc.ORG_ID 
, rc.ASN_ID 
, rc.item_id 
, rc.purchase_order_id
, sum(rc.quantity) rec_qty
FROM default_receiving_rcv_receipt rc
WHERE __HEVO__MARKED_DELETED = 'FALSE'
GROUP BY rc.ORG_ID 
, rc.ASN_ID 
, rc.purchase_order_id
, rc.item_id)rc ON asn.org_id = rc.org_id AND asn.asn_id = rc.asn_id AND asn.item_id = rc.item_id AND asn.purchase_order_id = rc.purchase_order_id
GROUP BY asn.org_id
, asn.item_id
, asn.dimstylesxf) D
    WHERE     a.aimstyle = b.bimstyle(+)
          AND a.asiwhse = b.bphwhse(+)
          AND a.aimstyle = c.cimstyle(+)
          AND a.asiwhse = c.cchwhse(+)
          AND a.aimstyle = d.dimstyle(+)
          AND a.asiwhse = d.dphwhse(+)
         -- AND a.aimstyle = '001805'--'931179'
         /* group by a.profile_id,
                   nvL(a.asiwhse,a.profile_id),
                   a.aimstyle,
                   a.aimstylesxf,
                   nvl(a.asiqtyonhand,0),
                   nvl(b.bpdunitsordered,0),
                   d.dpdunitsordered */;


-- ---- V_LOAD_SHEETS ----
CREATE OR REPLACE VIEW v_load_sheets AS WITH qryMain AS  (
	SELECT	sm.TRANSPORTATION_ORDER_ID,
 			sh.SHIPMENT_ID as SHIPMENT_ID,
 			from_utc_timestamp(sh.ORIGIN_PLANNED_ARR_START_DTTM, 'America/New_York') AS PICKUP_START_DTTM,
  			CARSH.description AS CARRIER_CODE_NAME,
     		FA.FACILITY_NAME,
       		SH.CLIMATE_CONTROL_ID AS protection_level,
     		TORD.DESTINATION_FACILITY_ID AS STORE_NBR,
     		s.FACILITY_ID AS STOP_FACILITY_ALIAS_ID ,
      		pc.PRODUCT_CLASS_ID ,
     		s.STOP_SEQUENCE AS STOP_SEQ ,
     		SN.NOTE_VALUE AS Note  ,
			CASE WHEN row_number() OVER (PARTITION BY tord.TRANSPORTATION_ORDER_ID ORDER BY tord.TRANSPORTATION_ORDER_ID )=1 THEN TORD.planned_SIZE1_VALUE ELSE NULL END as PALLETS       ,
			pc.ORDER_QTY   ,
  			pc.PLANNED_VOLUME   ,
			SH.PLANNED_SIZE1_VALUE AS PALLETS_ON_SHIPMENT          ,
			TOrd.ORIGIN_FACILITY_ID     ,
			LSQ.LOADING_SEQUENCE      ,
 			CASE	WHEN LSQ.LOADING_SEQUENCE= max(LSQ.LOADING_SEQUENCE) OVER (PARTITION BY sh.SHIPMENT_ID) THEN 'NOSE'       		WHEN LSQ.LOADING_SEQUENCE= min(LSQ.LOADING_SEQUENCE) OVER (PARTITION BY sh.SHIPMENT_ID) THEN 'TAIL'      		ELSE '' END AS SQ     ,
			sh.pk     ,
			sh.org_id ,
			CASE WHEN tord.ORIGIN_FACILITY_ID ='D0061' and pc.PRODUCT_CLASS_ID IN ('DAIRY','PRODUCE') THEN 'ASFPC' ELSE pc.PRODUCT_CLASS_ID END AS NEWPC  
FROM	ge_poc.bronze.DEFAULT_SHIPMENT_SHP_SHIPMENT sh  
 	join ge_poc.bronze.DEFAULT_SHIPMENT_TRANSPORT_ORDER_MOVEMENT sm 	
		ON sm.shipment_id=sh.shipment_id 	
 		and sh.org_id=sm.org_id 	
		and sh.__HEVO__MARKED_DELETED ='FALSE' 	
		and sm.__HEVO__MARKED_DELETED ='FALSE'  
	join ge_poc.bronze.DEFAULT_ROUTING_RTG_TRANSPORTATION_ORDER TOrd 	
		ON sm.TRANSPORTATION_ORDER_ID=TOrd.TRANSPORTATION_ORDER_ID 	
		and sm.org_id=tord.org_id 	
		and tord.__HEVO__MARKED_DELETED ='FALSE'  
	join ge_poc.bronze.DEFAULT_SHIPMENT_SHP_STOP S 	
		ON s.SHIPMENT_PK = sh.pk 	
		and s.org_id=sh.org_id 	
		and s.STOP_ID = sm.DELIVERY_STOP_ID  	
		and s.__HEVO__MARKED_DELETED ='FALSE'   
	LEFT join ge_poc.bronze.DEFAULT_CARRIER_CAR_CARRIER carsh  	
		ON sh.ASSIGNED_CARRIER_ID =carsh.CARRIER_ID	 	
		and SPLIT_PART(carsh.PROFILE_ID,'-P', 1) = sh.ORG_ID 
		and carsh.__HEVO__MARKED_DELETED ='FALSE'  INNER 
	join ge_poc.bronze.DEFAULT_FACILITY_FAC_FACILITY fa  		
		ON TOrd.DESTINATION_FACILITY_ID = fa.FACILITY_ID  		
		and fa.__HEVO__MARKED_DELETED = 'FALSE'  		
		and SPLIT_PART(FA.PROFILE_ID,'-P',1) = sh.ORG_ID   
	LEFT join ge_poc.bronze.DEFAULT_SHIPMENT_SHP_SHIPMENT_NOTE SN 		
		ON SH.PK = SN.SHIPMENT_PK  		
		and sh.org_id=sn.org_id 		
		and SN.__HEVO__MARKED_DELETED = 'FALSE'   
	LEFT join 	(SELECT 
				DISTINCT ol.ASSIGNED_SHIPMENT_ID
				,LPAD(ol.EXT_G_E_G_L_LOADING_SEQUENCE,2,0) AS LOADING_SEQUENCE
				,oh.DESTINATION_FACILITY_ID ,oh.FACILITY_ID  
				FROM ge_poc.bronze.DEFAULT_DCORDER_DCO_ORDER oh 
				join ge_poc.bronze.DEFAULT_DCORDER_DCO_ORDER_LINE OL  	
				ON oh.FACILITY_ID = ol.facility_id  	
				and oh.ORDER_ID = ol.order_id  	
				and oh.__HEVO__MARKED_DELETED = 'FALSE' 	
				and ol.__HEVO__MARKED_DELETED = 'FALSE') LSQ 		 
		ON LSQ.ASSIGNED_SHIPMENT_ID = sh.SHIPMENT_ID  		
		and LSQ.facility_id = TOrd.ORIGIN_FACILITY_ID  		
		and lsq.DESTINATION_FACILITY_ID=TOrd.DESTINATION_FACILITY_ID  
	LEFT join 	(SELECT TRANSPORTATION_ORDER_PK , sum(ORDERED_QUANTITY) AS ORDER_QTY , SUM(EXTENDED_VOLUME) AS PLANNED_VOLUME , PRODUCT_CLASS_ID  FROM DEFAULT_ROUTING_RTG_TRANSPORTATION_ORDER_LINE WHERE __HEVO__MARKED_DELETED = 'FALSE' GROUP BY PRODUCT_CLASS_ID, TRANSPORTATION_ORDER_PK) PC 
		ON PC.TRANSPORTATION_ORDER_PK = tord.pk   
WHERE   S.STOP_SEQUENCE > 1 
		and (tord.PLANNING_TYPE_ID IN ('Outbound','Shuttle') OR sh.PLANNING_TYPE_ID IN ('Outbound','Shuttle'))
		) 
,qm AS (Select 	count (distinct SHIPMENT_ID) AS OTHER_SHIPMENTS_FOR_STORE,
				SHIPMENT_ID,
				STOP_FACILITY_ALIAS_ID 
		from qryMain 
		GROUP BY	STOP_FACILITY_ALIAS_ID ,
					SHIPMENT_ID) 
,st AS (SELECT 	WAREHOUSE_STATUS_ID AS PLANNING_STATUS_ID ,
				SHIPMENT_PK,
				org_id,
				facility_id 
				FROM ge_poc.bronze.DEFAULT_SHIPMENT_SHP_STOP 
				WHERE __HEVO__MARKED_DELETED ='FALSE' 
				and STOP_ACTION_ID='PU') 
SELECT	qryMain.SHIPMENT_ID,
		qryMain.PICKUP_START_DTTM,
		qryMain.CARRIER_CODE_NAME,
		qryMain.PROTECTION_LEVEL,
		qryMain.PALLETS_ON_SHIPMENT,
		qryMain.FACILITY_NAME,
		qryMain.STORE_NBR,
		qryMain.STOP_FACILITY_ALIAS_ID,
		qryMain.PRODUCT_CLASS_ID AS PRODUCT_CLASS,
		qryMain.STOP_SEQ,
		SUM(qryMain.PLANNED_VOLUME) AS PLANNED_VOLUME,
		SUM(qryMain.ORDER_QTY) AS ORDER_QTY,
		SUM(qryMain.PALLETS) AS PALLETS,
		qryMain.NOTE,
		(Select count (distinct SHIPMENT_ID)   from qm WHERE qm.STOP_FACILITY_ALIAS_ID=qryMain.STOP_FACILITY_ALIAS_ID and qm.SHIPMENT_ID <>  qryMain.SHIPMENT_ID ) as OTHER_SHIPMENTS_FOR_STORE,
		qryMain.ORIGIN_FACILITY_ID,
		st.PLANNING_STATUS_ID,
		qryMain.LOADING_SEQUENCE,
		qryMain.SQ ,
		qryMain.NEWPC,
		st.facility_id 
FROM qryMain    
	LEFT  join st 
		ON st.shipment_pk=qryMain.pk             
		and st.org_id=qryMain.org_id 			
GROUP BY  	qryMain.SHIPMENT_ID,
			qryMain.PICKUP_START_DTTM,
			qryMain.CARRIER_CODE_NAME,
			qryMain.PROTECTION_LEVEL,
			qryMain.PALLETS_ON_SHIPMENT,
			qryMain.FACILITY_NAME,
			qryMain.STORE_NBR,
			qryMain.STOP_FACILITY_ALIAS_ID,
			qryMain.PRODUCT_CLASS_ID ,
			qryMain.STOP_SEQ ,
			qryMain.NOTE,
			OTHER_SHIPMENTS_FOR_STORE,
			qryMain.ORIGIN_FACILITY_ID,
			st.PLANNING_STATUS_ID,
			qryMain.LOADING_SEQUENCE,
			qryMain.SQ,
			qryMain.NEWPC,
			st.facility_id 
ORDER BY 	PICKUP_START_DTTM,
			SHIPMENT_ID,
			STOP_SEQ DESC,
			LOADING_SEQUENCE DESC,
			STORE_NBR,
			PRODUCT_CLASS
			;


-- =====================================================================
-- Specialty  (5 views)
-- =====================================================================

-- ---- PSE_CASE_V ----
CREATE OR REPLACE VIEW pse_case_v AS
  SELECT lpnh.ilpn_id                   AS case_nbr,
         '80'                           AS frm_whse_nbr,
         lpnh.whselocn                  AS to_whse_nbr,
         lpnh.asn_id                    AS asn_shpmt_nbr,
         lpnh.purchase_order_id         AS po_nbr,
         lpnh.asn_id                    AS whse_transfer_nbr,
         ite.item_id                    AS style,
         NULL                           AS sku_id,
         Substr(ite.description, 1, 40) AS sku_desc,
         NULL                           AS assort_nbr,
         dci.on_hand                    AS case_quantity,
         NULL                           AS package_type,
         lpnh.current_location_id       AS curr_locn_id,
         NULL                           AS LOCN_ID,
         lpnh.previous_location_id      AS prev_locn_id,
         lpnh.destination_location_id   AS dest_locn_id,
         NULL                           AS recv_locn_id,
         NULL                           AS pick_locn_id,
         Substr(lpnh.status, 1, 2)      AS ch_stat_code,
         lpnh.created_timestamp         AS recv_date_time,
         NULL                           AS transfer_date_time,
         NULL                           AS accepted_date_time,
         '00'                           AS stat_code,
         lpnh.updated_timestamp         AS mod_date_time,
         lpnh.created_timestamp         AS create_date_time,
         Substr(lpnh.updated_by, 1, 15) AS user_id
  FROM   (SELECT ( CASE
                     WHEN lpnx.current_location_id NOT IN (
                          'HRXTDZ0180R', 'HRXTSZ01' )
                          THEN '70'
                     WHEN lpnx.current_location_id IN (
                          'HRXTDZ0180R', 'HRXTSZ01'
                                                      ) THEN
                     ' '
                     WHEN lpnx.current_location_id LIKE 'P%' THEN '70'
                   END ) whselocn,
                 lpnx.*
          FROM   default_dcinventory_dci_ilpn lpnx
          WHERE  lpnx.__hevo__marked_deleted = 'false'
                 AND lpnx.previous_location_id IN ( 'HRXTDZ0180R', 'HRXTSZ01' )
                 AND lpnx.status < '9000'
                 AND lpnx.current_location_id NOT LIKE 'P%') lpnh
         inner join (SELECT dci.*
                     FROM   default_dcinventory_dci_inventory dci
                     WHERE  dci.org_id = 'D0080'
                            AND dci.__hevo__marked_deleted = 'false') dci
                 ON dci.ilpn_id = lpnh.ilpn_id
         inner join (SELECT ite.*
                     FROM   default_item_master_ite_item ite
                     WHERE  ite.profile_id = 'D0080'
                            AND ext_gegl_dcxx_virtual_whse = 'DC80-85') ite
                 ON lpnh.item_id = ite.item_id;


-- ---- SIS_V ----
CREATE OR REPLACE VIEW sis_v AS select default_item_master_ite_item.profile_id as profile_id, 
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as EXT_GEGLDCXXVIRTUALWHSE,
          DEFAULT_ITEM_MASTER_ITE_ITEM.EXT_GEGL_DCXX_VIRTUAL_WHSE as CO,
          DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID as ITEM,
          DEFAULT_ITEM_MASTER_ITE_ITEM.SHORT_DESCRIPTION as ITEM_DESCRIPTION,
          '   ' as SPL_INSTR_2,
          DEFAULT_ITEM_MASTER_ITE_ITEM.LPN_PER_TIER as LPN_PER_TIER,
          min(DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_BARCODE) as LOCATION_BARCODE,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.WEIGHT as UNIT_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.VOLUME as UNIT_VOLUME,
          DEFAULT_ITEM_MASTER_ITE_ITEM.TIERS_PER_PALLET as LPN_PER_PALLET,
          sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) as BOH_QTY,
          inv0.sum_on_hand as PICK_LOCN_QTY,
          inv1.sum_on_hand as ILPN_QTY,
          sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) as INV_ALLOC_INV,
          rec0.sum_shipped_quantity as INV_QTY_IN_TRAN,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE as INV_UNIT_PRICE,
          sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) as INV_NOT_ALLOC_QTY,
          DEFAULT_ITEM_MASTER_ITE_ITEM.CATCH_WEIGHT_ITEM as INV_CATCH_WT,
          sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ON_HAND, 0)) - sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.ALLOCATED, 0)) + sum(nvl(DEFAULT_DCINVENTORY_DCI_INVENTORY.TO_BE_FILLED, 0)) as INV_QTY_TO_BE_ALLOC,
          DEFAULT_ITEM_MASTER_ITE_ITEM.PK as SKU_ID,
          DEFAULT_ITEM_MASTER_ITE_ITEM.AVERAGE_WEIGHT AS ITEM_AVG_WT,
          DEFAULT_ITEM_MASTER_ITE_ITEM.UNIT_PRICE as ITEM_UNIT_PRICE
    from DEFAULT_ITEM_MASTER_ITE_ITEM
    join DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE on DEFAULT_ITEM_MASTER_ITE_ITEM.PK = DEFAULT_ITEM_MASTER_ITE_ITEM_PACKAGE.ITEM_PK


    left join DEFAULT_DCINVENTORY_DCI_INVENTORY on DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = DEFAULT_DCINVENTORY_DCI_INVENTORY.ITEM_ID
    left join DEFAULT_DCINVENTORY_DCI_LOCATION on DEFAULT_DCINVENTORY_DCI_INVENTORY.LOCATION_ID = DEFAULT_DCINVENTORY_DCI_LOCATION.LOCATION_ID


    left join (select item_id, sum(on_hand) as sum_on_hand from default_dcinventory_dci_inventory where inventory_container_type_id != 'ILPN' group by item_id) inv0 on DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = inv0.item_id
    left join (select item_id, sum(on_hand) as sum_on_hand from default_dcinventory_dci_inventory where inventory_container_type_id = 'ILPN' group by item_id) inv1 on DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID = inv1.item_id
    left join (select item_id, sum(shipped_quantity) as sum_shipped_quantity from DEFAULT_RECEIVING_RCV_ASN_LINE where asn_id in (select asn_id from default_receiving_rcv_asn where asn_origin_type_id in ('W','M','S','C')) group by item_id) rec0 on rec0.ITEM_ID = DEFAULT_ITEM_MASTER_ITE_ITEM.ITEM_ID
    where default_item_master_ite_item.process = 'ItemExportService'
    group by default_item_master_ite_item.profile_id,
    default_item_master_ite_item.ext_gegl_dcxx_virtual_whse,
    default_item_master_ite_item.item_id,
    default_item_master_ite_item.short_description,
    default_item_master_ite_item.lpn_per_tier,
    default_item_master_ite_item_package.weight,
    default_item_master_ite_item_package.volume,
    default_item_master_ite_item.tiers_per_pallet,
    default_item_master_ite_item.unit_price,
    default_item_master_ite_item.catch_weight_item,
    default_item_master_ite_item.pk,
    default_item_master_ite_item.average_weight,
    inv0.sum_on_hand,
    inv1.sum_on_hand,
    rec0.sum_shipped_quantity;


-- ---- ITEM_FIRST_RCPT ----
CREATE OR REPLACE VIEW item_first_rcpt AS
SELECT '270140' as ITEM_ID, CAST('1997-01-07' AS DATE) AS FIRST_RCPT_DATE;


-- ---- TIME_DIFF ----
CREATE OR REPLACE VIEW time_diff AS
SELECT 'DCI' component, datediff(MINUTE,max(from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCINVENTORY_DCI_INVENTORY
WHERE to_char(from_utc_timestamp(default_dcinventory_dci_inventory.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'PIX' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_PIX_PIX_PIX_ENTRY.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_PIX_PIX_PIX_ENTRY
WHERE to_char(from_utc_timestamp(DEFAULT_PIX_PIX_PIX_ENTRY.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'TSK' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_TASK_TSK_TASK.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_TASK_TSK_TASK
WHERE to_char(from_utc_timestamp(DEFAULT_TASK_TSK_TASK.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'TSK_DTL' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_TASK_TSK_TASK_DETAIL.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_TASK_TSK_TASK_DETAIL
WHERE to_char(from_utc_timestamp(DEFAULT_TASK_TSK_TASK_DETAIL.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'ORIG_ORD' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORIGINAL_ORDER.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCORDER_DCO_ORIGINAL_ORDER
WHERE to_char(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORIGINAL_ORDER.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York'))) 
UNION ALL
SELECT 'ORIG_ORD_DTL' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORIGINAL_ORDER_LINE.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCORDER_DCO_ORIGINAL_ORDER_LINE
WHERE to_char(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORIGINAL_ORDER_LINE.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'ORD' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORDER.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCORDER_DCO_ORDER
WHERE to_char(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORDER.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York'))) 
UNION ALL
SELECT 'ORD_DTL' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORDER_LINE.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCORDER_DCO_ORDER_LINE
WHERE to_char(from_utc_timestamp(DEFAULT_DCORDER_DCO_ORDER_LINE.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'LIA' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCINVENTORY_DCI_LOCATION_ITEM_ASSIGNMENT.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCINVENTORY_DCI_LOCATION_ITEM_ASSIGNMENT
WHERE to_char(from_utc_timestamp(DEFAULT_DCINVENTORY_DCI_LOCATION_ITEM_ASSIGNMENT.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'LCU' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_DCINVENTORY_DCI_LOCATION_CAPACITY_USAGE.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_DCINVENTORY_DCI_LOCATION_CAPACITY_USAGE
WHERE to_char(from_utc_timestamp(DEFAULT_DCINVENTORY_DCI_LOCATION_CAPACITY_USAGE.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'OLPN' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_PICKPACK_PPK_OLPN.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_PICKPACK_PPK_OLPN
WHERE to_char(from_utc_timestamp(DEFAULT_PICKPACK_PPK_OLPN.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')))
UNION ALL
SELECT 'OLPN_DTL' component, datediff(MINUTE,max(from_utc_timestamp(DEFAULT_PICKPACK_PPK_OLPN_DETAIL.updated_timestamp, 'America/New_York')), from_utc_timestamp(sysdate(, 'America/New_York'))) time_diff
FROM DEFAULT_PICKPACK_PPK_OLPN_DETAIL
WHERE to_char(from_utc_timestamp(DEFAULT_PICKPACK_PPK_OLPN_DETAIL.updated_timestamp, 'America/New_York'), 'YYYY-MM-DD') = to_char(from_utc_timestamp(sysdate(, 'America/New_York')), 'YYYY-MM-DD')
AND to_date(to_timestamp_ltz(to_char(__hevo__loaded_at))) = to_date(from_utc_timestamp(sysdate(, 'America/New_York')));


-- ---- MISHA_TEST_V ----
CREATE OR REPLACE VIEW misha_test_v AS   SELECT
    PO.ORG_ID AS "Org ID",
    PO.PURCHASE_ORDER_ID AS "PO ID",
    CONCAT(PO.ORG_ID, ' ', PO.PURCHASE_ORDER_ID) AS "Concat PO",
    POS.DESCRIPTION AS "PO Status"
FROM DEFAULT_RECEIVING_RCV_PURCHASE_ORDER PO
INNER JOIN DEFAULT_RECEIVING_RCV_PURCHASE_ORDER_STATUS POS 
    ON PO.PURCHASE_ORDER_STATUS = POS.PURCHASE_ORDER_STATUS_ID;


SHOW VIEWS IN gold_lift_shift;