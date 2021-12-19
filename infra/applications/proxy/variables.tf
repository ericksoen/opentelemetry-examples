variable "resource_prefix" {
    description = "The prefix to associate with all the resources"
}

variable "subnet_ids" {
    description = "The permitted subnets for the instance"
    type = list(string)
}

variable "target_base_url" {
    description = "The base url, e.g., https://domain.com to use as the proxy target" 
}

variable "http_trace_gateway_base_url" {
    description = "The base url, e.g., https://domain.com to use to send OTLP telemetry over HTTP" 
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