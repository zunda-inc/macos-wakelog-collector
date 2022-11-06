# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

variable "aws_region" {
  description = "AWS region for all resources."
  type = string
  default = "ap-northeast-1"
}

variable "namespace" {
  description = "Namespace of the project"
  type  = string
  default = "z-wlc"
}

variable "client_token" {
  description = "Client token"
  type  = string
  default = "ReplaceMeForSecurity"
}