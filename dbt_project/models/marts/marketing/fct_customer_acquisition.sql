{{
    config(
        materialized='table',
        tags=['marts', 'marketing']
    )
}}

-- Customer acquisition by month + source. Built off the current snapshot
-- of dim_customer so a customer's source attribution doesn't double-count
-- across SCD2 versions.

with customers as (
    select *
    from {{ ref('dim_customer') }}
    where is_current
)

select
    date_trunc('month', registration_date) as acquisition_month,
    coalesce(acquisition_source, 'UNKNOWN') as acquisition_source,

    count(*)                                                    as customers_acquired,
    sum(case when lifetime_orders > 0 then 1 else 0 end)        as customers_with_purchase,
    sum(lifetime_revenue)                                       as cohort_lifetime_revenue,
    sum(lifetime_orders)                                        as cohort_lifetime_orders,

    case
        when count(*) > 0
        then sum(lifetime_revenue) / count(*)
        else 0
    end as avg_customer_ltv,

    case
        when count(*) > 0
        then 100.0 * sum(case when lifetime_orders > 0 then 1 else 0 end) / count(*)
        else 0
    end as activation_rate_pct

from customers
where registration_date is not null
group by 1, 2
