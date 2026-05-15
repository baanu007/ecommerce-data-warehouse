"""
Generate small synthetic CSVs for the e-commerce data warehouse.

Run this once to regenerate everything in data/sample/. The output sizes
target ~500 rows for orders/order_items/payments and ~50 for the smaller
dimension-style sources. Volumes can be tuned with the constants below.

The data is intentionally deterministic (seeded random) so unit tests can
rely on stable outputs in CI.
"""

from __future__ import annotations

import csv
import os
import random
from datetime import date, datetime, timedelta
from pathlib import Path

random.seed(42)

OUT_DIR = Path(__file__).parent

N_CUSTOMERS  = 60
N_PRODUCTS   = 40
N_ORDERS     = 500
START_DATE   = date(2024, 1, 1)
END_DATE     = date(2024, 12, 31)

FIRST_NAMES = ['John', 'Sarah', 'Mike', 'Emily', 'David', 'Lisa', 'James', 'Anna', 'Chris',
               'Rachel', 'Tom', 'Jenny', 'Mark', 'Laura', 'Peter', 'Amy', 'Steve', 'Nina',
               'Alex', 'Kate', 'Brian', 'Maria', 'Jason', 'Diana', 'Kevin']
LAST_NAMES  = ['Smith', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Anderson', 'Taylor', 'Moore',
               'Lee', 'Garcia', 'Martinez', 'Robinson', 'Clark', 'Lewis', 'Hall', 'Allen']
STATES      = ['TX', 'CA', 'NY', 'FL', 'IL', 'WA', 'MA', 'CO', 'GA', 'AZ']
SEGMENTS    = ['PLATINUM', 'GOLD', 'SILVER', 'BRONZE', 'STANDARD']
SOURCES     = ['GOOGLE_ADS', 'FACEBOOK', 'REFERRAL', 'ORGANIC', 'EMAIL', 'AFFILIATE']
CATEGORIES  = [('ELECTRONICS', 'AUDIO'), ('ELECTRONICS', 'TV'), ('ELECTRONICS', 'LAPTOP'),
               ('APPAREL', 'MENS'), ('APPAREL', 'WOMENS'), ('HOME', 'KITCHEN'),
               ('HOME', 'FURNITURE'), ('BEAUTY', 'SKINCARE'), ('SPORTS', 'FITNESS')]
BRANDS      = ['SoundMax', 'VisionPro', 'TechLine', 'UrbanWear', 'HomeCo', 'GlowLab', 'FitPro']
PAYMENT_METHODS = ['CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL', 'APPLE_PAY', 'GIFT_CARD']
PAYMENT_STATUS  = ['CAPTURED'] * 12 + ['REFUNDED', 'FAILED']
ORDER_STATUS    = ['COMPLETED'] * 8 + ['SHIPPED', 'PROCESSING', 'CANCELLED', 'RETURNED']


def rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def rand_ts(d: date) -> str:
    return f"{d.isoformat()} {random.randint(8, 22):02d}:{random.randint(0, 59):02d}:{random.randint(0, 59):02d}"


def write_csv(name: str, header: list[str], rows: list[list]) -> None:
    path = OUT_DIR / name
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"  wrote {len(rows):5d} rows -> {path.name}")


# ---------------- customers ----------------
customers = []
emails_used: set[str] = set()
for i in range(1, N_CUSTOMERS + 1):
    fn = random.choice(FIRST_NAMES)
    ln = random.choice(LAST_NAMES)
    # ensure unique email
    while True:
        email = f"{fn.lower()}.{ln.lower()}{i}@example.com"
        if email not in emails_used:
            emails_used.add(email)
            break
    reg = rand_date(date(2023, 1, 1), date(2023, 12, 31))
    customers.append([
        f"CUST-{1000 + i}", fn, ln, email,
        f"{random.choice(['214', '512', '415', '212'])}-555-{random.randint(1000, 9999):04d}",
        rand_date(date(1970, 1, 1), date(2002, 12, 31)).isoformat(),
        random.choice(['M', 'F']),
        f"{random.randint(100, 9999)} {random.choice(['Main', 'Oak', 'Pine', 'Elm'])} St",
        random.choice(['Austin', 'Dallas', 'Houston', 'San Antonio', 'Los Angeles', 'NYC']),
        random.choice(STATES),
        f"{random.randint(10000, 99999)}",
        'USA',
        reg.isoformat(),
        random.choice(SEGMENTS),
        'true',
        random.choice(['true', 'false']),
        random.choice(['true', 'false']),
        random.choice(SOURCES),
        f"{reg.isoformat()} 10:00:00",
        f"{reg.isoformat()} 10:00:00",
    ])

write_csv('customers.csv', [
    'customer_id', 'first_name', 'last_name', 'email', 'phone_number',
    'date_of_birth', 'gender', 'billing_address', 'billing_city', 'billing_state',
    'billing_zip', 'billing_country', 'registration_date', 'customer_segment',
    'is_active', 'email_opt_in', 'sms_opt_in', 'acquisition_source',
    'created_at', 'updated_at',
], customers)


