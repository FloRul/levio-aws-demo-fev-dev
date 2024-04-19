import json
import boto3
import os
from aws_lambda_powertools import Logger, Metrics
from botocore.exceptions import ParamValidationError

logger = Logger()
metrics = Metrics()

step_functions_client = boto3.client("stepfunctions")
STATE_MACHINE_ARN = os.environ.get("STATE_MACHINE_ARN")


@metrics.log_metrics
def lambda_handler(event, context):
    """
    This function is responsible for invoking the state machine with the given event.
    The state machine arn is defined in the environment variable STATE_MACHINE_ARN.
    """
    logger.info(event)

    try:
        state_machine_execution_result = step_functions_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            input=json.dumps(event),
        )

        logger.info(state_machine_execution_result)
        return {
            "statusCode": 200,
            "body": json.dumps(state_machine_execution_result),
        }

    except ParamValidationError as e:
        logger.error(e)
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Parameter validation error", "details": str(e)}),
        }

    except Exception as e:
        logger.error(e)
        return {
            "statusCode": 400,
            "body": json.dumps(e),
        }



