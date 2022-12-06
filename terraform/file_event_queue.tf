# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

resource "aws_sns_topic" "log_upload_bucket_put" {
    name = "${var.namespace}-s3-log-upload-bucket-put-notify"
}

resource "aws_sqs_queue"  "log_upload_bucket_put" {
    name = "${var.namespace}-log-upload-queue"
    visibility_timeout_seconds = 240

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:${var.namespace}-log-upload-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.log_upload_bucket.arn}" }
      }
    }
  ]
}
POLICY
}

