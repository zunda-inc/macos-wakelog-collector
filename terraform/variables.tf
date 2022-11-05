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