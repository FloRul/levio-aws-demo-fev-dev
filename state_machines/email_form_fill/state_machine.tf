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
  name     = "esta-rfp-form-filler"
  role_arn = aws_iam_role.iam_for_sfn.arn
  definition = jsonencode({
  "Comment": "Retrieves attachments from an email and invokes an AI with the email attachments and a predefied set of promts. A form document is then filled with the AI responses and sent back to the user.",
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
          "StartAt": "Create copy of the RFP Form doc",
          "States": {
            "Create copy of the RFP Form doc": {
              "Comment": "Copy the form to be filled into this execution's email folder",
              "End": true,
              "Parameters": {
                "Bucket.$": "$.bucket",
                "CopySource.$": "States.Format('{}/rfp/standard/rfp.docx', $.bucket)",
                "Key.$": "States.Format('rfp/{}/formulaire_ao.docx', $.email_id)"
              },
              "Resource": "arn:aws:states:::aws-sdk:s3:copyObject",
              "Type": "Task"
            }
          }
        },
        {
          "StartAt": "Create copy of the RFP prompts and answers JSON",
          "States": {
            "Create copy of the RFP prompts and answers JSON": {
              "Type": "Task",
              "Parameters": {
                "Bucket.$": "$.bucket",
                "CopySource.$": "States.Format('{}/rfp/standard/rfp_prompts.json', $.bucket)",
                "Key.$": "States.Format('rfp/{}/rfp_prompts.json', $.email_id)"
              },
              "Resource": "arn:aws:states:::aws-sdk:s3:copyObject",
              "End": true
            }
          }
        },
        {
          "StartAt": "Download email attachments",
          "States": {
            "Download email attachments": {
              "Comment": "Extract attachments from a raw email MIME file and stores them in S3",
              "Next": "Map",
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
              "Type": "Task",
              "OutputPath": "$.Payload"
            },
            "Map": {
              "ItemProcessor": {
                "ProcessorConfig": {
                  "Mode": "INLINE"
                },
                "StartAt": "Choice",
                "States": {
                  "Choice": {
                    "Choices": [
                      {
                        "Next": "Rich PDF Ingestion",
                        "StringMatches": "*.pdf",
                        "Variable": "$"
                      }
                    ],
                    "Default": "Pass",
                    "Type": "Choice"
                  },
                  "Pass": {
                    "Comment": "Attachment is not PDF, no other processing needed. Map the input to an array just so it's easier to flatten the results of the map state.",
                    "End": true,
                    "Type": "Pass",
                    "Parameters": {
                      "arrr.$": "States.Array($)"
                    },
                    "OutputPath": "$.arrr"
                  },
                  "Rich PDF Ingestion": {
                    "OutputPath": "$.Payload.attachment_arns",
                    "Parameters": {
                      "FunctionName": "arn:aws:lambda:us-east-1:446872271111:function:rich_pdf_ingestion:$LATEST",
                      "Payload": {
                        "path.$": "$"
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
                    "Type": "Task",
                    "End": true
                  }
                }
              },
              "ItemsPath": "$.attachment_arns",
              "Type": "Map",
              "ResultSelector": {
                "attachment_arns.$": "$[*][*]"
              },
              "Next": "Get Prompts"
            },
            "Get Prompts": {
              "Type": "Task",
              "Parameters": {
                "Bucket": "levio-demo-fev-esta-ses-bucket-dev",
                "Key": "rfp/standard/rfp_prompts.json"
              },
              "Resource": "arn:aws:states:::aws-sdk:s3:getObject",
              "Next": "Get promps responses",
              "ResultPath": "$.Body",
              "ResultSelector": {
                "parsed_JSON.$": "States.StringToJson($.Body)"
              },
              "Comment": "Gets the promps s3 object and convert the escaped JSON to JSON"
            },
            "Get promps responses": {
              "Type": "Map",
              "ItemProcessor": {
                "ProcessorConfig": {
                  "Mode": "INLINE"
                },
                "StartAt": "Invoke Claude",
                "States": {
                  "Invoke Claude": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "OutputPath": "$.Payload",
                    "Parameters": {
                      "FunctionName": "arn:aws:lambda:us-east-1:446872271111:function:levio-esta-bedrock-invoker:$LATEST",
                      "Payload": {
                        "s3_arn": "sampleValue1",
                        "bedrock_params": {
                          "model_name": "",
                          "master": ""
                        },
                        "prompt.$": "$.prompt"
                      }
                    },
                    "Retry": [
                      {
                        "ErrorEquals": [
                          "Lambda.ServiceException",
                          "Lambda.AWSLambdaException",
                          "Lambda.SdkClientException",
                          "Lambda.TooManyRequestsException"
                        ],
                        "IntervalSeconds": 1,
                        "MaxAttempts": 3,
                        "BackoffRate": 2
                      }
                    ],
                    "End": true
                  }
                }
              },
              "End": true,
              "ItemsPath": "$.Body.parsed_JSON.prompts"
            }
          }
        }
      ],
      "Type": "Parallel",
      "End": true
    }
  }
})
}
