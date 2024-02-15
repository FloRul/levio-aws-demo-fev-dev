import json
from textractor import Textractor
from textractor.data.constants import TextractFeatures
from textractor.data.text_linearization_config import TextLinearizationConfig

OBJECT_CREATED = "ObjectCreated"
OBJECT_REMOVED = "ObjectRemoved"


def start_textract_job(bucket, key):
    extractor = Textractor()
    job = extractor.start_document_analysis(
        file_source=f"s3://{bucket}/{key}",
        features=[TextractFeatures.LAYOUT],
        save_image=False,
    )
    config = TextLinearizationConfig(
        hide_figure_layout=True,
        header_prefix="<header>",
        header_suffix="</header>",
        title_prefix="<title>",
        title_suffix="</title>",
        section_header_prefix="<section_header>",
        section_header_suffix="</section_header>",
        add_prefixes_and_suffixes_as_words=True,
        add_prefixes_and_suffixes_in_text=True,
    )
    linearized_text = job.document.get_text(config=config)
    return linearized_text
    


def get_bucket_and_key(record):
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]
    return bucket, key


def lambda_handler(event, context):
    print(event)
    records = json.loads(event["Records"][0]["body"])["Records"]
    for record in records:
        eventName = record["eventName"]
        print(f"eventName: {eventName}")
        try:
            bucket, key = get_bucket_and_key(record)
            print(f"source_bucket: {bucket}, source_key: {key}")

        except Exception as e:
            print(e)
            raise e
