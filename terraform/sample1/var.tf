variable "aws_region" {
  description = "The AWS region in which all resources will be created"
  type        = string
  validation {
    condition     = contains(["us-east-1", "eu-west-1"], var.aws_region)
    error_message = "AWS region must be 'us-east-1' or 'eu-west-1'."
  } 
}
#jbjkjkd
