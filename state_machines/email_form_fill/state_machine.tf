resource "aws_iam_role" "iam_for_sfn" {
  name               = "my_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "states.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "sfn_lambda_s3_access" {
  name = "sfn_lambda_s3_access"
  role = aws_iam_role.iam_for_sfn.id

  policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:AbortMultipartUpload",
                    "s3:ListBucket",
                    "s3:DeleteObject",
                    "s3:GetObjectVersion",
                    "s3:ListMultipartUploadParts"
                ],
                "Resource": [
                    "arn:aws:s3:::*/*"
                ]
            }
        ]
    }
  EOF
}


resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn
  definition = jsonencode({
    "Comment" : "A description of my state machine",
    "StartAt" : "Store Email Medata",
    "States" : {
      "Store Email Medata" : {
        "Type" : "Task",
        "Next" : "Lambda Invoke",
        "Parameters" : {
          "Body" : {
            "sender_email.$" : "$.ses.mail.source",
            "destination_email.$" : "$.ses.mail.destination",
            "email_id.$" : "$.ses.mail.messageId",
            "prompts" : [
              {
                "key" : "A",
                "prompt" : "",
                "answer" : ""
              }
            ]
          },
          "Bucket" : var.workspace_bucket_name,
          "Key" : "MyData"
        },
        "Resource" : "arn:aws:states:::aws-sdk:s3:putObject"
      },
      "Lambda Invoke" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::lambda:invoke",
        "OutputPath" : "$.Payload",
        "Parameters" : {
          "Payload.$" : "$",
          "FunctionName" : var.attachment_saver_lambda_name
        },
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ],
            "IntervalSeconds" : 1,
            "MaxAttempts" : 3,
            "BackoffRate" : 2
          }
        ],
        "End" : true
      }
    }
  })
}
