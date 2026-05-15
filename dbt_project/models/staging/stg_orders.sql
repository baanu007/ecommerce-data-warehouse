{{
    config(
        materialized='view',
        tags=['staging', 'daily']
    )
}}

with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        -- Primary Key
        order_id,
        
        -- Foreign Keys
        customer_id,
        product_id,
        
        -- Order Details
        order_date::date as order_date,
        order_timestamp::timestamp as order_timestamp,
        quantity::int as quantity,
        unit_price::decimal(10,2) as unit_price,
        discount_amount::decimal(10,2) as discount_amount,
        
        -- Calculated Fields
        (quantity * unit_price)::decimal(10,2) as gross_amount,
        (quantity * unit_price - coalesce(discount_amount, 0))::decimal(10,2) as net_amount,
        
        -- Order Status
        upper(trim(order_status)) as order_status,
        upper(trim(payment_method)) as payment_method,
        
        -- Shipping
        shipping_address,
        shipping_city,
        upper(trim(shipping_state)) as shipping_state,
        shipping_zip,
        upper(trim(shipping_country)) as shipping_country,
        
        -- Metadata
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at,
        current_timestamp as _loaded_at
        
    from source
    where order_id is not null
)

select * from renamed
