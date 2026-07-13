# E-Commerce Order Analytics System

## Project Overview

This project simulates a real-world scenario where raw e-commerce order data comes in messy
from multiple sources, and needs to be cleaned, loaded into a database, and analyzed to
generate business reports. Built entirely in Python + SQLite (local environment).

Duration: Intern Mini Project
Skills used: Python, Pandas, SQL (SQLite), CLI tools

---

## Architecture / Workflow

```
generate_data.py
      |
      v
data/raw/  (messy CSVs - nulls, wrong date formats, bad emails, negative qty)
      |
      v
clean_data.py
      |
      v
data/cleaned/  (cleaned CSVs + issues_report.txt)
      |
      v
load_database.py
      |
      v
ecommerce.db  (SQLite, schema.sql applied)
      |
      v
sql/*.sql  (16 analysis queries - aggregations, window functions, cohort analysis)
      |
      v
report_cli.py  (command line reporting tool)
      |
      v
output/sample_reports/
```

---

## Folder Structure

```
ecommerce-analytics-system/
├── data/
│   ├── raw/            -> generate_data.py output (messy data)
│   └── cleaned/        -> clean_data.py output (cleaned data + issues_report.txt)
├── scripts/
│   ├── generate_data.py    -> creates the 4 raw CSVs
│   ├── clean_data.py       -> cleans data, checks referential integrity
│   ├── load_database.py    -> loads cleaned data into SQLite
│   ├── report_cli.py       -> CLI reporting tool (Part 4)
│   ├── test_cases.py       -> edge case tests (Part 5)
│   └── run_sql_file.py     -> helper to run and print any .sql file's results
├── sql/
│   ├── schema.sql              -> table definitions (PK/FK constraints)
│   ├── aggregations.sql        -> basic + intermediate queries (Q1-6)
│   ├── window_functions.sql    -> advanced window function queries (Q7,8,9,11,12,13,14,16)
│   └── cohort_analysis.sql     -> multi-level CTE + cohort retention (Q10, Q15)
├── output/
│   └── sample_reports/     -> sample outputs from CLI tool + SQL query runs
├── screenshots/
│   ├── data_generation/
│   ├── data_cleaning/
│   ├── sql_queries/
│   ├── cli/
│   └── final_output/
├── requirements.txt
└── README.md
```

Note: `sql/aggregations.sql` and `sql/window_functions.sql` cover the same 16 queries the
assignment describes as "Basic/Intermediate Queries" and "Advanced Queries (Window
Functions, CTEs, Subqueries)" - just organized under the recommended file names.

---

## Data (Raw)

4 CSVs generated with intentional data quality issues:

| File | Rows | Issues injected |
|---|---|---|
| customers.csv | 600 | ~2% invalid emails |
| products.csv | 150 | ~15% names with extra spaces / mixed case |
| orders.csv | 700 | ~5% NULL customer_id, ~8% wrong date format (DD-MM-YYYY) |
| order_items.csv | 1500 | ~3% negative quantity (returns), ~3% invalid order_id |

## Data Cleaning

`clean_data.py` implements:
- `clean_orders()` - fixes mixed date formats, keeps NULL customer_id as NULL
- `clean_products()` - trims spaces, title-cases product names
- `validate_emails()` - returns list of customer_ids with invalid emails
- `check_referential_integrity()` - finds order_items pointing to non-existent orders

Output: cleaned CSVs in `data/cleaned/` + `issues_report.txt` summarizing everything found.

## SQL Analysis (16 queries)

Loaded into SQLite (`ecommerce.db`) via `load_database.py`, with schema constraints
(PK/FK) defined in `schema.sql`. Queries cover revenue analysis, customer segmentation
(NTILE quartiles), retention/cohort analysis, running totals, ranking, and more.

## CLI Reporting Tool

`report_cli.py` takes `--report`, `--start`, `--end` arguments, connects to SQLite,
and prints total orders/revenue/customers, top 3 products, and % change vs the previous
period of equal length. Built using only `sqlite3` + `argparse` (no external libraries),
per assignment requirement.

## Edge Case Tests

`test_cases.py` checks 4 scenarios: order_id not in orders, discount_percent > 100,
quantity = 0, and future order_date - and explains what should happen in each case.

---

## How to Run

```
# 1. set up environment
python -m venv venv
venv\Scripts\Activate.ps1        (Windows PowerShell)
pip install -r requirements.txt

# 2. generate raw data
python scripts\generate_data.py

# 3. clean the data
python scripts\clean_data.py

# 4. load into SQLite
python scripts\load_database.py

# 5. run SQL analysis
python scripts\run_sql_file.py sql\aggregations.sql
python scripts\run_sql_file.py sql\window_functions.sql
python scripts\run_sql_file.py sql\cohort_analysis.sql

# 6. run the CLI report tool
python scripts\report_cli.py --report monthly --start 2025-01-01 --end 2025-02-01

# 7. run edge case tests
python scripts\test_cases.py
```

---

## Output

- Cleaned CSVs: `data/cleaned/`
- SQLite database: `ecommerce.db` (generated locally, not committed to git)
- Sample reports: `output/sample_reports/`
- Screenshots of every step: `screenshots/`