import boto3
from docx import Document
from io import BytesIO

s3 = boto3.client('s3')


def lambda_handler(event, context):
    """
    Downloads the given docx and for each replacement item it replaces the matching replacement_key with the replacement_text 
    """
    try:
        s3_arn = event['doc_s3_arn']
        replacements = event['replacements']

        s3_bucket, s3_key = s3_arn.replace("s3://", "").replace("arn:aws:s3:::", "").split("/", 1)


        print(f"Download bucket: {s3_bucket}, key: {s3_key}")

        file_obj = s3.get_object(Bucket=s3_bucket, Key=s3_key)

        file_content = file_obj['Body'].read()

        doc = Document(BytesIO(file_content))

        for paragraph in doc.paragraphs:
            for replacement in replacements:
                if replacement['replacement_key'] in paragraph.text:
                    print(f"replacing {replacement['replacement_key']} with {replacement['replacement_text'][:10]}")
                    paragraph.text = paragraph.text.replace(replacement['replacement_key'], replacement['replacement_text'])

        output_stream = BytesIO()
        doc.save(output_stream)

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
