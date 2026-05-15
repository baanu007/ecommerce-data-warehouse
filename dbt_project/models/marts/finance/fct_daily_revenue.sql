{{
    config(
        materialized='table',
        tags=['marts', 'finance']
    )
}}

-- Daily revenue, profit and order counts. Drives the finance dashboard.

with orders as (
    select * from {{ ref('fct_orders') }}
)

select
    order_date,
    d.date_key,
    d.year,
    d.quarter,
    d.month_number,
    d.year_month,
    d.is_weekend,

    count(*)                                                       as total_orders,
    count(distinct customer_id)                                    as unique_customers,
    sum(case when is_completed then 1 else 0 end)                  as completed_orders,
    sum(case when is_returned  then 1 else 0 end)                  as returned_orders,
    sum(case when is_cancelled then 1 else 0 end)                  as cancelled_orders,

    sum(gross_amount)        as gross_revenue,
    sum(net_amount)          as net_revenue,
    sum(total_cost)          as total_cost,
    sum(gross_profit)        as gross_profit,
    sum(payments_captured)   as payments_captured,
    sum(payments_refunded)   as payments_refunded,

    case
        when count(*) > 0 then sum(net_amount) / count(*)
        else 0
    end as average_order_value

from orders o
left join {{ ref('dim_date') }} d on o.order_date = d.calendar_date
group by order_date, d.date_key, d.year, d.quarter, d.month_number, d.year_month, d.is_weekend
