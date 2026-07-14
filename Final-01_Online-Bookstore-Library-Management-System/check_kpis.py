import psycopg2

CONN_STR = "postgresql://neondb_owner:npg_v23EjFNHXzUZ@ep-still-morning-atgoy6du.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"

conn = psycopg2.connect(CONN_STR)
cur = conn.cursor()

views = [
    "gold_kpi_revenue_growth",
    "gold_kpi_retention_rate",
    "gold_kpi_sell_through",
    "gold_kpi_return_compliance",
    "gold_kpi_review_coverage",
]

for v in views:
    cur.execute(f"SELECT * FROM {v};")
    print(f"--- {v} ---")
    for row in cur.fetchall():
        print(row)

cur.close()
conn.close()
