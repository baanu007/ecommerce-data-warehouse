/*
    setup_warehouse.sql
    ---------------------------------------------------------------
    Bootstrap script for Snowflake. Creates the warehouse, database,
    schemas, roles and grants needed for this dbt project.

    Run as ACCOUNTADMIN (or a role with equivalent privileges).
    Replace `<YOUR_USER>` before running. No real account names,
    passwords, or keys are checked into this repo.
    ---------------------------------------------------------------
*/

-- =============================================================
-- 1. Warehouses
-- =============================================================
use role sysadmin;

create warehouse if not exists transform_wh
    with warehouse_size = 'xsmall'
         auto_suspend  = 60
         auto_resume   = true
         initially_suspended = true
         comment = 'Warehouse used by dbt and CI runs';

create warehouse if not exists reporting_wh
    with warehouse_size = 'small'
         auto_suspend  = 60
         auto_resume   = true
         initially_suspended = true
         comment = 'Warehouse used by BI tools (Power BI, Streamlit)';

-- =============================================================
-- 2. Database + schemas
-- =============================================================
create database if not exists ecommerce
    comment = 'E-commerce data warehouse - dbt managed';

use database ecommerce;

create schema if not exists raw          comment = 'Bronze: landed source tables';
create schema if not exists staging      comment = 'Silver: cleaned/typed views';
create schema if not exists intermediate comment = 'Intermediate building blocks';
create schema if not exists marts        comment = 'Gold: dimensional models';
create schema if not exists finance      comment = 'Finance subject area marts';
create schema if not exists marketing    comment = 'Marketing subject area marts';
create schema if not exists snapshots    comment = 'dbt SCD2 snapshots';
create schema if not exists seeds        comment = 'dbt seed reference tables';

-- =============================================================
-- 3. Roles
-- =============================================================
use role securityadmin;

-- TRANSFORM: used by dbt to build models. Read raw, write everything else.
create role if not exists transform;
grant role transform to role sysadmin;

-- REPORTER: used by BI tools. Read-only on marts.
create role if not exists reporter;
grant role reporter to role sysadmin;

-- LOADER: used by ingestion (Fivetran / Airbyte / python loader). Writes raw only.
create role if not exists loader;
grant role loader to role sysadmin;

-- =============================================================
-- 4. Grants
-- =============================================================
use role securityadmin;

-- TRANSFORM grants
grant usage on warehouse transform_wh to role transform;
grant usage on database ecommerce      to role transform;
grant usage on all schemas in database ecommerce       to role transform;
grant usage on future schemas in database ecommerce    to role transform;

-- Read on raw
grant select on all tables in schema ecommerce.raw     to role transform;
grant select on future tables in schema ecommerce.raw  to role transform;

-- Read/write on everything else dbt manages
grant all on schema ecommerce.staging      to role transform;
grant all on schema ecommerce.intermediate to role transform;
grant all on schema ecommerce.marts        to role transform;
grant all on schema ecommerce.finance      to role transform;
grant all on schema ecommerce.marketing    to role transform;
grant all on schema ecommerce.snapshots    to role transform;
grant all on schema ecommerce.seeds        to role transform;

-- REPORTER grants
grant usage on warehouse reporting_wh                                 to role reporter;
grant usage on database ecommerce                                     to role reporter;
grant usage on schema ecommerce.marts                                 to role reporter;
grant usage on schema ecommerce.finance                               to role reporter;
grant usage on schema ecommerce.marketing                             to role reporter;
grant select on all tables in schema ecommerce.marts                  to role reporter;
grant select on all tables in schema ecommerce.finance                to role reporter;
grant select on all tables in schema ecommerce.marketing              to role reporter;
grant select on future tables in schema ecommerce.marts               to role reporter;
grant select on future tables in schema ecommerce.finance             to role reporter;
grant select on future tables in schema ecommerce.marketing           to role reporter;

-- LOADER grants
grant usage on warehouse transform_wh                                 to role loader;
grant usage on database ecommerce                                     to role loader;
grant all   on schema ecommerce.raw                                   to role loader;

-- =============================================================
-- 5. User attachment (example - customize before running)
-- =============================================================
-- grant role transform to user <YOUR_USER>;
-- grant role reporter  to user <YOUR_USER>;
-- alter user <YOUR_USER> set default_role = transform;
