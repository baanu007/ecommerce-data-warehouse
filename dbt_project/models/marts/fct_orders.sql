{{
    config(
        materialized='incremental',
        unique_key='order_line_key',
        incremental_strategy='merge',
        tags=['marts', 'facts']
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

customers as (
    select customer_key, customer_id 
    from {{ ref('dim_customers') }}
),

products as (
    select product_key, product_id, cost_price
    from {{ ref('dim_products') }}
),

date_spine as (
    select date_key, calendar_date
    from {{ ref('dim_date') }}
),

final as (
    select
        -- Surrogate Key
        {{ dbt_utils.generate_surrogate_key(['o.order_id', 'o.product_id']) }} as order_line_key,
        
        -- Foreign Keys
        c.customer_key,
        p.product_key,
        d.date_key,
        
        -- Natural Keys (for debugging)
        o.order_id,
        o.customer_id,
        o.product_id,
        
        -- Date/Time
        o.order_date,
        o.order_timestamp,
        extract(year from o.order_date) as order_year,
        extract(month from o.order_date) as order_month,
        extract(day from o.order_date) as order_day,
        extract(dow from o.order_date) as order_day_of_week,
        extract(hour from o.order_timestamp) as order_hour,
        
        -- Order Attributes
        o.order_status,
        o.payment_method,
        
        -- Quantities
        o.quantity,
        
        -- Pricing
        o.unit_price,
        o.discount_amount,
        o.gross_amount,
        o.net_amount,
        
        -- Costs & Margins
        p.cost_price,
        (o.quantity * p.cost_price) as total_cost,
        (o.net_amount - (o.quantity * p.cost_price)) as gross_profit,
        
        -- Margin Percentage
        case 
            when o.net_amount > 0 
            then round(((o.net_amount - (o.quantity * p.cost_price)) / o.net_amount) * 100, 2)
            else 0 
        end as margin_percent,
        
        -- Flags
        case when o.discount_amount > 0 then true else false end as is_discounted,
        case when o.order_status = 'COMPLETED' then true else false end as is_completed,
        case when o.order_status = 'RETURNED' then true else false end as is_returned,
        
        -- Shipping
        o.shipping_city,
        o.shipping_state,
        o.shipping_country,
        
        -- Metadata
        o.created_at,
        o.updated_at,
        current_timestamp() as _loaded_at
        
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join products p on o.product_id = p.product_id
    left join date_spine d on o.order_date = d.calendar_date
)

select * from final
