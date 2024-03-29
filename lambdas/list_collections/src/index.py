import os
import psycopg2
import json

PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
PGVECTOR_USER = os.environ.get("PGVECTOR_USER", "postgres")
COLLECTION_TABLE_NAME = "langchain_pg_collection"
PASSWORD = "dbreader"

INTENT_NAME = "SelectCollection"
SLOT_TO_ELICIT = "collection"
# Initialize the connection outside of the handler
conn = psycopg2.connect(
    dbname=PGVECTOR_DATABASE,
    user=PGVECTOR_USER,
    password=PASSWORD,  # read only account
    host=PGVECTOR_HOST,
    port=PGVECTOR_PORT,
)

headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}


def lambda_handler(event, context):
    global conn  # Declare conn as a global variable
    rows = []
    try:
        # Check if the connection is still open
        if conn.closed:
            # If it's closed, reinitialize it
            conn = psycopg2.connect(
                dbname=PGVECTOR_DATABASE,
                user=PGVECTOR_USER,
                password=PASSWORD,  # read only account
                host=PGVECTOR_HOST,
                port=PGVECTOR_PORT,
            )

        with conn.cursor() as cur:
            cur.execute(f"SELECT name FROM {COLLECTION_TABLE_NAME}")
            rows = cur.fetchall()

        # Format the rows into a list of strings
        rows = [row[0] for row in rows]

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "collections": rows,
                }
            ),
            "headers": headers,
        }
    except Exception as e:
        print(f"Error querying the database: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps(e),
            "headers": headers,
            "isBase64Encoded": False,
        }
