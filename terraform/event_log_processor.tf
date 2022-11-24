# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

resource "null_resource" "event_log_processor_dependencies" {
  provisioner "local-exec" {
    command = "cd ../event_log_processor && npm install"
  }

  triggers = {
    package = sha256(file("../event_log_processor/package.json"))
    lock = sha256(file("../event_log_processor/package-lock.json"))
  }
}

resource "aws_iam_role" "event_log_processor" {
    name = "${var.namespace}-event_log_processor"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "event_log_processor" {
    role = aws_iam_role.event_log_processor.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "event_log_processor" {
    name = "${var.namespace}-event_log_processor-s3_access"
    role = aws_iam_role.event_log_processor.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "s3:*"
                Resource = [
                  "${aws_s3_bucket.log_upload_bucket.arn}",
                  "${aws_s3_bucket.log_upload_bucket.arn}/*",
                  "${aws_s3_bucket.aggregated_log_bucket.arn}",
                  "${aws_s3_bucket.aggregated_log_bucket.arn}/*",
                  "${aws_s3_bucket.log_archive_bucket.arn}",
                  "${aws_s3_bucket.log_archive_bucket.arn}/*",
                ]
            },
            {
                Effect = "Allow"
                Action = [
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage",
                    "sqs:GetQueueAttributes"
                ]
                Resource = "${aws_sqs_queue.log_upload_bucket_put.arn}"
            },
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "*"
            }
        ]
    })
}

data "archive_file" "event_log_processor" {
    type = "zip"
    source_dir = "../event_log_processor"
    output_path = ".terraform/event_log_processor.zip"
}

resource "aws_lambda_function" "event_log_processor" {
    function_name = "${var.namespace}-event_log_processor"
    role = aws_iam_role.event_log_processor.arn
    runtime = "nodejs16.x"
    handler = "index.dequeue"
    filename = data.archive_file.event_log_processor.output_path
    source_code_hash = data.archive_file.event_log_processor.output_base64sha256
    environment {
      variables = {
        aws_region = var.aws_region
        aws_s3_aggregated_log_bucket = aws_s3_bucket.aggregated_log_bucket.bucket
        aws_s3_log_archive_bucket = aws_s3_bucket.log_archive_bucket.bucket
        tz = "Asia/Tokyo"
      }
    }
}

resource "aws_lambda_event_source_mapping" "event_log_processor" {
  event_source_arn = "${aws_sqs_queue.log_upload_bucket_put.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.event_log_processor.arn}"
  batch_size       = 1
}
