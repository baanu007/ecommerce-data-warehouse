# 🛒 E-Commerce Data Warehouse

A production-ready data warehouse solution for e-commerce analytics built with **dbt**, **Snowflake**, and **Python**.

![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

## 📋 Overview

This project implements a complete data warehouse for an e-commerce platform, transforming raw transactional data into analytics-ready dimensional models. Features include:

- **Medallion Architecture**: Bronze → Silver → Gold layers
- **Dimensional Modeling**: Star schema with fact and dimension tables
- **Incremental Processing**: Efficient updates using dbt incremental models
- **Data Quality**: Comprehensive testing with dbt tests and custom validations
- **Documentation**: Auto-generated data catalog and lineage

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                 │
├──────────────┬──────────────┬──────────────┬───────────────────────┤
│   Orders     │   Products   │   Customers  │      Inventory        │
│   (CSV/API)  │   (CSV/API)  │   (CSV/API)  │      (CSV/API)        │
└──────┬───────┴──────┬───────┴──────┬───────┴───────────┬───────────┘
       │              │              │                   │
       ▼              ▼              ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BRONZE LAYER (Raw)                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │raw_orders│ │raw_products│ │raw_customers│ │raw_inventory│        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      SILVER LAYER (Cleaned)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │stg_orders│ │stg_products│ │stg_customers│ │stg_inventory│        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GOLD LAYER (Analytics)                          │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐             │
│  │  dim_customers │ │  dim_products  │ │   dim_date    │             │
│  └───────────────┘ └───────────────┘ └───────────────┘             │
│  ┌───────────────────────────────────────────────────┐             │
│  │                   fct_orders                       │             │
│  └───────────────────────────────────────────────────┘             │
│  ┌───────────────────────────────────────────────────┐             │
│  │                   fct_inventory                    │             │
│  └───────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA MARTS                                   │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐          │
│  │ mart_sales_daily│ │mart_product_perf│ │mart_customer_ltv│        │
│  └────────────────┘ └────────────────┘ └────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
ecommerce-data-warehouse/
├── dbt_project/
│   ├── models/
│   │   ├── staging/           # Silver layer - cleaned data
│   │   │   ├── stg_orders.sql
│   │   │   ├── stg_products.sql
│   │   │   ├── stg_customers.sql
│   │   │   └── stg_inventory.sql
│   │   ├── intermediate/      # Business logic transformations
│   │   │   ├── int_orders_enriched.sql
│   │   │   └── int_customer_orders.sql
│   │   ├── marts/             # Gold layer - analytics ready
│   │   │   ├── dim_customers.sql
│   │   │   ├── dim_products.sql
│   │   │   ├── dim_date.sql
│   │   │   ├── fct_orders.sql
│   │   │   └── fct_inventory.sql
│   │   └── analytics/         # Data marts for BI
│   │       ├── mart_sales_daily.sql
│   │       ├── mart_product_performance.sql
│   │       └── mart_customer_ltv.sql
│   ├── tests/                 # Custom data quality tests
│   ├── macros/                # Reusable SQL functions
│   ├── seeds/                 # Static reference data
│   └── dbt_project.yml
├── python/
│   ├── extract/               # Data extraction scripts
│   ├── load/                  # Loading to Snowflake
│   └── utils/                 # Helper functions
├── data/                      # Sample datasets
├── docs/                      # Documentation
└── requirements.txt
```

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- dbt-core 1.5+
- dbt-snowflake adapter
- Snowflake account

### Installation

```bash
# Clone the repository
git clone https://github.com/baanu007/ecommerce-data-warehouse.git
cd ecommerce-data-warehouse

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure dbt profile (update with your Snowflake credentials)
cp profiles.yml.example ~/.dbt/profiles.yml
```

### Running the Pipeline

```bash
# Navigate to dbt project
cd dbt_project

# Install dbt packages
dbt deps

# Test connection
dbt debug

# Run full pipeline
dbt build

# Generate documentation
dbt docs generate
dbt docs serve
```

## 📊 Data Models

### Fact Tables

| Table | Description | Grain |
|-------|-------------|-------|
| `fct_orders` | Order transactions | One row per order line item |
| `fct_inventory` | Daily inventory snapshots | One row per product per day |

### Dimension Tables

| Table | Description | Type |
|-------|-------------|------|
| `dim_customers` | Customer attributes | SCD Type 2 |
| `dim_products` | Product catalog | SCD Type 1 |
| `dim_date` | Date dimension | Static |

### Key Metrics

- **Gross Merchandise Value (GMV)**: Total sales value
- **Average Order Value (AOV)**: Revenue per order
- **Customer Lifetime Value (CLV)**: Total customer spend
- **Inventory Turnover**: Stock efficiency ratio

## 🧪 Data Quality

Built-in tests ensure data integrity:

```yaml
# Example tests in schema.yml
models:
  - name: fct_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: order_amount
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
```

Run tests:
```bash
dbt test
```

## 📈 Sample Queries

### Daily Sales Summary
```sql
SELECT 
    order_date,
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(order_amount) as gmv,
    AVG(order_amount) as aov
FROM {{ ref('fct_orders') }}
GROUP BY order_date
ORDER BY order_date DESC;
```

### Top Products by Revenue
```sql
SELECT 
    p.product_name,
    p.category,
    SUM(o.quantity) as units_sold,
    SUM(o.line_total) as revenue
FROM {{ ref('fct_orders') }} o
JOIN {{ ref('dim_products') }} p ON o.product_key = p.product_key
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;
```

## 🛠️ Technologies

- **Transformation**: dbt Core
- **Data Warehouse**: Snowflake
- **Orchestration**: Compatible with Airflow, Dagster, Prefect
- **Testing**: dbt tests, Great Expectations
- **CI/CD**: GitHub Actions

## 📄 License

MIT License - feel free to use this project as a template for your own data warehouse!

## 🤝 Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

---

*Built with ❤️ for the data engineering community*
