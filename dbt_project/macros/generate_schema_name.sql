{#
    Custom schema generation logic.

    Behavior:
      - In `prod` target, we honor the `+schema:` config from dbt_project.yml
        directly (no prefix), so models land in clean schemas like MARTS, STAGING.
      - In any non-prod target (dev, ci, local), we prefix with the target's
        configured `schema` to keep developer schemas isolated, e.g.:
            DEV_STAGING, DEV_MARTS, CI_MARTS

    This is the canonical dbt pattern for dev/prod schema separation.
    See: https://docs.getdbt.com/docs/build/custom-schemas
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if target.name == 'prod' -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- else -%}

        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
