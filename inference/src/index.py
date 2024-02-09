import json
import os
import boto3
from botocore.exceptions import ClientError
from retrieval import Retrieval
from history import History


def get_secret():
    try:
        response = boto3.client("secretsmanager").get_secret_value(
            SecretId=os.environ.get("PGVECTOR_PASSWORD_SECRET_NAME")
        )
        return response["SecretString"]
    except ClientError as e:
        raise e


PGVECTOR_DRIVER = os.environ.get("PGVECTOR_DRIVER", "psycopg2")
PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
PGVECTOR_USER = os.environ.get("PGVECTOR_USER", "postgres")
PGVECTOR_PASSWORD = get_secret()

RELEVANCE_TRESHOLD = os.environ.get("RELEVANCE_TRESHOLD", 0.5)

MODEL_ID = os.environ.get("MODEL_ID", "anthropic.claude-instant-v1")
ACCEPT = "application/json"
CONTENT_TYPE = "application/json"


def prepare_prompt(query: str, docs: list, history: list):
    try:
        system_prompt = os.environ.get(
            "SYSTEM_PROMPT",
            "Answer in four to five sentences.Answer in french.",
        )
        final_prompt = "{}{}\n\nAssistant:"

        basic_prompt = (
            f"""\n\nHuman: The user sent the following message : \"{query}\"."""
        )

        if len(docs) > 0:
            docs_context = ".\n".join(map(lambda x: x.page_content, docs))
            document_prompt = f"""Here is a set of quotes between <quotes></quotes> XML tags to help you answer: <quotes>{docs_context}</quotes>."""
        if len(docs) == 0:
            document_prompt = f"""I could not find any relevant quotes to help you answer the user's query."""

        basic_prompt = f"""{basic_prompt}\n{document_prompt}"""

        if len(history) > 0:
            history_context = ".\n".join(
                map(
                    lambda x: f"""Human:{x['HumanMessage']}\nAssistant:{x['AssistantMessage']}""",
                    history,
                )
            )
            history_prompt = f"""Here is the history of the previous messages history between <history></history> XML tags: <history>{history_context}</history>."""
            basic_prompt = f"""{basic_prompt}\n{history_prompt}"""

        final_prompt = final_prompt.format(system_prompt, basic_prompt)
        return final_prompt
    except Exception as e:
        print(f"Error while preparing prompt : {e}")
        raise e


# def prepare_lex_response(assistant_message: str, intent: str):
#     return {
#         "sessionState": {
#             "dialogAction": {"type": "ElicitIntent"},
#             "intent": {"name": intent, "state": "InProgress"},
#         },
#         "messages": [{"contentType": "PlainText", "content": assistant_message}],
#         "requestAttributes": {},
#     }


def invoke_model(prompt: str, max_tokens: int, temperature: float, top_p: float):
    body = json.dumps(
        {
            "prompt": prompt,
            "max_tokens_to_sample": max_tokens,
            "temperature": temperature,
            "top_p": top_p,
        }
    )
    try:
        response = boto3.client("bedrock-runtime").invoke_model(
            body=body, modelId=MODEL_ID, accept=ACCEPT, contentType=CONTENT_TYPE
        )
        body = response["body"].read().decode("utf-8")
        json_body = json.loads(body)
        return json_body["completion"]
    except Exception as e:
        print(f"Model invocation error : {e}")
        raise e


def lambda_handler(event, context):
    intent = str(event["sessionState"]["intent"]["name"])
    response = "this is a dummy response"

    enable_history = int(os.environ.get("ENABLE_HISTORY", 1))
    enable_retrieval = int(os.environ.get("ENABLE_RETRIEVAL", 1))
    max_tokens_to_sample = int(os.environ.get("MAX_TOKENS", 100))
    enable_inference = int(os.environ.get("ENABLE_INFERENCE", 1))
    top_k = int(os.environ.get("TOP_K", 10))
    embedding_collection_name = os.environ.get("EMBEDDING_COLLECTION_NAME", "docs")
    top_p = float(os.environ.get("TOP_P", 0.9))
    temperature = float(os.environ.get("TEMPERATURE", 0.3))

    history = History(event["sessionId"])

    try:
        query = event["inputTranscript"]
        docs = []
        chat_history = []

        if enable_inference != 0:
            if enable_retrieval != 0:
                retrieval = Retrieval(
                    driver=PGVECTOR_DRIVER,
                    host=PGVECTOR_HOST,
                    port=PGVECTOR_PORT,
                    database=PGVECTOR_DATABASE,
                    user=PGVECTOR_USER,
                    password=PGVECTOR_PASSWORD,
                    collection_name=embedding_collection_name,
                    relevance_treshold=RELEVANCE_TRESHOLD,
                )
                docs = retrieval.fetch_documents(query=query, top_k=top_k)

            if enable_history != 0:
                chat_history = json.loads(history.get(limit=10))

            # prepare the prompt
            prompt = prepare_prompt(query, docs, chat_history)
            response = invoke_model(prompt, max_tokens_to_sample, temperature, top_p)

            if enable_history != 0:
                history.add(
                    human_message=query, assistant_message=response, prompt=prompt
                )

        # lex_response = prepare_lex_response(response, intent)
        return {"statusCode": 200, "body": response}
    except Exception as e:
        print(e)
        # return prepare_lex_response("Sorry, an error has happened.", intent)
        return {"statusCode": 500, "body": json.dumps(e)}
