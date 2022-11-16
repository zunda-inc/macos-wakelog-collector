# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

resource "aws_s3_bucket" "log_upload_bucket" {
  bucket = "${var.namespace}-raw-logs"
}

resource "aws_s3_bucket_acl" "log_upload_bucker_acl" {
  bucket = aws_s3_bucket.log_upload_bucket.id
  acl = "private"
}

resource "aws_s3_bucket_notification" "log_upload_bucket" {
  bucket = aws_s3_bucket.log_upload_bucket.id

  queue {
    queue_arn     = aws_sqs_queue.log_upload_bucket_put.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
