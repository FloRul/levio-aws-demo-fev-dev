import os
import psycopg2

# from aws_lambda_powertools.utilities import parameters

PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
PGVECTOR_USER = os.environ.get("PGVECTOR_USER", "postgres")
# PG_PASSWORD = parameters.get_secret(
#     os.environ.get("PG_PASSWORD_SECRET_NAME", "pg-password")
# )

COLLECTION_TABLE_NAME = "langchain_pg_collection"


def lambda_handler(event, context):
    rows = []
    try:
        # Connect to the database
        with psycopg2.connect(
            dbname=PGVECTOR_DATABASE,
            user=PGVECTOR_USER,
            password="dbreader",  # read only account
            host=PGVECTOR_HOST,
            port=PGVECTOR_PORT,
        ) as conn:
            with conn.cursor() as cur:
                # Execute a query
                cur.execute(f"SELECT name FROM {COLLECTION_TABLE_NAME}")

                # Fetch the results
                rows = cur.fetchall()

                # Print the results
                for row in rows:
                    rows.append(row)

        return rows
    except Exception as e:
        print(f"Error querying the database: {e}")
        raise e
