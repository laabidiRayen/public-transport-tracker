import psycopg2
from psycopg2 import extensions
import sys
import os

# Set environment variable for PostgreSQL
os.environ['PGCLIENTENCODING'] = 'WIN1252'

# Force UTF-8 encoding for Python output
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

try:
    conn = psycopg2.connect(
        dbname='transport_db',
        user='postgres',
        password='postgres',
        host='localhost',
        port='5432'
    )
    
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM routes;')
    count = cur.fetchone()[0]
    print('✓ Connected to PostgreSQL!')
    print('✓ Routes count: {}'.format(count))
    
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name")
    tables = cur.fetchall()
    print('✓ Tables found: {}'.format(len(tables)))
    for table in tables:
        print('  - {}'.format(table[0]))
    
    conn.close()
    print('✓ All tests passed!')
except Exception as e:
    import traceback
    print('✗ Error: {}'.format(type(e).__name__))
    traceback.print_exc()
