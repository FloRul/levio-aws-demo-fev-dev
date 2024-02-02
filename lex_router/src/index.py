import os
import json
import boto3

# reuse client connection as global
client = boto3.client("lambda")


def router(event):
    try:
        intent_name = event["sessionState"]["intent"]["name"]
        fn_name = os.environ.get(intent_name)
        print(f"Intent: {intent_name} -> Lambda: {fn_name}")
        if not fn_name:
            raise ValueError(f"Intent {intent_name} could not be resolved")
        else:
            invoke_response = client.invoke(
                FunctionName=fn_name, Payload=json.dumps(event)
            )
            print(f"invoke respoonse : {invoke_response}")
            payload = json.load(invoke_response["Payload"])
            return payload
    except Exception as e:
        print(f"Error during intent lambda routing : {e}")
        raise e


def lambda_handler(event, context):
    print(event)
    response = router(event)
    return response
