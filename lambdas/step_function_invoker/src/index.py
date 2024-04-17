import json
import boto3
import os
from aws_lambda_powertools import Logger, Metrics

logger = Logger()
metrics = Metrics()

step_functions_client = boto3.client("stepfunctions")
STATE_MACHINE_ARN = os.environ.get("STATE_MACHINE_ARN"),


@metrics.log_metrics
def lambda_handler(event, context):
    logger.info(event)

    try:
        state_machine_execution_result = step_functions_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            input=json.dumps(event),
        )

        return {
            "statusCode": 200,
            "body": json.dumps(state_machine_execution_result),
        }
    
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps(e),
        }



