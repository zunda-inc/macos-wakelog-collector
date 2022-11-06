# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

output "upload_ticket_server-invoke_url" {
    value = aws_api_gateway_deployment.upload_ticket_server.invoke_url
}
