variable "resource_prefix" {
    description = "The prefix to associate with all the resources"
}

variable "region_name" {
    
}

variable "otlp_hostname" {

}

variable "subnet_ids" {
    description = "The permitted subnets for the instance"
    type = list(string)
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