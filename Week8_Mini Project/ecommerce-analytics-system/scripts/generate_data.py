import os
import random
import csv
from faker import Faker

fake = Faker()
random.seed(42)

NUM_CUSTOMERS = 600
NUM_PRODUCTS = 150
NUM_ORDERS = 700
NUM_ORDER_ITEMS = 1500

RAW_DIR = os.path.join("data", "raw")
os.makedirs(RAW_DIR, exist_ok=True)

CUSTOMER_TYPES = ["REGULAR", "PREMIUM", "VIP"]
ORDER_STATUSES = ["PLACED", "SHIPPED", "DELIVERED", "CANCELLED", "RETURNED"]
CATEGORIES = {
    "Electronics": ["Mobiles", "Laptops", "Accessories", "Cameras"],
    "Clothing": ["Men", "Women", "Kids", "Footwear"],
    "Home": ["Furniture", "Kitchen", "Decor", "Appliances"],
    "Books": ["Fiction", "Non-Fiction", "Academic", "Comics"],
}
REGION_CODES = ["NORTH", "SOUTH", "EAST", "WEST", "CENTRAL"]


# make some emails invalid on purpose
def make_bad_email(email):
    choice = random.choice(["no_at", "no_domain", "double_dot"])
    if choice == "no_at":
        return email.replace("@", "")
    elif choice == "no_domain":
        return email.split("@")[0] + "@"
    else:
        return email.replace("@", "@@")


def generate_customers():
    rows = []
    for i in range(1, NUM_CUSTOMERS + 1):
        name = fake.name()
        email = fake.email()

        # 2% invalid emails
        if random.random() < 0.02:
            email = make_bad_email(email)

        reg_date = fake.date_time_between(start_date="-3y", end_date="now")
        rows.append({
            "customer_id": i,
            "customer_name": name,
            "email": email,
            "registration_date": reg_date.strftime("%Y-%m-%d %H:%M:%S"),
            "customer_type": random.choice(CUSTOMER_TYPES),
        })

    with open(os.path.join(RAW_DIR, "customers.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    print("customers.csv done -", len(rows), "rows")
    return rows


def generate_products():
    rows = []
    for i in range(1, NUM_PRODUCTS + 1):
        category = random.choice(list(CATEGORIES.keys()))
        subcategory = random.choice(CATEGORIES[category])
        name = fake.word().capitalize() + " " + fake.word().capitalize()

        # some names messy - extra spaces, random case
        if random.random() < 0.15:
            variants = [
                "  " + name.lower() + "  ",
                name.upper() + "   ",
                " " + name,
            ]
            name = random.choice(variants)

        cost_price = round(random.uniform(50, 5000), 2)
        rows.append({
            "product_id": i,
            "product_name": name,
            "category": category,
            "subcategory": subcategory,
            "cost_price": cost_price,
        })

    with open(os.path.join(RAW_DIR, "products.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    print("products.csv done -", len(rows), "rows")
    return rows


def generate_orders(customer_ids):
    rows = []
    for i in range(1, NUM_ORDERS + 1):
        # 5% null customer id
        cust_id = "" if random.random() < 0.05 else random.choice(customer_ids)

        order_dt = fake.date_time_between(start_date="-2y", end_date="now")

        # some dates wrong format on purpose (DD-MM-YYYY)
        if random.random() < 0.08:
            date_str = order_dt.strftime("%d-%m-%Y")
        else:
            date_str = order_dt.strftime("%Y-%m-%d %H:%M:%S")

        rows.append({
            "order_id": i,
            "customer_id": cust_id,
            "order_date": date_str,
            "status": random.choice(ORDER_STATUSES),
            "region_code": random.choice(REGION_CODES),
        })

    with open(os.path.join(RAW_DIR, "orders.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    print("orders.csv done -", len(rows), "rows")
    return rows


def generate_order_items(order_ids, product_ids):
    rows = []
    for i in range(1, NUM_ORDER_ITEMS + 1):
        # mostly real order_id, but 3% fake ones so integrity check has something to find
        if random.random() < 0.03:
            order_id = max(order_ids) + random.randint(1, 500)
        else:
            order_id = random.choice(order_ids)

        qty = random.randint(1, 8)
        if random.random() < 0.03:
            qty = -qty  # treating as a return

        rows.append({
            "item_id": i,
            "order_id": order_id,
            "product_id": random.choice(product_ids),
            "quantity": qty,
            "unit_price": round(random.uniform(100, 8000), 2),
            "discount_percent": round(random.uniform(0, 100), 1),
        })

    with open(os.path.join(RAW_DIR, "order_items.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    print("order_items.csv done -", len(rows), "rows")
    return rows


if __name__ == "__main__":
    customers = generate_customers()
    products = generate_products()
    orders = generate_orders([c["customer_id"] for c in customers])
    order_items = generate_order_items(
        [o["order_id"] for o in orders],
        [p["product_id"] for p in products],
    )
    print("all files generated in data/raw/")