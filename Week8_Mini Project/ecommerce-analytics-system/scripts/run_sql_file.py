import sqlite3
from tabulate import tabulate

DB_PATH = "ecommerce.db"


def run_sql_file(path):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    with open(path) as f:
        sql = f.read()

    # split into separate queries - assuming each query ends with ;
    raw_chunks = [q.strip() for q in sql.split(";") if q.strip()]

    queries = []
    for chunk in raw_chunks:
        # remove comment-only lines from each chunk, keep the actual SQL
        lines = [line for line in chunk.split("\n") if not line.strip().startswith("--")]
        cleaned = "\n".join(lines).strip()
        if cleaned:
            queries.append(cleaned)

    for i, q in enumerate(queries, 1):
        print(f"\n--- Query {i} ---")
        cur.execute(q)
        cols = [desc[0] for desc in cur.description]
        rows = cur.fetchall()
        print(tabulate(rows, headers=cols, tablefmt="grid"))

    conn.close()


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("usage: python scripts/run_sql_file.py sql/basic_queries.sql")
    else:
        run_sql_file(sys.argv[1])