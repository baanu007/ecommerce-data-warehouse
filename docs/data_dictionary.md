# Data Dictionary

Per-column documentation for every mart. Source-system columns are documented inline in `models/staging/_schema.yml` and `models/staging/_sources.yml`.

> Tip: run `dbt docs generate && dbt docs serve` to browse this interactively with lineage.

---

## 📦 marts.core

### `dim_customer`
SCD Type 2 customer dimension built from the `snap_customers` snapshot.

| Column | Type | Description |
| --- | --- | --- |
| `customer_key` | string | Surrogate key — hash of `(customer_id, valid_from)`. PK. |
| `customer_id` | string | Natural key from source. |
| `valid_from` | timestamp | SCD2 start of this version. |
| `valid_to` | timestamp | SCD2 end of this version (NULL = current). |
| `is_current` | boolean | True for the latest version of the customer. |
| `first_name` / `last_name` / `full_name` | string | Customer name. |
| `email` | string | Lowercased email. |
| `phone_number` | string | Raw phone. |
| `date_of_birth` | date | DOB. |
| `age` | integer | Years between DOB and current_date. |
| `gender` | string | Upper-cased gender code. |
| `billing_address` / `billing_city` / `billing_state` / `billing_country` | string | Billing address parts. |
| `registration_date` | date | Date the customer signed up. |
| `customer_segment` | string | Marketing segment (PLATINUM / GOLD / SILVER / BRONZE / STANDARD). |
| `is_active` | boolean | Account active flag. |
| `acquisition_source` | string | Channel that acquired the customer. |
| `email_opt_in` / `sms_opt_in` | boolean | Marketing consent flags. |
| `first_order_date` / `last_order_date` | date | Order recency. |
| `lifetime_orders` | integer | Distinct orders to date. |
| `lifetime_revenue` | numeric | Sum of order net amount. |
| `lifetime_gross_profit` | numeric | Sum of line gross profit. |
| `avg_order_value` | numeric | LTV / lifetime_orders. |
| `days_since_last_order` | integer | Recency in days. |
| `customer_status` | enum | Active / At Risk / Lapsed / Churned / Never Purchased. |
| `value_tier` | enum | Platinum / Gold / Silver / Bronze (driven by `lifetime_revenue`). |
| `_loaded_at` | timestamp | When dbt built this row. |

### `dim_product`
Type-1 product dimension.

| Column | Type | Description |
| --- | --- | --- |
| `product_key` | string | Surrogate key — hash of `product_id`. PK. |
| `product_id` | string | Natural key. |
| `sku` | string | Stock-keeping unit. |
| `product_name` / `product_description` | string | Catalog text. |
| `brand` / `category` / `subcategory` | string | Classification. |
| `cost_price` / `list_price` / `sale_price` / `current_price` | numeric | Pricing. |
| `margin_percent` | numeric | (list_price - cost_price) / list_price * 100. |
| `price_tier` | enum | Premium / Mid-Range / Budget / Economy. |
| `stock_quantity` / `reorder_level` | integer | Inventory state. |
| `stock_status` | enum | In Stock / Low Stock / Out of Stock. |
| `is_active` / `is_featured` | boolean | Flags. |
| `weight_kg` | numeric | Physical weight. |
| `supplier_id` | string | FK to supplier dimension (not yet modeled). |
| `times_ordered` / `total_units_sold` / `total_revenue` / `total_gross_profit` | numeric | Lifetime sales rollups. |
| `performance_tier` | enum | Star / Cash Cow / Question Mark / Dog (BCG matrix flavoured). |

### `dim_date`
Static date dimension. Range `2020-01-01` .. `2030-12-31`. Key columns: `date_key` (YYYYMMDD integer), `calendar_date`, plus year/quarter/month/week/day attributes and convenience flags (`is_weekend`, `is_today`, `fiscal_year`, `fiscal_month`).

### `fct_orders`
Order-header grain. One row per order.

| Column | Type | Description |
| --- | --- | --- |
| `order_key` | string | Surrogate key. PK. |
| `customer_key` | string | FK to `dim_customer` (current version). |
| `date_key` | integer | FK to `dim_date`. |
| `order_id` | string | Natural key. |
| `order_date` / `order_timestamp` | date / timestamp | When the order happened. |
| `order_status` | enum | PENDING / PROCESSING / COMPLETED / SHIPPED / DELIVERED / CANCELLED / RETURNED. |
| `payment_method` | enum | CREDIT_CARD / DEBIT_CARD / PAYPAL / APPLE_PAY / GIFT_CARD / BANK_TRANSFER. |
| `line_item_count` | integer | Number of line items. |
| `total_quantity` | integer | Units in the order. |
| `gross_amount` | numeric | Sum of line gross amounts. |
| `net_amount` | numeric | Sum of line net amounts (gross - discount). |
| `total_cost` | numeric | Sum of `quantity * cost_price`. |
| `gross_profit` | numeric | `net_amount - total_cost`. |
| `margin_percent` | numeric | `gross_profit / net_amount * 100`. |
| `payments_captured` | numeric | Sum of payment rows with status CAPTURED. |
| `payments_refunded` | numeric | Sum of payment rows with status REFUNDED. |
| `is_completed` / `is_returned` / `is_cancelled` | boolean | Status flags. |
| `shipping_*` | string | Shipping address parts. |

### `fct_order_items`
Line-item grain. One row per (order, product) line. Mirrors the columns above but at finer grain (`order_item_key`, `quantity`, `unit_price`, `line_cost`, `line_gross_profit`, …).

---

## 💰 marts.finance

### `fct_daily_revenue`
One row per `order_date`. Columns: `total_orders`, `unique_customers`, `completed_orders`, `returned_orders`, `cancelled_orders`, `gross_revenue`, `net_revenue`, `total_cost`, `gross_profit`, `payments_captured`, `payments_refunded`, `average_order_value`, plus `date_key`, `year`, `quarter`, `month_number`, `year_month`, `is_weekend` from `dim_date`.

### `fct_payment_method_summary`
One row per (`order_date`, `payment_method`). Columns: `payment_count`, `captured_amount`, `refunded_amount`, `failed_count`, `net_amount`.

---

## 📣 marts.marketing

### `fct_customer_acquisition`
One row per (`acquisition_month`, `acquisition_source`). Columns: `customers_acquired`, `customers_with_purchase`, `cohort_lifetime_revenue`, `cohort_lifetime_orders`, `avg_customer_ltv`, `activation_rate_pct`.

### `fct_cohort_retention`
One row per (`cohort_month`, `activity_month`). Columns: `months_since_signup`, `active_customers`, `cohort_size`, `retention_pct`.
