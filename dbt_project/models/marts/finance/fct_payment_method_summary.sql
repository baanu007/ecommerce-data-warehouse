{{
    config(
        materialized='table',
        tags=['marts', 'finance']
    )
}}

-- One row per (order_date, payment_method) summarising captured / refunded
-- amounts. Demonstrates the `pivot_payment_methods` macro in a real mart.

with payments as (
    select * from {{ ref('stg_payments') }}
),

orders as (
    select order_id, order_date
    from {{ ref('stg_orders') }}
),

joined as (
    select
        o.order_date,
        p.payment_method,
        p.payment_status,
        p.amount
    from payments p
    inner join orders o on p.order_id = o.order_id
)

select
    order_date,
    payment_method,
    count(*)                                                              as payment_count,
    sum(case when payment_status = 'CAPTURED' then amount else 0 end)     as captured_amount,
    sum(case when payment_status = 'REFUNDED' then amount else 0 end)     as refunded_amount,
    sum(case when payment_status = 'FAILED'   then 1 else 0 end)          as failed_count,
    sum(
        case
            when payment_status = 'CAPTURED' then amount
            when payment_status = 'REFUNDED' then -amount
            else 0
        end
    ) as net_amount
from joined
group by order_date, payment_method
