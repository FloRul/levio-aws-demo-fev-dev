import tabula
import os
import boto3
from pypdf import PdfReader

OBJECT_CREATED = "ObjectCreated"
EXTRACTED_TEXT_S3_OBJECT_KEY_PREFIX = 'pdf_extracted_text'
s3 = boto3.client("s3")


def generate_text_form_pdf(pdf_file_path):
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
    local_filename = f"/tmp/{key.split('/')[-1]}"
    s3.download_file(bucket, key, local_filename)
    return local_filename


def upload_text(extracted_text, bucket, key):
    file_name = os.path.splitext(os.path.basename(key))[
        0] + "_pdf_extracted_text.txt"
    local_file_path = "/tmp/" + file_name
    # build a new object key in an adjacent folder
    s3_object_key = os.path.join(os.path.dirname(
        key), EXTRACTED_TEXT_S3_OBJECT_KEY_PREFIX, file_name)

    with open(local_file_path, "w") as f:
        f.write(extracted_text)

    with open(local_file_path, "rb") as f:
        s3.upload_fileobj(f, bucket, s3_object_key)

    print(f"Stored file {s3_object_key} in bucket {bucket}")


def add_adjacent_folder(file_path, adjacent_folder_name):
    """Modifies the given file_path to that is has an adjecent folder"""
    parts = file_path.split('/')

    if len(parts) > 1:
        new_file_path = '/'.join(parts[:-1]) + '/' + \
            adjacent_folder_name + '/' + parts[-1]
    else:
        new_file_path = adjacent_folder_name + '/' + parts[-1]

    return new_file_path


def lambda_handler(event, context):
    print(event)
    records = event["Records"]

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
                print("Finished extracting text from pdf")
                upload_text(document_text, bucket, key)

        except Exception as e:
            print(e)
            raise e
