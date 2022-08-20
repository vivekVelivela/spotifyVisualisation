variable "project_name" {
  type = string
  default = "lambda"
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "region"{
  type = string
  default = "ap-southeast-2"
}

variable "lambda_root" {
  type        = string
  description = "The relative path to the source of the Lambda function"
  default     = "../Lambda"
}