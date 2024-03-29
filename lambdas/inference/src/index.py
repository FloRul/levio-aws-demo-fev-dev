import json
import os
import boto3
from retrieval import Retrieval
from history import History
import uuid
from aws_lambda_powertools import Logger, Metrics, Tracer

tracer = Tracer()
logger = Logger()
metrics = Metrics()

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}

ENV_VARS = {
    "relevance_treshold": os.environ.get("RELEVANCE_TRESHOLD", 0.5),
    "model_id": os.environ.get("MODEL_ID", "anthropic.claude-instant-v1"),
    "system_prompt": os.environ.get("SYSTEM_PROMPT", "Answer in french."),
    "max_tokens": int(os.environ.get("MAX_TOKENS", 100)),
    "top_k": int(os.environ.get("TOP_K", 10)),
    "temperature": float(os.environ.get("TEMPERATURE", 0.01)),
}


def prepare_system_prompt(docs: list, source: str):
    source_prompt = prepare_source_prompt(source)
    document_prompt = prepare_document_prompt(docs)

    return f"""{source_prompt}
    {document_prompt}
    {os.environ.get("SYSTEM_PROMPT", "Answer in french.")}"""


def prepare_source_prompt(source: str):
    if source == "email":
        return os.environ.get(
            "EMAIL_PROMPT", "FALLBACK - You are currently answering an email\n"
        )
    elif source == "call":
        return os.environ.get(
            "CALL_PROMPT", "FALLBACK - Make your answer short and concise.\n"
        )
    else:
        return os.environ.get(
            "CHAT_PROMPT", "FALLBACK - Make your answer short and concise.\n"
        )


def prepare_document_prompt(docs):
    if len(docs) > 0:
        docs_context = ".\n".join(doc[0].page_content for doc in docs)
        return os.environ.get(
            "DOCUMENT_PROMPT", "Here are some relevant quotes:\n{}\n"
        ).format(docs_context)
    return os.environ.get(
        "NO_DOCUMENT_FOUND_PROMPT",
        "You could not find any relevant quotes to help answer the user's query.",
    )


def get_chat_history(history):
    chat_history = []
    if history:
        for x in history:
            chat_history.append({"role": "user", "content": x["HumanMessage"]})
            chat_history.append({"role": "assistant", "content": x["AssistantMessage"]})
    return chat_history


def invoke_model(
    system_prompt: str,
    source: str,
    messages: list,
):
    max_tokens = ENV_VARS["max_tokens"]
    if source == "email":
        max_tokens *= 2
    if source == "call":
        max_tokens //= 2

    try:
        response = boto3.client("bedrock-runtime").invoke_model(
            modelId=ENV_VARS["model_id"],
            accept="application/json",
            contentType="application/json",
            body=json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": max_tokens,
                    "temperature": ENV_VARS["temperature"],
                    "system": system_prompt,
                    "messages": messages,
                }
            ),
        )

        res = response["body"].read().decode("utf-8")
        logger.info(f"Model response: {res}")
        return res
    except Exception as e:
        print(f"Model invocation error : {e}")
        raise e


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    response = "this is a dummy response"
    try:
        source = event.get("queryStringParameters", {}).get("source", "message")
        embedding_collection_name = event["queryStringParameters"]["collectionName"]

        logger.info(str(event))

        sessionId = str(uuid.uuid1())

        if "sessionId" in event["queryStringParameters"]:
            sessionId = event["queryStringParameters"]["sessionId"]

        logger.info(f"loading history for session {sessionId}")
        history = History(session_id=sessionId)

        query = event["queryStringParameters"]["query"]
        docs = []

        logger.info(f"intializing retrieval for query {query}")
        # fetch documents
        retrieval = Retrieval(
            collection_name=embedding_collection_name,
            relevance_treshold=ENV_VARS["relevance_treshold"],
        )
        docs = retrieval.fetch_documents(query=query, top_k=ENV_VARS["top_k"])

        system_prompt = prepare_system_prompt(docs, source)
        logger.info(f"System prompt: {system_prompt}")

        logger.info("fetching chat history...")
        chat_history = history.get(limit=5)
        chat_history.append(
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": query,
                    },
                ],
            }
        )

        logger.info(f"Chat history: {chat_history}")

        raw_response = invoke_model(
            system_prompt=system_prompt,
            source=source,
            messages=chat_history,
        )

        response_dict = json.loads(raw_response)

        # Extract the assistant's messages from the response
        assistant_messages = [item["text"] for item in response_dict["content"]]
        # Join all the assistant's messages into a single string
        response = " ".join(assistant_messages)

        # save the conversation history
        history.add(
            human_message=query, assistant_message=response, prompt=system_prompt
        )
        result = {
            "completion": response,
            "final_prompt": system_prompt,
            "docs": json.dumps(
                list(
                    map(
                        lambda x: {
                            "content": x[0].page_content,
                            "metadata": x[0].metadata,
                            "score": x[1],
                        },
                        docs,
                    )
                )
            ),
        }
        return {
            "statusCode": 200,
            "body": json.dumps(result),
            "headers": HEADERS,
            "isBase64Encoded": False,
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps(str(e)),
            "headers": HEADERS,
        }


# The Anthropic Claude model returns the following fields for a messages inference call.
# https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-anthropic-claude-messages.html

# {
#     "id": string,
#     "model": string,
#     "type" : "message",
#     "role" : "assistant",
#     "content": [
#         {
#             "type": "text",
#             "text": string
#         }
#     ],
#     "stop_reason": string,
#     "stop_sequence": string,
#     "usage": {
#         "input_tokens": integer,
#         "output_tokens": integer
#     }

# }
