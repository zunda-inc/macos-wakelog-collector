variable "upload_s3_bucket_arn" {
    type = string
}

variable "namespace" {
    type = string
}

resource "aws_iam_role" "upload_ticket_server" {
    name = "${var.namespace}-upload_ticket_server"
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
resource "aws_iam_role_policy_attachment" "upload_ticket_server" {
    role = aws_iam_role.upload_ticket_server.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "upload_ticket_server" {
    name = "${var.namespace}-upload_ticket_server-s3_access"
    role = aws_iam_role.upload_ticket_server.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject"
                ]
                Resource = "${var.upload_s3_bucket_arn}"
            }
        ]
    })
}

data "archive_file" "upload_ticket_server" {
    type = "zip"
    source_dir = "../upload_ticket_server"
    output_path = ".terraform/upload_ticket_server.zip"
}

resource "aws_lambda_function" "upload_ticket_server" {
    filename = data.archive_file.upload_ticket_server.output_path
    function_name = "${var.namespace}-upload_ticket_server"
    role = aws_iam_role.upload_ticket_server.arn
    handler = "main.hander"
    runtime = "nodejs16.x"
    source_code_hash = data.archive_file.upload_ticket_server.output_base64sha256
}