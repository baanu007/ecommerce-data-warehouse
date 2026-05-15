{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['email', 'billing_address', 'billing_city', 'billing_state', 'customer_segment'],
        invalidate_hard_deletes=True
    )
}}

-- SCD Type 2 snapshot of customers.
--
-- We use the `check` strategy on a small set of slowly-changing attributes
-- rather than `timestamp` because the source `updated_at` is touched by
-- non-meaningful changes (e.g. login activity) in this synthetic dataset.
--
-- Each `dbt snapshot` run inserts a new row when any of the `check_cols`
-- changes, populating `dbt_valid_from` / `dbt_valid_to`. `dim_customer`
-- reads this directly.

select
    customer_id,
    first_name,
    last_name,
    concat(trim(first_name), ' ', trim(last_name)) as full_name,
    lower(trim(email)) as email,
    phone_number,
    cast(date_of_birth as date) as date_of_birth,
    datediff('year', cast(date_of_birth as date), current_date) as age,
    upper(trim(gender)) as gender,
    billing_address,
    billing_city,
    upper(trim(billing_state))   as billing_state,
    billing_zip,
    upper(trim(billing_country)) as billing_country,
    cast(registration_date as date) as registration_date,
    upper(trim(customer_segment)) as customer_segment,
    cast(is_active as boolean)    as is_active,
    cast(email_opt_in as boolean) as email_opt_in,
    cast(sms_opt_in as boolean)   as sms_opt_in,
    upper(trim(acquisition_source)) as acquisition_source

from {{ source('raw', 'customers') }}
where customer_id is not null

{% endsnapshot %}
