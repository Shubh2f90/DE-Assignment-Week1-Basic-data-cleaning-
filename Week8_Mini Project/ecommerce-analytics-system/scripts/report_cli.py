import sqlite3
import argparse
from datetime import datetime, timedelta

DB_PATH = "ecommerce.db"


def get_period_stats(cur, start_date, end_date):
    # total orders + unique customers
    cur.execute("""
        SELECT COUNT(DISTINCT order_id), COUNT(DISTINCT customer_id)
        FROM orders
        WHERE order_date >= ? AND order_date < ?
    """, (start_date, end_date))
    total_orders, unique_customers = cur.fetchone()

    # revenue in this window
    cur.execute("""
        SELECT SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0))
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_date >= ? AND o.order_date < ? AND oi.quantity > 0
    """, (start_date, end_date))
    revenue = cur.fetchone()[0] or 0

    # top 3 products by revenue in this window
    cur.execute("""
        SELECT p.product_name, SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS rev
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE o.order_date >= ? AND o.order_date < ? AND oi.quantity > 0
        GROUP BY p.product_name
        ORDER BY rev DESC
        LIMIT 3
    """, (start_date, end_date))
    top_products = cur.fetchall()

    return {
        "orders": total_orders,
        "customers": unique_customers,
        "revenue": revenue,
        "top_products": top_products,
    }


def get_previous_period(start_date, end_date, report_type):
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    diff = end - start

    prev_end = start
    prev_start = start - diff

    return prev_start.strftime("%Y-%m-%d"), prev_end.strftime("%Y-%m-%d")


def pct_change(old, new):
    if old == 0:
        return None
    return round((new - old) * 100.0 / old, 2)


def print_report(report_type, start_date, end_date, current, previous):
    print(f"\n===== {report_type.upper()} REPORT ({start_date} to {end_date}) =====\n")
    print(f"Total Orders     : {current['orders']}")
    print(f"Unique Customers : {current['customers']}")
    print(f"Total Revenue    : {round(current['revenue'], 2)}")

    print("\nTop 3 Products:")
    if current["top_products"]:
        for name, rev in current["top_products"]:
            print(f"  - {name}: {round(rev, 2)}")
    else:
        print("  (no orders in this period)")

    print("\nComparison with previous period:")
    order_change = pct_change(previous["orders"], current["orders"])
    revenue_change = pct_change(previous["revenue"], current["revenue"])

    print(f"  Orders change  : {order_change if order_change is not None else 'N/A'}%")
    print(f"  Revenue change : {revenue_change if revenue_change is not None else 'N/A'}%")
    print()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="E-commerce report CLI tool")
    parser.add_argument("--report", choices=["daily", "weekly", "monthly"], required=True)
    parser.add_argument("--start", required=True, help="start date YYYY-MM-DD")
    parser.add_argument("--end", required=True, help="end date YYYY-MM-DD")
    args = parser.parse_args()

    # basic input validation
    try:
        datetime.strptime(args.start, "%Y-%m-%d")
        datetime.strptime(args.end, "%Y-%m-%d")
    except ValueError:
        print("Error: dates must be in YYYY-MM-DD format")
        exit(1)

    if args.start >= args.end:
        print("Error: start date must be before end date")
        exit(1)

    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
    except sqlite3.Error as e:
        print(f"Error connecting to database: {e}")
        exit(1)

    current_stats = get_period_stats(cur, args.start, args.end)
    prev_start, prev_end = get_previous_period(args.start, args.end, args.report)
    previous_stats = get_period_stats(cur, prev_start, prev_end)

    print_report(args.report, args.start, args.end, current_stats, previous_stats)

    conn.close()