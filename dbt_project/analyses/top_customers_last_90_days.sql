-- Top 25 customers by net revenue in the trailing 90 days.
-- Use:  dbt compile -s top_customers_last_90_days
-- This file is a one-off analytical query; it is NOT materialized.

with recent_orders as (
    select *
    from {{ ref('fct_orders') }}
    where order_date >= dateadd('day', -90, current_date)
      and is_completed
),

ranked as (
    select
        c.customer_id,
        c.full_name,
        c.email,
        c.value_tier,
        c.customer_status,
        sum(o.net_amount) as revenue_90d,
        count(*)          as orders_90d
    from recent_orders o
    join {{ ref('dim_customer') }} c
      on o.customer_key = c.customer_key
    group by 1, 2, 3, 4, 5
)

select *
from ranked
order by revenue_90d desc
limit 25
