variable "resource_prefix" {
  description = "The prefix/name for all resources"
  default     = "otel-app"
}

variable "vpc_filters" {
  description = "A set of filters used to dynamically identify a single VPC to use"
  type        = map(any)
}

variable subnet_configuration {
  description = "The subnet configuration to use for your gateway services. The default configuration will launch _all_ services in a public subnet with a public IP."
  type = object({
    prefer_private_ip = bool
    public_subnet_filters = map(any)
    private_subnet_filters = map(any)
  })

  default = {
    prefer_private_ip = false
    public_subnet_filters = {}
    private_subnet_filters = {}
  }

    validation {
        condition = (length(var.subnet_configuration.public_subnet_filters) > 0 
            && (var.subnet_configuration.prefer_private_ip == true ? length(var.subnet_configuration.private_subnet_filters) > 0 : true))
        error_message = "Public subnet filters are _always_ required. Private subnet filters are required when prefer_private_ip == true."
    }
}

variable "image_repository" {
  description = "The image id to use"
}

variable "default_tags" {
  description = "The tags to assign to all resources"
}

variable "domain" {
  description = "The name of the domain to associate with resources"
}

variable "app_subdomain" {
  description = "The subdomain for application traffic"
  default     = "demo"
}

variable "otlp_grpc_hostname" {
  description = "The URL for receiving OTLP traces via gRPC"
}
variable "otlp_http_hostname" {
  description = "The URL for receiving OTLP traces via http"
}