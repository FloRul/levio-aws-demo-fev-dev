import boto3
import json
from botocore.exceptions import BotoCoreError, ClientError
from botocore.config import Config

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime', config=Config(read_timeout=1000))

def lambda_handler(event, context):
    """
    Invokes a bedrock model with the given parameters and s3 text object
    """
    s3_arn = event['s3_arn']
    system_prompt = event['system_prompt']
    prompts = event['prompts']
    s3_uri = s3_arn.replace("s3://", "")
    bucket, key = s3_uri.split('/', 1)

    print(f"Fetching file bucket: {bucket}, key: {key}")
    try:
        s3_object = s3.get_object(Bucket=bucket, Key=key)
    except ClientError as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }

    extracted_text = s3_object['Body'].read().decode('utf-8')
    print(f"Extracted text that is {len(extracted_text)} characters long")
    print(f"Preview of the first 100 chars: {extracted_text[:100]}")


    claude_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        'type': "text",
                        "text": f"<document>{extracted_text}</document>"
                    }
                ]
            }
        ] + [
            {
                "role": "user",
                "content": [
                    {
                        'type': "text",
                        "text": f"{prompt}"
                    }
                ]
            } for prompt in prompts
        ]
    }

    bedrock_model = 'anthropic.claude-3-sonnet-20240229-v1:0'
    print(f"Invoke bedock with this model: ", bedrock_model)
    print(f"Invoke claude with system prompt: ", system_prompt)
    print(f"Invoke claude with prompt: ", prompts)


    try:
        response = bedrock.invoke_model(
            body=json.dumps(claude_body),
            contentType='application/json',
            accept='application/json',
            modelId=bedrock_model,
        )

        return {
            'statusCode': 200,
            'body': response['body'].read().decode('utf-8')
        }

    except BotoCoreError as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }
