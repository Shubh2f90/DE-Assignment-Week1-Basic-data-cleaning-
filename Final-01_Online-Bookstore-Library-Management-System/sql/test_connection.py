import psycopg2

conn = psycopg2.connect("postgresql://neondb_owner:npg_v23EjFNHXzUZ@ep-still-morning-atgoy6du.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require")
cur = conn.cursor()
cur.execute("SELECT version();")
print(cur.fetchone())
conn.close()