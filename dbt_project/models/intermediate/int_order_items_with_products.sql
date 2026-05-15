{{
    config(
        materialized='ephemeral',
        tags=['intermediate']
    )
}}

-- Join order items to product attributes once so downstream marts don't
-- repeat the same join. Carries cost information needed for profitability.

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select
        product_id,
        product_name,
        brand,
        category,
        subcategory,
        cost_price,
        list_price
    from {{ ref('stg_products') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_date,
        order_status
    from {{ ref('stg_orders') }}
)

select
    oi.order_item_id,
    oi.order_id,
    oi.product_id,

    o.customer_id,
    o.order_date,
    o.order_status,

    p.product_name,
    p.brand,
    p.category,
    p.subcategory,

    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    oi.gross_amount,
    oi.net_amount,

    p.cost_price,
    (oi.quantity * p.cost_price) as line_cost,
    (oi.net_amount - (oi.quantity * p.cost_price)) as line_gross_profit

from order_items oi
left join orders   o on oi.order_id   = o.order_id
left join products p on oi.product_id = p.product_id
