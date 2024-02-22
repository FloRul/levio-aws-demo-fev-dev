import json
import os
import boto3
from retrieval import Retrieval
from history import History


def prepare_source_prompt(source: str):
    if source == "email":
        return "You are currently answering an email so your answer can be more detailed. After you finish answering the initial query generate follow-up questions and answer it too up to 4 questions."
    elif source == "call":
        return "Make your answer short and concise."
    else:
        return "You are currently answering a message."


HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}

ENV_VARS = {
    "relevance_treshold": os.environ.get("RELEVANCE_TRESHOLD", 0.5),
    "model_id": os.environ.get("MODEL_ID", "anthropic.claude-instant-v1"),
    "system_prompt": os.environ.get("SYSTEM_PROMPT", "Answer in french."),
    "enable_history": int(os.environ.get("ENABLE_HISTORY", 1)),
    "enable_retrieval": int(os.environ.get("ENABLE_RETRIEVAL", 1)),
    "max_tokens": int(os.environ.get("MAX_TOKENS", 100)),
    "enable_inference": int(os.environ.get("ENABLE_INFERENCE", 1)),
    "top_k": int(os.environ.get("TOP_K", 10)),
    "top_p": float(os.environ.get("TOP_P", 0.9)),
    "temperature": float(os.environ.get("TEMPERATURE", 0.3)),
}


def prepare_prompt(query: str, docs: list, history: list, source: str):
    basic_prompt = f'\n\nHuman: The user sent the following message : "{query}".'
    document_prompt = prepare_document_prompt(docs)
    history_prompt = prepare_history_prompt(history)
    source_prompt = prepare_source_prompt(source)
    final_prompt = f"""{basic_prompt}\n
    {source_prompt}\n
    {document_prompt}\n
    {history_prompt}\n
    {ENV_VARS['system_prompt']}\n
    \nAssistant:"""
    print(final_prompt)
    return final_prompt


def prepare_document_prompt(docs):
    if docs:
        docs_context = ".\n".join(doc[0].page_content for doc in docs)
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


def invoke_model(prompt: str, source: str = "message"):
    maxtokens = ENV_VARS["max_tokens"]
    if source == "email":
        maxtokens *= 2
    if source == "call":
        maxtokens //= 2
    body = json.dumps(
        {
            "prompt": prompt,
            "max_tokens_to_sample": maxtokens,
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
    source = event.get("queryStringParameters", {}).get("source", "message")
    embedding_collection_name = event["queryStringParameters"]["collectionName"]
    
    enable_history = False
    if "sessionId" in event["queryStringParameters"]:
        enable_history = True
        history = History(event["queryStringParameters"]["sessionId"])

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
            if enable_history:
                chat_history = json.loads(history.get(limit=10))

            # prepare the prompt
            prompt = prepare_prompt(query, docs, chat_history, source)
            response = invoke_model(prompt, source=source)

            if enable_history:
                history.add(
                    human_message=query, assistant_message=response, prompt=prompt
                )
        result = {
            "completion": response,
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
