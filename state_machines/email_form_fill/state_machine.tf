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

resource "aws_iam_role_policy" "sfn_lambda_invoke_access" {
  name = "sfn_lambda_invoke_access"
  role = aws_iam_role.iam_for_sfn.id

  policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "lambda:InvokeFunction"
                ],
                "Resource": [
                    "arn:aws:lambda:*:*:function:*"
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
  "Comment": "A description of my state machine",
  "StartAt": "Map SES email",
  "States": {
    "Map SES email": {
      "Comment": "Map an SES email for easier consumption later on in the sate machine:\n\nemail_id: the ID of the email\ndestination_email: the destination of the email\nsender_email: the sender of the email\nbucket: the  S3 bucket in which all operations should take place in\nraw_email_key: the s3 key to the raw email. See the SES \"Deliver to S3 Bucket\" action",
      "Next": "Parallel",
      "Parameters": {
        "bucket": "levio-demo-fev-esta-ses-bucket-dev",
        "destination_email.$": "$.Records[0].ses.mail.destination",
        "email_id.$": "$.Records[0].ses.mail.messageId",
        "raw_email_key.$": "States.Format('rfp/raw_emails/{}', $.Records[0].ses.mail.messageId)",
        "sender_email.$": "$.Records[0].ses.mail.source"
      },
      "Type": "Pass"
    },
    "Parallel": {
      "Branches": [
        {
          "StartAt": "Store Email Medata",
          "States": {
            "Store Email Medata": {
              "Comment": "Stores the input in the specified bucket/key",
              "End": true,
              "Parameters": {
                "Body.$": "$",
                "Bucket.$": "$.bucket",
                "Key.$": "States.Format('rfp/{}/email', $.email_id)"
              },
              "Resource": "arn:aws:states:::aws-sdk:s3:putObject",
              "Type": "Task"
            }
          }
        },
        {
          "StartAt": "Download email attachments",
          "States": {
            "Download email attachments": {
              "Comment": "Extract attachments from a raw email MIME file and stores them in S3",
              "Next": "Filter PDF attachments",
              "OutputPath": "$.Payload",
              "Parameters": {
                "FunctionName": "email-attachment-saver-dev",
                "Payload": {
                  "bucket.$": "$.bucket",
                  "s3_email_key.$": "$.raw_email_key",
                  "s3_folder_key.$": "States.Format('rfp/{}/attachments', $.email_id)"
                }
              },
              "Resource": "arn:aws:states:::lambda:invoke",
              "Retry": [
                {
                  "BackoffRate": 2,
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  "IntervalSeconds": 1,
                  "MaxAttempts": 3
                }
              ],
              "Type": "Task"
            },
            "Extract Text/Tables/Images from PDF attachments": {
              "End": true,
              "ItemProcessor": {
                "ProcessorConfig": {
                  "Mode": "INLINE"
                },
                "StartAt": "Rich PDF Ingestion",
                "States": {
                  "Rich PDF Ingestion": {
                    "End": true,
                    "OutputPath": "$.Payload",
                    "Parameters": {
                      "FunctionName": "arn:aws:lambda:us-east-1:446872271111:function:rich_pdf_ingestion:$LATEST",
                      "Payload.$": "$"
                    },
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Retry": [
                      {
                        "BackoffRate": 2,
                        "ErrorEquals": [
                          "Lambda.ServiceException",
                          "Lambda.AWSLambdaException",
                          "Lambda.SdkClientException",
                          "Lambda.TooManyRequestsException"
                        ],
                        "IntervalSeconds": 1,
                        "MaxAttempts": 3
                      }
                    ],
                    "Type": "Task"
                  }
                }
              },
              "Type": "Map"
            },
            "Filter PDF attachments": {
              "InputPath": "$..attachment_arns[?(@.extension==pdf)]",
              "Next": "Extract Text/Tables/Images from PDF attachments",
              "Type": "Pass"
            }
          }
        }
      ],
      "End": true,
      "Type": "Parallel"
    }
  }
})
}
