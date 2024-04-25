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
    prompt = event['prompt']

    # Parse the S3 ARN to get the bucket and key
    s3_path = s3_arn.replace("arn:aws:s3:::", "")
    bucket, key = s3_path.split('/', 1)

    # Download the file from S3
    try:
        s3_object = s3.get_object(Bucket=bucket, Key=key)
    except ClientError as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }

    # Extract text from the S3 object
    extracted_text = s3_object['Body'].read().decode('utf-8')

    claude_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "system": "Agis comme un analyste d'appel d'offres. Tu as en main un appel d'offres. Ton travail est de répondre aux questions posées afin de remplire un formulaire. Répond qu’à partir de appel d'offres, ne résume pas les questions dans tes réponses. Répond en français. ",
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

    # Invoke the Bedrock model with the extracted text and the provided parameters
    try:
        response = bedrock.invoke_model(
            body=json.dumps(claude_body),
            contentType='application/json',
            accept='application/json',
            modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        )
    except BotoCoreError as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }

    return {
        'statusCode': 200,
        'body': response
    }
