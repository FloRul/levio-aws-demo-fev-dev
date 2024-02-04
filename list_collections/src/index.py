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

        # Format the sessionAttributes as a map of string to string
        sessionAttributes = {f"option{i}": option for i, option in enumerate(rows)}

        # Format the slots as a map of slot names to slot objects
        slots = {
            f"option{i}": {"shape": "Scalar", "value": option}
            for i, option in enumerate(rows)
        }

        response = {
            "sessionState": {
                "intent": {
                    "name": INTENT_NAME,
                    "state": "ReadyForFulfillment",
                    "confirmationState": "None",
                    "slots": slots,
                },
                "sessionAttributes": sessionAttributes,
            },
            "messages": [
                {
                    "contentType": "PlainText",
                    "content": f"Here are the collections: {', '.join(rows)}",
                }
            ],
            "requestAttributes": {},
        }
        return test_response()
    except Exception as e:
        print(f"Error querying the database: {e}")
        raise e


def test_response():
    return {
        "sessionState": {
            "dialogAction": {
                "slotToElicit": SLOT_TO_ELICIT,
                "type": "ElicitSlot",
            },
            "intent": {
                "confirmationState": "None",
                "name": INTENT_NAME,
                "state": "InProgress",
                "slots": {
                    SLOT_TO_ELICIT: {
                        "shape": "Scalar",
                        "value": {
                            "originalValue": "originalValue",
                            "interpretedValue": "interpretedValue",
                            "resolvedValues": ["resolvedValues"],
                        },
                    },
                },
            },
        },
        "messages": [
            {
                "contentType": "PlainText",
                "content": "the content of the message from the lambda list collections",
            },
        ],
    }
