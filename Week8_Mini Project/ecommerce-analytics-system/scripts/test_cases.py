import pandas as pd
from datetime import datetime

RAW_DIR = "data/raw"


def test_order_id_not_in_orders():
    """what happens when order_items has an order_id not in orders?"""
    orders = pd.read_csv(f"{RAW_DIR}/orders.csv")
    order_items = pd.read_csv(f"{RAW_DIR}/order_items.csv")

    valid_ids = set(orders["order_id"])
    bad_rows = order_items[~order_items["order_id"].isin(valid_ids)]

    print(f"[Test 1] order_id not in orders -> {len(bad_rows)} rows found")
    if len(bad_rows) > 0:
        print("these rows would break a join/foreign key, so they get filtered out during cleaning (check_referential_integrity)")
    return bad_rows


def test_discount_over_100():
    """what happens when discount_percent > 100?"""
    order_items = pd.read_csv(f"{RAW_DIR}/order_items.csv")
    bad_rows = order_items[order_items["discount_percent"] > 100]

    print(f"[Test 2] discount_percent > 100 -> {len(bad_rows)} rows found")
    if len(bad_rows) > 0:
        print("this would make revenue negative in the formula (1 - discount/100), which doesn't make business sense")
    else:
        print("none found in this dataset since generate_data.py caps it at 100, but the check itself would still catch it if present")
    return bad_rows


def test_zero_quantity():
    """what happens when quantity is 0?"""
    order_items = pd.read_csv(f"{RAW_DIR}/order_items.csv")
    zero_qty_rows = order_items[order_items["quantity"] == 0]

    print(f"[Test 3] quantity = 0 -> {len(zero_qty_rows)} rows found")
    print("a 0 quantity order item doesn't add revenue and doesn't count as a return either, "
          "so it's basically a useless row - should probably be dropped during cleaning")
    return zero_qty_rows


def test_future_order_date():
    """what happens when order_date is in the future?"""
    orders = pd.read_csv(f"{RAW_DIR}/orders.csv")

    def try_parse(v):
        v = str(v).strip()
        try:
            return pd.to_datetime(v, format="%Y-%m-%d %H:%M:%S")
        except ValueError:
            try:
                return pd.to_datetime(v, format="%d-%m-%Y")
            except ValueError:
                return pd.NaT

    orders["parsed_date"] = orders["order_date"].apply(try_parse)
    future_rows = orders[orders["parsed_date"] > datetime.now()]

    print(f"[Test 4] order_date in the future -> {len(future_rows)} rows found")
    if len(future_rows) > 0:
        print("these are probably data entry errors, should be flagged and reviewed, not silently included in reports")
    return future_rows


if __name__ == "__main__":
    print("---- Running edge case tests ----\n")
    test_order_id_not_in_orders()
    print()
    test_discount_over_100()
    print()
    test_zero_quantity()
    print()
    test_future_order_date()
    print("\n---- done ----")