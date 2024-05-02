import tabula
import os
import boto3
from pypdf import PdfReader
import uuid
from pathlib import Path

OBJECT_CREATED = "ObjectCreated"
EXTRACTED_TEXT_S3_OBJECT_KEY_PREFIX = 'pdf_extraction_result'
PATH_TO_WRITE_FILES = "/tmp"
s3 = boto3.client("s3")


def lambda_handler(event, context):
    """
    Etract text/tables from a PDF and store in a s3 object
    """
    print(event)

    try:
        bucket, key = event['pdf_s3_uri'].replace("s3://", "").split("/", 1)

        print(f"Attachment located at bucket: {bucket} and key: {key}")

        if os.path.splitext(key)[1][1:] != "pdf":
            return {
                'statusCode': 400,
                'body': 'Invalid file format. Only PDF files are supported.'
            }

        local_filename = fetch_file(bucket, key)
        extracted_text = extract_text_from_pdf(local_filename)
        extracted_text_local_file = store_extracted_text_in_local_file(extracted_text)
        base_path = Path(key).parent
        base_name = Path(key).stem
        new_key = f"{base_path}/{base_name}_extracted_pdf_content.txt"
        upload_file(
            file_to_upload=extracted_text_local_file,
            bucket=bucket,
            key=new_key
        )
        extracted_files_s3_arns = []
        extracted_files_s3_arns.append(f"arn:aws:s3:::{bucket}/{new_key}")

        return {
            'statusCode': 200,
            'body': 'PDF text content extracted and saved',
            'attachment_arns': extracted_files_s3_arns
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 400,
            'body': e
        }


def extract_text_from_pdf(pdf_file_path):
    text = ""

    reader = PdfReader(pdf_file_path)
    for page in reader.pages:
        text += page.extract_text()

    dataFrames = tabula.read_pdf(pdf_file_path, pages="all", lattice=True)
    for df in dataFrames:
        text += df.to_html()

    return text

def fetch_file(bucket, key):
    local_filename = f"{PATH_TO_WRITE_FILES}/{key.split('/')[-1]}"
    s3.download_file(bucket, key, local_filename)
    return local_filename


def upload_file(file_to_upload, bucket, key,):
    with open(file_to_upload, "rb") as f:
        s3.upload_fileobj(f, bucket, key)


def store_extracted_text_in_local_file(extracted_text):
    local_file_path = f"{PATH_TO_WRITE_FILES}/{str(uuid.uuid4())}"

    with open(local_file_path, "w") as f:
        f.write(extracted_text)

    return local_file_path
