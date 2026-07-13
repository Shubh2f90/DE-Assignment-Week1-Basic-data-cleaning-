# E-Commerce Order Analytics System

## Project Overview

This project is an end-to-end data analytics solution developed for analyzing e-commerce order data. It demonstrates the complete workflow starting from synthetic data generation, data cleaning, database creation, SQL analysis, and report generation.

The project combines Python, Pandas, SQLite, and SQL to simulate a real-world data engineering and analytics pipeline.

---

## Objectives

- Generate realistic e-commerce datasets.
- Introduce intentional data quality issues.
- Clean and validate the datasets using Pandas.
- Load the cleaned data into a SQL database.
- Perform business analytics using SQL queries.
- Generate reports through a Python command-line interface.

---

## Technologies Used

- Python
- Pandas
- Faker
- SQLite
- SQL
- Git & GitHub

---

## Project Structure

```
week8_ecommerce-analytics-system/
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── scripts/
│   ├── generate_data.py
│   ├── clean_data.py
│   └── report_cli.py
│
├── sql/
│   ├── schema.sql
│   ├── aggregations.sql
│   ├── window_functions.sql
│   └── cohort_analysis.sql
│
├── output/
│   └── sample_reports/
│
├── database.db
├── requirements.txt
└── README.md
```

---

## Workflow

### Step 1 - Data Generation

The `generate_data.py` script creates four datasets:

- Customers
- Products
- Orders
- Order Items

It also introduces common data quality issues such as:

- Missing values
- Invalid email addresses
- Duplicate records
- Incorrect date formats
- Negative quantities

---

### Step 2 - Data Cleaning

The `clean_data.py` script performs:

- Missing value handling
- Duplicate removal
- Date format correction
- Email validation
- Referential integrity checks

The cleaned files are saved inside the `data/cleaned` folder.

---

### Step 3 - Database Creation

The cleaned datasets are loaded into a SQLite database using the schema defined in `schema.sql`.

The database includes:

- Primary Keys
- Foreign Keys
- Data integrity constraints

---

### Step 4 - SQL Analysis

Several SQL queries are used to generate business insights, including:

- Revenue by customer
- Revenue by category
- Monthly sales
- Top-selling products
- Customer rankings
- Window function analysis
- Cohort and retention analysis

---

### Step 5 - CLI Reports

The `report_cli.py` script allows users to generate reports directly from the command line.

Example:

```bash
python report_cli.py --report revenue
```

---

## Features

- Automated data generation
- Data cleaning using Pandas
- SQL analytics
- Window Functions
- Common Table Expressions (CTEs)
- Customer segmentation
- Cohort analysis
- Command-line reporting

---

## Sample Output

The generated reports include:

- Customer Revenue
- Product Performance
- Monthly Revenue Trends
- Retention Metrics
- Top Customers

---

## Installation

Clone the repository:

```bash
git clone <repository-url>
```

Install the required libraries:

```bash
pip install -r requirements.txt
```

---

## How to Run

Generate raw datasets:

```bash
python scripts/generate_data.py
```

Clean the datasets:

```bash
python scripts/clean_data.py
```

Run SQL scripts using SQLite.

Generate reports:

```bash
python scripts/report_cli.py
```

---

## Learning Outcomes

This project demonstrates practical knowledge of:

- Data generation
- Data preprocessing
- Data validation
- SQL querying
- Window functions
- Data analytics
- End-to-end ETL workflow

---

## Future Improvements

- Interactive dashboard using Power BI or Tableau
- PostgreSQL/MySQL support
- Automated data pipeline scheduling
- Cloud deployment
- Real-time streaming data integration

---

## Author

**Shubham**

Data Engineering Internship Project
