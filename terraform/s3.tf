# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

resource "aws_s3_bucket" "aggregated_log_bucket" {
  bucket = "${var.namespace}-aggregated-logs"
}

resource "aws_s3_bucket_acl" "aggregated_log_bucket_acl" {
  bucket = aws_s3_bucket.aggregated_log_bucket.id
  acl = "private"
}

resource "aws_s3_bucket" "log_archive_bucket" {
  bucket = "${var.namespace}-archived-logs"
}

resource "aws_s3_bucket_acl" "log_archive_bucket_acl" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  acl = "private"
}
