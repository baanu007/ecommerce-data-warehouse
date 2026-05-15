{{
    config(
        materialized='table',
        tags=['marts', 'marketing']
    )
}}

-- Monthly cohort retention. Each row = (signup cohort month, activity month).
-- Captures "of the customers who signed up in cohort X, how many ordered in
-- month X + N".

with customers as (
    select customer_id, registration_date
    from {{ ref('stg_customers') }}
),

cohort_assignment as (
    select
        customer_id,
        date_trunc('month', registration_date) as cohort_month
    from customers
),

orders as (
    select
        customer_id,
        date_trunc('month', order_date) as activity_month
    from {{ ref('stg_orders') }}
    where order_status not in ('CANCELLED')
    group by customer_id, date_trunc('month', order_date)
),

joined as (
    select
        ca.cohort_month,
        o.activity_month,
        ca.customer_id
    from cohort_assignment ca
    inner join orders o on ca.customer_id = o.customer_id
),

cohort_sizes as (
    select cohort_month, count(distinct customer_id) as cohort_size
    from cohort_assignment
    group by cohort_month
)

select
    j.cohort_month,
    j.activity_month,
    datediff('month', j.cohort_month, j.activity_month) as months_since_signup,

    count(distinct j.customer_id)                as active_customers,
    cs.cohort_size,

    case
        when cs.cohort_size > 0
        then 100.0 * count(distinct j.customer_id) / cs.cohort_size
        else 0
    end as retention_pct

from joined j
left join cohort_sizes cs on j.cohort_month = cs.cohort_month
group by j.cohort_month, j.activity_month, cs.cohort_size
