import psycopg2

CONN_STR = "postgresql://neondb_owner:npg_v23EjFNHXzUZ@ep-still-morning-atgoy6du.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"

with open("sql/task5_audit.sql") as f:
    sql = f.read()

conn = psycopg2.connect(CONN_STR)
cur = conn.cursor()
cur.execute(sql)
conn.commit()

for row in cur.fetchall():
    print(row)

cur.close()
conn.close()
print("done")