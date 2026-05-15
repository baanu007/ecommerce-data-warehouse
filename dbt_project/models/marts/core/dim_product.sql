{{
    config(
        materialized='table',
        unique_key='product_key',
        tags=['marts', 'core', 'dimensions']
    )
}}

-- Type-1 product dimension. We track the current state of the catalog.
-- (If product-history tracking is needed, a `snap_products` snapshot
--  can be added alongside `snap_customers`.)

with products as (
    select * from {{ ref('stg_products') }}
),

product_sales as (
    select
        product_id,
        count(distinct order_id) as times_ordered,
        sum(quantity)            as total_units_sold,
        sum(net_amount)          as total_revenue,
        sum(line_gross_profit)   as total_gross_profit
    from {{ ref('int_order_items_with_products') }}
    group by product_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,

        p.product_id,
        p.sku,
        p.product_name,
        p.product_description,
        p.brand,
        p.category,
        p.subcategory,

        p.cost_price,
        p.list_price,
        p.sale_price,
        coalesce(p.sale_price, p.list_price) as current_price,
        p.margin_percent,

        case
            when coalesce(p.sale_price, p.list_price) >= 500 then 'Premium'
            when coalesce(p.sale_price, p.list_price) >= 100 then 'Mid-Range'
            when coalesce(p.sale_price, p.list_price) >= 25  then 'Budget'
            else 'Economy'
        end as price_tier,

        p.stock_quantity,
        p.reorder_level,
        case
            when p.stock_quantity = 0 then 'Out of Stock'
            when p.stock_quantity <= p.reorder_level then 'Low Stock'
            else 'In Stock'
        end as stock_status,

        p.is_active,
        p.is_featured,
        p.weight_kg,
        p.supplier_id,

        coalesce(s.times_ordered, 0)     as times_ordered,
        coalesce(s.total_units_sold, 0)  as total_units_sold,
        coalesce(s.total_revenue, 0)     as total_revenue,
        coalesce(s.total_gross_profit, 0) as total_gross_profit,

        case
            when coalesce(s.total_revenue, 0) >= 100000 then 'Star'
            when coalesce(s.total_revenue, 0) >= 10000  then 'Cash Cow'
            when coalesce(s.total_revenue, 0) >= 1000   then 'Question Mark'
            else 'Dog'
        end as performance_tier,

        current_timestamp as _loaded_at

    from products p
    left join product_sales s on p.product_id = s.product_id
)

select * from final
