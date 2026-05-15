{{
    config(
        materialized='ephemeral',
        tags=['intermediate']
    )
}}

-- Aggregates order-level facts to one row per customer. Used by
-- dim_customer for LTV/tier and by mart_customer_ltv for cohort analytics.

with line_items as (
    select * from {{ ref('int_order_items_with_products') }}
),

per_order as (
    -- Collapse line items to one row per order so we don't double-count orders.
    select
        order_id,
        customer_id,
        order_date,
        order_status,
        sum(net_amount)        as order_net_amount,
        sum(line_gross_profit) as order_gross_profit,
        count(*)               as order_line_count
    from line_items
    group by 1, 2, 3, 4
)

select
    customer_id,

    min(order_date) as first_order_date,
    max(order_date) as last_order_date,

    count(distinct order_id) as lifetime_orders,
    sum(order_line_count)    as lifetime_line_items,

    sum(order_net_amount)    as lifetime_revenue,
    sum(order_gross_profit)  as lifetime_gross_profit,

    case
        when count(distinct order_id) > 0
        then sum(order_net_amount) / count(distinct order_id)
        else 0
    end as avg_order_value,

    sum(case when order_status = 'RETURNED'  then 1 else 0 end) as returned_orders,
    sum(case when order_status = 'CANCELLED' then 1 else 0 end) as cancelled_orders

from per_order
group by customer_id
