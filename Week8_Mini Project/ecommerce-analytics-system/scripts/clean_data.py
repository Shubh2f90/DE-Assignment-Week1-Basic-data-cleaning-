import os
import pandas as pd

RAW_DIR = os.path.join("data", "raw")
CLEAN_DIR = os.path.join("data", "cleaned")
os.makedirs(CLEAN_DIR, exist_ok=True)

issues_log = []  # will collect text lines for the report at the end


def log(msg):
    print(msg)
    issues_log.append(msg)


def clean_orders(df):
    df = df.copy()

    # order_date has 2 formats mixed - YYYY-MM-DD HH:MM:SS and DD-MM-YYYY
    # try the normal one first, if it fails try the other one
    def fix_date(val):
        val = str(val).strip()
        try:
            return pd.to_datetime(val, format="%Y-%m-%d %H:%M:%S")
        except ValueError:
            try:
                return pd.to_datetime(val, format="%d-%m-%Y")
            except ValueError:
                return pd.NaT

    def is_wrong_format(val):
        try:
            pd.to_datetime(str(val).strip(), format="%Y-%m-%d %H:%M:%S")
            return False
        except ValueError:
            return True

    bad_dates_before = df["order_date"].apply(is_wrong_format).sum()

    df["order_date"] = df["order_date"].apply(fix_date)
    log(f"orders: fixed date formats, {bad_dates_before} rows had non standard date format")

    # customer_id missing / NULL handling
    null_count = df["customer_id"].isna().sum() + (df["customer_id"] == "").sum()
    df["customer_id"] = df["customer_id"].replace("", pd.NA)
    log(f"orders: {null_count} rows have missing customer_id, keeping as NULL (not dropping, since order still valid)")

    return df


def clean_products(df):
    df = df.copy()
    messy_count = df["product_name"].apply(lambda x: x != x.strip() or x != x.title()).sum()

    df["product_name"] = df["product_name"].str.strip().str.title()
    log(f"products: normalized {messy_count} product names (trimmed spaces + title case)")
    return df


def validate_emails(df):
    # simple regex check - something@something.something
    pattern = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    invalid_mask = ~df["email"].astype(str).str.match(pattern)
    invalid_ids = df.loc[invalid_mask, "customer_id"].tolist()
    log(f"customers: found {len(invalid_ids)} invalid emails -> customer_ids: {invalid_ids[:10]}{'...' if len(invalid_ids) > 10 else ''}")
    return invalid_ids


def check_referential_integrity(orders_df, order_items_df):
    valid_order_ids = set(orders_df["order_id"])
    bad_rows = order_items_df[~order_items_df["order_id"].isin(valid_order_ids)]
    log(f"order_items: {len(bad_rows)} rows reference an order_id that doesn't exist in orders.csv")
    return bad_rows


if __name__ == "__main__":
    customers = pd.read_csv(os.path.join(RAW_DIR, "customers.csv"))
    products = pd.read_csv(os.path.join(RAW_DIR, "products.csv"))
    orders = pd.read_csv(os.path.join(RAW_DIR, "orders.csv"))
    order_items = pd.read_csv(os.path.join(RAW_DIR, "order_items.csv"))

    log("---- Data Cleaning Report ----\n")

    # customers - just check emails, no other cleaning needed for now
    bad_emails = validate_emails(customers)

    # products
    products_clean = clean_products(products)

    # orders
    orders_clean = clean_orders(orders)

    # duplicates check across all 4 (basic dedup)
    for name, d in [("customers", customers), ("products", products_clean),
                    ("orders", orders_clean), ("order_items", order_items)]:
        dupes = d.duplicated().sum()
        if dupes > 0:
            log(f"{name}: removed {dupes} duplicate rows")
            d.drop_duplicates(inplace=True)

    # referential integrity - order_items vs orders
    bad_items = check_referential_integrity(orders_clean, order_items)
    order_items_clean = order_items[~order_items.index.isin(bad_items.index)]

    # negative quantity - just noting it, not removing since these are returns (valid business case)
    neg_qty_count = (order_items_clean["quantity"] < 0).sum()
    log(f"order_items: {neg_qty_count} rows have negative quantity (these are returns, keeping them)")

    # save cleaned files
    customers.to_csv(os.path.join(CLEAN_DIR, "customers_clean.csv"), index=False)
    products_clean.to_csv(os.path.join(CLEAN_DIR, "products_clean.csv"), index=False)
    orders_clean.to_csv(os.path.join(CLEAN_DIR, "orders_clean.csv"), index=False)
    order_items_clean.to_csv(os.path.join(CLEAN_DIR, "order_items_clean.csv"), index=False)

    log("\nall cleaned files saved to data/cleaned/")

    # write the report
    with open(os.path.join(CLEAN_DIR, "issues_report.txt"), "w") as f:
        f.write("\n".join(issues_log))

    print("\nreport saved")