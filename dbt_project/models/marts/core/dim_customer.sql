{{
    config(
        materialized='table',
        unique_key='customer_key',
        tags=['marts', 'core', 'dimensions']
    )
}}

-- Customer dimension. Sourced from the SCD2 snapshot (`snap_customers`)
-- so we get historical versions of email / billing address / loyalty tier
-- preserved. Each row is one (customer_id, version) pair.

with snap as (
    select * from {{ ref('snap_customers') }}
),

ltv as (
    select * from {{ ref('int_customer_lifetime_value') }}
),

final as (
    select
        -- Surrogate key: customer + version
        {{ dbt_utils.generate_surrogate_key(['s.customer_id', 's.dbt_valid_from']) }}
            as customer_key,

        -- Natural key
        s.customer_id,

        -- SCD2 version metadata
        s.dbt_valid_from as valid_from,
        s.dbt_valid_to   as valid_to,
        case when s.dbt_valid_to is null then true else false end as is_current,

        -- Customer attributes (versioned)
        s.first_name,
        s.last_name,
        s.full_name,
        s.email,
        s.phone_number,
        s.date_of_birth,
        s.age,
        s.gender,
        s.billing_address,
        s.billing_city,
        s.billing_state,
        s.billing_country,
        s.registration_date,
        s.customer_segment,
        s.is_active,
        s.acquisition_source,
        s.email_opt_in,
        s.sms_opt_in,

        -- Lifetime metrics (computed once on the most recent version only;
        -- historical versions still get the same totals — this is a common
        -- pattern when the metrics aren't time-sliced).
        coalesce(l.first_order_date, s.registration_date) as first_order_date,
        l.last_order_date,
        coalesce(l.lifetime_orders, 0)        as lifetime_orders,
        coalesce(l.lifetime_revenue, 0)       as lifetime_revenue,
        coalesce(l.lifetime_gross_profit, 0)  as lifetime_gross_profit,
        coalesce(l.avg_order_value, 0)        as avg_order_value,

        -- Recency / status (only meaningful on current row)
        datediff('day', l.last_order_date, current_date) as days_since_last_order,
        case
            when l.last_order_date is null then 'Never Purchased'
            when datediff('day', l.last_order_date, current_date) <= 30  then 'Active'
            when datediff('day', l.last_order_date, current_date) <= 90  then 'At Risk'
            when datediff('day', l.last_order_date, current_date) <= 180 then 'Lapsed'
            else 'Churned'
        end as customer_status,

        case
            when coalesce(l.lifetime_revenue, 0) >= 10000 then 'Platinum'
            when coalesce(l.lifetime_revenue, 0) >= 5000  then 'Gold'
            when coalesce(l.lifetime_revenue, 0) >= 1000  then 'Silver'
            else 'Bronze'
        end as value_tier,

        current_timestamp as _loaded_at

    from snap s
    left join ltv l on s.customer_id = l.customer_id
)

select * from final
