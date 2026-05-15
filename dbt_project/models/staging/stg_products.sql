{{
    config(
        materialized='view',
        tags=['staging', 'daily']
    )
}}

with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        -- Primary Key
        product_id,
        
        -- Product Info
        trim(product_name) as product_name,
        trim(product_description) as product_description,
        sku,
        
        -- Categorization
        upper(trim(category)) as category,
        upper(trim(subcategory)) as subcategory,
        upper(trim(brand)) as brand,
        
        -- Pricing
        cost_price::decimal(10,2) as cost_price,
        list_price::decimal(10,2) as list_price,
        sale_price::decimal(10,2) as sale_price,
        
        -- Calculated margin
        case 
            when list_price > 0 
            then round((list_price - cost_price) / list_price * 100, 2)
            else 0 
        end as margin_percent,
        
        -- Inventory
        stock_quantity::int as stock_quantity,
        reorder_level::int as reorder_level,
        
        -- Flags
        is_active::boolean as is_active,
        is_featured::boolean as is_featured,
        
        -- Dimensions
        weight_kg::decimal(8,2) as weight_kg,
        
        -- Supplier
        supplier_id,
        
        -- Metadata
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at,
        current_timestamp as _loaded_at
        
    from source
    where product_id is not null
)

select * from renamed
