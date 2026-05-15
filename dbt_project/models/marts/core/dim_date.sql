{{
    config(
        materialized='table',
        tags=['marts', 'core', 'dimensions', 'static']
    )
}}

-- Static date dimension built from dbt_utils.date_spine.
-- Range covers 2020-01-01 .. 2030-12-31. Adjust dates as needed.

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

calendar as (
    select
        cast(date_day as date) as calendar_date,
        cast(strftime(cast(date_day as date), '%Y%m%d') as integer) as date_key,

        extract(year    from date_day) as year,
        extract(quarter from date_day) as quarter,
        'Q' || cast(extract(quarter from date_day) as varchar) as quarter_name,

        extract(month from date_day) as month_number,
        strftime(cast(date_day as date), '%B') as month_name,
        strftime(cast(date_day as date), '%b') as month_short_name,
        strftime(cast(date_day as date), '%Y-%m') as year_month,

        extract(week        from date_day) as week_of_year,
        extract(day         from date_day) as day_of_month,
        extract(dayofyear   from date_day) as day_of_year,
        extract(dayofweek   from date_day) as day_of_week,
        strftime(cast(date_day as date), '%A') as day_name,
        strftime(cast(date_day as date), '%a') as day_short_name,

        case
            when extract(dayofweek from date_day) in (0, 6) then true
            else false
        end as is_weekend,

        case when cast(date_day as date) = current_date then true else false end as is_today,
        datediff('day', cast(date_day as date), current_date) as days_ago,

        -- Fiscal year: July start
        case
            when extract(month from date_day) >= 7
            then extract(year from date_day) + 1
            else extract(year from date_day)
        end as fiscal_year,

        case
            when extract(month from date_day) >= 7
            then extract(month from date_day) - 6
            else extract(month from date_day) + 6
        end as fiscal_month

    from spine
)

select * from calendar
