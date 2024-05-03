import boto3
from docx import Document
import os
from pathlib import Path
import uuid

s3 = boto3.client('s3')
PATH_TO_WRITE_FILES = "/tmp"

def lambda_handler(event, context):
    """
    Downloads the given docx file from S3, extracts the text content and saves it as a txt file in the same bucket, adjacent to the docx file.
    """
    try:
        print(event)
        
        bucket, key = event['docx_s3_uri'].replace("s3://", "").split("/", 1)
        print(f"File located at bucket: {bucket} and key: {key}")

        if os.path.splitext(key)[1][1:] != "docx":
            return {
                'statusCode': 400,
                'body': 'Invalid file format. Only PDF files are supported.'
            }

        downloaded_docx_path = fetch_file(bucket, key)
        doc = Document(downloaded_docx_path)
        extracted_text = '\n'.join([paragraph.text for paragraph in doc.paragraphs])
        txt_file_path = f"{PATH_TO_WRITE_FILES}/{str(uuid.uuid4())}.txt"

        with open(txt_file_path, 'w') as txt_file:
            txt_file.write(extracted_text)

        base_path = Path(key).parent
        base_name = Path(key).stem
        new_key = f"{base_path}/{base_name}_extracted_docx_content.txt"

        with open(txt_file_path, "rb") as f:
            s3.upload_fileobj(f, bucket, new_key)
        
        return {
            'statusCode': 200,
            'body': 'DOCX text content extracted and saved',
            'attachment_uri': f"s3://{bucket}/{new_key}"
        }

    except Exception as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }



def fetch_file(bucket, key):
    local_file_path = f"{PATH_TO_WRITE_FILES}/{key.split('/')[-1]}"
    s3.download_file(bucket, key, local_file_path)
    return local_file_path
