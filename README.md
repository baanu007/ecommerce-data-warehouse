# 🛒 E-Commerce Data Warehouse

A production-ready analytics warehouse for an e-commerce platform — modeled
with **dbt**, deployable on **Snowflake**, and runnable locally on
**DuckDB** in under five minutes.

[![dbt](https://img.shields.io/badge/dbt-1.7-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com)
[![Snowflake](https://img.shields.io/badge/Snowflake-prod-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com)
[![DuckDB](https://img.shields.io/badge/DuckDB-local%20dev-FFF000?logo=duckdb&logoColor=black)](https://duckdb.org)
[![CI](https://github.com/baanu007/ecommerce-data-warehouse/actions/workflows/ci.yml/badge.svg)](https://github.com/baanu007/ecommerce-data-warehouse/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## ✨ What's in here

| Layer | Purpose | Models |
| --- | --- | --- |
| **Sources** | Raw landing tables defined as dbt sources, with **freshness** checks. | `orders`, `order_items`, `customers`, `products`, `payments`, `inventory` |
| **Staging** | One view per source. Typed, renamed, lightly cleaned. | `stg_orders`, `stg_order_items`, `stg_customers`, `stg_products`, `stg_payments` |
| **Intermediate** | Ephemeral building blocks reused across marts. | `int_order_items_with_products`, `int_customer_lifetime_value` |
| **Snapshots** | SCD Type 2 history of slowly-changing dimensions. | `snap_customers` (check strategy on email / address / segment) |
| **Marts — core** | Star schema. | `dim_customer` (SCD2), `dim_product`, `dim_date`, `fct_orders`, `fct_order_items` |
| **Marts — finance** | Revenue & payments rollups. | `fct_daily_revenue`, `fct_payment_method_summary` |
| **Marts — marketing** | Acquisition & retention. | `fct_customer_acquisition`, `fct_cohort_retention` |
| **Exposures** | Documented downstream BI consumers. | Power BI dashboards, Streamlit app |
| **Seeds** | Versioned reference data. | `country_codes`, `product_categories` |
| **Macros** | Reusable SQL. | `generate_schema_name`, `cents_to_dollars`, `pivot_payment_methods` |
| **Tests** | 70+ schema tests + 3 singular tests (`assert_positive_revenue`, `assert_referential_integrity_orders`, `assert_no_future_dates`). | |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              SOURCES (Bronze)                            │
│   raw.orders   raw.order_items   raw.customers                           │
│   raw.products raw.payments      raw.inventory                           │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                              STAGING (Silver)                            │
│   stg_orders  stg_order_items  stg_customers  stg_products  stg_payments │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                            INTERMEDIATE (ephemeral)                      │
│   int_order_items_with_products      int_customer_lifetime_value         │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                              MARTS (Gold)                                │
│                                                                          │
│   core/   dim_customer (SCD2)  dim_product   dim_date                    │
│           fct_orders           fct_order_items                           │
│                                                                          │
│   finance/   fct_daily_revenue           fct_payment_method_summary      │
│                                                                          │
│   marketing/ fct_customer_acquisition    fct_cohort_retention            │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                  📊  Power BI dashboards   |   🐍  Streamlit app
                          (modeled as dbt exposures)
```

> Lineage screenshots live in [`screenshots/`](screenshots/dbt-lineage.md) —
> generate them locally with `dbt docs generate && dbt docs serve`.

---

## 🚀 Quickstart — run locally with DuckDB (no Snowflake needed)

Everything below takes ~3 minutes on a laptop.

```bash
# 1. Clone + install
git clone https://github.com/baanu007/ecommerce-data-warehouse.git
cd ecommerce-data-warehouse
python -m venv venv && source venv/bin/activate     # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 2. Generate the synthetic CSVs + load them into DuckDB
python data/sample/generate.py
python data/sample/load_to_duckdb.py

# 3. Point dbt at the bundled DuckDB profile (profiles.yml lives in dbt_project/profiles/)
export DBT_PROFILES_DIR="$(pwd)/dbt_project/profiles"   # Windows: set DBT_PROFILES_DIR=%cd%\dbt_project\profiles
cd dbt_project

# 4. Build everything
dbt deps
dbt seed
dbt snapshot
dbt run
dbt test

# 5. Browse the docs + lineage
dbt docs generate
dbt docs serve
```

> The CI workflow in `.github/workflows/ci.yml` runs exactly this flow on
> every push, so you can copy the steps from there if anything drifts.

### Sample queries that work after `dbt run`

```sql
-- Daily revenue + profit
select order_date, net_revenue, gross_profit, total_orders
from finance.fct_daily_revenue
order by order_date desc
limit 14;

-- Top 10 products by gross profit
select product_name, brand, total_revenue, total_gross_profit
from marts.dim_product
order by total_gross_profit desc
limit 10;

-- LTV by acquisition channel
select acquisition_source,
       sum(customers_acquired)  as cohort_size,
       avg(avg_customer_ltv)    as avg_ltv,
       avg(activation_rate_pct) as avg_activation_pct
from marketing.fct_customer_acquisition
group by acquisition_source
order by avg_ltv desc;

-- Month-over-month retention curve
select cohort_month, months_since_signup, retention_pct
from marketing.fct_cohort_retention
order by cohort_month, months_since_signup;
```

---

## ❄️ Run in production with Snowflake

1. Run [`snowflake/setup_warehouse.sql`](snowflake/setup_warehouse.sql) as `ACCOUNTADMIN`
   to create the warehouse, database, schemas (`raw`, `staging`, `marts`, …) and the
   `TRANSFORM` / `REPORTER` / `LOADER` roles.
2. Run [`snowflake/bootstrap_raw_tables.sql`](snowflake/bootstrap_raw_tables.sql) as
   `TRANSFORM` to create the empty `raw.*` tables. Land data into them with Fivetran,
   Airbyte, or the included [`python/load_to_snowflake.py`](python/load_to_snowflake.py).
3. Copy [`dbt_project/profiles/snowflake_profile.yml.example`](dbt_project/profiles/snowflake_profile.yml.example)
   to `~/.dbt/profiles.yml` and fill in the env vars. No credentials live in the repo.
4. Build:

```bash
cd dbt_project
dbt deps
dbt source freshness                # checks the raw layer is fresh
dbt build --target prod
```

The custom `generate_schema_name` macro keeps dev/prod schemas isolated automatically:
in `prod` you get clean schemas like `MARTS`, `FINANCE`; in `dev` they're prefixed
(`DEV_BAANU_MARTS`, etc.).

---

## 🧪 Data quality

Every model has tests. Highlights:

- **Schema tests** (in `models/**/_schema.yml`): `not_null`, `unique`, `accepted_values`,
  `relationships`, plus `dbt_utils.accepted_range` on numeric measures.
- **Singular tests** (in `tests/`):
  - `assert_positive_revenue` — `fct_daily_revenue.net_revenue` never goes negative.
  - `assert_referential_integrity_orders` — every `order_item` resolves to an `order`.
  - `assert_no_future_dates` — no `order_date` in the future.
- **Source freshness** declared in `models/staging/_sources.yml` (warn after 24h,
  error after 48h on most sources; 26/72h on inventory snapshots).

Run with:

```bash
dbt test
dbt source freshness
```

---

## 🧱 Project layout

```
ecommerce-data-warehouse/
├── dbt_project/
│   ├── dbt_project.yml         # layered materialization + schema config
│   ├── packages.yml            # dbt_utils, dbt_expectations, codegen
│   ├── macros/
│   │   ├── generate_schema_name.sql
│   │   ├── cents_to_dollars.sql
│   │   └── pivot_payment_methods.sql
│   ├── models/
│   │   ├── exposures.yml
│   │   ├── staging/            # stg_* + _sources.yml + _schema.yml
│   │   ├── intermediate/       # int_*
│   │   └── marts/
│   │       ├── core/           # dim_customer, dim_product, dim_date, fct_orders, fct_order_items
│   │       ├── finance/        # fct_daily_revenue, fct_payment_method_summary
│   │       └── marketing/      # fct_customer_acquisition, fct_cohort_retention
│   ├── snapshots/
│   │   └── snap_customers.sql  # SCD2 (check strategy)
│   ├── seeds/                  # country_codes.csv, product_categories.csv
│   ├── tests/                  # singular tests
│   └── profiles/
│       ├── duckdb_profile.yml          # local dev
│       └── snowflake_profile.yml.example
├── snowflake/                  # one-time setup DDL
├── python/                     # ingestion helper into Snowflake RAW
├── data/sample/                # generate.py + load_to_duckdb.py + fixtures
├── docs/data_dictionary.md
├── screenshots/                # dbt-docs lineage screenshots
├── .github/workflows/ci.yml    # dbt deps/seed/run/test on every push (DuckDB)
└── README.md
```

---

## 🧰 Tech stack

- **Transformation:** dbt-core 1.7
- **Warehouse:** Snowflake (prod) · DuckDB (local dev / CI)
- **Packages:** `dbt_utils`, `dbt_expectations`, `codegen`
- **Modeling:** Kimball star schema with SCD2 on `dim_customer`
- **CI/CD:** GitHub Actions
- **Downstream:** Power BI, Streamlit (declared as dbt exposures)

---

## 📄 License

MIT — see [LICENSE](LICENSE).
