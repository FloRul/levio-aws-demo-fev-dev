import boto3
import re
from io import BytesIO

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Downloads the given text file (txt, html, json, csv, xml, js, py, md etc...) and for each replacement item it replaces the matching replacement_key with the replacement_text 
    """
    try:
        s3_arn = event['doc_s3_arn']
        replacements = event['replacements']

        s3_bucket, s3_key = s3_arn.replace("s3://", "").replace("arn:aws:s3:::", "").split("/", 1)

        print(f"Download bucket: {s3_bucket}, key: {s3_key}")

        file_obj = s3.get_object(Bucket=s3_bucket, Key=s3_key)

        file_content = file_obj['Body'].read().decode('utf-8')

        for replacement in replacements:
            print(f"replacing {replacement['replacement_key']} with {replacement['replacement_text'][:10]}")
            file_content = re.sub(re.escape(replacement['replacement_key']), replacement['replacement_text'], file_content)

        output_stream = BytesIO()
        output_stream.write(file_content.encode('utf-8'))

        s3.put_object(Bucket=s3_bucket, Key=s3_key, Body=output_stream.getvalue())

        return {
            'statusCode': 200,
            'body': f'Successfully modified {s3_key} and uploaded to {s3_bucket}'
        }

    except Exception as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }