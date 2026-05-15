-- Singular test: no order_date in fct_orders should be in the future.
-- This guards against clock skew on the source system and bad timezone
-- conversions that occasionally produce tomorrow's date.

select
    order_id,
    order_date
from {{ ref('fct_orders') }}
where order_date > current_date
