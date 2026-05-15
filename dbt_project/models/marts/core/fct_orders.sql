{{
    config(
        materialized='incremental',
        unique_key='order_id',
        on_schema_change='append_new_columns',
        tags=['marts', 'core', 'facts']
    )
}}

-- Order-header grain. One row per order. Line-item grain lives in fct_order_items.
--
-- Materialization: incremental on `order_date` so production runs append only
-- new orders. Use `dbt run --full-refresh --select fct_orders` to rebuild
-- from scratch when historical orders are corrected or back-filled.
--
-- Customer join: temporal join into the SCD2 `dim_customer` so historical
-- orders bind to the customer version that was current AT THE TIME of the
-- order, not whatever the customer looks like today.

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

dim_customer_versions as (
    -- All SCD2 versions; we'll temporal-join below so each order picks up
    -- the customer version that was in effect on its order_date.
    select
        customer_key,
        customer_id,
        valid_from,
        valid_to
    from {{ ref('dim_customer') }}
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
    -- Temporal SCD2 join: the order's customer_key resolves to the
    -- customer version that was current on o.order_date.
    left join dim_customer_versions c
        on o.customer_id = c.customer_id
        and o.order_date >= c.valid_from
        and (o.order_date < c.valid_to or c.valid_to is null)
    left join {{ ref('dim_date') }} d on o.order_date = d.calendar_date

    {% if is_incremental() %}
    -- Only process orders newer than what's already in the target table.
    -- Use --full-refresh to rebuild historical orders if back-filled.
    where o.order_date >= (select coalesce(max(order_date), date '1900-01-01') from {{ this }})
    {% endif %}
)

select * from final
