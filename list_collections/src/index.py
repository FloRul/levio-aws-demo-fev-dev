import os
import psycopg2

PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
PGVECTOR_USER = os.environ.get("PGVECTOR_USER", "postgres")
COLLECTION_TABLE_NAME = "langchain_pg_collection"
PASSWORD = "dbreader"
# Initialize the connection outside of the handler
conn = psycopg2.connect(
    dbname=PGVECTOR_DATABASE,
    user=PGVECTOR_USER,
    password=PASSWORD,  # read only account
    host=PGVECTOR_HOST,
    port=PGVECTOR_PORT,
)


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
            rows = [row[0] for row in rows]

        return {
            "sessionState": {
                "intent": {
                    "name": "ListCollections",
                    "state": "Fulfilled",
                    "confirmationState": "None",
                },
                "sessionAttributes": {"options": rows},
            },
            "messages": [
                {
                    "contentType": "PlainText",
                    "content": "Voici les sources de données disponibles :",
                }
            ],
            "requestAttributes": {},
        }
    except Exception as e:
        print(f"Error querying the database: {e}")
        raise e
