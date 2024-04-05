import tabula
import os
import boto3
from pypdf import PdfReader
from botocore.exceptions import NoCredentialsError, BotoCoreError, ClientError

OBJECT_CREATED = "ObjectCreated"


def generate_text_form_pdf(pdf_file_path):
    text = ""

    reader = PdfReader(pdf_file_path)
    for page in reader.pages:
        text += page.extract_text()

    dataFrames = tabula.read_pdf(pdf_file_path, pages="all",lattice=True)
    for df in dataFrames:
        text += df.to_html()

    return text

def get_bucket_and_key(record):
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]
    return bucket, key

def fetch_file(bucket, key):
    s3 = boto3.client("s3")
    local_filename = f"/tmp/{key.split('/')[-1]}"

    try:
        s3.download_file(bucket, key, local_filename)
    except NoCredentialsError as e:
        print(e)
        raise e
    except BotoCoreError as e:
        print(e)
        raise e
    except ClientError as e:
        print(e)
        raise e
    
    return local_filename


def lambda_handler(event, context): 
    print(event)
    records = event["Records"]
    print(tabula.environment_info())
    for record in records:
        eventName = record["eventName"]
        print(f"eventName: {eventName}")

        try:
            bucket, key = get_bucket_and_key(record)
            print(f"source_bucket: {bucket}, source_key: {key}")

            if eventName.startswith(OBJECT_CREATED) and os.path.splitext(key)[1][1:] == "pdf":
                local_filename = fetch_file(bucket, key)
                print("Extracting text from pdf")
                document_text = generate_text_form_pdf(local_filename)
                print(f"Extracted: {document_text}")

        except Exception as e:
            print(e)
            raise e
