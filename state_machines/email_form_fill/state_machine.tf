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
  definition = jsonencode(file("${path.module}/state_machine.json"))
}
