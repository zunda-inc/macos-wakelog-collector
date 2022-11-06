# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

resource "null_resource" "upload_ticket_server_dependencies" {
  provisioner "local-exec" {
    command = "cd ../upload_ticket_server && npm install"
  }

  triggers = {
    package = sha256(file("../upload_ticket_server/package.json"))
    lock = sha256(file("../upload_ticket_server/package-lock.json"))
  }
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
                Resource = [
                  "${aws_s3_bucket.log_upload_bucket.arn}",
                  "${aws_s3_bucket.log_upload_bucket.arn}/*"
                ]
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
    function_name = "${var.namespace}-upload_ticket_server"
    role = aws_iam_role.upload_ticket_server.arn
    runtime = "nodejs16.x"
    handler = "index.handler"
    filename = data.archive_file.upload_ticket_server.output_path
    source_code_hash = data.archive_file.upload_ticket_server.output_base64sha256
    environment {
      variables = {
        aws_region = var.aws_region
        aws_s3_upload_bucket = aws_s3_bucket.log_upload_bucket.bucket
        client_token = var.client_token
      }
    }
}

resource "aws_api_gateway_rest_api" "upload_ticket_server" {
  name        = "${var.namespace}-upload ticket server"
  description = "${var.namespace}-upload ticket server"
}

resource "aws_api_gateway_resource" "upload_ticket_server" {
  rest_api_id = "${aws_api_gateway_rest_api.upload_ticket_server.id}"
  parent_id   = "${aws_api_gateway_rest_api.upload_ticket_server.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "upload_ticket_server" {
  rest_api_id   = "${aws_api_gateway_rest_api.upload_ticket_server.id}"
  resource_id   = "${aws_api_gateway_resource.upload_ticket_server.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_ticket_server" {
  rest_api_id = "${aws_api_gateway_rest_api.upload_ticket_server.id}"
  resource_id = "${aws_api_gateway_method.upload_ticket_server.resource_id}"
  http_method = "${aws_api_gateway_method.upload_ticket_server.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.upload_ticket_server.invoke_arn}"
}

resource "aws_api_gateway_deployment" "upload_ticket_server" {
  depends_on = [
    aws_api_gateway_integration.upload_ticket_server
  ]

  rest_api_id = "${aws_api_gateway_rest_api.upload_ticket_server.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "upload_ticket_server" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.upload_ticket_server.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.upload_ticket_server.execution_arn}/*/*"
}
