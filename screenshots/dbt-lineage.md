# dbt Lineage & Docs Screenshots

This folder is the place to drop dbt-docs screenshots so the README has
visuals. After every meaningful schema change, regenerate them with:

```bash
cd dbt_project
dbt docs generate
dbt docs serve
```

Then take screenshots and save them here with the following naming convention:

| File | What to capture |
| --- | --- |
| `lineage_full.png` | The full DAG (Source → Staging → Intermediate → Marts → Exposures). |
| `lineage_fct_orders.png` | Focused lineage for `fct_orders` (right-click → "Focus" on the node). |
| `lineage_dim_customer.png` | Focused lineage for `dim_customer` including `snap_customers`. |
| `model_dim_customer.png` | The column-list / docs page for `dim_customer`. |
| `exposures_dashboards.png` | The exposures graph showing Power BI dashboards. |

Embed in the root `README.md` using:

```markdown
![dbt lineage](screenshots/lineage_full.png)
```

> The screenshots themselves are not version-controlled until Baanu adds them.
> This file documents the intent so future updates stay consistent.
