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
    attachment_s3_arn = event['path']

    try:
        attachment_s3_info = parse_s3_arn(attachment_s3_arn)
        print("Attachment s3 arn parsed info: ", attachment_s3_info)
        bucket = attachment_s3_info["bucket"]
        key = attachment_s3_info["key"]

        if os.path.splitext(key)[1][1:] != "pdf":
            return {
                'statusCode': 400,
                'body': 'Invalid file format. Only PDF files are supported.'
            }

        local_filename = fetch_file(bucket, key)
        extracted_text = extract_text_from_pdf(local_filename)
        extracted_text_local_file = store_extracted_text_in_local_file(extracted_text)
        base_name = Path(key).stem
        new_key = f"{base_name}_extracted_pdf_content.txt"
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


def parse_s3_arn(s3_arn):
    # Remove the ARN prefix
    s3_path = s3_arn.replace("arn:aws:s3:::", "")

    # Split the path into components
    components = s3_path.split("/")

    # The first component is the bucket
    bucket = components[0]


    # The folder is all components of the key except the last one
    folder = "/".join(components[1:-1])

    return {
        "bucket": bucket,
        "folder": folder,
    }


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
