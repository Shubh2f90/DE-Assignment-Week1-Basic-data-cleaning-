# Ecommerce-Data-Exploration-and-Cleaning

Professional ecommerce data cleaning and exploratory data analysis project using Python Pandas.

---

## Project Overview

This project demonstrates practical data cleaning and preprocessing techniques on an ecommerce dataset.  
The notebook includes dataset exploration, missing value handling, duplicate removal, feature engineering, filtering, aggregation, and business insight generation.

---

## Technologies Used

- Python
- Pandas
- Jupyter Notebook
- PyCharm

---

## Dataset Operations Performed

### 1. Data Loading
- Loaded ecommerce dataset using Pandas

### 2. Data Exploration
Used:
- `head()`
- `info()`
- `describe()`
- `shape`
- `columns`

### 3. Missing Value Handling
- Checked null values using:
```python
df.isnull().sum()
```

- Removed unnecessary columns
- Filled important missing values
- Cleaned pricing-related columns

### 4. Duplicate Removal
Removed duplicate rows using:
```python
df.drop_duplicates()
```

### 5. Data Cleaning
- Removed null values
- Converted columns into numeric format
- Standardized dataset

### 6. Feature Engineering
Created new derived columns:

```python
df["total_amount"] = df["final_price"] * df["quantity"]

df["discount_amount"] = df["initial_price"] - df["final_price"]
```

### 7. Filtering
Filtered highly rated products:

```python
df[df["ratings"] > 4]
```

### 8. GroupBy Analysis
Performed aggregation analysis on:
- categories
- seller names
- brands
- ratings
- pricing

### 9. Exported Cleaned Dataset
Saved processed dataset as:

```text
cleaned_dataset.csv
```

---

## Files Included

| File Name | Description |
|---|---|
| DE-Project.ipynb | Main Jupyter notebook |
| cleaned_dataset.csv | Final cleaned dataset |
| README.md | Project documentation |

---

## Business Insights Generated

- Most common ecommerce brands
- Average product ratings by category
- Seller-wise pricing analysis
- Discount trend analysis
- Product distribution insights

---

## Project Outcome

Successfully cleaned and transformed raw ecommerce data into an analysis-ready dataset using professional data preprocessing techniques.

---

## Author

Shubham Sharma
