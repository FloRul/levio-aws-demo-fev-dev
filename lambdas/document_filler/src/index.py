import boto3
from docx import Document
from io import BytesIO

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Downloads the given docx and for each replacement item it replaces the matching replacement_key with the replacement_text
    """
    s3_arn = event['doc_s3_arn']
    replacements = event['replacements']

    bucket_name = s3_arn.split(':')[5].split('/')[0]
    key = '/'.join(s3_arn.split(':')[5].split('/')[1:])

    print(f"Download bucket: {bucket_name}, key: {key}")

    file_obj = s3.get_object(Bucket=bucket_name, Key=key)
    file_content = file_obj['Body'].read()

    doc = Document(BytesIO(file_content))

    for paragraph in doc.paragraphs:
        for replacement in replacements:
            if replacement['replacement_key'] in paragraph.text:
                paragraph.text = paragraph.text.replace(replacement['replacement_key'], replacement['replacement_text'])

    output_stream = BytesIO()
    doc.save(output_stream)

    s3.put_object(Bucket=bucket_name, Key=key, Body=output_stream.getvalue())

    return {
        'statusCode': 200,
        'body': f'Successfully modified {key} and uploaded to {bucket_name}'
    }