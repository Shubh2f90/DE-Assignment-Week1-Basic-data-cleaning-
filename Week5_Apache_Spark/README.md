# Week 5: Apache Spark Fundamentals, Data Cleaning & Aggregation

## 📌 Objective
The primary objective of this module is to understand the core architecture of Apache Spark and perform comprehensive data engineering operations—including data cleaning, structural schema transformations, and complex aggregations—using PySpark DataFrames on a large-scale transactional dataset (`Sample - Superstore.csv`).

---

## 📊 Dataset Overview
* **Dataset Name:** Sample - Superstore.csv
* **Total Volume:** 9,994 transactional records
* **Target Schema Attributes:** Order ID, Order Date, Region, State, Sales, Quantity, Profit, and Category.

---

## 🛠️ Core Concepts Covered

### 1. Architecture: Apache Spark vs. MapReduce
* **In-Memory Speed:** Traditional MapReduce relies heavily on persistent disk reads/writes to HDFS after every Map and Reduce cycle, creating severe I/O bottlenecks. Spark handles intermediate operations directly within cluster RAM using Resilient Distributed Datasets (RDDs) and DataFrames, boosting processing performance by 10x to 100x.
* **Iterative Machine Learning Processing:** MapReduce triggers high-latency disk cycles for every looping pass. Spark reads data once and persists it inside RAM (`.cache()` / `.persist()`), allowing consecutive loops to access memory strings immediately.

### 2. Practical Data Cleaning Mechanics
* **DataFrame Immutability & Lineage:** Spark DataFrames are immutable and cannot be updated in-place. Structural operations generate entirely new execution components, tracking transformations through a Directed Acyclic Graph (DAG) for built-in fault tolerance.
* **Targeted Deduplication:** Isolated and scrubbed duplicate entries safely via composite subsets (`.dropDuplicates(subset=['Order ID', 'Product ID'])`) rather than full-row evaluations.
* **Defensive Missing Value Management:** Neutralized statistical calculation skewing caused by null items by structuring `.na.drop()` and `.na.fill(0)` pipelines ahead of running analytical calculations.

### 3. Wide Transformations & Schema Structures
* **The Shuffle Process:** Grouping operations (`groupBy`) execute a data Shuffle across cluster executors. Because identical keys are scattered randomly at ingestion, Spark hashes and physically transfers matching rows over the network to a single executor partition.
* **Compound Aggregations:** Utilized Spark's central `.agg()` schema interface to calculate multiple concurrent stats (`min()`, `max()`, `avg()`, `sum()`) efficiently in a single processing sweep.
* **Explicit Schema Constraints:** Evaluated the architectural stability risks of `inferSchema=True` on inconsistent raw dates, implementing explicit structural transformations (`.withColumn()`, `to_date()`) and column updates (`.withColumnRenamed()`).

---

## 🚀 End-to-End Production Pipeline Synthesis
The assignment concluded with the development of a unified, sequential big data processing pipeline:

```python
# Execution Path Overview
1. Data Ingestion    -> Load raw transactional files into a DataFrame
2. Deduplication     -> Filter redundant rows based on transaction composite keys
3. Imputation        -> Fill missing numerical records (Sales, Profit) safely with 0
4. Aggregation       -> Group by 'State' to compute and round total revenues
5. Sorting           -> Order output in descending sequence for executive insights
