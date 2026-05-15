-- Singular test: the daily revenue mart must never report a negative
-- net_revenue. If a refund-heavy day pushes it negative we want to know
-- about it loudly because it'll skew executive dashboards.

select
    order_date,
    net_revenue
from {{ ref('fct_daily_revenue') }}
where net_revenue < 0
