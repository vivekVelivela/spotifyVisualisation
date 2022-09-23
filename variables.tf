variable "project_name" {
  type = string
  default = "spotifyVisualisation"
}

variable "region"{
  type = string
  default = "ap-southeast-2"
}

variable "lambda_root" {
  type        = string
  description = "The relative path to the source of the Lambda function"
  default     = "./Lambda"
}
variable "aws_secret_access_key" {
  type        = string
}
variable "aws_access_key_id" {
   type        = string
  
}
variable "env" {
  type = string
} 

 