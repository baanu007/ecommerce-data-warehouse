-- Asserts that fct_orders' customer_key resolves to the dim_customer
-- SCD2 version that was current on the order_date.
--
-- Failure mode this guards against: regressing the SCD2 temporal join back
-- to a `where is_current = true` join, which would bind historical orders
-- to today's customer state.
--
-- Returns rows ONLY when the join is incorrect (test passes when zero rows).

with orders as (
    select
        order_id,
        order_date,
        customer_key
    from {{ ref('fct_orders') }}
    where customer_key is not null
),

joined as (
    select
        o.order_id,
        o.order_date,
        o.customer_key,
        dc.valid_from,
        dc.valid_to
    from orders o
    left join {{ ref('dim_customer') }} dc
      on o.customer_key = dc.customer_key
)

select *
from joined
where
    -- No matching dim row at all -> broken FK
    valid_from is null
    -- Or the order_date falls outside this dim version's validity window
    or order_date < valid_from
    or (valid_to is not null and order_date >= valid_to)
