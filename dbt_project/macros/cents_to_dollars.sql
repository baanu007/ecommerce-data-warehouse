{#
    Convert a cents column (integer) to dollars (decimal).

    Usage:
        select
            {{ cents_to_dollars('amount_cents') }} as amount_dollars
        from {{ ref('stg_payments') }}

    Args:
        column_name: name of the integer-cents column
        decimal_places: precision (default 2)
#}

{% macro cents_to_dollars(column_name, decimal_places=2) -%}
    (cast({{ column_name }} as numeric(18, {{ decimal_places }})) / 100)
{%- endmacro %}
