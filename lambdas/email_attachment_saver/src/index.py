import boto3
import email
from botocore.exceptions import NoCredentialsError
from aws_lambda_powertools import Logger, Metrics

logger = Logger()
metrics = Metrics()
s3 = boto3.client('s3')


def lambda_handler(event, context):
    """
    This lambda downloads an email MIME file from S3, extracts its attachments, and saves them to another S3 folder.
    Returns: A dictionary containing the status code, a message, and the list of attachment ARNs
    """
    logger.info(event)
    bucket = event['bucket']
    s3_email_key = event['s3_email_key']
    s3_folder = event['s3_folder_key']

    try:
        response = s3.get_object(Bucket=bucket, Key=s3_email_key)
    except NoCredentialsError:
        logger.error('No AWS credentials found')
        return {
            'statusCode': 400,
            'body': 'Error in the credentials'
        }

    raw_email_data = response['Body'].read()
    msg = email.message_from_bytes(raw_email_data)

    attachment_arns = []

    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_maintype() != 'multipart' and part['Content-Disposition'] is not None:
                try:
                    key = "/".join([s3_folder,part.get_filename()])
                    logger.info(f"Putting object in bucket:{bucket} and key:{key}")
                    s3.put_object(Bucket=bucket, Key=key, Body=part.get_payload(decode=True))
                    file_extension = key.split('.')[-1] if '.' in key else None
                    attachment_arns.append({
                        'path': 'arn:aws:s3:::' + bucket + '/' + key,
                        'extension': file_extension
                    })

                except NoCredentialsError:
                    logger.error('No AWS credentials found')
                    return {
                        'statusCode': 400,
                        'body': 'Error in the credentials'
                    }

    logger.info(attachment_arns)
    return {
        'statusCode': 200,
        'body': 'Attachments saved to S3',
        'attachment_arns': attachment_arns
    }
