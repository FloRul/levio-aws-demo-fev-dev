import json
import boto3
import os

ses = boto3.client('ses')


def lambda_handler(event, context):
    mail = json.loads(json.dumps(event['Records'][0]['ses']['mail']))

    subject = 'Re: ' + mail['commonHeaders']['subject']

    source = mail['destination'][0]

    to_addresses = [mail['source']]

    destination = {
        'ToAddresses': to_addresses
    }

    reply_text = os.environ.get(
        "RECEIPT_REPLY_TEXT", "Nous avons reçu votre demande et elle sera traité sous peut. Merci.\n"
    )

    reply_message = {
        'Subject': {
            'Data': subject,
        },
        'Body': {
            'Text': {
                'Data': reply_text
            }
        }
    }

    reply_to_addresses = [mail['destination'][0]]

    ses.send_email(
        Destination=destination,
        Message=reply_message,
        ReplyToAddresses=reply_to_addresses,
        Source=source
    )

    return 'Email sent!'