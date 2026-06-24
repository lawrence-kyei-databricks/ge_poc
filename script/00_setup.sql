-- Databricks notebook source
-- DBTITLE 1,Setup: Catalog and Schemas
-- =====================================================================
-- Giant Eagle: 00_setup.sql
-- Catalog and schema provisioning for Manhattan WMS reporting on Databricks
-- Run order: 00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08
-- =====================================================================
--
-- CUSTOMER CONFIGURATION:
-- Update the catalog name below to match your environment.
-- Default: ge_poc (POC catalog)
-- Production: recommend a dedicated catalog (e.g. ge_manhattan_wms)
--
-- SCHEMA MAPPING (Snowflake → Databricks):
--   AGISIGHT_PROD.MAWM_ODM base tables → {catalog}.bronze
--   AGISIGHT_PROD.MAWM_ODM views       → {catalog}.gold_lift_shift
--   Lakehouse-native model              → {catalog}.gold_native
--
-- PREREQUISITES:
-- 1. You must have CREATE CATALOG or USE CATALOG privileges
-- 2. For production: Lakeflow Connect populates bronze from Manhattan WMS
-- 3. For POC testing: scripts 01/02 create sample bronze tables
-- =====================================================================

-- Catalog (create only if you don't already have one for this work)
CREATE CATALOG IF NOT EXISTS ge_poc
  COMMENT 'Giant Eagle Manhattan WMS POC: Gold layer remodel track';

USE CATALOG ge_poc;

-- Schemas
CREATE SCHEMA IF NOT EXISTS bronze
  COMMENT 'Reverse-engineered Manhattan base tables (sample). Superseded by real Lakeflow Connect Bronze when source pipeline lands.';

CREATE SCHEMA IF NOT EXISTS gold_lift_shift
  COMMENT 'Version A: 1:1 Delta-view ports of the Snowflake views.';

CREATE SCHEMA IF NOT EXISTS gold_native
  COMMENT 'Version B: lakehouse-native dimensional model. Conformed dimensions + facts + compatibility views.';

-- Confirm
SHOW SCHEMAS IN ge_poc;