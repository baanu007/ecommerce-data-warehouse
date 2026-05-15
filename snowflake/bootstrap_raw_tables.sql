/*
    bootstrap_raw_tables.sql
    ---------------------------------------------------------------
    Create RAW-layer tables that dbt's `source()` statements expect.
    These are the landing tables that ingestion fills. Once they're
    in place, `dbt seed` + `dbt run` will build everything downstream.
    ---------------------------------------------------------------
*/

use role transform;
use warehouse transform_wh;
use database ecommerce;
use schema raw;

-- ---------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------
create table if not exists customers (
    customer_id          string,
    first_name           string,
    last_name            string,
    email                string,
    phone_number         string,
    date_of_birth        date,
    gender               string,
    billing_address      string,
    billing_city         string,
    billing_state        string,
    billing_zip          string,
    billing_country      string,
    registration_date    date,
    customer_segment     string,
    is_active            boolean,
    email_opt_in         boolean,
    sms_opt_in           boolean,
    acquisition_source   string,
    created_at           timestamp_ntz,
    updated_at           timestamp_ntz,
    _loaded_at           timestamp_ntz default current_timestamp()
);

-- ---------------------------------------------------------------
-- products
-- ---------------------------------------------------------------
create table if not exists products (
    product_id           string,
    product_name         string,
    product_description  string,
    sku                  string,
    category             string,
    subcategory          string,
    brand                string,
    cost_price           number(10, 2),
    list_price           number(10, 2),
    sale_price           number(10, 2),
    stock_quantity       integer,
    reorder_level        integer,
    is_active            boolean,
    is_featured          boolean,
    weight_kg            number(8, 2),
    supplier_id          string,
    created_at           timestamp_ntz,
    updated_at           timestamp_ntz,
    _loaded_at           timestamp_ntz default current_timestamp()
);

-- ---------------------------------------------------------------
-- orders (order header)
-- ---------------------------------------------------------------
create table if not exists orders (
    order_id             string,
    customer_id          string,
    product_id           string,                -- legacy denormalized column
    order_date           date,
    order_timestamp      timestamp_ntz,
    quantity             integer,
    unit_price           number(10, 2),
    discount_amount      number(10, 2),
    order_status         string,
    payment_method       string,
    shipping_address     string,
    shipping_city        string,
    shipping_state       string,
    shipping_zip         string,
    shipping_country     string,
    created_at           timestamp_ntz,
    updated_at           timestamp_ntz,
    _loaded_at           timestamp_ntz default current_timestamp()
);

-- ---------------------------------------------------------------
-- order_items (one row per line)
-- ---------------------------------------------------------------
create table if not exists order_items (
    order_item_id        string,
    order_id             string,
    product_id           string,
    quantity             integer,
    unit_price           number(10, 2),
    discount_amount      number(10, 2),
    created_at           timestamp_ntz,
    updated_at           timestamp_ntz,
    _loaded_at           timestamp_ntz default current_timestamp()
);

-- ---------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------
create table if not exists payments (
    payment_id           string,
    order_id             string,
    payment_method       string,
    amount               number(10, 2),
    status               string,
    payment_date         date,
    payment_timestamp    timestamp_ntz,
    created_at           timestamp_ntz,
    updated_at           timestamp_ntz,
    _loaded_at           timestamp_ntz default current_timestamp()
);

-- ---------------------------------------------------------------
-- inventory (daily snapshot)
-- ---------------------------------------------------------------
create table if not exists inventory (
    product_id           string,
    snapshot_date        date,
    stock_quantity       integer,
    inbound_quantity     integer,
    outbound_quantity    integer,
    warehouse_code       string,
    _loaded_at           timestamp_ntz default current_timestamp()
);
