variable "resource_prefix" {
  description = "The prefix to associate with all the resources"
}

variable "resource_suffix" {
  description = "The suffix to apply to ensure unique resource names"
}

variable "subnet_ids" {
  description = "The permitted subnets for the instance"
  type        = list(string)
}

variable "source_security_group_id" {
  description = "The security group id to permit traffic from"
}

variable "vpc_id" {
  description = "The VPC for the instance"
}

variable "use_existing_cloudwatch_log_group" {
  description = "Indicates whether the Lambda CloudWatch group already exists"
}


variable "lambda_artifact_path" {

}

variable "lambda_handler" {

}

variable "lambda_runtime" {

}

variable "lambda_memory_size" {

}

variable "lambda_timeout" {

}

variable "lambda_layers" {
  default = []
}

variable "lambda_tracing_mode" {

}

variable "environment_variables" {

}