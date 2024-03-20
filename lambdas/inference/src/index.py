import json
import os
import boto3
from retrieval import Retrieval
from history import History
import uuid


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
    user_message: str,
    source: str,
    message_history: list,
):
    maxtokens = ENV_VARS["max_tokens"]
    if source == "email":
        maxtokens *= 2
    if source == "call":
        maxtokens //= 2

    messages = message_history.append({"role": "user", "content": user_message})

    body = json.dumps(
        {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": maxtokens,
            "temperature": ENV_VARS["temperature"],
            "system": system_prompt,
            "messages": messages,
        }
    )
    try:
        response = boto3.client("bedrock-runtime").invoke_model(
            modelId=ENV_VARS["model_id"],
            accept="application/json",
            contentType="application/json",
            body=body,
        )

        res = response["body"].read().decode("utf-8")
        return res["content"][0]["text"]
    except Exception as e:
        print(f"Model invocation error : {e}")
        raise e


def lambda_handler(event, context):
    response = "this is a dummy response"
    source = event.get("queryStringParameters", {}).get("source", "message")
    embedding_collection_name = event["queryStringParameters"]["collectionName"]

    enable_history = False

    sessionId = uuid.uuid1()
    if "sessionId" in event["queryStringParameters"]:
        sessionId = event["queryStringParameters"]["sessionId"]

    history = History(session_id=sessionId)

    try:
        query = event["queryStringParameters"]["query"]
        docs = []
        chat_history = []

        # fetch documents
        retrieval = Retrieval(
            collection_name=embedding_collection_name,
            relevance_treshold=ENV_VARS["relevance_treshold"],
        )
        docs = retrieval.fetch_documents(query=query, top_k=ENV_VARS["top_k"])

        # fetch chat history
        chat_history = json.loads(history.get(limit=5))

        # prepare the prompt
        system_prompt = prepare_system_prompt(query, docs, source)
        user_message = query
        response = invoke_model(
            system_prompt=system_prompt,
            user_message=user_message,
            source=source,
            message_history=get_chat_history(chat_history),
        )

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
            "body": json.dumps(e),
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
