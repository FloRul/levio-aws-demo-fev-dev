import json
import boto3
import os
from aws_lambda_powertools import Logger, Metrics

logger = Logger()
metrics = Metrics()

ses = boto3.client("ses")


@metrics.log_metrics
def lambda_handler(event, context):
    logger.info(event)
    try:
        mail = json.loads(json.dumps(event["Records"][0]["ses"]["mail"]))

        subject = "Re: " + mail["commonHeaders"]["subject"]

        source = mail["destination"][0]

        to_addresses = [mail["source"]]

        destination = {"ToAddresses": to_addresses}

        reply_text = os.environ.get(
            "RECEIPT_REPLY_TEXT",
            "Nous avons reçu votre demande et elle sera traitée sous peu. Merci.\n",
        )

        reply_message = {
            "Subject": {
                "Data": subject,
            },
            "Body": {"Text": {"Data": reply_text}},
        }

        reply_to_addresses = [mail["destination"][0]]

        ses.send_email(
            Destination=destination,
            Message=reply_message,
            ReplyToAddresses=reply_to_addresses,
            Source=source,
        )

        return {
            "statusCode": 200,
            "body": json.dumps("Email sent successfully"),
        }
    except Exception as e:
        logger.error(e)
        return {
            "statusCode": 500,
            "body": json.dumps("An error occurred"),
        }
