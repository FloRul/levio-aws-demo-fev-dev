import json
import boto3
from botocore.exceptions import NoCredentialsError
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

def lambda_handler(event, context):
    """
    Downloads the attachment_s3_arns into memory and add them as attachments before sending the email with the given params.
    body is an array of json strings with the following format: {type: "plain/html/xml/csv", message: "Hello World"}
    attachment_s3_arns can be in URI or ARN format
    """
    sender_email = event['sender_email']
    destination_email = event['destination_email']
    subject = event['subject']
    body = event['body']
    attachment_s3_arns = event.get('attachment_s3_arns', [])
    multipart_mime_type = event.get('multipart_mime_type', 'mixed')

    ses = boto3.client('ses')
    s3 = boto3.client('s3')
    msg = MIMEMultipart(multipart_mime_type)
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = destination_email

    for mime_text_dict in body:
        mime_text = MIMEText(mime_text_dict['message'], mime_text_dict['type'])
        msg.attach(mime_text)

    for attachment in attachment_s3_arns:
        try:
            s3_bucket, s3_key = attachment.replace("s3://", "").replace("arn:aws:s3:::", "").split("/", 1)
            print(f"Fetching attachment {s3_key} from bucket {s3_bucket}")
            file_obj = s3.get_object(Bucket=s3_bucket, Key=s3_key)
            file_content = file_obj['Body'].read()

            part = MIMEApplication(file_content)
            part.add_header('Content-Disposition', 'attachment', filename=s3_key)
            msg.attach(part)
        except NoCredentialsError:
            print("S3 Access Denied")

    try:
        response = ses.send_raw_email(
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

