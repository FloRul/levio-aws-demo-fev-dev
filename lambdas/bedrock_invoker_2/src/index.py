import boto3
import json
from botocore.exceptions import BotoCoreError, ClientError
from botocore.config import Config
import os
import base64

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock-runtime', config=Config(read_timeout=1000))


def lambda_handler(event, context):
    """
    Invokes a bedrock model with the given parameters and s3 text object
    """
    system_prompt = event['system_prompt']
    prompt = event['prompt']
    s3_uris = event['s3_uris']  


    user_prompt_content = []

    for s3_uri in s3_uris:
        bucket, key = s3_uri.replace("s3://", "").split('/', 1)
        extension = os.path.splitext(key)[1]

        try:
            print(f"Fetching file bucket: {bucket}, key: {key}")
            s3_object = s3.get_object(Bucket=bucket, Key=key)

            if extension in ['.txt', '.csv', '.json']:
                user_prompt_content.append({
                    'type': 'text',
                    'text': s3_object['Body'].read().decode('utf-8')
                })
            elif extension in ['.jpg', '.png', '.jpeg']:
                image_data = s3_object['Body'].read()
                encoded_image_data = base64.b64encode(image_data).decode()
                user_prompt_content.append({
                    'type': 'image',
                    'source': {'type': 'base64', 'data': encoded_image_data, 'media_type': f'image/{'png' if extension == '.png' else 'jpeg'}'}
                })

        except ClientError as e:
            return {
                'statusCode': 400,
                'body': str(e)
            }

    user_prompt_content.append({
        'type': 'text',
        'text': f"{prompt}"
    })

    claude_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": [
            {
                "role": "user",
                "content": user_prompt_content
            }
        ]
    }

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
