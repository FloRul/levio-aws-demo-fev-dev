import boto3
import pandas as pd
import os
from pathlib import Path
import uuid

s3 = boto3.client('s3')
PATH_TO_WRITE_FILES = "/tmp"

def lambda_handler(event, context):
    """
    Downloads the given xlsx file from S3, extracts the text content and saves it as a csv file in the same bucket, adjacent to the original xlsx file.
    """
    try:
        print(event)
        
        bucket, key = event['xlsx_s3_uri'].replace("s3://", "").split("/", 1)
        print(f"File located at bucket: {bucket} and key: {key}")

        if os.path.splitext(key)[1][1:] != "xlsx":
            return {
                'statusCode': 400,
                'body': 'Invalid file format. Only xlsx files are supported.'
            }

        downloaded_excel_path = fetch_file(bucket, key)
        df = pd.read_excel(downloaded_excel_path)
        csv_file_path = f"{PATH_TO_WRITE_FILES}/{str(uuid.uuid4())}.csv"
        df.to_csv(csv_file_path, index=False, sep='\t')
        base_path = Path(key).parent
        base_name = Path(key).stem
        new_key = f"{base_path}/{base_name}_extracted_xlsx_content.csv"

        with open(csv_file_path, "rb") as f:
            s3.upload_fileobj(f, bucket, new_key)
        
        return {
            'statusCode': 200,
            'body': 'xlsx text content extracted and saved',
            'extracted_csv_uri': f"s3://{bucket}/{new_key}"
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
