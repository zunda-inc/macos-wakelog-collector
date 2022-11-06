resource "aws_s3_bucket" "log_upload_bucket" {
  bucket = "${var.namespace}-raw-logs"
}

resource "aws_s3_bucket_acl" "log_upload_bucker_acl" {
  bucket = aws_s3_bucket.log_upload_bucket.id
  acl = "private"
}
