{{
    config(
        materialized='table',
        unique_key='product_key',
        tags=['marts', 'dimensions']
    )
}}

with products as (
    select * from {{ ref('stg_products') }}
),

product_sales as (
    select
        product_id,
        count(distinct order_id) as times_ordered,
        sum(quantity) as total_units_sold,
        sum(net_amount) as total_revenue
    from {{ ref('stg_orders') }}
    group by product_id
),

final as (
    select
        -- Surrogate Key
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        
        -- Natural Key
        p.product_id,
        p.sku,
        
        -- Product Attributes
        p.product_name,
        p.product_description,
        p.brand,
        p.category,
        p.subcategory,
        
        -- Pricing
        p.cost_price,
        p.list_price,
        p.sale_price,
        p.margin_percent,
        
        -- Current Price (use sale price if available)
        coalesce(p.sale_price, p.list_price) as current_price,
        
        -- Price Tier
        case
            when coalesce(p.sale_price, p.list_price) >= 500 then 'Premium'
            when coalesce(p.sale_price, p.list_price) >= 100 then 'Mid-Range'
            when coalesce(p.sale_price, p.list_price) >= 25 then 'Budget'
            else 'Economy'
        end as price_tier,
        
        -- Inventory
        p.stock_quantity,
        p.reorder_level,
        
        -- Stock Status
        case
            when p.stock_quantity = 0 then 'Out of Stock'
            when p.stock_quantity <= p.reorder_level then 'Low Stock'
            else 'In Stock'
        end as stock_status,
        
        -- Flags
        p.is_active,
        p.is_featured,
        
        -- Physical
        p.weight_kg,
        
        -- Sales Performance
        coalesce(s.times_ordered, 0) as times_ordered,
        coalesce(s.total_units_sold, 0) as total_units_sold,
        coalesce(s.total_revenue, 0) as total_revenue,
        
        -- Performance Tier
        case
            when coalesce(s.total_revenue, 0) >= 100000 then 'Star'
            when coalesce(s.total_revenue, 0) >= 10000 then 'Cash Cow'
            when coalesce(s.total_revenue, 0) >= 1000 then 'Question Mark'
            else 'Dog'
        end as performance_tier,
        
        -- Supplier
        p.supplier_id,
        
        -- Metadata
        p.created_at,
        p.updated_at,
        current_timestamp() as _loaded_at
        
    from products p
    left join product_sales s on p.product_id = s.product_id
)

select * from final
