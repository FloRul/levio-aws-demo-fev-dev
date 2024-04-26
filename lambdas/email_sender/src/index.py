import boto3
from botocore.exceptions import NoCredentialsError
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

def lambda_handler(event, context):
    """
    Downloads the attachment_s3_arns into memory and add them as attachments before sending the email with the given params.

    """
    sender_email = event['sender_email']
    destination_email = event['destination_email']
    subject = event['subject']
    body = event['body']
    attachment_s3_uris = event['attachment_s3_uris']

    client = boto3.client('ses')
    s3 = boto3.client('s3')

    msg = MIMEMultipart()
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = destination_email
    msg.attach(MIMEText(body, 'plain'))

    for attachment in attachment_s3_uris:
        try:
            s3_bucket, s3_key = attachment.replace("s3://", "").split("/", 1)
            file_obj = s3.get_object(Bucket=s3_bucket, Key=s3_key)
            file_content = file_obj['Body'].read()

            part = MIMEApplication(file_content)
            part.add_header('Content-Disposition', 'attachment', filename=s3_key)
            msg.attach(part)
        except NoCredentialsError:
            print("S3 Access Denied")

    try:
        response = client.send_raw_email(
            Source=sender_email,
            Destinations=[destination_email],
            RawMessage={
                'Data': msg.as_string(),
            }
        )

        return {
            'statusCode': 200,
            'body': response
        }

    except Exception as e:
        print(e)
        raise e

