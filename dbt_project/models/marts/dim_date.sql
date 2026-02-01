{{
    config(
        materialized='table',
        tags=['marts', 'dimensions', 'static']
    )
}}

{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2020-01-01' as date)",
    end_date="cast('2030-12-31' as date)"
) }}

, calendar as (
    select
        date_day as calendar_date,
        
        -- Date Key (YYYYMMDD format)
        to_number(to_char(date_day, 'YYYYMMDD')) as date_key,
        
        -- Year
        extract(year from date_day) as year,
        
        -- Quarter
        extract(quarter from date_day) as quarter,
        concat('Q', extract(quarter from date_day)) as quarter_name,
        concat(extract(year from date_day), '-Q', extract(quarter from date_day)) as year_quarter,
        
        -- Month
        extract(month from date_day) as month_number,
        to_char(date_day, 'Month') as month_name,
        to_char(date_day, 'Mon') as month_short_name,
        concat(extract(year from date_day), '-', lpad(extract(month from date_day)::text, 2, '0')) as year_month,
        
        -- Week
        extract(week from date_day) as week_of_year,
        extract(yearofweek from date_day) as year_of_week,
        
        -- Day
        extract(day from date_day) as day_of_month,
        extract(dayofyear from date_day) as day_of_year,
        extract(dow from date_day) as day_of_week,
        to_char(date_day, 'Day') as day_name,
        to_char(date_day, 'Dy') as day_short_name,
        
        -- Flags
        case 
            when extract(dow from date_day) in (0, 6) then true 
            else false 
        end as is_weekend,
        
        -- Relative dates
        case when date_day = current_date() then true else false end as is_today,
        datediff('day', date_day, current_date()) as days_ago,
        
        -- Fiscal Year (assuming July start)
        case 
            when extract(month from date_day) >= 7 
            then extract(year from date_day) + 1 
            else extract(year from date_day) 
        end as fiscal_year,
        
        case 
            when extract(month from date_day) >= 7 
            then extract(month from date_day) - 6 
            else extract(month from date_day) + 6 
        end as fiscal_month,
        
        -- Period Flags
        case when date_day >= dateadd('day', -7, current_date()) then true else false end as is_last_7_days,
        case when date_day >= dateadd('day', -30, current_date()) then true else false end as is_last_30_days,
        case when date_day >= dateadd('day', -90, current_date()) then true else false end as is_last_90_days,
        case when date_day >= dateadd('year', -1, current_date()) then true else false end as is_last_year
        
    from {{ ref('date_spine') }}
)

select * from calendar
