import boto3
import json
from botocore.exceptions import BotoCoreError, ClientError

s3 = boto3.client('s3')
bedrock = boto3.client('bedrock')

def lambda_handler(event, context):
    """
    Invokes a bedrock model with the given parameters and s3 text object
    """
    s3_arn = event['s3_arn']
    bedrock_params = event['bedrock_params']
    prompt = event['prompt']

    # Parse the S3 ARN to get the bucket and key
    bucket, key = s3_arn.split(':::')[1].split('/')

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

    # Invoke the Bedrock model with the extracted text and the provided parameters
    try:
        response = bedrock.invoke_model(
            ModelName=bedrock_params['model_name'],
            Payload=json.dumps({
                'master': bedrock_params['master'],
                'prompt': prompt,
                'message': extracted_text
            })
        )
    except BotoCoreError as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }

    return {
        'statusCode': 200,
        'body': 'Successfully processed the S3 ARN',
        'bedrockResponse': response
    }