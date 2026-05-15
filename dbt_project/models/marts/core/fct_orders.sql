{{
    config(
        materialized='table',
        unique_key='order_key',
        tags=['marts', 'core', 'facts']
    )
}}

-- Order-header grain. One row per order. Line-item grain lives in fct_order_items.

with order_items as (
    select * from {{ ref('int_order_items_with_products') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select
        order_id,
        sum(case when payment_status = 'CAPTURED' then amount else 0 end) as captured_amount,
        sum(case when payment_status = 'REFUNDED' then amount else 0 end) as refunded_amount
    from {{ ref('stg_payments') }}
    group by order_id
),

dim_customer as (
    -- Only current version of each customer (SCD2 -> single row per natural key)
    select customer_key, customer_id
    from {{ ref('dim_customer') }}
    where is_current
),

order_agg as (
    select
        order_id,
        count(distinct order_item_id) as line_item_count,
        sum(quantity)                  as total_quantity,
        sum(gross_amount)              as gross_amount,
        sum(net_amount)                as net_amount,
        sum(line_cost)                 as total_cost,
        sum(line_gross_profit)         as gross_profit
    from order_items
    group by order_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_key,
        c.customer_key,
        d.date_key,

        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_timestamp,
        o.order_status,
        o.payment_method,

        oa.line_item_count,
        oa.total_quantity,
        oa.gross_amount,
        oa.net_amount,
        oa.total_cost,
        oa.gross_profit,

        case
            when oa.net_amount > 0
            then round((oa.gross_profit / oa.net_amount) * 100, 2)
            else 0
        end as margin_percent,

        coalesce(p.captured_amount, 0) as payments_captured,
        coalesce(p.refunded_amount, 0) as payments_refunded,

        case when o.order_status = 'COMPLETED' then true else false end as is_completed,
        case when o.order_status = 'RETURNED'  then true else false end as is_returned,
        case when o.order_status = 'CANCELLED' then true else false end as is_cancelled,

        o.shipping_city,
        o.shipping_state,
        o.shipping_country,

        o.created_at,
        o.updated_at,
        current_timestamp as _loaded_at

    from orders o
    left join order_agg   oa on o.order_id    = oa.order_id
    left join payments    p  on o.order_id    = p.order_id
    left join dim_customer c on o.customer_id = c.customer_id
    left join {{ ref('dim_date') }} d on o.order_date = d.calendar_date
)

select * from final
