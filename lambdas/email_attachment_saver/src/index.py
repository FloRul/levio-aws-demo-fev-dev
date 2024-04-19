import boto3
import email
import base64
from botocore.exceptions import NoCredentialsError
from aws_lambda_powertools import Logger, Metrics

logger = Logger()
metrics = Metrics()
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    This lambda saves email attachments to S3. 

    It expects to receive the s3 bucket and folder where the attachments will be saved
    """
    
    logger.info(event)
    bucket = event['bucket']
    s3_folder = event['s3_folder']
    raw_email_data = event['Records'][0]['ses']['mail']['content']
    
    msg = email.message_from_bytes(base64.b64decode(raw_email_data))


    attachment_arns = []

    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_maintype() != 'multipart' and part['Content-Disposition'] is not None:
                try:
                    key = part.get_filename()
                    s3.put_object(Bucket=bucket, Key=s3_folder+key, Body=part.get_payload(decode=True))
                    attachment_arns.append('arn:aws:s3:::' + bucket + '/' + s3_folder + '/' + key)

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