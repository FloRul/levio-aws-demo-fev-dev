import json
import os
import boto3
from retrieval import Retrieval
from history import History

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}

ENV_VARS = {
    "relevance_treshold": os.environ.get("RELEVANCE_TRESHOLD", 0.5),
    "model_id": os.environ.get("MODEL_ID", "anthropic.claude-instant-v1"),
    "system_prompt": os.environ.get(
        "SYSTEM_PROMPT", "Answer in four to five sentences.Answer in french."
    ),
    "enable_history": int(os.environ.get("ENABLE_HISTORY", 1)),
    "enable_retrieval": int(os.environ.get("ENABLE_RETRIEVAL", 1)),
    "max_tokens": int(os.environ.get("MAX_TOKENS", 100)),
    "enable_inference": int(os.environ.get("ENABLE_INFERENCE", 1)),
    "top_k": int(os.environ.get("TOP_K", 10)),
    "top_p": float(os.environ.get("TOP_P", 0.9)),
    "temperature": float(os.environ.get("TEMPERATURE", 0.3)),
}


def prepare_prompt(query: str, docs: list, history: list):
    basic_prompt = f'\n\nHuman: The user sent the following message : "{query}".'
    document_prompt = prepare_document_prompt(docs)
    history_prompt = prepare_history_prompt(history)
    final_prompt = f"{ENV_VARS['system_prompt']}{basic_prompt}\n{document_prompt}\n{history_prompt}\n\nAssistant:"
    return final_prompt


def prepare_document_prompt(docs):
    if docs:
        docs_context = ".\n".join(doc.page_content for doc in docs)
        return f"Here is a set of quotes between <quotes></quotes> XML tags to help you answer: <quotes>{docs_context}</quotes>."
    return "I could not find any relevant quotes to help you answer the user's query."


def prepare_history_prompt(history):
    if history:
        history_context = ".\n".join(
            f"Human:{x['HumanMessage']}\nAssistant:{x['AssistantMessage']}"
            for x in history
        )
        return f"Here is the history of the previous messages history between <history></history> XML tags: <history>{history_context}</history>."
    return ""


def invoke_model(prompt: str):
    body = json.dumps(
        {
            "prompt": prompt,
            "max_tokens_to_sample": ENV_VARS["max_tokens"],
            "temperature": ENV_VARS["temperature"],
            "top_p": ENV_VARS["top_p"],
        }
    )
    try:
        response = boto3.client("bedrock-runtime").invoke_model(
            body=body,
            modelId=ENV_VARS["model_id"],
            accept="application/json",
            contentType="application/json",
        )
        body = response["body"].read().decode("utf-8")
        json_body = json.loads(body)
        return json_body["completion"]
    except Exception as e:
        print(f"Model invocation error : {e}")
        raise e


def lambda_handler(event, context):
    response = "this is a dummy response"
    history = History(event["queryStringParameters"]["sessionId"])
    embedding_collection_name = event["queryStringParameters"]["collectionName"]

    try:
        query = event["queryStringParameters"]["query"]
        docs = []
        chat_history = []

        if ENV_VARS["enable_inference"]:
            if ENV_VARS["enable_retrieval"]:
                retrieval = Retrieval(
                    collection_name=embedding_collection_name,
                    relevance_treshold=ENV_VARS["relevance_treshold"],
                )
                docs = retrieval.fetch_documents(query=query, top_k=ENV_VARS["top_k"])

            if ENV_VARS["enable_history"]:
                chat_history = json.loads(history.get(limit=10))

            # prepare the prompt
            prompt = prepare_prompt(query, docs, chat_history)
            response = invoke_model(prompt)

            if ENV_VARS["enable_history"]:
                history.add(
                    human_message=query, assistant_message=response, prompt=prompt
                )

        return {
            "statusCode": 200,
            "body": response,
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
