{{
    config(
        materialized='view',
        tags=['staging', 'daily']
    )
}}

-- Payment events at payment_id grain. A single order can have multiple
-- payments (split tender, refunds). Downstream marts dedupe/sum as needed.

with source as (
    select * from {{ source('raw', 'payments') }}
),

renamed as (
    select
        -- Primary key
        payment_id,

        -- Foreign keys
        order_id,

        -- Attributes (normalized to upper-snake for enum stability)
        upper(trim(payment_method)) as payment_method,
        upper(trim(status))         as payment_status,

        -- Measures
        cast(amount as decimal(10, 2)) as amount,

        -- Time
        cast(payment_date as date)       as payment_date,
        cast(payment_timestamp as timestamp) as payment_timestamp,

        -- Metadata
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        current_timestamp as _loaded_at

    from source
    where payment_id is not null
)

select * from renamed
