{{
    config(
        materialized='table',
        unique_key='customer_key',
        tags=['marts', 'dimensions']
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(distinct order_id) as total_orders,
        sum(net_amount) as total_spent,
        avg(net_amount) as avg_order_value
    from {{ ref('stg_orders') }}
    group by customer_id
),

final as (
    select
        -- Surrogate Key
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_key,
        
        -- Natural Key
        c.customer_id,
        
        -- Customer Attributes
        c.first_name,
        c.last_name,
        c.full_name,
        c.email,
        c.phone_number,
        
        -- Demographics
        c.date_of_birth,
        c.age,
        c.gender,
        
        -- Location
        c.billing_city,
        c.billing_state,
        c.billing_country,
        
        -- Account Details
        c.registration_date,
        c.customer_segment,
        c.is_active,
        c.acquisition_source,
        
        -- Marketing Preferences
        c.email_opt_in,
        c.sms_opt_in,
        
        -- Order Metrics
        coalesce(o.first_order_date, c.registration_date) as first_order_date,
        o.last_order_date,
        coalesce(o.total_orders, 0) as lifetime_orders,
        coalesce(o.total_spent, 0) as lifetime_value,
        coalesce(o.avg_order_value, 0) as avg_order_value,
        
        -- Customer Tenure
        datediff('day', c.registration_date, current_date()) as days_since_registration,
        datediff('day', o.last_order_date, current_date()) as days_since_last_order,
        
        -- Customer Status
        case
            when o.last_order_date is null then 'Never Purchased'
            when datediff('day', o.last_order_date, current_date()) <= 30 then 'Active'
            when datediff('day', o.last_order_date, current_date()) <= 90 then 'At Risk'
            when datediff('day', o.last_order_date, current_date()) <= 180 then 'Lapsed'
            else 'Churned'
        end as customer_status,
        
        -- Value Tier
        case
            when coalesce(o.total_spent, 0) >= 10000 then 'Platinum'
            when coalesce(o.total_spent, 0) >= 5000 then 'Gold'
            when coalesce(o.total_spent, 0) >= 1000 then 'Silver'
            else 'Bronze'
        end as value_tier,
        
        -- Metadata
        c.created_at,
        c.updated_at,
        current_timestamp() as _loaded_at
        
    from customers c
    left join customer_orders o on c.customer_id = o.customer_id
)

select * from final
