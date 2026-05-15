{{
    config(
        materialized='table',
        unique_key='order_item_key',
        tags=['marts', 'core', 'facts']
    )
}}

-- Line-item grain fact. One row per (order_id, product_id) line.

with items as (
    select * from {{ ref('int_order_items_with_products') }}
),

dim_customer_versions as (
    -- All SCD2 versions; temporal-join below so each line item binds to
    -- the customer version that was current on the order date.
    select
        customer_key,
        customer_id,
        valid_from,
        valid_to
    from {{ ref('dim_customer') }}
),

dim_product as (
    select product_key, product_id
    from {{ ref('dim_product') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['i.order_item_id']) }} as order_item_key,

    c.customer_key,
    p.product_key,
    d.date_key,

    i.order_item_id,
    i.order_id,
    i.customer_id,
    i.product_id,
    i.order_date,
    i.order_status,

    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.gross_amount,
    i.net_amount,
    i.cost_price,
    i.line_cost,
    i.line_gross_profit,

    case
        when i.net_amount > 0
        then round((i.line_gross_profit / i.net_amount) * 100, 2)
        else 0
    end as margin_percent,

    current_timestamp as _loaded_at

from items i
-- Temporal SCD2 join: line item picks up the customer version current on order_date.
left join dim_customer_versions c
    on i.customer_id = c.customer_id
    and i.order_date >= c.valid_from
    and (i.order_date < c.valid_to or c.valid_to is null)
left join dim_product  p on i.product_id  = p.product_id
left join {{ ref('dim_date') }} d on i.order_date = d.calendar_date
