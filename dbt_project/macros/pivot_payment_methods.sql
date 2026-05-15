{#
    Pivot payment methods into one column per method, summing `value_column`.

    Usage:
        select
            order_id,
            {{ pivot_payment_methods(
                relation=ref('stg_payments'),
                pivot_column='payment_method',
                value_column='amount',
                methods=['CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL', 'APPLE_PAY', 'GIFT_CARD']
            ) }}
        from {{ ref('stg_payments') }}
        group by order_id

    This is a small showcase macro that demonstrates dynamic SQL generation
    in dbt without depending on dbt_utils.pivot (which works too but hides
    intent). Keeping it explicit so reviewers can read what's happening.
#}

{% macro pivot_payment_methods(relation, pivot_column, value_column, methods, agg='sum', prefix='pmt_') -%}
    {%- for method in methods -%}
        {{ agg }}(
            case
                when upper(trim({{ pivot_column }})) = '{{ method | upper }}'
                then {{ value_column }}
                else 0
            end
        ) as {{ prefix }}{{ method | lower }}
        {%- if not loop.last -%},{% endif %}
    {% endfor %}
{%- endmacro %}
