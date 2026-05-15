{{
    config(
        materialized='view',
        tags=['staging', 'daily']
    )
}}

with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        -- Primary Key
        customer_id,
        
        -- Customer Info
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        concat(trim(first_name), ' ', trim(last_name)) as full_name,
        lower(trim(email)) as email,
        phone_number,
        
        -- Demographics
        date_of_birth::date as date_of_birth,
        datediff('year', cast(date_of_birth as date), current_date) as age,
        upper(trim(gender)) as gender,
        
        -- Address
        billing_address,
        billing_city,
        upper(trim(billing_state)) as billing_state,
        billing_zip,
        upper(trim(billing_country)) as billing_country,
        
        -- Account Info
        registration_date::date as registration_date,
        upper(trim(customer_segment)) as customer_segment,
        is_active::boolean as is_active,
        
        -- Marketing
        email_opt_in::boolean as email_opt_in,
        sms_opt_in::boolean as sms_opt_in,
        upper(trim(acquisition_source)) as acquisition_source,
        
        -- Metadata
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at,
        current_timestamp as _loaded_at
        
    from source
    where customer_id is not null
)

select * from renamed
