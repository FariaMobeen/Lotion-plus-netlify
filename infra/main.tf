terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

# specify the provider region
provider "aws" {
  region = "ca-central-1"
  access_key = "AKIAXHPQRW4CRDSNA2W2"
  secret_key = "mmn0WeL1GcnPx5iB/f1DaBJpjuc5LNQp7YShmEbG"
}

# the locals block is used to declare constants that
# you can use throughout your code
locals {
  function_name = "save-note-30139868"
  handler_name  = "main.lambda_handler"
  artifact_name = "artifact.zip"

  get_notes_artifact_name = "get-notes-artifact.zip"
  delete_note_artifact_name = "delete-note-artifact.zip"
}

# create a role for the Lambda function to assume
# every service on AWS that wants to call other AWS services should first assume a role and
# then any policy attached to the role will give permissions
# to the service so it can interact with other AWS services
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda" {
  name               = "iam-for-lambda-${local.function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create archive file from main.py
data "archive_file" "lambda" {
  type = "zip"
  source_file = "functions/save-note/main.py"
  output_path = "artifact.zip"
}

data "archive_file" "lambda_get_notes" {
  type = "zip"
  source_file = "functions/get-notes/main.py"
  output_path = local.get_notes_artifact_name
}


data "archive_file" "lambda_delete_note" {
  type = "zip"
  source_file = "functions/delete-note/main.py"
  output_path = local.delete_note_artifact_name
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda" {
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name
  handler          = local.handler_name
  filename         = local.artifact_name
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

resource "aws_lambda_function" "get_notes" {
  role             = aws_iam_role.lambda.arn
  function_name    = "get-notes-30139868"
  handler          = local.handler_name
  filename         = local.get_notes_artifact_name
  source_code_hash = data.archive_file.lambda_get_notes.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

resource "aws_lambda_function" "delete_note" {
  role             = aws_iam_role.lambda.arn
  function_name    = "delete-notes-30139868"
  handler          = local.handler_name
  filename         = local.delete_note_artifact_name
  source_code_hash = data.archive_file.lambda_delete_note.output_base64sha256

  # see all available runtimes here: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime
  runtime = "python3.9"
}

# create a policy for publishing logs to CloudWatch
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "logs" {
  name        = "lambda-logging-${local.function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:DeleteItem"
      ],
      "Resource": ["arn:aws:logs:::*",
"${aws_dynamodb_table.lotion-30122680.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}


# attach the above policy to the function role
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}

# create a Function URL for Lambda
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url
resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "get_notes" {
  function_name      = aws_lambda_function.get_notes.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "delete_note" {
  function_name      = aws_lambda_function.delete_note.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

# show the Function URL after creation

//502 Bad Gateway error fix this
output "lambda_url" {
  value = aws_lambda_function_url.url.function_url
}

//502 Bad Gateway error fix this
output "get_notes_lanmda_url" {
  value = aws_lambda_function_url.get_notes.function_url
}

output "delete_note_lanmda_url" {
  value = aws_lambda_function_url.delete_note.function_url
}


# read the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "lotion-30122680" {
  name         = "lotion-30122680"
  billing_mode = "PROVISIONED"

  # up to 8KB read per second (eventually consistent)
  read_capacity = 1

  # up to 1KB per second
  write_capacity = 1

  # we only need a student id to find an item in the table; therefore, we
  # don't need a sort key here
  hash_key = "email"
  range_key = "id"

  # the hash_key data type is string
  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}