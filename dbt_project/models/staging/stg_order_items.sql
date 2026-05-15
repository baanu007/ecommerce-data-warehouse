{{
    config(
        materialized='view',
        tags=['staging', 'daily']
    )
}}

-- Line-item grain for orders. Where `stg_orders` is the order header,
-- this model owns per-product revenue components so downstream marts
-- can aggregate consistently.

with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed as (
    select
        -- Primary key
        order_item_id,

        -- Foreign keys
        order_id,
        product_id,

        -- Measures
        cast(quantity as integer) as quantity,
        cast(unit_price as decimal(10, 2)) as unit_price,
        cast(coalesce(discount_amount, 0) as decimal(10, 2)) as discount_amount,

        -- Derived: revenue components
        (cast(quantity as decimal(10, 2)) * cast(unit_price as decimal(10, 2)))
            as gross_amount,

        (
            cast(quantity as decimal(10, 2)) * cast(unit_price as decimal(10, 2))
            - cast(coalesce(discount_amount, 0) as decimal(10, 2))
        ) as net_amount,

        -- Metadata
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        current_timestamp as _loaded_at

    from source
    where order_item_id is not null
      and order_id is not null
      and product_id is not null
)

select * from renamed
