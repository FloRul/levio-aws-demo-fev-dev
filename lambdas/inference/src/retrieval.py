from calendar import c
import os
import json
from botocore.exceptions import ClientError
from langchain_community.vectorstores.pgvector import PGVector

import boto3
from langchain_community.embeddings import BedrockEmbeddings

def get_secret():
    try:
        response = boto3.client("secretsmanager").get_secret_value(
            SecretId=os.environ.get("PGVECTOR_PASSWORD_SECRET_NAME")
        )
        return response["SecretString"]
    except ClientError as e:
        raise e


class Retrieval:
    def __init__(
        self,
        collection_name,
        relevance_treshold,
    ):
        self._relevance_treshold = relevance_treshold
        PGVECTOR_DRIVER = os.environ.get("PGVECTOR_DRIVER", "psycopg2")
        PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
        PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
        PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
        PGVECTOR_USER = os.environ.get("PGVECTOR_USER", "postgres")
        PGVECTOR_PASSWORD = get_secret()
        self._vector_store = PGVector(
            connection_string=PGVector.connection_string_from_db_params(
                driver=PGVECTOR_DRIVER,
                host=PGVECTOR_HOST,
                port=PGVECTOR_PORT,
                database=PGVECTOR_DATABASE,
                user=PGVECTOR_USER,
                password=PGVECTOR_PASSWORD,
            ),
            collection_name=collection_name,
            embedding_function=BedrockEmbeddings(
                client=boto3.client("bedrock-runtime")
            ),
        )

    def fetch_documents(self, query: str, top_k: int = 10):
        try:
            docs = self._vector_store.similarity_search_with_relevance_scores(
                query=query, k=top_k
            )
            print(f"retrieved docs: {docs}")
            return [x[0] for x in docs if x[1] > self._relevance_treshold]
        except Exception as e:
            print(f"Error while retrieving documents : {e}")
            raise e