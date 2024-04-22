import tabula
import os
import boto3
from pypdf import PdfReader

OBJECT_CREATED = "ObjectCreated"
EXTRACTED_TEXT_S3_OBJECT_KEY_PREFIX = 'pdf_extraction_result'
PATH_TO_WRITE_FILES = "/tmp"
s3 = boto3.client("s3")


def extract_text_from_pdf(pdf_file_path):
    text = ""

    reader = PdfReader(pdf_file_path)
    for page in reader.pages:
        text += page.extract_text()

    dataFrames = tabula.read_pdf(pdf_file_path, pages="all", lattice=True)
    for df in dataFrames:
        text += df.to_html()

    return text


def get_bucket_and_key(record):
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]
    return bucket, key


def fetch_file(bucket, key):
    local_filename = f"{PATH_TO_WRITE_FILES}/{key.split('/')[-1]}"
    s3.download_file(bucket, key, local_filename)
    return local_filename


def upload_text(extracted_text, bucket, key):
    file_name = os.path.splitext(
        os.path.basename(key)
    )[0] + "_pdf_extracted_text.txt"

    local_file_path = f"{PATH_TO_WRITE_FILES}/{file_name}"

    # build a new object key in an adjacent folder
    parts = key.split('/')
    parts.insert(-1, EXTRACTED_TEXT_S3_OBJECT_KEY_PREFIX)
    s3_object_key = '/'.join(parts[:-1] + [file_name])

    with open(local_file_path, "w") as f:
        f.write(extracted_text)

    with open(local_file_path, "rb") as f:
        s3.upload_fileobj(f, bucket, s3_object_key)

    print(f"Stored file {s3_object_key} in bucket {bucket}")


def lambda_handler(event, context):
    print(event)
    attachment_path = event['path']


    try:
        bucket, key = get_bucket_and_key(attachment_path)
        print(f"source_bucket: {bucket}, source_key: {key}")

        if os.path.splitext(key)[1][1:] == "pdf":
            local_filename = fetch_file(bucket, key)
            print("Extracting text from pdf")
            extracted_text = extract_text_from_pdf(local_filename)
            print("Finished extracting text from pdf")
            upload_text(extracted_text, bucket, key)

    except Exception as e:
        print(e)
        raise e
