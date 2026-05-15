-- Singular test: every order_item must point to a valid order.
-- This catches the case where an order header was hard-deleted upstream
-- but its line items are still landing in raw.order_items.

select
    oi.order_item_id,
    oi.order_id
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o on oi.order_id = o.order_id
where o.order_id is null
