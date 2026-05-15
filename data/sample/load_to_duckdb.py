"""
Load sample CSVs into a DuckDB database under the `raw` schema so dbt
sources resolve. Designed to be idempotent: drops and re-creates each
raw table.

Usage:
    python data/sample/load_to_duckdb.py [path_to_duckdb_file]

Default path is dbt_project/target/ecommerce.duckdb to match
profiles/duckdb_profile.yml.
"""

from __future__ import annotations

import sys
from pathlib import Path

import duckdb  # noqa

HERE = Path(__file__).parent
DEFAULT_DB = HERE.parent.parent / "dbt_project" / "target" / "ecommerce.duckdb"

TABLES = [
    "customers",
    "products",
    "orders",
    "order_items",
    "payments",
    "inventory",
]


def main() -> int:
    db_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DB
    db_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"-> using DuckDB file: {db_path}")
    con = duckdb.connect(str(db_path))
    con.execute("create schema if not exists raw")

    for tbl in TABLES:
        csv_path = HERE / f"{tbl}.csv"
        if not csv_path.exists():
            print(f"   [skip] no CSV for {tbl}")
            continue
        con.execute(f"drop table if exists raw.{tbl}")
        con.execute(
            f"create table raw.{tbl} as "
            f"select *, current_timestamp as _loaded_at "
            f"from read_csv_auto('{csv_path.as_posix()}', header=true, sample_size=-1)"
        )
        (count,) = con.execute(f"select count(*) from raw.{tbl}").fetchone()
        print(f"   loaded {count:5d} rows -> raw.{tbl}")

    con.close()
    print("done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
