import json
import boto3
from aws_lambda_powertools import Logger, Metrics

logger = Logger()
metrics = Metrics()

step_functions_client = boto3.client("stepfunctions")


@metrics.log_metrics
def lambda_handler(event, context):
    logger.info(event)

    print("Hello, Step Functions! Let's list up to 10 of your state machines:")
    state_machines = step_functions_client.list_state_machines(maxResults=10)
    for sm in state_machines["stateMachines"]:
        logger.info(f"\t{sm['name']}: {sm['stateMachineArn']}")
        print(f"\t{sm['name']}: {sm['stateMachineArn']}")

    return {
        "statusCode": 400,
        "body": json.dumps("An error occurred"),
    }