# ---------------- products ----------------
products = []
for i in range(1, N_PRODUCTS + 1):
    cat, sub = random.choice(CATEGORIES)
    cost = round(random.uniform(5, 400), 2)
    markup = random.uniform(1.4, 2.5)
    list_p = round(cost * markup, 2)
    sale_p = round(list_p * random.uniform(0.8, 1.0), 2) if random.random() < 0.4 else ''
    products.append([
        f"PROD-{100 + i}",
        f"{random.choice(BRANDS)} {cat.title()} #{i}",
        f"High quality {sub.lower()} item",
        f"SKU-{cat[:3]}-{i:03d}",
        cat, sub,
        random.choice(BRANDS),
        cost, list_p, sale_p,
        random.randint(10, 500),
        random.randint(5, 50),
        'true',
        random.choice(['true', 'false']),
        round(random.uniform(0.1, 20.0), 2),
        f"SUP-{random.randint(1, 10):03d}",
        '2023-01-01 00:00:00',
        '2024-01-01 00:00:00',
    ])

write_csv('products.csv', [
    'product_id', 'product_name', 'product_description', 'sku', 'category', 'subcategory',
    'brand', 'cost_price', 'list_price', 'sale_price', 'stock_quantity', 'reorder_level',
    'is_active', 'is_featured', 'weight_kg', 'supplier_id', 'created_at', 'updated_at',
], products)


# ---------------- orders + order_items + payments ----------------
orders, order_items, payments = [], [], []
for i in range(1, N_ORDERS + 1):
    order_id = f"ORD-{i:05d}"
    cust = random.choice(customers)
    customer_id = cust[0]
    order_date = rand_date(START_DATE, END_DATE)
    order_ts   = rand_ts(order_date)
    status     = random.choice(ORDER_STATUS)
    pm         = random.choice(PAYMENT_METHODS)
    # 1..4 line items per order
    line_count = random.randint(1, 4)
    chosen_products = random.sample(products, line_count)
    order_net = 0.0
    primary_product_id = chosen_products[0][0]
    for j, p in enumerate(chosen_products, start=1):
        qty   = random.randint(1, 4)
        price = float(p[8])  # list_price
        disc  = round(price * qty * random.uniform(0, 0.15), 2) if random.random() < 0.3 else 0
        net   = round(qty * price - disc, 2)
        order_net += net
        order_items.append([
            f"OI-{i:05d}-{j}", order_id, p[0], qty, price, disc,
            order_ts, order_ts,
        ])
    orders.append([
        order_id, customer_id, primary_product_id,
        order_date.isoformat(), order_ts,
        sum(int(oi[3]) for oi in order_items if oi[1] == order_id),
        round(order_net / max(line_count, 1), 2),
        0,
        status, pm,
        cust[7], cust[8], cust[9], cust[10], cust[11],
        order_ts, order_ts,
    ])
    # one payment per order (occasionally a refund row too)
    payments.append([
        f"PAY-{i:05d}", order_id, pm, round(order_net, 2),
        'CAPTURED' if status not in ('CANCELLED', 'RETURNED') else 'REFUNDED',
        order_date.isoformat(), order_ts, order_ts, order_ts,
    ])
    if status == 'RETURNED' and random.random() < 0.5:
        payments.append([
            f"PAY-{i:05d}-R", order_id, pm, round(order_net, 2),
            'REFUNDED', order_date.isoformat(), order_ts, order_ts, order_ts,
        ])

write_csv('orders.csv', [
    'order_id', 'customer_id', 'product_id', 'order_date', 'order_timestamp',
    'quantity', 'unit_price', 'discount_amount', 'order_status', 'payment_method',
    'shipping_address', 'shipping_city', 'shipping_state', 'shipping_zip',
    'shipping_country', 'created_at', 'updated_at',
], orders)

write_csv('order_items.csv', [
    'order_item_id', 'order_id', 'product_id', 'quantity', 'unit_price',
    'discount_amount', 'created_at', 'updated_at',
], order_items)

write_csv('payments.csv', [
    'payment_id', 'order_id', 'payment_method', 'amount', 'status',
    'payment_date', 'payment_timestamp', 'created_at', 'updated_at',
], payments)


# ---------------- inventory ----------------
inventory = []
for p in products[:20]:
    for day_offset in range(0, 30, 7):  # weekly snapshots
        snap = END_DATE - timedelta(days=day_offset)
        inventory.append([
            p[0], snap.isoformat(),
            random.randint(0, 500),
            random.randint(0, 100),
            random.randint(0, 100),
            f"WH-{random.choice(['ATX', 'DFW', 'SFO'])}",
        ])

write_csv('inventory.csv', [
    'product_id', 'snapshot_date', 'stock_quantity',
    'inbound_quantity', 'outbound_quantity', 'warehouse_code',
], inventory)

print("Done.")
