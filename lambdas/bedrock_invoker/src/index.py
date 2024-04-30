import boto3
import json
from botocore.exceptions import BotoCoreError, ClientError

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime')


def lambda_handler(event, context):
    """
    Invokes a bedrock model with the given parameters and s3 text object
    """
    s3_arn = event['s3_arn']
    system_prompt = event['system_prompt']
    prompt = event['prompt']



    s3_path = s3_arn.replace("arn:aws:s3:::", "")
    bucket, key = s3_path.split('/', 1)

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
                        "text": f"{prompt} <document>{extracted_text}</document>"
                    }
                ]
            }
        ]
    }

    # Replace all the text values in messages with "redacted" since we don't want to log sensitive data
    redacted_claude_body = claude_body.copy()

    for message in redacted_claude_body["messages"]:
        for content in message["content"]:
            if 'text' in content:
                content['text'] = "redacted"

    print(f"Invoke bedrock with this body: ", redacted_claude_body)
    bedrock_model = 'anthropic.claude-3-sonnet-20240229-v1:0'
    print(f"Invoke bedock with this model: ", bedrock_model)
    print(f"Invoke claude with system prompt: ", system_prompt)
    print(f"Invoke claude with prompt: ", prompt)

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
