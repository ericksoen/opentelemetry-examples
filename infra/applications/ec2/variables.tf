variable "source_security_group_id" {
    description = "The security group id to permit traffic from"
}

variable "server_hostname" {
    description = "The server hostname for requests"
}

variable "server_request_resource" {
    description = "The resource to request from the server"
}

variable "health_check_path" {
    description = "The resource to use for health checks"
}

variable "subnet_ids" {
    description = "The permitted subnets for the instance"
    type = list(string)
}

variable "vpc_id" {
    description = "The VPC for the instance"
}

variable "assign_public_ip" {
    description = "Boolean flag to determine if service should be assigned a public IP"
    type = bool
    default = false
}

variable "resource_prefix" {
    description = "The prefix to associate with all the resources"
}

variable "otlp_insecure_hostname" {

}