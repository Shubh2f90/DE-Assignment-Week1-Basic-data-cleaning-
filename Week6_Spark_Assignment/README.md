# Week 6 - Spark Assignment

## Overview

**Submitted By:** Shubham Sharma
**Date:** June 2026
**Dataset:** Sample - Superstore.csv

This assignment focuses on Apache Spark fundamentals and practical Spark DataFrame operations. The work covers Spark architecture, lazy evaluation, DAG-based execution, schema handling, filtering, transformations, actions, file format comparison, and performance optimization concepts.

The assignment includes both conceptual and code-based questions designed to build understanding of how Spark processes large datasets efficiently in a distributed environment.

---

## Assignment Objective

The objective of this assignment is to understand Spark architecture and perform efficient data processing using Spark DataFrames.

This includes:
- understanding the role of the **Driver, Cluster Manager, and Executors**
- learning how **Lazy Evaluation** improves Spark performance
- working with **CSV and Parquet** file formats
- performing **filtering, selection, renaming, casting, and derived column creation**
- understanding **Transformations vs Actions**
- learning Spark performance concepts such as **Predicate Pushdown** and safe exploration of large datasets

---

## Assignment Questions Covered

The Week 6 assignment contains **15 Spark questions**, including both conceptual and coding tasks.

### Conceptual Questions
- Roles of Driver, Cluster Manager, and Executor
- Spark Lazy Evaluation
- CSV vs Parquet comparison
- DAG / Lineage Graph and fault tolerance
- Predicate Pushdown
- Transformations vs Actions
- Client Mode vs Cluster Mode
- Why `.show(5)` is safer than `.collect()`

### Coding / Query-Based Questions
- Read CSV with schema inference
- Select specific columns with filter conditions
- Rename columns and cast datatypes
- Filter DataFrames with multiple conditions
- Add derived columns
- Read Parquet, filter nulls, and save as CSV
- Apply OR / AND conditions in filters

---

## Topics Covered

### 1. Spark Architecture
- Driver
- Cluster Manager
- Executors
- Client Mode vs Cluster Mode

### 2. Spark Execution Concepts
- Lazy Evaluation
- DAG / Lineage Graph
- Fault Tolerance in Spark
- Transformations and Actions

### 3. Spark DataFrame Operations
- Read CSV with `header=true` and `inferSchema=true`
- Read and write Parquet files
- Filter rows using conditions
- Select required columns
- Rename columns
- Cast datatypes
- Add derived columns
- Handle null values

### 4. Spark Performance Concepts
- CSV vs Parquet
- Predicate Pushdown
- Why `.show()` is safer than `.collect()` for large datasets

---

## Key Spark Commands Used

```python
spark.read.csv()
spark.read.parquet()
.select()
.filter()
.withColumnRenamed()
.withColumn()
.cast()
.write.csv()
.write.parquet()
.show()
```

---

## Folder Structure
spark-assignment-week6/

│── data/

│   └── Sample_-_Superstore.csv

│── notebook/

│   └── spark_week6.ipynb

│── output/

│   └── superstore_parquet/

│   └── superstore_output_csv/

│── README.md

---

## Files Included

- `README.md` → Assignment overview and documentation
- `notebook/spark_week6.ipynb` → Jupyter Notebook with all 15 Q&A and output screenshots
- `data/Sample_-_Superstore.csv` → Dataset used for all queries
- `output/superstore_parquet/` → Parquet output generated from Q12
- `output/superstore_output_csv/` → CSV output generated from Q12

---

## Skills Demonstrated

By completing this assignment, the following Spark skills are demonstrated:
- understanding Spark's distributed architecture
- writing Spark DataFrame queries
- working with structured data in CSV and Parquet formats
- applying filters and transformations on large datasets
- modifying schema and column datatypes
- handling null values
- understanding performance optimization concepts in Spark

---

## Learning Outcome

This assignment provided hands-on exposure to Spark fundamentals and DataFrame-based data processing. It helped strengthen understanding of Spark architecture, lazy execution, schema handling, filtering, transformations, and performance-related concepts required for large-scale data engineering workflows.

---

## Conclusion

Week 6 serves as a strong foundation for Spark-based data engineering. It combines Spark theory with practical DataFrame operations and prepares the base for more advanced distributed data processing in later weeks.
